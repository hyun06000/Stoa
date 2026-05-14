#!/usr/bin/env bash
# RFC-004 §6.3 Phase C C2 — `/inbox/ack` 두 path 인증 게이트.
#
# Walter msg_48 Q1: 에이전트 ed25519 envelope vs 사람 RFC-002 Bearer 토큰.
# client identity로 path 분리. Phase >= 1에서만 게이트 활성, Phase 0 grandfather.
#
# AC:
#   C1a  ed25519 signed ack (trio + valid sig) → 200 + cursor advance.
#   C1b  Bearer session token ack (login → token → ack with header) → 200.
#   C1c  무인증 ack (Phase=1) → 401.
#   C1d  ed25519 잘못된 signature → 403.
#   C1e  Bearer token 이름 mismatch (alice token으로 bob 앞 ack) → 403.
#   C1f  Phase=0 (default)에서 무인증 ack → 200 (grandfather 회귀 보존, AC-A1~A6 covered).

set -uo pipefail

if ! python3 -c "from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey" 2>/dev/null; then
    echo "SKIP test_rfc004_C1: cryptography 미설치 (pip install cryptography)"
    exit 0
fi

PORT="${RFC004_C1_PORT:-18895}"
URL="http://localhost:$PORT"
# STOA_AUTH_HMAC_KEY 32-byte hex (테스트용 deterministic).
HMAC_KEY="${RFC004_C1_HMAC_KEY:-1111111111111111111111111111111111111111111111111111111111111111}"

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-rfc004-c1-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

# Phase 1 gate 활성으로 booting.
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_SIGNING_PHASE=1 \
    STOA_AUTH_HMAC_KEY="$HMAC_KEY" \
    ail run server.ail > server.log 2>&1 &
SRV=$!
for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"; tail -40 server.log; exit 1
fi

# alice·bob 등록 (ed25519 path 용 alice, Bearer path 용 bob 사람 계정).
ALICE_KEYS=$(python3 - <<'PY'
import json
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization
sk = Ed25519PrivateKey.generate()
sk_hex = sk.private_bytes(encoding=serialization.Encoding.Raw, format=serialization.PrivateFormat.Raw, encryption_algorithm=serialization.NoEncryption()).hex()
pk_hex = sk.public_key().public_bytes(encoding=serialization.Encoding.Raw, format=serialization.PublicFormat.Raw).hex()
print(json.dumps({"sk": sk_hex, "pk": pk_hex}))
PY
)
ALICE_SK=$(echo "$ALICE_KEYS" | python3 -c 'import sys,json; print(json.load(sys.stdin)["sk"])')
ALICE_PK=$(echo "$ALICE_KEYS" | python3 -c 'import sys,json; print(json.load(sys.stdin)["pk"])')

curl -fs -X POST "$URL/api/v1/agents" -H 'Content-Type: application/json' \
    -d "{\"name\":\"alice-c1\",\"address\":\"$URL/inbox/alice-c1\",\"public_key\":\"$ALICE_PK\"}" >/dev/null

curl -fs -X POST "$URL/api/v1/agents" -H 'Content-Type: application/json' \
    -d "{\"name\":\"bob-c1\",\"address\":\"$URL/inbox/bob-c1\"}" >/dev/null
# bob 사람 계정 password 설정 + login.
curl -fs -X POST "$URL/api/v1/password" -H 'Content-Type: application/json' \
    -d '{"name":"bob-c1","password":"bobpass123"}' >/dev/null
LOGIN_R=$(curl -fs -X POST "$URL/api/v1/login" -H 'Content-Type: application/json' \
    -d '{"name":"bob-c1","password":"bobpass123"}')
BOB_TOKEN=$(echo "$LOGIN_R" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))')

# seed letter — alice가 bob에게 1건 보내고, alice도 자기 앞으로 1건 받게 (carol→alice).
register_agent() {
    curl -fs -X POST "$URL/api/v1/agents" -H 'Content-Type: application/json' \
        -d "{\"name\":\"$1\",\"address\":\"$URL/inbox/$1\"}" >/dev/null
}
register_agent "carol-c1"

