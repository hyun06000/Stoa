#!/usr/bin/env bash
# test_schema_invalid.sh — 잘못된 입력은 400으로 거부되어야.

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

post_invalid() {
    local desc="$1"
    local body="$2"
    code=$(curl -s -o /tmp/stoa-test-resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$body")
    if [ "$code" = "400" ]; then
        msg=$(python3 -c "import json; print(json.load(open('/tmp/stoa-test-resp'))['error'])" 2>/dev/null || echo "")
        echo "  ✓ $desc → 400 (\"$msg\")"
    else
        echo "  ✗ $desc → $code (expected 400)"
        cat /tmp/stoa-test-resp
        return 1
    fi
}

echo "[1] from 누락"
post_invalid "from 없음" '{"to":[{"name":"a","address":"x"}],"content":"y"}'

echo "[2] from.name 누락"
post_invalid "from.name 없음" '{"from":{"address":"x"},"to":[{"name":"a","address":"x"}],"content":"y"}'

echo "[3] to 빈 배열"
post_invalid "to=[]" '{"from":{"name":"a","address":"x"},"to":[],"content":"y"}'

echo "[4] recipient.address 누락"
post_invalid "recipient.address 없음" '{"from":{"name":"a","address":"x"},"to":[{"name":"b"}],"content":"y"}'

echo "[5] content 누락"
post_invalid "content 없음" '{"from":{"name":"a","address":"x"},"to":[{"name":"b","address":"x"}]}'

echo "[6] path traversal 시도 (recipient.name = ../)"
post_invalid "name=../etc" '{"from":{"name":"a","address":"x"},"to":[{"name":"../etc","address":"x"}],"content":"y"}'

echo "[7] path slash 시도"
post_invalid "name=foo/bar" '{"from":{"name":"a","address":"x"},"to":[{"name":"foo/bar","address":"x"}],"content":"y"}'

echo "[8] 빈 문자열 from.name"
post_invalid "from.name=''" '{"from":{"name":"","address":"x"},"to":[{"name":"a","address":"x"}],"content":"y"}'

echo "PASS test_schema_invalid"
