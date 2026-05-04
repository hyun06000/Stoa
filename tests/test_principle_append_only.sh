#!/usr/bin/env bash
# 원칙 3: 쌓이기만.
# DELETE/PUT/PATCH 핸들러 자체가 없음 (404).
# 같은 id로 INSERT 재시도하면 SQLite primary key가 막음 (서버 500이지만
# 기존 row 그대로).

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

# issue#4 sender registry gate — 발신자 ergon 사전 등록 (idempotent).
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"ergon","address":"http://x"}' > /dev/null

echo "[1] DELETE는 404 (grammar에 없음)"
code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$URL/api/v1/messages/anything")
[ "$code" = "404" ] || { echo "FAIL: DELETE returned $code (expected 404)"; exit 1; }
echo "  ✓ DELETE → 404"

echo "[2] PUT은 404"
code=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$URL/api/v1/messages/anything" -d '{}')
[ "$code" = "404" ] || { echo "FAIL: PUT returned $code"; exit 1; }
echo "  ✓ PUT → 404"

echo "[3] PATCH는 404"
code=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$URL/api/v1/messages/anything" -d '{}')
[ "$code" = "404" ] || { echo "FAIL: PATCH returned $code"; exit 1; }
echo "  ✓ PATCH → 404"

echo "[4] 편지 한 통 INSERT, 그 다음 어떤 endpoint로도 변경 못 한다"
r=$(curl -s -X POST "$URL/api/v1/messages" -H "Content-Type: application/json" -d '{
  "from":{"name":"ergon","address":"http://x"},
  "to":[{"name":"arche","address":"http://y"}],
  "content":"original"
}')
id=$(echo "$r" | python3 -c "import json,sys; print(json.load(sys.stdin)['envelope']['id'])")
original=$(curl -s "$URL/api/v1/messages/$id" | python3 -c "import json,sys; print(json.load(sys.stdin)['content'])")
[ "$original" = "original" ] || { echo "FAIL: content not original"; exit 1; }
echo "  ✓ original content saved (id=$id)"

# DELETE/PUT 시도 (이미 위에서 검증됨)
curl -s -o /dev/null -X DELETE "$URL/api/v1/messages/$id" || true
curl -s -o /dev/null -X PUT "$URL/api/v1/messages/$id" -d '{"content":"hacked"}' || true

after=$(curl -s "$URL/api/v1/messages/$id" | python3 -c "import json,sys; print(json.load(sys.stdin)['content'])")
[ "$after" = "original" ] || { echo "FAIL: content changed to $after"; exit 1; }
echo "  ✓ DELETE/PUT 시도 후에도 'original' 그대로"

echo "[5] 새 편지는 새 id를 받는다 (덮어쓰기 불가)"
r2=$(curl -s -X POST "$URL/api/v1/messages" -H "Content-Type: application/json" -d '{
  "from":{"name":"ergon","address":"http://x"},
  "to":[{"name":"arche","address":"http://y"}],
  "content":"second"
}')
id2=$(echo "$r2" | python3 -c "import json,sys; print(json.load(sys.stdin)['envelope']['id'])")
[ "$id2" != "$id" ] || { echo "FAIL: same id reused"; exit 1; }
echo "  ✓ 새 id $id2 ≠ $id"

# 인박스에는 두 편지가 다 살아있음 (둘 다 보존)
count=$(curl -s "$URL/api/v1/messages?to=arche" | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])")
[ "$count" -ge 2 ] || { echo "FAIL: arche inbox has $count"; exit 1; }
echo "  ✓ arche 인박스에 ≥2 (쌓이기만)"

echo "PASS test_principle_append_only"
