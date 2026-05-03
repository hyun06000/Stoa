#!/usr/bin/env bash
# RFC-001 §12 Acceptance — AC-1 ~ AC-12. Self-contained: 자기 server 인스턴스를
# STOA_SIGNING_PHASE=2, STOA_TEST_TIME=<anchor> 로 띄우고 12 시나리오를 sh+curl로 회귀.
#
# 의존: python3 + cryptography (ed25519). bash, curl, ail-interpreter v1.71.1+.
#
# 다른 test_*.sh와 달리 외부 STOA_URL을 받지 않는다 — phase=2 환경이 다른 phase=0
# 테스트들과 호환 안 됨 (run_all.sh는 phase=0 server 띄움).
#
# 종료 코드: 0 = 전 PASS, 1 = 1건 이상 FAIL.

set -uo pipefail

PORT="${SIGN_TEST_PORT:-18890}"
URL="http://localhost:$PORT"
ANCHOR_ISO="2026-05-04T12:00:00Z"
ANCHOR_UNIX=1777896000

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

if ! python3 -c "from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey" 2>/dev/null; then
    echo "SKIP test_signing: python3 cryptography 패키지 부재 (pip install cryptography)"
    exit 0
fi

TMP=$(mktemp -d -t stoa-sign-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_SIGNING_PHASE=2 \
    STOA_TEST_TIME="$ANCHOR_UNIX" \
    ail run server.ail > server.log 2>&1 &
SRV=$!

for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.5
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"
    tail -40 server.log
    exit 1
fi

# Python helper: keygen, canonical, sign. 단일 process 호출로 stdin JSON command 처리.
cat > "$TMP/sign_helper.py" <<'PYEOF'
import sys, json, secrets
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
from cryptography.hazmat.primitives.serialization import (
    Encoding, PrivateFormat, PublicFormat, NoEncryption,
)

def _esc(s):
    return (s.replace("\\", "\\\\")
             .replace("|", "\\|")
             .replace(";", "\\;")
             .replace(":", "\\:"))

def canonical_letter(fr_name, fr_addr, recipients, content, created_at, nonce):
    sorted_to = sorted(recipients, key=lambda r: r["name"])
    parts = [_esc(r["name"]) + ":" + _esc(r["address"]) for r in sorted_to]
    return ("letter|" + _esc(fr_name) + "|" + _esc(fr_addr) + "|"
            + ";".join(parts) + "|" + _esc(content) + "|"
            + _esc(created_at) + "|" + _esc(nonce))

def canonical_register(name, addr, pk, created_at, nonce):
    return ("register|" + _esc(name) + "|" + _esc(addr) + "|"
            + _esc(pk) + "|" + _esc(created_at) + "|" + _esc(nonce))

def keygen():
    sk = Ed25519PrivateKey.generate()
    sk_hex = sk.private_bytes(Encoding.Raw, PrivateFormat.Raw, NoEncryption()).hex()
    pk_hex = sk.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw).hex()
    return {"sk": sk_hex, "pk": pk_hex}

def sign(sk_hex, msg):
    sk = Ed25519PrivateKey.from_private_bytes(bytes.fromhex(sk_hex))
    return sk.sign(msg.encode("utf-8")).hex()

def main():
    cmd = sys.argv[1]
    if cmd == "keygen":
        print(json.dumps(keygen()))
    elif cmd == "nonce":
        print(secrets.token_bytes(16).hex())
    elif cmd == "canonical_letter":
        a = json.loads(sys.stdin.read())
        print(canonical_letter(a["from_name"], a["from_address"],
                               a["recipients"], a["content"],
                               a["created_at"], a["nonce"]))
    elif cmd == "canonical_register":
        a = json.loads(sys.stdin.read())
        print(canonical_register(a["name"], a["address"], a["public_key"],
                                 a["created_at"], a["nonce"]))
    elif cmd == "sign":
        a = json.loads(sys.stdin.read())
        print(sign(a["sk"], a["msg"]))
    elif cmd == "send_letter":
        a = json.loads(sys.stdin.read())
        canon = canonical_letter(a["from_name"], a["from_address"],
                                 a["recipients"], a["content"],
                                 a["created_at"], a["nonce"])
        sig = sign(a["sk"], canon)
        body = {
            "from": {"name": a["from_name"], "address": a["from_address"]},
            "to": a["recipients"],
            "content": a["content"],
            "created_at": a["created_at"],
            "nonce": a["nonce"],
            "signature": sig,
        }
        print(json.dumps({"body": body, "canonical": canon, "signature": sig}))

