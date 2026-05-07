#!/usr/bin/env bash
# Memory pressure hotfix — Railway 메모리 압력 즉효 fix.
#
# 위임: Stoa-Admin priority:high (msg_1778156220_8) + arche audit (msg_1778156441_12).
# 진단: messages 테이블 무한 누적이 압력 source. 본 사이클 표본 avg 1.97KB · max 11.2KB.
# (a) STOA_LETTER_CONTENT_MAX_BYTES — validate_envelope에서 content cap → 400.
# (b) STOA_LETTERS_RETENTION_SECONDS — _purge_old_letters가 polling 시점에 옛 letter 삭제.
#
# 본 테스트는 자체 server 인스턴스 (cap 1000자, retention 2초)로 결정적 시나리오 회귀.
# run_all.sh의 phase=0 server에 attach 안 함 — env가 다른 테스트와 호환 안 됨.
#
# 시나리오:
#   M1. content > 1000자 → 400 "content_too_large".
#   M2. content ≤ 1000자 → 201.
#   M3. retention 2초 → POST 후 즉시 GET inbox 1건 → sleep 3 → GET inbox 0건 (purge 발동).
#   M4. validate_envelope 다른 에러는 그대로 (cap 게이트가 다른 검증 깨뜨리지 않음).

set -uo pipefail

PORT="${MEM_TEST_PORT:-18891}"
URL="http://localhost:$PORT"

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-mem-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_LETTER_CONTENT_MAX_BYTES=1000 \
    STOA_LETTERS_RETENTION_SECONDS=2 \
    ail run server.ail > server.log 2>&1 &
SRV=$!

for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.5
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"
    tail -40 server.log
    exit 1
fi

PASS=0
FAIL=0

# 사전 등록 — sender + recipient.
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"mem-sender","address":"http://127.0.0.1:1/inbox"}' > /dev/null
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"mem-recv","address":"http://127.0.0.1:2/inbox"}' > /dev/null

# ── M1: content > 1000자 → 400 content_too_large ──
BIG=$(printf 'x%.0s' $(seq 1 1500))
PAYLOAD=$(python3 -c "
import json,sys
print(json.dumps({
    'from':{'name':'mem-sender','address':'http://127.0.0.1:1/inbox'},
    'to':[{'name':'mem-recv','address':'http://127.0.0.1:2/inbox'}],
    'content':'$BIG'
}))")
code=$(curl -s -o /tmp/mem_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" -d "$PAYLOAD")
if [ "$code" = "400" ] && grep -q "content_too_large" /tmp/mem_resp; then
    PASS=$((PASS+1))
    echo "  ✓ M1 content > cap → 400 content_too_large"
else
    FAIL=$((FAIL+1))
    echo "  ✗ M1 → HTTP $code, body:"
    cat /tmp/mem_resp; echo
fi

# ── M2: content ≤ 1000자 → 201 ──
SMALL_PAYLOAD='{"from":{"name":"mem-sender","address":"http://127.0.0.1:1/inbox"},"to":[{"name":"mem-recv","address":"http://127.0.0.1:2/inbox"}],"content":"hello small letter"}'
code=$(curl -s -o /tmp/mem_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" -d "$SMALL_PAYLOAD")
if [ "$code" = "201" ]; then
    PASS=$((PASS+1))
    echo "  ✓ M2 content ≤ cap → 201"
else
    FAIL=$((FAIL+1))
    echo "  ✗ M2 → HTTP $code, body:"
    cat /tmp/mem_resp; echo
fi

# ── M3: retention 2초 → POST → 즉시 GET 1건 → sleep 3 → GET 0건 ──
# M2가 이미 mem-recv 인박스에 1건 넣음. 즉시 확인.
INBOX=$(curl -s "$URL/api/v1/messages?to=mem-recv")
COUNT_NOW=$(python3 -c "
import json,sys
d = json.loads('''$INBOX''')
print(len(d.get('messages',[])))")
if [ "$COUNT_NOW" = "1" ]; then
    echo "  · M3 pre: inbox 1건 확인"
else
    FAIL=$((FAIL+1))
    echo "  ✗ M3 pre: inbox $COUNT_NOW건 (expected 1)"
fi

sleep 3
INBOX=$(curl -s "$URL/api/v1/messages?to=mem-recv")
COUNT_AFTER=$(python3 -c "
import json,sys
d = json.loads('''$INBOX''')
print(len(d.get('messages',[])))")
if [ "$COUNT_AFTER" = "0" ]; then
    PASS=$((PASS+1))
    echo "  ✓ M3 retention purge: inbox 0건 (sleep 3 후, retention=2)"
else
    FAIL=$((FAIL+1))
    echo "  ✗ M3 retention purge: inbox $COUNT_AFTER건 (expected 0)"
fi

# ── M4: 다른 검증 에러는 그대로 (cap 게이트가 다른 검증 깨뜨리지 않음) ──
code=$(curl -s -o /tmp/mem_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{"from":{"name":"mem-sender","address":"http://127.0.0.1:1/inbox"},"to":[],"content":"empty to"}')
if [ "$code" = "400" ] && grep -q "to must have at least 1" /tmp/mem_resp; then
    PASS=$((PASS+1))
    echo "  ✓ M4 회귀: 빈 to 검증 그대로 400"
else
    FAIL=$((FAIL+1))
    echo "  ✗ M4 → HTTP $code, body:"
    cat /tmp/mem_resp; echo
fi

echo "  PASS=$PASS  FAIL=$FAIL"
[ $FAIL -eq 0 ] && echo "PASS test_memory_pressure_hotfix" || exit 1
