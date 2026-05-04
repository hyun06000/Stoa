#!/usr/bin/env bash
# RFC-002 §6.4 platform key registration endpoint Acceptance.
# Self-contained server boot, ~8 AC.
#
# Covered:
#   AC-1  endpoint disabled (env token unset) → 503
#   AC-2  missing X-Platform-Token → 401
#   AC-3  wrong X-Platform-Token → 401
#   AC-4  valid token + bad pubkey shape (length) → 400
#   AC-5  valid token + missing id → 400
#   AC-6  valid token + good shape → 201
#   AC-7  GET /api/v1/platform-keys → 200, count==1
#   AC-8  GET /api/v1/platform-keys/<id> → 200, pubkey matches
#   AC-9  re-register same id, latest wins (append-only)
#
# Not covered (out of scope, Marcus §6.6 attestation flow):
#   - attestation envelope sig 검증 (Step 6/7).
#   - discord_users binding 분기.

set -uo pipefail

PORT="${PLATFORM_KEY_TEST_PORT:-18891}"
URL="http://localhost:$PORT"
TOKEN="secret123-test"

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cleanup() {
    [ -n "${SRV1:-}" ] && kill "$SRV1" 2>/dev/null || true
    [ -n "${SRV2:-}" ] && kill "$SRV2" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-platkey-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_DIR/server.ail" "$TMP/"

# ── Phase 1: env token UNSET → endpoint 비활성 (AC-1) ─────────────
echo "── Boot 1: STOA_PLATFORM_REGISTER_TOKEN unset (AC-1) ──"
PORT_A=$((PORT+10))
URL_A="http://localhost:$PORT_A"
cd "$TMP"
PYTHONUNBUFFERED=1 PORT="$PORT_A" \
    STOA_DB_FILE="$TMP/messages-a.db" \
    ail run server.ail > server-a.log 2>&1 &
SRV1=$!
for _ in $(seq 1 40); do
    curl -fs "$URL_A/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done
if ! curl -fs "$URL_A/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server A didn't come up"
    tail -40 server-a.log
    exit 1
fi

resp=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL_A/api/v1/platform-keys" \
    -H "Content-Type: application/json" \
    -H "X-Platform-Token: anything" \
    -d '{"id":"default","public_key":"abc"}')
if [ "$resp" = "503" ]; then
    body=$(cat "$TMP/r.json")
    case "$body" in *disabled*) report_pass "AC-1 endpoint disabled → 503 ($body)" ;; *) report_fail "AC-1 503 but body=$body (expected 'disabled')" ;; esac
else
    report_fail "AC-1 expected 503, got $resp (body=$(cat $TMP/r.json))"
fi

kill "$SRV1" 2>/dev/null || true
wait "$SRV1" 2>/dev/null || true
SRV1=""

# ── Phase 2: env token SET → AC-2~AC-9 ────────────────────────────
echo "── Boot 2: STOA_PLATFORM_REGISTER_TOKEN=$TOKEN (AC-2~AC-9) ──"
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages-b.db" \
    STOA_PLATFORM_REGISTER_TOKEN="$TOKEN" \
    ail run server.ail > server-b.log 2>&1 &
SRV2=$!
for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server B didn't come up"
    tail -40 server-b.log
    exit 1
fi

# 64-char lower hex ed25519 pubkey (랜덤)
PK1=$(python3 -c "import secrets;print(secrets.token_hex(32))" 2>/dev/null || echo "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff")
PK2=$(python3 -c "import secrets;print(secrets.token_hex(32))" 2>/dev/null || echo "ffeeddccbbaa99887766554433221100ffeeddccbbaa99887766554433221100")

# AC-2: missing token header → 401
resp=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/platform-keys" \
    -H "Content-Type: application/json" \
    -d "{\"id\":\"default\",\"public_key\":\"$PK1\"}")
[ "$resp" = "401" ] && report_pass "AC-2 missing token → 401" || report_fail "AC-2 expected 401, got $resp"

# AC-3: wrong token → 401
resp=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/platform-keys" \
    -H "Content-Type: application/json" \
    -H "X-Platform-Token: wrong-token" \
    -d "{\"id\":\"default\",\"public_key\":\"$PK1\"}")
[ "$resp" = "401" ] && report_pass "AC-3 wrong token → 401" || report_fail "AC-3 expected 401, got $resp"

