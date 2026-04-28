#!/usr/bin/env bash
# 필수 필드 검증 (최소만).

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

post_invalid() {
    local desc="$1"; local body="$2"
    code=$(curl -s -o /tmp/r -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$body")
    if [ "$code" = "400" ]; then
        msg=$(python3 -c "import json; print(json.load(open('/tmp/r'))['error'])" 2>/dev/null || echo "?")
        echo "  ✓ $desc → 400 (\"$msg\")"
    else
        echo "  ✗ $desc → $code"
        cat /tmp/r
        return 1
    fi
}

post_invalid "from 없음" '{"to":[{"name":"a","address":"x"}],"content":"y"}'
post_invalid "from.name 빈 문자열" '{"from":{"name":"","address":"x"},"to":[{"name":"a","address":"x"}],"content":"y"}'
post_invalid "to=[]" '{"from":{"name":"a","address":"x"},"to":[],"content":"y"}'
post_invalid "to[0].address 없음" '{"from":{"name":"a","address":"x"},"to":[{"name":"a"}],"content":"y"}'
post_invalid "content 없음" '{"from":{"name":"a","address":"x"},"to":[{"name":"a","address":"x"}]}'

echo "PASS test_validation"
