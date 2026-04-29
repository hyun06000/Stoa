#!/usr/bin/env bash
# Stoa client 테스트.
# alice / bob 두 클라이언트가 Stoa를 거쳐 편지를 주고받는다.
#
# 클라이언트의 세 정체성: name, address(listening), stoa_url
# - GET /         → 자기 정체 응답
# - POST /send    → Stoa로 편지 forward
# - POST /inbox   → Stoa의 push 수신
# - GET /inbox    → 받은 편지 목록

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

CLIENT_AIL="$(cd "$(dirname "$0")/.." && pwd)/client.ail"
[ -f "$CLIENT_AIL" ] || { echo "client.ail not found at $CLIENT_AIL"; exit 1; }

TMP=$(mktemp -d -t stoa-client-XXXXXX)
ALICE="$TMP/alice"; BOB="$TMP/bob"
mkdir -p "$ALICE" "$BOB"
cp "$CLIENT_AIL" "$ALICE/"
cp "$CLIENT_AIL" "$BOB/"

cleanup() {
    [ -n "${AP:-}" ] && kill "$AP" 2>/dev/null
    [ -n "${BP:-}" ] && kill "$BP" 2>/dev/null
    rm -rf "$TMP"
}
trap cleanup EXIT

A_PORT=29001
B_PORT=29002
A_ADDR="http://127.0.0.1:$A_PORT/inbox"
B_ADDR="http://127.0.0.1:$B_PORT/inbox"

(cd "$ALICE" && CLIENT_NAME=alice CLIENT_ADDRESS="$A_ADDR" STOA_URL="$URL" PORT=$A_PORT PYTHONUNBUFFERED=1 ail run client.ail > "$TMP/alice.log" 2>&1) &
AP=$!
(cd "$BOB" && CLIENT_NAME=bob CLIENT_ADDRESS="$B_ADDR" STOA_URL="$URL" PORT=$B_PORT PYTHONUNBUFFERED=1 ail run client.ail > "$TMP/bob.log" 2>&1) &
BP=$!

# 기동 대기
for _ in $(seq 1 30); do
    if curl -fs http://127.0.0.1:$A_PORT/health > /dev/null 2>&1 \
        && curl -fs http://127.0.0.1:$B_PORT/health > /dev/null 2>&1; then break; fi
    sleep 0.3
done

echo "[1] 클라이언트는 자기 정체를 안다 (name + address + stoa_url)"
identity=$(curl -fs http://127.0.0.1:$A_PORT/)
echo "$identity" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['name'] == 'alice', d
assert d['address'] == '$A_ADDR', d
assert d['stoa_url'] == '$URL', d
print('  ✓', d)
"

echo "[2] alice → bob (Stoa 경유)"
r=$(curl -fs -X POST http://127.0.0.1:$A_PORT/send -H "Content-Type: application/json" \
    -d "{\"to\":[{\"name\":\"bob\",\"address\":\"$B_ADDR\"}],\"content\":\"hi bob\"}")
echo "  ✓ send response: $r"
sleep 0.5

echo "[3] bob 인박스에 alice 편지 도착"
bob_inbox=$(curl -fs http://127.0.0.1:$B_PORT/inbox)
echo "$bob_inbox" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['count'] >= 1, d
m = d['messages'][-1]
assert m['from']['name'] == 'alice', m
assert m['content'] == 'hi bob', m
print('  ✓ bob received from alice:', m['content'])
"

echo "[4] alice 인박스는 비어있다 (받은 적 없음)"
alice_inbox=$(curl -fs http://127.0.0.1:$A_PORT/inbox)
echo "$alice_inbox" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['count'] == 0, d
print('  ✓ alice inbox empty')
"

echo "[5] bob → alice (반대 방향도)"
curl -fs -X POST http://127.0.0.1:$B_PORT/send -H "Content-Type: application/json" \
    -d "{\"to\":[{\"name\":\"alice\",\"address\":\"$A_ADDR\"}],\"content\":\"hi alice\"}" > /dev/null
sleep 0.5
alice_inbox=$(curl -fs http://127.0.0.1:$A_PORT/inbox)
echo "$alice_inbox" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['count'] == 1, d
m = d['messages'][0]
assert m['from']['name'] == 'bob', m
assert m['content'] == 'hi alice', m
print('  ✓ alice received from bob:', m['content'])
"

echo "PASS test_client"
