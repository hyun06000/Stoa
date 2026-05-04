#!/usr/bin/env bash
# stoa-cli internal tool — keygen·canonical·sign·verify·send.
# Self-contained: PHASE=2 server + 임시 STOA_HOME + cryptography 패키지 검사.
#
# 시나리오:
#   C1. canonical Python output == server.ail RFC §6.1 expected bytes (AC-11 fixture).
#   C2. keygen creates ~/.stoa/<name>.key (chmod 600) + emits public_key json.
#   C3. sign envelope round-trip: register pk → sign → POST /api/v1/messages → 201.
#   C4. verify command on signed envelope → exit 0 ("ok"). Tampered → exit 1.
#   C5. send command (one-shot): keygen + register pk + send → server 201.

set -uo pipefail

PORT="${CLI_TEST_PORT:-18895}"
URL="http://localhost:$PORT"
ANCHOR_ISO="2026-05-04T12:00:00Z"
ANCHOR_UNIX=1777896000

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    pids=$(lsof -ti tcp:$PORT 2>/dev/null || true)
    [ -n "$pids" ] && echo "$pids" | xargs kill -9 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

if ! python3 -c "from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey" 2>/dev/null; then
    echo "SKIP test_stoa_cli: python3 cryptography 없음"
    exit 0
fi

pids=$(lsof -ti tcp:$PORT 2>/dev/null || true); [ -n "$pids" ] && echo "$pids" | xargs kill -9 2>/dev/null || true
sleep 0.3

TMP=$(mktemp -d -t stoa-cli-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI_DIR="$REPO_DIR/community-tools/stoa-cli"
export STOA_HOME="$TMP/stoa-home"
export STOA_BASE_URL="$URL"

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cli() { python3 "$CLI_DIR/stoa_cli.py" "$@"; }

# server (PHASE=2 + real time — sign uses real now_iso).
cp "$REPO_DIR/server.ail" "$TMP/"
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_SIGNING_PHASE=2 \
    ail run "$TMP/server.ail" > "$TMP/server.log" 2>&1 &
SRV=$!
for _ in $(seq 1 40); do curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break; sleep 0.5; done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"; tail -40 "$TMP/server.log"; exit 1
fi

# ─── C1. canonical byte-equal with RFC §6.1 fixture ───
echo "── C1: canonical byte-equality with server.ail / RFC §6.1 ──"
cat > "$TMP/fixture.json" <<'EOF'
{"from":{"name":"alice","address":"https://a/inbox"},
 "to":[{"name":"bob","address":"https://b/inbox"},{"name":"carol","address":"https://c/inbox"}],
 "content":"hi|test","created_at":"2026-05-01T03:00:00Z","nonce":"deadbeef"}
EOF
expected='letter|alice|https\://a/inbox|bob:https\://b/inbox;carol:https\://c/inbox|hi\|test|2026-05-01T03\:00\:00Z|deadbeef'
# strip trailing newline (BSD head doesn't support `-c -1`).
actual=$(cli canonical "$TMP/fixture.json" | python3 -c "import sys; sys.stdout.write(sys.stdin.read().rstrip('\n'))")
if [ "$actual" = "$expected" ]; then
    report_pass "C1 canonical bytes match RFC §6.1 fixture"
else
    report_fail "C1 canonical mismatch:
  expected: $expected
  actual:   $actual"
fi

# ─── C2. keygen creates key file ───
echo "── C2: keygen creates ~/.stoa/<name>.key ──"
out=$(cli keygen --name alice-cli)
PK_ALICE=$(echo "$out" | python3 -c "import json,sys; print(json.load(sys.stdin)['public_key'])")
KEY_PATH=$(echo "$out" | python3 -c "import json,sys; print(json.load(sys.stdin)['key_path'])")
if [ -f "$KEY_PATH" ] && [ "$(stat -f '%A' "$KEY_PATH" 2>/dev/null || stat -c '%a' "$KEY_PATH")" = "600" ]; then
    report_pass "C2 key file created with chmod 600 ($KEY_PATH)"
else
    report_fail "C2 key file missing or wrong perms"
fi

# alice-cli + bob-cli register on server.
curl -fs -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d "{\"name\":\"alice-cli\",\"address\":\"http://127.0.0.1:29981/inbox\",\"public_key\":\"$PK_ALICE\"}" > /dev/null \
    || { report_fail "C2 alice-cli register"; exit 1; }
curl -fs -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"bob-cli","address":"http://127.0.0.1:29982/inbox"}' > /dev/null \
    || { report_fail "C2 bob-cli register"; exit 1; }

# ─── C3. sign envelope + POST → 201 ───
echo "── C3: sign + POST round-trip ──"
cat > "$TMP/env.json" <<EOF
{"from":{"name":"alice-cli","address":"http://127.0.0.1:29981/inbox"},
 "to":[{"name":"bob-cli","address":"http://127.0.0.1:29982/inbox"}],
 "content":"hello via stoa-cli"}
EOF
signed=$(cli sign "$TMP/env.json")
echo "$signed" > "$TMP/env.signed.json"
code=$(curl -s -o "$TMP/post.resp" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" -d "$signed")
if [ "$code" = "201" ]; then
    report_pass "C3 signed envelope POST → 201"
else
    report_fail "C3 POST → $code, body=$(cat "$TMP/post.resp")"
fi

# ─── C4. verify command on signed envelope ───
echo "── C4: verify command ──"
out=$(cli verify "$TMP/env.signed.json" --public-key "$PK_ALICE" 2>&1)
if [ "$out" = "ok" ]; then
    report_pass "C4 verify ok on signed envelope"
else
    report_fail "C4 verify failed: $out"
fi

# tamper content → invalid sig.
python3 -c "
import json
e = json.load(open('$TMP/env.signed.json'))
e['content'] = 'tampered'
json.dump(e, open('$TMP/env.tampered.json', 'w'))
"
out=$(cli verify "$TMP/env.tampered.json" --public-key "$PK_ALICE" 2>&1 || true)
case "$out" in
    *"invalid signature"*) report_pass "C4 verify rejects tampered content" ;;
    *) report_fail "C4 expected 'invalid signature', got: $out" ;;
esac

# ─── C5. send command (one-shot) ───
echo "── C5: send command (sign + POST helper) ──"
cli keygen --name carol-cli > "$TMP/carol_keygen.json"
PK_CAROL=$(python3 -c "import json; print(json.load(open('$TMP/carol_keygen.json'))['public_key'])")
curl -fs -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d "{\"name\":\"carol-cli\",\"address\":\"http://127.0.0.1:29983/inbox\",\"public_key\":\"$PK_CAROL\"}" > /dev/null
before=$(curl -fs "$URL/api/v1/messages?to=bob-cli" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])")
STOA_NAME=carol-cli cli send bob-cli "hi from carol via send" > "$TMP/send.resp" 2>&1 || {
    report_fail "C5 send command failed: $(cat "$TMP/send.resp")"
    [ $FAIL -eq 0 ] && echo "PASS test_stoa_cli" || exit 1
}
sleep 0.3
after=$(curl -fs "$URL/api/v1/messages?to=bob-cli" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])")
if [ "$after" -gt "$before" ]; then
    report_pass "C5 send command → bob-cli inbox count $before → $after"
else
    report_fail "C5 send: bob-cli count unchanged ($before → $after)"
fi

echo
echo "  PASS=$PASS  FAIL=$FAIL"
[ $FAIL -eq 0 ] && echo "PASS test_stoa_cli" || exit 1
