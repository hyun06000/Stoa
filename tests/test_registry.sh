#!/usr/bin/env bash
# Registry 테스트.
#  - POST /api/v1/agents 로 자기 이름과 주소 등록
#  - GET  /api/v1/agents 전체 / GET /api/v1/agents/<name> 단건
#  - 같은 이름으로 다시 등록하면 latest wins (append-only — 이전 row 보존)

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

echo "[1] alice 등록"
r=$(curl -sf -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"alice","address":"http://a1/inbox"}')
echo "$r" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['name']=='alice', d
assert d['address']=='http://a1/inbox', d
assert 'registered_at' in d, d
print('  ✓', d)
"

echo "[2] bob 등록"
curl -sf -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"bob","address":"http://b1/inbox"}' > /dev/null
echo "  ✓ bob 등록"

echo "[3] 단건 조회"
single=$(curl -sf "$URL/api/v1/agents/alice")
echo "$single" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['name']=='alice'
assert d['address']=='http://a1/inbox'
print('  ✓ alice → http://a1/inbox')
"

echo "[4] 전체 조회"
all=$(curl -sf "$URL/api/v1/agents")
echo "$all" | python3 -c "
import json, sys
d = json.load(sys.stdin)
names = [a['name'] for a in d['agents']]
assert 'alice' in names and 'bob' in names, names
print('  ✓ count=', d['count'], 'names=', names)
"

echo "[5] alice 주소 변경 — 같은 이름으로 재등록"
curl -sf -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"alice","address":"http://a2/inbox"}' > /dev/null

latest=$(curl -sf "$URL/api/v1/agents/alice")
echo "$latest" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['address']=='http://a2/inbox', d
print('  ✓ latest wins:', d['address'])
"

echo "[6] 알 수 없는 이름 → 404"
code=$(curl -s -o /dev/null -w "%{http_code}" "$URL/api/v1/agents/ghost")
[ "$code" = "404" ] || { echo "FAIL: ghost returned $code"; exit 1; }
echo "  ✓ ghost → 404"

echo "[7] 검증 — name 누락"
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL/api/v1/agents" \
    -H "Content-Type: application/json" -d '{"address":"http://x"}')
[ "$code" = "400" ] || { echo "FAIL: missing name returned $code"; exit 1; }
echo "  ✓ name 없음 → 400"

echo "[8] 검증 — address 빈 문자열"
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$URL/api/v1/agents" \
    -H "Content-Type: application/json" -d '{"name":"x","address":""}')
[ "$code" = "400" ] || { echo "FAIL: empty address returned $code"; exit 1; }
echo "  ✓ address 빈 문자열 → 400"

echo "PASS test_registry"