if __name__ == "__main__":
    main()
PYEOF

py() { python3 "$TMP/sign_helper.py" "$@"; }
jval() { python3 -c "import json,sys; v=json.load(open('$1'))$2; print('null' if v is None else v)"; }

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

# ─── AC-1: 키 없이 register → 201, public_key null ───────────────
echo "── AC-1: register without key ───────────────"
code=$(curl -s -o "$TMP/r1.json" -w "%{http_code}" -X POST "$URL/api/v1/agents" \
    -H "Content-Type: application/json" \
    -d '{"name":"newcomer","address":"https://newcomer.example/inbox"}')
if [ "$code" = "201" ] && [ "$(jval "$TMP/r1.json" "['public_key']")" = "null" ]; then
    report_pass "AC-1 newcomer registered, public_key=null"
else
    report_fail "AC-1 status=$code body=$(cat "$TMP/r1.json")"
fi

# alice 키 두 쌍 미리 생성
alice1=$(py keygen)
SK1=$(echo "$alice1" | python3 -c "import json,sys; print(json.load(sys.stdin)['sk'])")
PK1=$(echo "$alice1" | python3 -c "import json,sys; print(json.load(sys.stdin)['pk'])")
alice2=$(py keygen)
SK2=$(echo "$alice2" | python3 -c "import json,sys; print(json.load(sys.stdin)['sk'])")
PK2=$(echo "$alice2" | python3 -c "import json,sys; print(json.load(sys.stdin)['pk'])")
ALICE_ADDR1="https://alice.example/inbox"
ALICE_ADDR2="https://alice2.example/inbox"

# bob/carol 발신용 키 (letter 검증)
bobkeys=$(py keygen)
BOB_SK=$(echo "$bobkeys" | python3 -c "import json,sys; print(json.load(sys.stdin)['sk'])")
BOB_PK=$(echo "$bobkeys" | python3 -c "import json,sys; print(json.load(sys.stdin)['pk'])")

# ─── AC-2: 같은 이름, 새 키, 서명 누락 → 400/403 ─────────────────
echo "── AC-2: re-register without sig ────────────"
code=$(curl -s -o "$TMP/r2a.json" -w "%{http_code}" -X POST "$URL/api/v1/agents" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"alice\",\"address\":\"$ALICE_ADDR1\",\"public_key\":\"$PK1\"}")
[ "$code" = "201" ] || { report_fail "AC-2 grandfather alice status=$code"; }
code=$(curl -s -o "$TMP/r2b.json" -w "%{http_code}" -X POST "$URL/api/v1/agents" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"alice\",\"address\":\"$ALICE_ADDR2\",\"public_key\":\"$PK2\"}")
if [ "$code" = "400" ] || [ "$code" = "403" ]; then
    report_pass "AC-2 grandfather alice OK; re-register no sig blocked ($code)"
else
    report_fail "AC-2 re-register no sig status=$code body=$(cat "$TMP/r2b.json")"
fi

# ─── AC-3: 직전 키 서명으로 재등록 → 201, latest = pk2 ────────────
echo "── AC-3: re-register signed ─────────────────"
NONCE=$(py nonce)
canon=$(printf '{"name":"alice","address":"%s","public_key":"%s","created_at":"%s","nonce":"%s"}' \
    "$ALICE_ADDR2" "$PK2" "$ANCHOR_ISO" "$NONCE" | py canonical_register)