# Phase 1: carol→alice/bob seed letter는 무서명 통과 가능 (alice/bob 발신자도 carol).
# carol pk 없음, alice pk 있음 — Phase 1 verify_required: phase==1 && has_sig_claim.
# 무서명이면 통과.
SEED_BOB=$(curl -fs -X POST "$URL/api/v1/messages" -H 'Content-Type: application/json' \
    -d "{\"from\":{\"name\":\"carol-c1\",\"address\":\"http://x\"},\"to\":[{\"name\":\"bob-c1\",\"address\":\"$URL/inbox/bob-c1\"}],\"content\":\"seed-bob\"}")
SEED_BOB_ID=$(echo "$SEED_BOB" | python3 -c 'import sys,json; print(json.load(sys.stdin)["envelope"]["id"])')

SEED_ALICE=$(curl -fs -X POST "$URL/api/v1/messages" -H 'Content-Type: application/json' \
    -d "{\"from\":{\"name\":\"carol-c1\",\"address\":\"http://x\"},\"to\":[{\"name\":\"alice-c1\",\"address\":\"$URL/inbox/alice-c1\"}],\"content\":\"seed-alice\"}")
SEED_ALICE_ID=$(echo "$SEED_ALICE" | python3 -c 'import sys,json; print(json.load(sys.stdin)["envelope"]["id"])')

# C1c — 무인증 ack → 401 (Phase 1).
CODE=$(curl -s -o /tmp/c1c.body -w "%{http_code}" -X POST "$URL/api/v1/inbox/ack" \
    -H 'Content-Type: application/json' \
    -d "{\"to\":\"alice-c1\",\"up_to_msg_id\":\"$SEED_ALICE_ID\"}")
if [ "$CODE" = "401" ]; then
    report_pass "C1c 무인증 ack → 401 (Phase 1 게이트)"
else
    report_fail "C1c expected 401, got $CODE body=$(cat /tmp/c1c.body)"
fi

# C1a — alice ed25519 signed ack → 200.
SIGN_OUT=$(SK="$ALICE_SK" NAME="alice-c1" MID="$SEED_ALICE_ID" python3 - <<'PY'
import os, json, secrets, time
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
def esc(s):
    return s.replace("\\","\\\\").replace("|","\\|").replace(";","\\;").replace(":","\\:")
name = os.environ["NAME"]; mid = os.environ["MID"]
nonce = secrets.token_hex(16)
created_at = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
canonical = "ack|" + esc(name) + "|" + esc(mid) + "|" + esc(created_at) + "|" + esc(nonce)
sk = Ed25519PrivateKey.from_private_bytes(bytes.fromhex(os.environ["SK"]))
sig = sk.sign(canonical.encode("utf-8")).hex()
print(json.dumps({"signature":sig,"nonce":nonce,"created_at":created_at}))
PY
)
SIG=$(echo "$SIGN_OUT" | python3 -c 'import sys,json; print(json.load(sys.stdin)["signature"])')
NONCE=$(echo "$SIGN_OUT" | python3 -c 'import sys,json; print(json.load(sys.stdin)["nonce"])')
CA=$(echo "$SIGN_OUT" | python3 -c 'import sys,json; print(json.load(sys.stdin)["created_at"])')

CODE=$(curl -s -o /tmp/c1a.body -w "%{http_code}" -X POST "$URL/api/v1/inbox/ack" \
    -H 'Content-Type: application/json' \
    -d "{\"to\":\"alice-c1\",\"up_to_msg_id\":\"$SEED_ALICE_ID\",\"signature\":\"$SIG\",\"nonce\":\"$NONCE\",\"created_at\":\"$CA\"}")
if [ "$CODE" = "200" ]; then
    CURSOR=$(python3 -c "import json; print(json.load(open('/tmp/c1a.body'))['cursor'])")
    if [ "$CURSOR" = "$SEED_ALICE_ID" ]; then
        report_pass "C1a ed25519 signed ack → 200 + cursor=$CURSOR"
    else
        report_fail "C1a 200 but cursor mismatch: $CURSOR"
    fi
