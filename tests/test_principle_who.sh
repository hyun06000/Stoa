#!/usr/bin/env bash
# 원칙 1: 누가 누구에게.
# from/to를 그대로 보존하고, ?to=name 검색이 그 사람 메일만 돌려준다.

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

echo "[1] POST  ergon → arche"
r1=$(curl -s -X POST "$URL/api/v1/messages" -H "Content-Type: application/json" -d '{
  "from":{"name":"ergon","address":"http://x"},
  "to":[{"name":"arche","address":"http://y"}],
  "content":"hello arche"
}')
id1=$(echo "$r1" | python3 -c "import json,sys; print(json.load(sys.stdin)['envelope']['id'])")

echo "[2] POST  ergon → telos"
r2=$(curl -s -X POST "$URL/api/v1/messages" -H "Content-Type: application/json" -d '{
  "from":{"name":"ergon","address":"http://x"},
  "to":[{"name":"telos","address":"http://z"}],
  "content":"hello telos"
}')
id2=$(echo "$r2" | python3 -c "import json,sys; print(json.load(sys.stdin)['envelope']['id'])")

echo "[3] arche 인박스에는 첫 편지만"
arche_inbox=$(curl -s "$URL/api/v1/messages?to=arche")
echo "$arche_inbox" | python3 -c "
import json,sys
d = json.load(sys.stdin)
ids = [m['id'] for m in d['messages']]
assert '$id1' in ids
assert '$id2' not in ids, 'telos 편지가 arche 인박스에 새어들어옴'
print('  ✓ arche has only', d['count'], 'letter')
"

echo "[4] telos 인박스에는 둘째 편지만"
telos_inbox=$(curl -s "$URL/api/v1/messages?to=telos")
echo "$telos_inbox" | python3 -c "
import json,sys
d = json.load(sys.stdin)
ids = [m['id'] for m in d['messages']]
assert '$id2' in ids
assert '$id1' not in ids
print('  ✓ telos has only', d['count'], 'letter')
"

echo "[5] roundtrip — envelope 안에 from/to 그대로"
single=$(curl -s "$URL/api/v1/messages/$id1")
echo "$single" | python3 -c "
import json,sys
m = json.load(sys.stdin)
assert m['from']['name']=='ergon'
assert m['from']['address']=='http://x'
assert m['to'][0]['name']=='arche'
assert m['to'][0]['address']=='http://y'
print('  ✓ from/to 보존')
"

echo "PASS test_principle_who"