# AC-4: bad pubkey shape (too short) → 400
resp=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/platform-keys" \
    -H "Content-Type: application/json" \
    -H "X-Platform-Token: $TOKEN" \
    -d '{"id":"default","public_key":"abcd"}')
if [ "$resp" = "400" ]; then
    body=$(cat "$TMP/r.json")
    case "$body" in *hex*|*64*) report_pass "AC-4 bad pubkey shape → 400 ($body)" ;; *) report_fail "AC-4 400 but body=$body (expected hex/64 hint)" ;; esac
else
    report_fail "AC-4 expected 400, got $resp"
fi

# AC-5: missing id → 400
resp=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/platform-keys" \
    -H "Content-Type: application/json" \
    -H "X-Platform-Token: $TOKEN" \
    -d "{\"public_key\":\"$PK1\"}")
[ "$resp" = "400" ] && report_pass "AC-5 missing id → 400" || report_fail "AC-5 expected 400, got $resp"

# JSON 본문 매칭: AIL encode_json은 콜론 뒤 공백 출력 → 공백 제거 후 비교.
strip_ws() { tr -d ' \t\r\n'; }

# AC-6: valid → 201
resp=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/platform-keys" \
    -H "Content-Type: application/json" \
    -H "X-Platform-Token: $TOKEN" \
    -d "{\"id\":\"default\",\"public_key\":\"$PK1\"}")
if [ "$resp" = "201" ]; then
    body=$(cat "$TMP/r.json" | strip_ws)
    case "$body" in *"\"id\":\"default\""*"\"public_key\":\"$PK1\""*) report_pass "AC-6 valid register → 201" ;; *) report_fail "AC-6 201 but body=$body" ;; esac
else
    report_fail "AC-6 expected 201, got $resp body=$(cat $TMP/r.json)"
fi

# AC-7: GET list → 200 count=1
resp=$(curl -s -o "$TMP/r.json" -w "%{http_code}" "$URL/api/v1/platform-keys")
if [ "$resp" = "200" ]; then
    body=$(cat "$TMP/r.json" | strip_ws)
    case "$body" in *"\"count\":1"*) report_pass "AC-7 GET list count=1" ;; *) report_fail "AC-7 200 but body=$body (expected count:1)" ;; esac
else
    report_fail "AC-7 expected 200, got $resp"
fi

# AC-8: GET /:id → 200, pubkey matches
resp=$(curl -s -o "$TMP/r.json" -w "%{http_code}" "$URL/api/v1/platform-keys/default")
if [ "$resp" = "200" ]; then
    body=$(cat "$TMP/r.json" | strip_ws)
    case "$body" in *"\"public_key\":\"$PK1\""*) report_pass "AC-8 GET /:id returns pubkey" ;; *) report_fail "AC-8 200 but body=$body" ;; esac
else
    report_fail "AC-8 expected 200, got $resp"
fi

# AC-9: re-register same id, latest wins
resp=$(curl -s -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/platform-keys" \
    -H "Content-Type: application/json" \
    -H "X-Platform-Token: $TOKEN" \
    -d "{\"id\":\"default\",\"public_key\":\"$PK2\"}")
if [ "$resp" = "201" ]; then
    g=$(curl -s "$URL/api/v1/platform-keys/default" | strip_ws)
    case "$g" in *"\"public_key\":\"$PK2\""*) report_pass "AC-9 re-register latest wins (PK2 visible)" ;; *) report_fail "AC-9 latest mismatch: $g" ;; esac
else
    report_fail "AC-9 re-register expected 201, got $resp"
fi

# AC-10: PRINCIPLES §3 — append-only check (rowcount via debug query)
# DB 직접 sqlite3로 row count 확인. 두 INSERT (AC-6, AC-9) → 2 rows.
if command -v sqlite3 >/dev/null 2>&1; then
    cnt=$(sqlite3 "$TMP/messages-b.db" "SELECT COUNT(*) FROM platform_keys;" 2>/dev/null || echo 0)
    [ "$cnt" = "2" ] && report_pass "AC-10 append-only — 2 rows preserved (PRINCIPLES §3)" || report_fail "AC-10 expected 2 rows, got $cnt"
else
    echo "  · AC-10 SKIP (no sqlite3 in PATH)"
fi

echo
echo "── summary ──"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" = "0" ]