sig=$(printf '{"sk":"%s","msg":%s}' "$SK1" "$(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$canon")" | py sign)
code=$(curl -s -o "$TMP/r3.json" -w "%{http_code}" -X POST "$URL/api/v1/agents" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"alice\",\"address\":\"$ALICE_ADDR2\",\"public_key\":\"$PK2\",\"signature\":\"$sig\",\"nonce\":\"$NONCE\",\"created_at\":\"$ANCHOR_ISO\"}")
if [ "$code" = "201" ]; then
    pk_now=$(curl -s "$URL/api/v1/agents/alice" | python3 -c "import json,sys; print(json.load(sys.stdin)['public_key'])")
    if [ "$pk_now" = "$PK2" ]; then
        report_pass "AC-3 alice re-registered with pk2 (latest=pk2)"
    else
        report_fail "AC-3 lookup pk=$pk_now expected $PK2"
    fi
else
    report_fail "AC-3 status=$code body=$(cat "$TMP/r3.json")"
fi

# bob을 alice2와 같은 패턴으로 grandfather 등록 (AC-4 발신자로 사용)
curl -s -o /dev/null -X POST "$URL/api/v1/agents" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"bob\",\"address\":\"http://127.0.0.1:1/inbox\",\"public_key\":\"$BOB_PK\"}"

# ─── AC-4: valid 서명 letter → 201, envelope echo ────────────────
echo "── AC-4: valid signed letter ────────────────"
NONCE4=$(py nonce)
build4=$(python3 "$TMP/sign_helper.py" send_letter <<EOF
{"from_name":"bob","from_address":"http://127.0.0.1:1/inbox",
 "recipients":[{"name":"newcomer","address":"http://127.0.0.1:1/x"}],
 "content":"hi newcomer signed by bob",
 "created_at":"$ANCHOR_ISO","nonce":"$NONCE4","sk":"$BOB_SK"}
EOF
)
body4=$(echo "$build4" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['body']))")
code=$(curl -s -o "$TMP/r4.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" -d "$body4")
if [ "$code" = "201" ]; then
    sig_echo=$(jval "$TMP/r4.json" "['envelope']['signature']")
    nonce_echo=$(jval "$TMP/r4.json" "['envelope']['nonce']")
    if [ "$nonce_echo" = "$NONCE4" ] && [ -n "$sig_echo" ] && [ "$sig_echo" != "null" ]; then
        report_pass "AC-4 letter accepted, envelope preserves signature/nonce"
    else
        report_fail "AC-4 envelope echo missing: sig=$sig_echo nonce=$nonce_echo"
    fi
else
    report_fail "AC-4 status=$code body=$(cat "$TMP/r4.json") log=$(tail -10 server.log)"
fi

