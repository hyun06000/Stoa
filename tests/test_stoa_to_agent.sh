#!/usr/bin/env bash
# test_stoa_to_agent.sh
# Stoa(시스템)가 특정 에이전트에게 편지를 보내는 흐름.
# from=stoa, to=ergon.
# 시스템 공지/알림 패턴: 백업 완료, scheduler 발화 등.
#
# Pass: 201 + ?from=stoa 필터에 포함.

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

echo "[1] POST  from=stoa to=ergon"
post_resp=$(curl -s -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{"from":"stoa","to":"ergon","content":"백업 완료: seq=42 → /data/snapshots"}')
echo "  $post_resp"

msg_id=$(echo "$post_resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
[ -n "$msg_id" ] || { echo "FAIL: no id"; exit 1; }

echo "[2] GET  /api/v1/messages?from=stoa  → must contain $msg_id"
list_resp=$(curl -s "$URL/api/v1/messages?from=stoa")
echo "$list_resp" | python3 -c "
import json,sys
d = json.load(sys.stdin)
ids = [m['id'] for m in d['messages']]
assert '$msg_id' in ids, f'missing: {ids}'
# 모든 항목의 from이 stoa여야 한다 (필터 동작)
assert all(m['from']=='stoa' for m in d['messages']), 'filter broken'
print('  ✓ filter ok, count=', d['count'])
"

echo "PASS test_stoa_to_agent"
