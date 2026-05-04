#!/usr/bin/env bash
# RFC-001 §11 (client signing) — client.ail send_letter signing AC.
# Self-contained: PHASE=2 server + 두 client.ail 인스턴스 (alice 서명 + bob 수신).
#
# 시나리오:
#   AC-C1. CLIENT_SECRET_KEY 있는 alice → bob 발송 → server 200 + DB 보존 + signature/nonce 비어있지 않음.
#   AC-C2. WRONG sk(rotated) alice → bob 발송 → server 403 → DB 보존 안 됨 (count 변화 없음).
#   AC-C3. CLIENT_SECRET_KEY 부재(grandfather 의도) alice → bob 발송. alice는 키가 등록돼 있으므로 Phase 2에서 server 403 (no signature claim, registered key 발신자).
#
# 의존: python3 + cryptography, bash, curl, ail-interpreter v1.71.1+.

set -uo pipefail

PORT="${SIGN_TEST_PORT:-18891}"
URL="http://localhost:$PORT"
ANCHOR_ISO="2026-05-04T12:00:00Z"
ANCHOR_UNIX=1777896000

A_PORT=29101
B_PORT=29102
A_ADDR="http://127.0.0.1:$A_PORT/inbox"
B_ADDR="http://127.0.0.1:$B_PORT/inbox"

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    [ -n "${AP:-}" ] && kill "$AP" 2>/dev/null || true
    [ -n "${BP:-}" ] && kill "$BP" 2>/dev/null || true
    # 보장: orphan 프로세스도 정리 (이전 실패 run에서 남은 채로 시작 금지).
    for p in "$PORT" "$A_PORT" "$B_PORT"; do
        pids=$(lsof -ti tcp:"$p" 2>/dev/null || true)
        [ -n "$pids" ] && echo "$pids" | xargs kill 2>/dev/null || true
    done
    wait 2>/dev/null || true
}
# 시작 전에도 orphan 정리.
for p in "$PORT" "$A_PORT" "$B_PORT"; do
    pids=$(lsof -ti tcp:"$p" 2>/dev/null || true)
    [ -n "$pids" ] && echo "$pids" | xargs kill 2>/dev/null || true
done
sleep 0.3
trap cleanup EXIT

if ! python3 -c "from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey" 2>/dev/null; then
    echo "SKIP test_client_signing: python3 cryptography 패키지 부재"
    exit 0
fi

TMP=$(mktemp -d -t stoa-clientsig-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cp "$REPO_DIR/server.ail" "$TMP/"
ALICE="$TMP/alice"; BOB="$TMP/bob"
mkdir -p "$ALICE" "$BOB"
cp "$REPO_DIR/client.ail" "$ALICE/"
cp "$REPO_DIR/client.ail" "$BOB/"

# server 기동 (PHASE=2). 시간은 real clock 사용 — client.ail이 real now_iso() 발신해
# 서버 _server_now_unix와 동일 기준이어야 window(±60s) 통과.
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_SIGNING_PHASE=2 \
    ail run "$TMP/server.ail" > "$TMP/server.log" 2>&1 &
SRV=$!
for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.5
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"
    tail -40 "$TMP/server.log"
    exit 1
fi

# 키쌍 생성
KEYS=$(python3 - <<'PY'
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives import serialization
sk = Ed25519PrivateKey.generate()
pk = sk.public_key()
sk_hex = sk.private_bytes(
    encoding=serialization.Encoding.Raw,
    format=serialization.PrivateFormat.Raw,
    encryption_algorithm=serialization.NoEncryption()
).hex()
pk_hex = pk.public_bytes(
    encoding=serialization.Encoding.Raw,
    format=serialization.PublicFormat.Raw
).hex()
print(sk_hex)
print(pk_hex)

sk2 = Ed25519PrivateKey.generate()
sk2_hex = sk2.private_bytes(
    encoding=serialization.Encoding.Raw,
    format=serialization.PrivateFormat.Raw,
    encryption_algorithm=serialization.NoEncryption()
).hex()
print(sk2_hex)
PY
)
SK_HEX=$(echo "$KEYS" | sed -n 1p)
PK_HEX=$(echo "$KEYS" | sed -n 2p)
WRONG_SK=$(echo "$KEYS" | sed -n 3p)

# alice 등록 (키 포함, 첫 등록은 free per RFC §5.1) + bob 등록 (키 없이)
curl -fs -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d "{\"name\":\"alice-c\",\"address\":\"$A_ADDR\",\"public_key\":\"$PK_HEX\"}" > /dev/null \
    || { echo "FAIL: alice register"; exit 1; }
curl -fs -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d "{\"name\":\"bob-c\",\"address\":\"$B_ADDR\"}" > /dev/null \
    || { echo "FAIL: bob register"; exit 1; }

start_alice() {
    local sk="$1"
    if [ -n "${AP:-}" ]; then
        kill "$AP" 2>/dev/null || true
        wait "$AP" 2>/dev/null || true
    fi
    # 포트 release 보장 — Flask가 종료에 시간 걸림.
    for _ in $(seq 1 20); do
        if ! lsof -ti tcp:"$A_PORT" >/dev/null 2>&1; then break; fi
        sleep 0.2
    done
    pids=$(lsof -ti tcp:"$A_PORT" 2>/dev/null || true)
    [ -n "$pids" ] && echo "$pids" | xargs kill -9 2>/dev/null || true
    AP=
    if [ -n "$sk" ]; then
        (cd "$ALICE" && CLIENT_NAME=alice-c CLIENT_ADDRESS="$A_ADDR" STOA_URL="$URL" \
            CLIENT_SECRET_KEY="$sk" PORT=$A_PORT PYTHONUNBUFFERED=1 \
            ail run client.ail > "$TMP/alice.log" 2>&1) &
    else
        (cd "$ALICE" && CLIENT_NAME=alice-c CLIENT_ADDRESS="$A_ADDR" STOA_URL="$URL" \
            PORT=$A_PORT PYTHONUNBUFFERED=1 \
            ail run client.ail > "$TMP/alice.log" 2>&1) &
    fi
    AP=$!
    for _ in $(seq 1 30); do
        curl -fs "http://127.0.0.1:$A_PORT/health" >/dev/null 2>&1 && return 0
        sleep 0.3
    done
    return 1
}

count_bob() {
    curl -fs "$URL/api/v1/messages?to=bob-c" \
        | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])"
}

