#!/usr/bin/env bash
# test_schema_valid.sh — 정상 envelope 한 통.
# 한 명에게. 폴더 1개 생기고 envelope 사본 1개.

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

echo "[1] POST 한 명에게"
resp=$(curl -s -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{
      "from": {"name":"ergon","address":"http://localhost:0/agent-ergon"},
      "to":   [{"name":"arche","address":"http://localhost:0/agent-arche"}],
      "content":"v0.0.3 첫 편지"
    }')
echo "  $resp"

msg_id=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin)['envelope']['id'])")
[ -n "$msg_id" ] || { echo "FAIL: no id"; exit 1; }

echo "[2] GET ?to=arche  → 포함"
echo "$(curl -s "$URL/api/v1/messages?to=arche")" | python3 -c "
import json,sys
d = json.load(sys.stdin)
ids = [m['id'] for m in d['messages']]
assert '$msg_id' in ids, f'missing: {ids}'
assert d['recipient'] == 'arche'
print('  ✓ count=', d['count'])
"

echo "[3] GET single  → roundtrip"
single=$(curl -s "$URL/api/v1/messages/$msg_id?to=arche")
echo "$single" | python3 -c "
import json,sys
m = json.load(sys.stdin)
assert m['id'] == '$msg_id'
assert m['from']['name'] == 'ergon'
assert m['to'][0]['name'] == 'arche'
assert m['content'] == 'v0.0.3 첫 편지'
print('  ✓ roundtrip')
"

echo "PASS test_schema_valid"
