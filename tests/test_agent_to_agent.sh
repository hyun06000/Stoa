#!/usr/bin/env bash
# test_agent_to_agent.sh
# 에이전트끼리 편지 — Stoa는 라우팅만.
# from=ergon, to=arche.
#
# Pass: 201 + ?to=arche 필터에 포함 + Stoa 자체는 sender도 recipient도 아님.

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

echo "[1] POST  from=ergon to=arche"
post_resp=$(curl -s -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{"from":"ergon","to":"arche","content":"on_letter 문법화 완료. v1.69.0 라이브."}')
msg_id=$(echo "$post_resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
[ -n "$msg_id" ] || { echo "FAIL: no id"; echo "$post_resp"; exit 1; }
echo "  msg_id=$msg_id"

echo "[2] GET  /api/v1/messages?to=arche  → 포함"
echo "$(curl -s "$URL/api/v1/messages?to=arche")" | python3 -c "
import json,sys
d = json.load(sys.stdin)
ids = [m['id'] for m in d['messages']]
assert '$msg_id' in ids
print('  ✓ to=arche 필터 통과')
"

echo "[3] GET  /api/v1/messages?from=ergon  → 포함"
echo "$(curl -s "$URL/api/v1/messages?from=ergon")" | python3 -c "
import json,sys
d = json.load(sys.stdin)
ids = [m['id'] for m in d['messages']]
assert '$msg_id' in ids
print('  ✓ from=ergon 필터 통과')
"

echo "[4] GET  /api/v1/messages?to=stoa  → 미포함 (Stoa는 라우터일 뿐)"
echo "$(curl -s "$URL/api/v1/messages?to=stoa")" | python3 -c "
import json,sys
d = json.load(sys.stdin)
ids = [m['id'] for m in d['messages']]
assert '$msg_id' not in ids, f'agent-to-agent letter leaked into stoa inbox: {ids}'
print('  ✓ Stoa 인박스 격리됨')
"

echo "PASS test_agent_to_agent"
