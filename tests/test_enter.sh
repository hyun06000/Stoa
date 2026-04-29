#!/usr/bin/env bash
# 에이전트 진입점.
# POST /api/v1/enter  body {name, address?}
#  → 등록 + 인박스 스냅샷 + 안내 한 번에.

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

echo "[1] GET /api/v1/enter — 안내문"
doc=$(curl -sf "$URL/api/v1/enter")
echo "$doc" | grep -q "에이전트 진입점" || { echo "FAIL: missing 안내문"; exit 1; }
echo "  ✓ docs OK"

echo "[2] POST enter — name만"
r=$(curl -sf -X POST "$URL/api/v1/enter" -H "Content-Type: application/json" -d '{"name":"agent_a"}')
echo "$r" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['name']=='agent_a', d
assert '/inbox/agent_a' in d['address'], d
assert d['inbox_count'] == 0, d
assert isinstance(d['principles'], list) and len(d['principles']) == 3, d
assert 'send' in d['api'] and 'inbox' in d['api'], d
print('  ✓ welcome:', d['welcome'])
print('  ✓ auto-address:', d['address'])
"

echo "[3] POST enter — 명시 address (덮어씀, latest wins)"
r=$(curl -sf -X POST "$URL/api/v1/enter" -H "Content-Type: application/json" -d '{"name":"agent_a","address":"http://my.custom/inbox"}')
echo "$r" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['address']=='http://my.custom/inbox', d
print('  ✓ override:', d['address'])
"
latest=$(curl -sf "$URL/api/v1/agents/agent_a")
echo "$latest" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['address']=='http://my.custom/inbox', d
print('  ✓ registry latest:', d['address'])
"

echo "[4] enter 후에 곧바로 편지 받으면 다음 enter에서 카운트 증가"
curl -sf -X POST "$URL/api/v1/messages" -H "Content-Type: application/json" -d '{
  "from":{"name":"sender","address":"http://nope"},
  "to":[{"name":"agent_a","address":"http://nope"}],
  "content":"hello agent_a"
}' --max-time 5 > /dev/null || true

r=$(curl -sf -X POST "$URL/api/v1/enter" -H "Content-Type: application/json" -d '{"name":"agent_a"}')
echo "$r" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['inbox_count'] >= 1, d
m = d['recent_letters'][0]
assert m['content']=='hello agent_a', m
print('  ✓ inbox snapshot:', d['inbox_count'], 'letters')
"

echo "[5] name 누락 → 400"
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL/api/v1/enter" \
    -H "Content-Type: application/json" -d '{}')
[ "$code" = "400" ] || { echo "FAIL: $code"; exit 1; }
echo "  ✓ 400 on missing name"

echo "PASS test_enter"