# ─── AC-5: signature 1바이트 tamper → 403, 저장 안 됨 ──────────────
echo "── AC-5: tampered signature ─────────────────"
sig5=$(echo "$build4" | python3 -c "import json,sys; s=json.load(sys.stdin)['signature']; print((s[:-1] + ('0' if s[-1]!='0' else '1')))")
NONCE5=$(py nonce)  # different nonce so it's not nonce-replay
# rebuild canonical with new nonce, but tamper signature anyway
build5=$(python3 "$TMP/sign_helper.py" send_letter <<EOF
{"from_name":"bob","from_address":"http://127.0.0.1:1/inbox",
 "recipients":[{"name":"newcomer","address":"http://127.0.0.1:1/x"}],
 "content":"hi-tampered",
 "created_at":"$ANCHOR_ISO","nonce":"$NONCE5","sk":"$BOB_SK"}
EOF
)
body5=$(echo "$build5" | python3 -c "
import json,sys
d=json.load(sys.stdin)
b=d['body']
s=b['signature']
b['signature'] = s[:-1] + ('0' if s[-1]!='0' else '1')
print(json.dumps(b))")
code=$(curl -s -o "$TMP/r5.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" -d "$body5")
if [ "$code" = "403" ]; then
    # 저장 안 됨 검증
    found=$(curl -s "$URL/api/v1/messages" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(any(m.get('content')=='hi-tampered' for m in d.get('messages',[])))")
    if [ "$found" = "False" ]; then
        report_pass "AC-5 tampered sig 403 + 저장 안 됨"
    else
        report_fail "AC-5 tampered letter saved (should not)"
    fi
else
    report_fail "AC-5 status=$code (expected 403)"
fi

# ─── AC-6: stale created_at → 403 ────────────────────────────────
echo "── AC-6: stale created_at ───────────────────"
STALE_ISO=$(python3 -c "import datetime; t=datetime.datetime(2026,5,4,11,57,0,tzinfo=datetime.timezone.utc); print(t.strftime('%Y-%m-%dT%H:%M:%SZ'))")  # anchor - 180s
NONCE6=$(py nonce)
build6=$(python3 "$TMP/sign_helper.py" send_letter <<EOF
{"from_name":"bob","from_address":"http://127.0.0.1:1/inbox",
 "recipients":[{"name":"newcomer","address":"http://127.0.0.1:1/x"}],
 "content":"stale ping",
 "created_at":"$STALE_ISO","nonce":"$NONCE6","sk":"$BOB_SK"}
EOF
)
body6=$(echo "$build6" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['body']))")
code=$(curl -s -o "$TMP/r6.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" -d "$body6")
if [ "$code" = "403" ]; then
    msg=$(jval "$TMP/r6.json" "['error']")
    case "$msg" in *window*) report_pass "AC-6 stale rejected: $msg" ;; *) report_fail "AC-6 403 but error=$msg (expected window)" ;; esac
else
    report_fail "AC-6 status=$code body=$(cat "$TMP/r6.json")"
fi

# ─── AC-7: future created_at → 403 ───────────────────────────────
echo "── AC-7: future created_at ──────────────────"
FUT_ISO=$(python3 -c "import datetime; t=datetime.datetime(2026,5,4,12,3,0,tzinfo=datetime.timezone.utc); print(t.strftime('%Y-%m-%dT%H:%M:%SZ'))")  # anchor + 180s
NONCE7=$(py nonce)
build7=$(python3 "$TMP/sign_helper.py" send_letter <<EOF
{"from_name":"bob","from_address":"http://127.0.0.1:1/inbox",
 "recipients":[{"name":"newcomer","address":"http://127.0.0.1:1/x"}],
 "content":"future ping",
 "created_at":"$FUT_ISO","nonce":"$NONCE7","sk":"$BOB_SK"}
EOF
)
body7=$(echo "$build7" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['body']))")
code=$(curl -s -o "$TMP/r7.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" -d "$body7")
if [ "$code" = "403" ]; then
    msg=$(jval "$TMP/r7.json" "['error']")
    case "$msg" in *window*) report_pass "AC-7 future rejected: $msg" ;; *) report_fail "AC-7 403 but error=$msg (expected window)" ;; esac
else
    report_fail "AC-7 status=$code body=$(cat "$TMP/r7.json")"
fi

# ─── AC-8: 같은 (from, nonce) 두 번 → 두 번째 403 ─────────────────
echo "── AC-8: nonce replay ───────────────────────"
NONCE8=$(py nonce)
build8=$(python3 "$TMP/sign_helper.py" send_letter <<EOF
{"from_name":"bob","from_address":"http://127.0.0.1:1/inbox",
 "recipients":[{"name":"newcomer","address":"http://127.0.0.1:1/x"}],
 "content":"replay test","created_at":"$ANCHOR_ISO","nonce":"$NONCE8","sk":"$BOB_SK"}
EOF
)
body8=$(echo "$build8" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)['body']))")
code1=$(curl -s -o "$TMP/r8a.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" -d "$body8")
code2=$(curl -s -o "$TMP/r8b.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" -d "$body8")
if [ "$code1" = "201" ] && [ "$code2" = "403" ]; then
    msg=$(jval "$TMP/r8b.json" "['error']")
    case "$msg" in *nonce*) report_pass "AC-8 nonce replay rejected: $msg" ;; *) report_fail "AC-8 403 but error=$msg (expected nonce)" ;; esac
