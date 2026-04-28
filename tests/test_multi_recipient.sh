#!/usr/bin/env bash
# test_multi_recipient.sh — 한 통, 수신자 N명.
# Stoa는 N개 폴더에 동일 사본을 두어야 한다 (id 동일).

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

echo "[1] POST 세 명에게"
resp=$(curl -s -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{
      "from": {"name":"ergon","address":"http://localhost:0/none"},
      "to":   [
        {"name":"arche", "address":"http://localhost:0/none"},
        {"name":"telos", "address":"http://localhost:0/none"},
        {"name":"homeros","address":"http://localhost:0/none"}
      ],
      "content":"broadcast 테스트"
    }')
msg_id=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin)['envelope']['id'])")
[ -n "$msg_id" ] || { echo "FAIL: $resp"; exit 1; }
echo "  msg_id=$msg_id"

echo "[2] 세 폴더 각각 같은 envelope 보유"
for who in arche telos homeros; do
    body=$(curl -s "$URL/api/v1/messages/$msg_id?to=$who")
    actual=$(echo "$body" | python3 -c "import json,sys; m=json.load(sys.stdin); print(m['id'])")
    if [ "$actual" = "$msg_id" ]; then
        echo "  ✓ $who has $msg_id"
    else
        echo "  ✗ $who missing it (got: $actual)"
        exit 1
    fi
done

echo "[3] envelope.to[]에는 세 명 모두 보존"
body=$(curl -s "$URL/api/v1/messages/$msg_id?to=arche")
echo "$body" | python3 -c "
import json,sys
m = json.load(sys.stdin)
names = [r['name'] for r in m['to']]
assert names == ['arche','telos','homeros'], names
print('  ✓ to[] = arche, telos, homeros')
"

echo "PASS test_multi_recipient"
