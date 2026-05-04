#!/usr/bin/env bash
# Issue #1 hotfix — server.ail POST /api/v1/messages 500 on non-record body.
# 원인: AIL stdlib `get(text, key)` / `length(record)` 호출 시 NameError loud
# (reference card v1.8 line 339). validate_envelope이 body shape 검증 전에 get()을
#호출 → 500 'undefined function: get'.
#
# 회귀 시나리오 (run_all.sh의 phase=0 server에 STOA_URL로 attach):
#   I1-1. simplified body {"from":"test","content":"hello"} → 400 (was 500).
#   I1-2. body=array → 400.
#   I1-3. body 자체가 JSON 문자열 (예: "hello") → 400.
#   I1-4. from = string → 400.
#   I1-5. to = string → 400.
#   I1-6. to[0] = string → 400.
#   I1-7. full envelope → 201 (회귀 sanity).

set -uo pipefail

URL="${STOA_URL:-http://localhost:18888}"
PASS=0
FAIL=0

assert_400() {
    local label="$1"; shift
    local payload="$1"; shift
    local code
    code=$(curl -s -o /tmp/issue1_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$payload")
    if [ "$code" = "400" ]; then
        PASS=$((PASS+1))
        echo "  ✓ $label → 400"
    else
        FAIL=$((FAIL+1))
        echo "  ✗ $label → HTTP $code (expected 400)"
        cat /tmp/issue1_resp; echo
    fi
}

assert_201() {
    local label="$1"; shift
    local payload="$1"; shift
    local code
    code=$(curl -s -o /tmp/issue1_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$payload")
    if [ "$code" = "201" ]; then
        PASS=$((PASS+1))
        echo "  ✓ $label → 201"
    else
        FAIL=$((FAIL+1))
        echo "  ✗ $label → HTTP $code (expected 201)"
        cat /tmp/issue1_resp; echo
    fi
}

echo "── Issue #1: simplified-body / wrong-shape POST /api/v1/messages ──"

# issue#4 sender registry gate — I1-7 sanity 발신자 alice-i1 사전 등록.
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"alice-i1","address":"http://a/inbox"}' > /dev/null
assert_400 "I1-1 simplified {from:text, content:text}" \
    '{"from":"test","content":"hello"}'
assert_400 "I1-2 body is array" \
    '[1,2,3]'
assert_400 "I1-3 body is JSON string" \
    '"hello"'
assert_400 "I1-4 from is string" \
    '{"from":"test","to":[{"name":"bob","address":"http://b/inbox"}],"content":"hi"}'
assert_400 "I1-5 to is string" \
    '{"from":{"name":"a","address":"http://a/inbox"},"to":"bob","content":"hi"}'
assert_400 "I1-6 to[0] is string" \
    '{"from":{"name":"a","address":"http://a/inbox"},"to":["bob"],"content":"hi"}'
assert_201 "I1-7 sanity full envelope" \
    '{"from":{"name":"alice-i1","address":"http://a/inbox"},"to":[{"name":"bob-i1","address":"http://b/inbox"}],"content":"hi"}'

echo "  PASS=$PASS  FAIL=$FAIL"
[ $FAIL -eq 0 ] && echo "PASS test_issue1_simplified_body" || exit 1