else
    report_fail "AC-8 status1=$code1 status2=$code2 (expected 201,403)"
fi

# ─── AC-9: 키 없는 발신자 letter → 201 (Phase 2 grandfather) ──────
echo "── AC-9: keyless sender grandfather (Phase 2)"
curl -s -o /dev/null -X POST "$URL/api/v1/agents" \
    -H "Content-Type: application/json" \
    -d '{"name":"carol","address":"http://127.0.0.1:1/carol"}'
code=$(curl -s -o "$TMP/r9.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{"from":{"name":"carol","address":"http://127.0.0.1:1/carol"},"to":[{"name":"newcomer","address":"http://127.0.0.1:1/x"}],"content":"carol unsigned"}')
if [ "$code" = "201" ]; then
    report_pass "AC-9 keyless sender unsigned letter accepted (Phase 2 grandfather)"
else
    report_fail "AC-9 status=$code body=$(cat "$TMP/r9.json")"
fi

# ─── AC-10: 수신자 inbox에서 envelope sig/nonce/created_at 보존 ───
echo "── AC-10: envelope preserved on read ────────"
nl=$(curl -s "$URL/api/v1/messages?to=newcomer" | python3 -c "
import json,sys
d=json.load(sys.stdin)
hits=[m for m in d.get('messages',[]) if m.get('content')=='hi newcomer signed by bob']
if not hits: print('none'); sys.exit(0)
m=hits[0]
print(','.join(['sig' if m.get('signature') else '_',
                'nonce' if m.get('nonce') else '_',
                'ca' if m.get('created_at') else '_']))
")
if [ "$nl" = "sig,nonce,ca" ]; then
    report_pass "AC-10 inbox envelope sig+nonce+created_at 모두 보존"
else
    report_fail "AC-10 envelope echo on read: $nl"
fi

# ─── AC-11: canonical 직렬화 byte 일치성 (RFC §6.1 + Appendix) ────
# Note: RFC §12 line 644 fixture (illustrative example)는 필드 *내부* `:` escape
# 누락 — `https://`/`T03:00:00Z` 등이 raw로 적혀 있음. Appendix Python `esc`
# (= 우리 _esc) 정의는 필드 내부 `:`를 escape. 본 테스트는 Appendix 기준.
# *recipient-pair 구분자* `:` (name과 address 사이)는 raw — escape 대상은 필드
# 내부만. Walter에게 RFC §12 fixture 정정 letter 발신 (TODO).
echo "── AC-11: canonical fixture byte-equality ───"
expected='letter|alice|https\://a/inbox|bob:https\://b/inbox;carol:https\://c/inbox|hi\|test|2026-05-01T03\:00\:00Z|deadbeef'
actual=$(python3 "$TMP/sign_helper.py" canonical_letter <<'EOF'
{"from_name":"alice","from_address":"https://a/inbox",
 "recipients":[{"name":"bob","address":"https://b/inbox"},{"name":"carol","address":"https://c/inbox"}],
 "content":"hi|test","created_at":"2026-05-01T03:00:00Z","nonce":"deadbeef"}
EOF
)
if [ "$actual" = "$expected" ]; then
    # backslash escape order regression: \\ → \\\\, | → \|
    bsl_actual=$(python3 "$TMP/sign_helper.py" canonical_letter <<'EOF'
{"from_name":"x","from_address":"y",
 "recipients":[{"name":"z","address":"w"}],
 "content":"a\\b|c","created_at":"t","nonce":"n"}
EOF
)
    # 입력 content (JSON decode 후) = `a\b|c` (1 backslash). escape 순서 \\ → \|로
    # backslash가 먼저 `\\`로 doubled → 그 다음 pipe가 `\|`로. 결과: `a\\b\|c`.
    # 순서 거꾸로면 (| 먼저) backslash 자기 자신이 두 번 escape돼 `\\\\` 4개가 나옴.
    case "$bsl_actual" in *'a\\b\|c'*) bsl_ok=1 ;; *) bsl_ok=0 ;; esac
    if [ "$bsl_ok" = "1" ]; then
        report_pass "AC-11 fixture byte-equal + escape 순서 회귀 OK"
    else
        report_fail "AC-11 escape 순서 회귀: $bsl_actual"
    fi
