#!/usr/bin/env bash
# test_agent_to_stoa.sh
# 에이전트가 Stoa(시스템) 자체에게 편지를 보내는 흐름.
# from=ergon, to=stoa.
#
# Pass: 201 응답 + GET /messages?to=stoa 결과에 포함.

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

echo "[1] POST /api/v1/messages  from=ergon to=stoa"
post_resp=$(curl -s -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{"from":"ergon","to":"stoa","content":"백업 일정 알려줘"}')
echo "  $post_resp"

msg_id=$(echo "$post_resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
[ -n "$msg_id" ] || { echo "FAIL: no id in response"; exit 1; }

echo "[2] GET  /api/v1/messages?to=stoa  → must contain $msg_id"
list_resp=$(curl -s "$URL/api/v1/messages?to=stoa")
if echo "$list_resp" | python3 -c "import json,sys; d=json.load(sys.stdin); ids=[m['id'] for m in d['messages']]; sys.exit(0 if '$msg_id' in ids else 1)"; then
    echo "  ✓ found"
else
    echo "  FAIL: id $msg_id not in list"
    echo "  list_resp: $list_resp"
    exit 1
fi

echo "[3] GET  /api/v1/messages/$msg_id  → roundtrip identity"
single=$(curl -s "$URL/api/v1/messages/$msg_id")
echo "$single" | python3 -c "
import json,sys
m = json.load(sys.stdin)
assert m['id'] == '$msg_id'
assert m['from'] == 'ergon'
assert m['to'] == 'stoa'
assert m['content'] == '백업 일정 알려줘'
print('  ✓ roundtrip ok')
"

echo "PASS test_agent_to_stoa"