else
    report_fail "C1a expected 200, got $CODE body=$(cat /tmp/c1a.body)"
fi

# C1b — bob Bearer ack → 200.
CODE=$(curl -s -o /tmp/c1b.body -w "%{http_code}" -X POST "$URL/api/v1/inbox/ack" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $BOB_TOKEN" \
    -d "{\"to\":\"bob-c1\",\"up_to_msg_id\":\"$SEED_BOB_ID\"}")
if [ "$CODE" = "200" ]; then
    report_pass "C1b Bearer session ack → 200"
else
    report_fail "C1b expected 200, got $CODE body=$(cat /tmp/c1b.body)"
fi

# C1d — ed25519 wrong signature → 403. nonce 새로 (dedup 회피).
NEW_NONCE=$(python3 -c 'import secrets; print(secrets.token_hex(16))')
NEW_CA=$(python3 -c 'import time; print(time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()))')
# alice의 sig를 carol 앞으로 가짜로 — sig 자체는 valid 형식이지만 canonical mismatch.
BAD_SIG="0000$(echo "$SIG" | cut -c5-)"
CODE=$(curl -s -o /tmp/c1d.body -w "%{http_code}" -X POST "$URL/api/v1/inbox/ack" \
    -H 'Content-Type: application/json' \
    -d "{\"to\":\"alice-c1\",\"up_to_msg_id\":\"$SEED_ALICE_ID\",\"signature\":\"$BAD_SIG\",\"nonce\":\"$NEW_NONCE\",\"created_at\":\"$NEW_CA\"}")
if [ "$CODE" = "403" ]; then
    report_pass "C1d ed25519 wrong signature → 403"
else
    report_fail "C1d expected 403, got $CODE body=$(cat /tmp/c1d.body)"
fi

# C1e — Bearer token 이름 mismatch. bob token으로 alice 앞 ack.
CODE=$(curl -s -o /tmp/c1e.body -w "%{http_code}" -X POST "$URL/api/v1/inbox/ack" \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $BOB_TOKEN" \
    -d "{\"to\":\"alice-c1\",\"up_to_msg_id\":\"$SEED_ALICE_ID\"}")
if [ "$CODE" = "403" ]; then
    report_pass "C1e Bearer name mismatch (bob token, alice ack) → 403"
else
    report_fail "C1e expected 403, got $CODE body=$(cat /tmp/c1e.body)"
fi

# 서버 정지 후 Phase 0으로 재기동 (C1f grandfather).
kill $SRV 2>/dev/null; wait 2>/dev/null
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    ail run server.ail > server.log 2>&1 &
SRV=$!
for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done

# seed letter 추가 (다른 mid).
register_agent "dan-c1"
SEED_DAN=$(curl -fs -X POST "$URL/api/v1/messages" -H 'Content-Type: application/json' \
    -d "{\"from\":{\"name\":\"carol-c1\",\"address\":\"http://x\"},\"to\":[{\"name\":\"dan-c1\",\"address\":\"$URL/inbox/dan-c1\"}],\"content\":\"seed-dan\"}")
SEED_DAN_ID=$(echo "$SEED_DAN" | python3 -c 'import sys,json; print(json.load(sys.stdin)["envelope"]["id"])')

CODE=$(curl -s -o /tmp/c1f.body -w "%{http_code}" -X POST "$URL/api/v1/inbox/ack" \
    -H 'Content-Type: application/json' \
    -d "{\"to\":\"dan-c1\",\"up_to_msg_id\":\"$SEED_DAN_ID\"}")
if [ "$CODE" = "200" ]; then
    report_pass "C1f Phase 0 grandfather 무인증 ack → 200"
else
    report_fail "C1f expected 200, got $CODE body=$(cat /tmp/c1f.body)"
fi

echo ""
echo "── summary ──"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" = "0" ]
