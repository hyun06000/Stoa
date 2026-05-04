#!/usr/bin/env bash
# Issue #4 hotfix — 송신자 registry 강제 (impersonation 방어).
#
# 증상: 수신자 to.name은 registry 등재 필수인데, 송신자 from.name은 무방비 →
# 누구나 임의 from.name 주장 가능. 서명 강제 (Phase 2/3) 전까지 무방비 impersonation.
#
# Phase A 권고 (Homeros): handle_post_message 진입점 db_lookup(from_name) None →
# 400 + clear error. 자동 self-register 안 함.
#
# 시나리오 (run_all.sh의 phase=0 server에 STOA_URL로 attach):
#   I4-1. 미등록 발신자 → 400 (was 201).
#   I4-2. 등록 발신자 → 201 (envelope full body).
#   I4-3. 등록 발신자 + simplified body → 400 (issue#1 회귀; sender gate 안 닿고 shape gate가 먼저).
#   I4-4. 회귀 sanity: validate_envelope 거짓 입력 → 400 유지.

set -uo pipefail

URL="${STOA_URL:-http://localhost:18888}"
PASS=0
FAIL=0

assert_400() {
    local label="$1"; shift
    local payload="$1"; shift
    local code
    code=$(curl -s -o /tmp/i4_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$payload")
    if [ "$code" = "400" ]; then
        PASS=$((PASS+1))
        echo "  ✓ $label → 400"
    else
        FAIL=$((FAIL+1))
        echo "  ✗ $label → HTTP $code (expected 400)"
        cat /tmp/i4_resp; echo
    fi
}

assert_201() {
    local label="$1"; shift
    local payload="$1"; shift
    local code
    code=$(curl -s -o /tmp/i4_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$payload")
    if [ "$code" = "201" ]; then
        PASS=$((PASS+1))
        echo "  ✓ $label → 201"
    else
        FAIL=$((FAIL+1))
        echo "  ✗ $label → HTTP $code (expected 201)"
        cat /tmp/i4_resp; echo
    fi
}

assert_400_msg_contains() {
    local label="$1"; shift
    local payload="$1"; shift
    local needle="$1"; shift
    local code
    code=$(curl -s -o /tmp/i4_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$payload")
    if [ "$code" = "400" ] && grep -q "$needle" /tmp/i4_resp; then
        PASS=$((PASS+1))
        echo "  ✓ $label → 400 containing '$needle'"
    else
        FAIL=$((FAIL+1))
        echo "  ✗ $label → HTTP $code, body:"
        cat /tmp/i4_resp; echo
    fi
}

echo "── Issue #4: sender registry gate (impersonation 방어, Phase A) ──"

# 등록된 발신자 sentinel-i4. bob-i4도 수신용으로 등록.
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"sentinel-i4","address":"http://127.0.0.1:29991/inbox"}' > /dev/null
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"bob-i4","address":"http://127.0.0.1:1/inbox"}' > /dev/null

assert_400_msg_contains \
    "I4-1 unregistered sender 'ghost-i4' → 400 + 'not in registry'" \
    '{"from":{"name":"ghost-i4","address":"http://x/inbox"},"to":[{"name":"bob-i4","address":"http://127.0.0.1:1/inbox"}],"content":"impersonation attempt"}' \
    "not in registry"

assert_201 \
    "I4-2 registered sender 'sentinel-i4' → 201" \
    '{"from":{"name":"sentinel-i4","address":"http://127.0.0.1:29991/inbox"},"to":[{"name":"bob-i4","address":"http://127.0.0.1:1/inbox"}],"content":"valid sender"}'

assert_400 \
    "I4-3 registered sender + simplified body → 400 (issue#1 shape gate first)" \
    '{"from":"sentinel-i4","content":"simplified"}'

assert_400 \
    "I4-4 회귀: validate_envelope rejects to=[] before sender check" \
    '{"from":{"name":"sentinel-i4","address":"http://127.0.0.1:29991/inbox"},"to":[],"content":"empty to"}'

echo "  PASS=$PASS  FAIL=$FAIL"
[ $FAIL -eq 0 ] && echo "PASS test_issue4_sender_gate" || exit 1