else
    report_fail "AC-11 mismatch:\n  expected: $expected\n  actual:   $actual"
fi

# ─── AC-12: PRINCIPLES §3 회귀 ────────────────────────────────────
echo "── AC-12: PRINCIPLES §3 append-only regression"
if STOA_URL="$URL" bash "$SCRIPT_DIR/test_principle_append_only.sh" >"$TMP/ac12.log" 2>&1; then
    report_pass "AC-12 test_principle_append_only PASS"
else
    report_fail "AC-12 test_principle_append_only FAIL — $(tail -5 "$TMP/ac12.log")"
fi

# ─── AC-13: Q1 §6.5 hotfix — Web UI POST 차단 (사람 + 무서명 → 401) ──
# discord_users에 등재된 from.name이 attestation 부재 letter 보내면 401.
# enumeration 방어 위해 통일 메시지 'unauthorized envelope'.
echo "── AC-13: Q1 hotfix human attestation gate ──"
if command -v sqlite3 >/dev/null 2>&1; then
    # carol은 AC-9에서 키 없이 등록됨 — discord_users에도 직접 binding.
    sqlite3 "$TMP/messages.db" "INSERT INTO discord_users (discord_id, stoa_name, bound_at) VALUES ('test_dc_1', 'carol', '$ANCHOR_ISO');" 2>"$TMP/ac13_db.log"
    code=$(curl -s -o "$TMP/r13.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" \
        -d '{"from":{"name":"carol","address":"http://127.0.0.1:1/carol"},"to":[{"name":"newcomer","address":"http://127.0.0.1:1/x"}],"content":"web ui human attempt"}')
    if [ "$code" = "401" ]; then
        msg=$(jval "$TMP/r13.json" "['error']")
        case "$msg" in *unauthorized*) report_pass "AC-13 human + no attestation → 401 ($msg)" ;; *) report_fail "AC-13 401 but error=$msg (expected unauthorized envelope)" ;; esac
    else
        report_fail "AC-13 status=$code body=$(cat "$TMP/r13.json")"
    fi
else
    echo "  ⚠ AC-13 SKIP — sqlite3 CLI 부재"
fi

# ─── AC-14: Bug B — `?since_id=0` 0건 반환 → no-since-id 분기와 동일 ──
# `since_id == "0"`도 빈 since와 동등 처리. 발견 동기: wake_monitor 첫 부트 fallback.
echo "── AC-14: Bug B since_id=0 falls back to no-since branch"
all_count=$(curl -s "$URL/api/v1/messages?to=newcomer" | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])")
zero_count=$(curl -s "$URL/api/v1/messages?to=newcomer&since_id=0" | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])")
if [ "$all_count" = "$zero_count" ] && [ "$all_count" != "0" ]; then
    report_pass "AC-14 since_id=0 == no-since (count=$all_count)"
else
    report_fail "AC-14 since_id=0 count=$zero_count vs no-since count=$all_count"
fi
# all 경로 (?to= 미지정)도 동일하게.
all2=$(curl -s "$URL/api/v1/messages" | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])")
zero2=$(curl -s "$URL/api/v1/messages?since_id=0" | python3 -c "import json,sys; print(json.load(sys.stdin)['count'])")
if [ "$all2" = "$zero2" ] && [ "$all2" != "0" ]; then
    report_pass "AC-14 (all path) since_id=0 == no-since (count=$all2)"
else
    report_fail "AC-14 (all path) since_id=0 count=$zero2 vs no-since count=$all2"
fi

echo
echo "──────────────────────────────────"
echo "  PASS: $PASS"
echo "  FAIL: $FAIL"
echo "──────────────────────────────────"
[ "$FAIL" -eq 0 ] && echo "PASS test_signing" || { echo "FAIL test_signing"; tail -30 server.log; exit 1; }
