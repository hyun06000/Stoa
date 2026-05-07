#!/usr/bin/env bash
# Memory pressure hotfix v2 — INSERT throttle purge.
#
# 위임: Stoa-Admin priority:high incident msg_1778164886_2. v1 (polling 입구만 purge)이
# INSERT burst 시 fire 안 함이 Stoa 3차 다운 자리. v2는 N INSERT마다 purge 한 번 추가 호출.
#
# 시나리오 (자체 server, retention 2s + throttle 3):
#   V2-1. POST A → sleep 3 (A 만료) → POST B,C → throttle=3 도달, purge fire → A inbox 0건.
#   V2-2. (회귀) v1 polling 입구 purge 그대로 유지 (M3 회귀 — polling 시점 purge fire).
#   V2-3. throttle=0 (env override) — INSERT 측 비활성, v1 동작 (sleep 후 polling 시 fire).

set -uo pipefail

PORT="${MEM_V2_PORT:-18892}"
URL="http://localhost:$PORT"

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-mem-v2-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_LETTERS_RETENTION_SECONDS=2 \
    STOA_PURGE_THROTTLE_INSERTS=3 \
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

# 사전 등록
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"v2-sender","address":"http://127.0.0.1:1/inbox"}' > /dev/null
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"v2-recv","address":"http://127.0.0.1:2/inbox"}' > /dev/null

post_letter() {
    local msg="$1"
    curl -s -o /dev/null -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" \
        -d "{\"from\":{\"name\":\"v2-sender\",\"address\":\"http://127.0.0.1:1/inbox\"},\"to\":[{\"name\":\"v2-recv\",\"address\":\"http://127.0.0.1:2/inbox\"}],\"content\":\"$msg\"}"
}

inbox_count() {
    curl -s "$URL/api/v1/messages?to=v2-recv" | python3 -c "
import json,sys
d = json.load(sys.stdin)
print(len(d.get('messages',[])))"
}

# ── V2-1: throttle 3 — INSERT 측 purge 발동 ──
# polling 회피를 위해 GET 호출은 마지막 검증 시 한 번만.
post_letter "A-old"
# 직접 inbox 체크하면 polling purge fire되므로 sleep만.
sleep 3
# 이 시점 A는 retention(2s) 초과 — polling 안 하면 살아 있음. 이제 INSERT 2건 더.
post_letter "B-fresh"
post_letter "C-fresh"
# counter: A=1, B=2, C=3 → C에서 throttle 도달, purge fire. A 제거.
# 이제 GET — purge는 polling 입구에서도 fire하지만 이미 A 없음.
COUNT=$(inbox_count)
if [ "$COUNT" = "2" ]; then
    PASS=$((PASS+1))
    echo "  ✓ V2-1 INSERT throttle purge: A 제거 후 inbox 2건 (B, C)"
else
    FAIL=$((FAIL+1))
    echo "  ✗ V2-1: inbox $COUNT건 (expected 2 — B, C)"
fi

# ── V2-2: polling 입구 purge 회귀 ──
# 새 letter D POST, sleep 3, GET → D 만료로 0건.
post_letter "D-soon-old"
sleep 3
COUNT=$(inbox_count)
if [ "$COUNT" = "0" ]; then
    PASS=$((PASS+1))
    echo "  ✓ V2-2 polling 입구 purge 그대로 (D 만료 후 GET → 0)"
else
    FAIL=$((FAIL+1))
    echo "  ✗ V2-2: inbox $COUNT건 (expected 0)"
fi

cleanup
sleep 1

# ── V2-3: throttle=0 (env override) — INSERT 측 비활성, v1 동작 ──
TMP3=$(mktemp -d -t stoa-mem-v3-XXXXXX)
cp "$REPO_DIR/server.ail" "$TMP3/"
cd "$TMP3"
PORT3="${MEM_V3_PORT:-18893}"
URL3="http://localhost:$PORT3"
PYTHONUNBUFFERED=1 PORT="$PORT3" \
    STOA_DB_FILE="$TMP3/messages.db" \
    STOA_LETTERS_RETENTION_SECONDS=2 \
    STOA_PURGE_THROTTLE_INSERTS=0 \
    ail run server.ail > server3.log 2>&1 &
SRV=$!

for _ in $(seq 1 40); do
    curl -fs "$URL3/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.5
done

curl -s -X POST "$URL3/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"v2-sender","address":"http://127.0.0.1:1/inbox"}' > /dev/null
curl -s -X POST "$URL3/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"v2-recv","address":"http://127.0.0.1:2/inbox"}' > /dev/null

# A POST → sleep 3 → B, C, D POST (INSERT throttle 비활성이므로 purge 안 fire) → GET 시 첫 polling purge.
curl -s -o /dev/null -X POST "$URL3/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{"from":{"name":"v2-sender","address":"http://127.0.0.1:1/inbox"},"to":[{"name":"v2-recv","address":"http://127.0.0.1:2/inbox"}],"content":"A"}'
sleep 3
for body in B C D; do
    curl -s -o /dev/null -X POST "$URL3/api/v1/messages" \
        -H "Content-Type: application/json" \
        -d "{\"from\":{\"name\":\"v2-sender\",\"address\":\"http://127.0.0.1:1/inbox\"},\"to\":[{\"name\":\"v2-recv\",\"address\":\"http://127.0.0.1:2/inbox\"}],\"content\":\"$body\"}"
done
# 이 시점 throttle=0이라 INSERT 측 purge 안 발동. 다음 GET이 polling purge fire.
COUNT3=$(curl -s "$URL3/api/v1/messages?to=v2-recv" | python3 -c "
import json,sys
d = json.load(sys.stdin)
print(len(d.get('messages',[])))")
# polling purge가 fire되므로 A는 제거, B/C/D 살아남음 → 3건.
if [ "$COUNT3" = "3" ]; then
    PASS=$((PASS+1))
    echo "  ✓ V2-3 throttle=0 비활성: GET 시 polling purge로 A만 제거, 3건 (B,C,D)"
else
    FAIL=$((FAIL+1))
    echo "  ✗ V2-3: inbox $COUNT3건 (expected 3)"
fi

echo "  PASS=$PASS  FAIL=$FAIL"
[ $FAIL -eq 0 ] && echo "PASS test_memory_pressure_hotfix_v2" || exit 1
