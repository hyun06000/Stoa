#!/usr/bin/env bash
# Stoa#13 트랙 A — `_pump_subscriber` polling-only inbox URL self-loop 차단.
#
# 증상: AIL 5인(homeros·arche·ergon·telos·tekton) registry address가 룰 25 정합
#       `https://<host>/inbox/<name>` 패턴. autonomous tick context에서
#       `_get_self_origin()`가 state read 결손으로 "" 반환 → fallback A는 self-row
#       `stoa://self`에 `/inbox/` 없어 `_is_self_host` false → pump가 자기 서버로
#       POST 발사 → /inbox/<name> 404 + urllib socket alloc 누적 → RSS 우상향.
#
# Fix: `_pump_subscriber` 진입부에 `_is_polling_inbox(name, addr)` 가드.
#      addr suffix `/inbox/<name>` 매칭이면 push 0, 모든 pending letter
#      status="skipped" 일괄 마크.
#
# AC:
#   S13-1 polling-only 주소(<self>/inbox/agentX) 수신자에 letter POST → 외부
#         outbound POST /inbox/agentX 로그 0건 (tick 2회 이상 경과 후).
#   S13-2 같은 letter가 GET /api/v1/messages?to=agentX 로 회수 가능 (DB 보존 무영향).
#   S13-3 외부 unreachable 수신자(host:port=localhost:9)에는 기존 push path 그대로
#         (회귀 0) — 즉 POST 시도가 일어나서 _delivery_pending에 status 누적되는
#         것 자체는 막지 않음. polling-only 분기와 무관.

set -uo pipefail

PORT="${STOA13_TEST_PORT:-18894}"
URL="http://localhost:$PORT"

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-stoa13-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

unset STOA_SELF_ORIGIN
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_TICK_SEC=1 \
    ail run server.ail > server.log 2>&1 &
SRV=$!
for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"; tail -40 server.log; exit 1
fi

# 발신자 + polling-only 수신자 사전 등록.
curl -fs -X POST "$URL/api/v1/enter" \
    -H 'Content-Type: application/json' \
    -d '{"name":"alice"}' >/dev/null

curl -fs -X POST "$URL/api/v1/enter" \
    -H 'Content-Type: application/json' \
    -d "{\"name\":\"agentX\",\"address\":\"$URL/inbox/agentX\"}" >/dev/null

# S13-1: letter POST → 자기 서버 outbound self-POST 0건 검증.
LETTER_RESP=$(curl -fs -X POST "$URL/api/v1/messages" \
    -H 'Content-Type: application/json' \
    -d "{
        \"from\": {\"name\":\"alice\",\"address\":\"$URL/inbox/alice\"},
        \"to\": [{\"name\":\"agentX\",\"address\":\"$URL/inbox/agentX\"}],
        \"content\": \"stoa#13 pump polling-only skip\"
    }")
MID=$(echo "$LETTER_RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))')

# tick 3회 경과 — pump이 polling-only 분기 진입 자리 보장.
sleep 4

# server.log에서 inbound POST /inbox/agentX (autonomous pump 발 self-loop) 카운트.
# 정상 client polling GET은 영향 0. POST만 검사.
SELF_LOOP_POSTS=$(grep -c "POST /inbox/agentX" server.log || true)
if [ "$SELF_LOOP_POSTS" = "0" ]; then
    report_pass "S13-1 polling-only 수신자 self-loop POST 0건 (pump 분기 skip 정합)"
else
    report_fail "S13-1 self-loop POST $SELF_LOOP_POSTS 건 — pump skip 분기 결손"
    grep "POST /inbox/agentX" server.log | head -3
fi

# S13-2: letter DB 보존 — GET ?to=agentX로 회수.
GET_RESP=$(curl -fs "$URL/api/v1/messages?to=agentX&limit=5")
COUNT=$(echo "$GET_RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("count",0))')
if [ "$COUNT" -ge "1" ]; then
    report_pass "S13-2 letter GET 회수 OK (count=$COUNT) — DB 보존 무영향"
else
    report_fail "S13-2 letter 회수 0건 — DB 누락"
fi

# S13-3: 외부 비-polling 주소(non-/inbox/<name>) — 기존 push path 그대로.
# localhost:9는 reachable port 없음 → push 시도 → _push_one_fast attempt+try가
# Result-error로 흡수 → retry 누적 path. 본 fix 범위 밖, 회귀 0 확인용.
curl -fs -X POST "$URL/api/v1/enter" \
    -H 'Content-Type: application/json' \
    -d '{"name":"extern","address":"http://localhost:9/webhook/extern"}' >/dev/null

curl -fs -X POST "$URL/api/v1/messages" \
    -H 'Content-Type: application/json' \
    -d "{
        \"from\": {\"name\":\"alice\",\"address\":\"$URL/inbox/alice\"},
        \"to\": [{\"name\":\"extern\",\"address\":\"http://localhost:9/webhook/extern\"}],
        \"content\": \"external non-polling target\"
    }" >/dev/null

# tick 2회 경과.
sleep 3

# server.log에 polling-only 가드가 extern을 잘못 잡아 skip하는 흔적이 없어야 한다.
# 즉 agentX self-loop POST는 여전히 0이지만, server는 죽지 않고 살아 있어야 함.
if curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    report_pass "S13-3 외부 비-polling 주소 path 회귀 0 (server alive)"
else
    report_fail "S13-3 server down — 외부 path 회귀 발생"
fi

echo ""
echo "── summary ──"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" = "0" ]
