#!/usr/bin/env bash
# Q1 Phase A — Web UI 인증 게이트.
# 박상현 priority:high "WebUI 로그인 시스템 없음, impersonation 가능" 회수.
#
# AC:
#   Q1A-1  STOA_AUTH_HMAC_KEY 미설정 → /api/v1/login 503
#   Q1A-2  /api/v1/password 정상 설정 → 201
#   Q1A-3  /api/v1/login 잘못된 password → 401
#   Q1A-4  /api/v1/login 정상 → 200 + token
#   Q1A-5  /api/v1/web/messages 토큰 없음 → 401
#   Q1A-6  /api/v1/web/messages 토큰 있음 + name 일치 → 201
#   Q1A-7  /api/v1/web/messages 토큰 있음 + name 불일치 → 401 (impersonation 차단)
#   Q1A-8  /api/v1/messages 직접 POST (외부 에이전트 흐름) → 회귀 0 (영향 없음)
#   Q1A-9  /api/v1/password 미등록 name → 404
#   Q1A-10 /api/v1/login 미등록 name → 401 (uniform error 메시지)

set -uo pipefail

PORT="${Q1A_TEST_PORT:-18893}"
URL="http://localhost:$PORT"
HMAC_KEY="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

PASS=0; FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cleanup() {
    [ -n "${SRV1:-}" ] && kill "$SRV1" 2>/dev/null || true
    [ -n "${SRV2:-}" ] && kill "$SRV2" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-q1a-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

# ── Phase 1: env unset → /api/v1/login 503 ──
PORT_A=$((PORT+10))
URL_A="http://localhost:$PORT_A"
PYTHONUNBUFFERED=1 PORT="$PORT_A" \
    STOA_DB_FILE="$TMP/q1a-a.db" \
    ail run server.ail > server-a.log 2>&1 &
SRV1=$!
for _ in $(seq 1 40); do curl -fs "$URL_A/api/v1/health" >/dev/null 2>&1 && break; sleep 0.3; done

code=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL_A/api/v1/login" \
    -H "Content-Type: application/json" -d '{"name":"x","password":"y"}')
[ "$code" = "503" ] && report_pass "Q1A-1 env unset → 503" || report_fail "Q1A-1 expected 503, got $code"

kill "$SRV1" 2>/dev/null || true; wait "$SRV1" 2>/dev/null || true; SRV1=""

# ── Phase 2: env set → AC-2~10 ──
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/q1a-b.db" \
    STOA_AUTH_HMAC_KEY="$HMAC_KEY" \
    ail run server.ail > server-b.log 2>&1 &
SRV2=$!
for _ in $(seq 1 40); do curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break; sleep 0.3; done

# pre-register agents
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"alice","address":"http://example/inbox/alice"}' > /dev/null
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"bob","address":"http://example/inbox/bob"}' > /dev/null

# Q1A-9: /api/v1/password 미등록 name → 404
code=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/password" \
    -H "Content-Type: application/json" -d '{"name":"ghost","password":"longenough"}')
[ "$code" = "404" ] && report_pass "Q1A-9 unregistered name → 404" || report_fail "Q1A-9 expected 404, got $code"

# Q1A-10: /api/v1/login 미등록 name → 401
code=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/login" \
    -H "Content-Type: application/json" -d '{"name":"ghost","password":"any"}')
[ "$code" = "401" ] && report_pass "Q1A-10 login unregistered → 401" || report_fail "Q1A-10 expected 401, got $code"

# Q1A-2: alice password 설정 → 201
code=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/password" \
    -H "Content-Type: application/json" -d '{"name":"alice","password":"secret123"}')
[ "$code" = "201" ] && report_pass "Q1A-2 set password → 201" || report_fail "Q1A-2 expected 201, got $code body=$(cat $TMP/r.json)"

# Q1A-3: 잘못된 password → 401
code=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/login" \
    -H "Content-Type: application/json" -d '{"name":"alice","password":"wrong"}')
[ "$code" = "401" ] && report_pass "Q1A-3 wrong password → 401" || report_fail "Q1A-3 expected 401, got $code"

# Q1A-4: 정상 login → 200 + token
body=$(curl -s -X POST "$URL/api/v1/login" \
    -H "Content-Type: application/json" -d '{"name":"alice","password":"secret123"}')
TOKEN=$(echo "$body" | python3 -c "import json,sys;print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
if [ -n "$TOKEN" ] && [ ${#TOKEN} -ge 32 ]; then
    report_pass "Q1A-4 login OK → token (${#TOKEN} chars)"
else
    report_fail "Q1A-4 no token in body=$body"
fi

# Set bob password too for Q1A-7 mismatch test
curl -s -X POST "$URL/api/v1/password" -H "Content-Type: application/json" \
    -d '{"name":"bob","password":"bobsecret"}' > /dev/null
BOB_TOKEN=$(curl -s -X POST "$URL/api/v1/login" -H "Content-Type: application/json" \
    -d '{"name":"bob","password":"bobsecret"}' | python3 -c "import json,sys;print(json.load(sys.stdin).get('token',''))")

# Q1A-5: web/messages 토큰 없음 → 401
code=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/web/messages" \
    -H "Content-Type: application/json" \
    -d '{"from":{"name":"alice","address":"http://example/inbox/alice"},"to":[{"name":"bob","address":"http://example/inbox/bob"}],"content":"hi"}')
[ "$code" = "401" ] && report_pass "Q1A-5 web/messages no token → 401" || report_fail "Q1A-5 expected 401, got $code"

# Q1A-6: web/messages 토큰 + 매칭 → 201
code=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/web/messages" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"from":{"name":"alice","address":"http://example/inbox/alice"},"to":[{"name":"bob","address":"http://example/inbox/bob"}],"content":"hi from alice"}')
[ "$code" = "201" ] && report_pass "Q1A-6 web/messages valid token → 201" || report_fail "Q1A-6 expected 201, got $code body=$(cat $TMP/r.json)"

# Q1A-7: web/messages 토큰 + 미스매칭 → 401 (impersonation 차단)
code=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/web/messages" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d '{"from":{"name":"bob","address":"http://example/inbox/bob"},"to":[{"name":"alice","address":"http://example/inbox/alice"}],"content":"impersonation attempt"}')
[ "$code" = "401" ] && report_pass "Q1A-7 web/messages token name 불일치 → 401 (impersonation 차단)" || report_fail "Q1A-7 expected 401, got $code body=$(cat $TMP/r.json)"

# Q1A-8: /api/v1/messages 직접 POST (외부 흐름) → 영향 0
# 외부 에이전트(carol, password 미설정)는 그대로 작동. issue#4 sender registry gate
# 만족 위해 carol 사전 등록.
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"carol","address":"http://example/inbox/carol"}' > /dev/null
code=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{"from":{"name":"carol","address":"http://example/inbox/carol"},"to":[{"name":"alice","address":"http://example/inbox/alice"}],"content":"agent direct"}')
[ "$code" = "201" ] && report_pass "Q1A-8 /api/v1/messages 직접 POST (외부 에이전트) → 201 (회귀 0)" || report_fail "Q1A-8 expected 201, got $code body=$(cat $TMP/r.json)"

echo
echo "── summary ──"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" = "0" ]