echo "[AC-C1] alice (signed) → bob-c → server 200, signature/nonce 보존"
start_alice "$SK_HEX" || { echo "FAIL: alice didn't come up"; tail -40 "$TMP/alice.log"; exit 1; }
before=$(count_bob)
curl -fs -X POST "http://127.0.0.1:$A_PORT/send" -H "Content-Type: application/json" \
    -d "{\"to\":[{\"name\":\"bob-c\",\"address\":\"$B_ADDR\"}],\"content\":\"hi bob signed\"}" \
    > "$TMP/c1.resp" || { echo "FAIL C1: /send"; cat "$TMP/c1.resp"; exit 1; }
sleep 0.5
after=$(count_bob)
if [ "$after" != $((before + 1)) ]; then
    echo "FAIL C1: bob inbox count $before → $after (expected +1)"
    echo "--- alice.log ---"; tail -30 "$TMP/alice.log"
    echo "--- server.log (filtered) ---"; tail -60 "$TMP/server.log"
    exit 1
fi
LAST=$(curl -fs "$URL/api/v1/messages?to=bob-c" | python3 -c "
import json,sys
d=json.load(sys.stdin)
m=d['messages'][-1]
assert m['from']['name']=='alice-c', m
assert m.get('signature'), 'signature missing/empty'
assert m.get('nonce'), 'nonce missing/empty'
assert m.get('created_at'), 'created_at missing/empty'
print('OK')
") || { echo "FAIL C1: envelope assertions"; exit 1; }
echo "  ✓ AC-C1 PASS"

echo "[AC-C2] alice (WRONG sk) → bob-c → server 403, count 불변"
start_alice "$WRONG_SK" || { echo "FAIL C2: alice didn't come up"; exit 1; }
before=$(count_bob)
curl -fs -X POST "http://127.0.0.1:$A_PORT/send" -H "Content-Type: application/json" \
    -d "{\"to\":[{\"name\":\"bob-c\",\"address\":\"$B_ADDR\"}],\"content\":\"hi bob wrong sk\"}" \
    > "$TMP/c2.resp" || true
sleep 0.5
after=$(count_bob)
if [ "$after" != "$before" ]; then
    echo "FAIL C2: bob count $before → $after (expected unchanged)"
    tail -40 "$TMP/server.log"; exit 1
fi
echo "  ✓ AC-C2 PASS"

echo "[AC-C3] alice (sk 부재, 키 등록된 발신자) → bob-c → server 403, count 불변"
start_alice "" || { echo "FAIL C3: alice didn't come up"; exit 1; }
before=$(count_bob)
curl -fs -X POST "http://127.0.0.1:$A_PORT/send" -H "Content-Type: application/json" \
    -d "{\"to\":[{\"name\":\"bob-c\",\"address\":\"$B_ADDR\"}],\"content\":\"hi bob no sk\"}" \
    > "$TMP/c3.resp" || true
sleep 0.5
after=$(count_bob)
if [ "$after" != "$before" ]; then
    echo "FAIL C3: bob count $before → $after (expected unchanged — Phase 2 강제)"
    exit 1
fi
echo "  ✓ AC-C3 PASS"

echo "PASS test_client_signing (AC-C1~C3)"
