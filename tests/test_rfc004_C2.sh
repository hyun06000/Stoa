#!/usr/bin/env bash
# RFC-004 §5.3 / §6.3 Phase C C1 — `Stoa-Stoa` letter 자기서명.
#
# `_emit_self_letter`가 RFC-001 §6.1 canonical_letter 직렬화 후 self.secret
# 으로 crypto_sign_ed25519. 수신측은 registry self-row `Stoa-Stoa`.public_key
# 로 crypto_verify_ed25519. tamper 시 검증 fail.
#
# AC:
#   C2-1  Stoa-Stoa emit letter row에 signature/nonce 비공 (NOT NULL).
#   C2-2  signature를 registry self-row public_key로 verify → true (untampered).
#   C2-3  content tamper 후 같은 signature로 verify → false (서명 무결성).
#   C2-4  signature tamper 후 verify → false.

set -uo pipefail

PORT="${RFC004_C2_PORT:-18894}"
URL="http://localhost:$PORT"

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-rfc004-c2-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

# tick/idle_ping interval 1초로 즉시 발사 + Stoa-Admin enter로 발신 대상 등재.
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_TICK_SEC=1 \
    STOA_IDLE_PING_INTERVAL_S=1 \
    ail run server.ail > server.log 2>&1 &
SRV=$!
for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"; tail -40 server.log; exit 1
fi

# Stoa-Admin enter — self-letter 발신 대상으로 등재.
curl -fs -X POST "$URL/api/v1/enter" \
    -H 'Content-Type: application/json' \
    -d '{"name":"Stoa-Admin","address":"'"$URL"'/inbox/Stoa-Admin"}' >/dev/null

# idle_ping이 2~3 tick 안에 fire. self-letter row 등장 polling.
SELF_LETTER_ID=""
for _ in $(seq 1 30); do
    SELF_LETTER_ID=$(sqlite3 "$TMP/messages.db" "SELECT id FROM letters WHERE from_name='Stoa-Stoa' ORDER BY rowid DESC LIMIT 1;" 2>/dev/null || echo "")
    [ -n "$SELF_LETTER_ID" ] && break
    sleep 0.3
done

if [ -z "$SELF_LETTER_ID" ]; then
    report_fail "C2-pre: Stoa-Stoa self-letter emit 미관측 (idle_ping 안 발사)"
    echo "── server.log tail ──"
    tail -40 server.log
    echo ""
    echo "── summary ──"
    echo "PASS: $PASS"
    echo "FAIL: 1"
    exit 1
fi

SIG=$(sqlite3 "$TMP/messages.db" "SELECT signature FROM letters WHERE id='$SELF_LETTER_ID';")
NONCE=$(sqlite3 "$TMP/messages.db" "SELECT nonce FROM letters WHERE id='$SELF_LETTER_ID';")
CONTENT=$(sqlite3 "$TMP/messages.db" "SELECT content FROM letters WHERE id='$SELF_LETTER_ID';")
CREATED_AT=$(sqlite3 "$TMP/messages.db" "SELECT created_at FROM letters WHERE id='$SELF_LETTER_ID';")

# C2-1: signature/nonce 비공.
if [ -n "$SIG" ] && [ -n "$NONCE" ]; then
    report_pass "C2-1 self-letter signature/nonce 비공 (sig=${SIG:0:16}... nonce=${NONCE:0:8}...)"
else
    report_fail "C2-1 self-letter signature/nonce 누락: sig='$SIG' nonce='$NONCE'"
fi

# C2-2~4: registry self-row public_key로 verify. 모든 round-trip을 Python 안에서
# 처리해 sqlite3 shell 출력 multi-line 손실 회피.
VERIFY_OUT=$(DB="$TMP/messages.db" MID="$SELF_LETTER_ID" python3 - <<'PY'
import os, sqlite3, sys
try:
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey
    from cryptography.exceptions import InvalidSignature
except ImportError:
    print("SKIP"); sys.exit(0)

def esc(s):
    return s.replace("\\","\\\\").replace("|","\\|").replace(";","\\;").replace(":","\\:")

c = sqlite3.connect(os.environ["DB"])
mid = os.environ["MID"]
row = c.execute("SELECT from_name, from_address, content, created_at, signature, nonce FROM letters WHERE id=?", [mid]).fetchone()
fn, fa, content, created_at, sig_hex, nonce = row
rcpts = c.execute("SELECT name, address FROM recipients WHERE letter_id=? ORDER BY name ASC", [mid]).fetchall()
pk_row = c.execute("SELECT public_key FROM registry WHERE name='Stoa-Stoa' ORDER BY rowid DESC LIMIT 1").fetchone()
if not pk_row or not pk_row[0]:
    print("NO_PK"); sys.exit(0)
pk_hex = pk_row[0]

to_str = ";".join(esc(n) + ":" + esc(a) for n,a in rcpts)
canonical = "letter|" + esc(fn) + "|" + esc(fa) + "|" + to_str + "|" + esc(content) + "|" + esc(created_at) + "|" + esc(nonce)

vk = Ed25519PublicKey.from_public_bytes(bytes.fromhex(pk_hex))

# C2-2 untampered
try:
    vk.verify(bytes.fromhex(sig_hex), canonical.encode("utf-8"))
    r1 = "PASS"
except InvalidSignature:
    r1 = "FAIL"

# C2-3 content tamper
canonical_t = "letter|" + esc(fn) + "|" + esc(fa) + "|" + to_str + "|" + esc(content + "_TAMPER") + "|" + esc(created_at) + "|" + esc(nonce)
try:
    vk.verify(bytes.fromhex(sig_hex), canonical_t.encode("utf-8"))
    r2 = "UNEXPECTED_PASS"
except InvalidSignature:
    r2 = "EXPECTED_FAIL"

# C2-4 signature tamper (flip first hex char)
bad_sig = ("1" if sig_hex[0] == "0" else "0") + sig_hex[1:]
try:
    vk.verify(bytes.fromhex(bad_sig), canonical.encode("utf-8"))
    r3 = "UNEXPECTED_PASS"
except (InvalidSignature, ValueError):
    r3 = "EXPECTED_FAIL"

print(f"{r1}|{r2}|{r3}")
PY
)
if [ "$VERIFY_OUT" = "SKIP" ]; then
    echo "  ⊙ C2-2/3/4 SKIP (cryptography 미설치)"
elif [ "$VERIFY_OUT" = "NO_PK" ]; then
    report_fail "C2-2 self-row public_key 누락"
else
    R1=$(echo "$VERIFY_OUT" | cut -d'|' -f1)
    R2=$(echo "$VERIFY_OUT" | cut -d'|' -f2)
    R3=$(echo "$VERIFY_OUT" | cut -d'|' -f3)
    [ "$R1" = "PASS" ] && report_pass "C2-2 untampered signature verify → true" || report_fail "C2-2 verify failed: $R1"
    [ "$R2" = "EXPECTED_FAIL" ] && report_pass "C2-3 content tamper → verify false" || report_fail "C2-3: $R2"
    [ "$R3" = "EXPECTED_FAIL" ] && report_pass "C2-4 signature tamper → verify false" || report_fail "C2-4: $R3"
fi

echo ""
echo "── summary ──"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" = "0" ]
