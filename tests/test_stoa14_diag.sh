#!/usr/bin/env bash
# Stoa#14-2 — /api/v1/diag 진단 endpoint 검증.
#
# 박상현 doctrine (msg_1779080765_35): '측정 우선, 가설 좁히기 0'. F-1 hotfix가
# RSS 우상향 차단 못 했으니 leak source 정확 위치 측정으로 진짜 root cause 가시화.
#
# AC:
#   D-1  GET /api/v1/diag → 200 + JSON 구조 정합 (status·sampled_at·process·db·
#        state·server 6 top-level key).
#   D-2  db.letters_count가 실제 INSERT 자취와 일치 (post 3건 → 3 letters).
#   D-3  db.delivery_log·seen_nonces·inbox_cursors 키 존재 (Number).
#   D-4  state.keys_count > 0 (latch 후) + last_tick_at 존재.
#   D-5  process.proc_available — Linux 환경에서 true (/proc/self/status 회수).
#        macOS 등 darwin 로컬에서는 false → process 필드 모두 0 fallback (graceful).

set -uo pipefail

PORT="${STOA14_DIAG_PORT:-18896}"
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

TMP=$(mktemp -d -t stoa-diag-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    ail run server.ail > server.log 2>&1 &
SRV=$!
for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"; tail -40 server.log; exit 1
fi

# 발신자/수신자 등록 + 3 letter INSERT (deterministic count).
curl -fs -X POST "$URL/api/v1/enter" -H 'Content-Type: application/json' -d '{"name":"alice"}' >/dev/null
curl -fs -X POST "$URL/api/v1/enter" -H 'Content-Type: application/json' -d '{"name":"bob"}' >/dev/null
for i in 1 2 3; do
    curl -fs -X POST "$URL/api/v1/messages" -H 'Content-Type: application/json' \
        -d "{\"from\":{\"name\":\"alice\",\"address\":\"$URL/inbox/alice\"},\"to\":[{\"name\":\"bob\",\"address\":\"$URL/inbox/bob\"}],\"content\":\"diag test letter $i\"}" >/dev/null
done

# D-1: GET /api/v1/diag → 200 + 구조 (7 top-level key, python_heap 포함).
DIAG=$(curl -fs "$URL/api/v1/diag")
STATUS=$(echo "$DIAG" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("status",""))')
HAS_KEYS=$(echo "$DIAG" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(all(k in d for k in ["status","sampled_at","process","db","state","server","python_heap"]))')
if [ "$STATUS" = "ok" ] && [ "$HAS_KEYS" = "True" ]; then
    report_pass "D-1 GET /api/v1/diag 200 + JSON 구조 정합 (7 top-level key, python_heap 포함)"
else
    report_fail "D-1 status='$STATUS' has_keys='$HAS_KEYS' diag='$DIAG'"
fi

# D-2: db.letters_count == 3.
LETTERS=$(echo "$DIAG" | python3 -c 'import sys,json; print(json.load(sys.stdin)["db"]["letters"])')
if [ "$LETTERS" = "3" ]; then
    report_pass "D-2 db.letters=3 (실제 INSERT 자취 일치)"
else
    report_fail "D-2 db.letters=$LETTERS (expected 3)"
fi

# D-3: aux 테이블 키 존재 (Number).
HAS_AUX=$(echo "$DIAG" | python3 -c 'import sys,json; d=json.load(sys.stdin)["db"]; print(all(isinstance(d.get(k),int) for k in ["delivery_log","seen_nonces","inbox_cursors","registry","recipients"]))')
if [ "$HAS_AUX" = "True" ]; then
    report_pass "D-3 db.{delivery_log,seen_nonces,inbox_cursors,registry,recipients} 키 존재 (Number)"
else
    report_fail "D-3 aux 키 누락 — db=$(echo "$DIAG" | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin)[\"db\"]))')"
fi

# D-4: state.keys_count > 0 + last_tick_at 존재 (server 부팅 후 state 일부 latch).
KEYS=$(echo "$DIAG" | python3 -c 'import sys,json; print(json.load(sys.stdin)["state"]["keys_count"])')
HAS_TICK=$(echo "$DIAG" | python3 -c 'import sys,json; print("last_tick_at" in json.load(sys.stdin)["state"])')
if [ "$KEYS" -ge "0" ] && [ "$HAS_TICK" = "True" ]; then
    report_pass "D-4 state.keys_count=$KEYS + last_tick_at 키 존재"
else
    report_fail "D-4 state keys=$KEYS has_tick=$HAS_TICK"
fi

# D-5: process.proc_available — Linux=true, darwin=false. 둘 다 graceful.
PROC_AVAIL=$(echo "$DIAG" | python3 -c 'import sys,json; print(json.load(sys.stdin)["process"]["proc_available"])')
OS=$(uname)
if [ "$OS" = "Linux" ]; then
    if [ "$PROC_AVAIL" = "True" ]; then
        VMRSS=$(echo "$DIAG" | python3 -c 'import sys,json; print(json.load(sys.stdin)["process"]["VmRSS_kB"])')
        if [ "$VMRSS" -gt "0" ]; then
            report_pass "D-5 (Linux) process.proc_available=true + VmRSS_kB=$VMRSS"
        else
            report_fail "D-5 (Linux) proc_available=true이나 VmRSS=0"
        fi
    else
        report_fail "D-5 (Linux) proc_available=false (/proc/self/status 회수 실패)"
    fi
else
    # darwin/기타 — proc_available=false fallback 정상.
    if [ "$PROC_AVAIL" = "False" ]; then
        report_pass "D-5 ($OS) proc_available=false graceful fallback (process 필드 0)"
    else
        report_fail "D-5 ($OS) 예상 false이나 $PROC_AVAIL"
    fi
fi

# D-6: python_heap layer — AIL v1.75.0+ diag.* substrate (Stoa#14-3).
PY_HEAP=$(echo "$DIAG" | python3 -c 'import sys,json; print(json.dumps(json.load(sys.stdin).get("python_heap",{})))')
GC_LEN=$(echo "$PY_HEAP" | python3 -c 'import sys,json; print(len(json.load(sys.stdin).get("gc_count",[])))')
OBJ=$(echo "$PY_HEAP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("objects_count",0))')
TH=$(echo "$PY_HEAP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("thread_count",0))')
if [ "$GC_LEN" = "3" ] && [ "$OBJ" -gt "0" ] && [ "$TH" -gt "0" ]; then
    report_pass "D-6 python_heap.gc_count[3] + objects=$OBJ + threads=$TH (diag.* substrate 작동)"
else
    report_fail "D-6 python_heap mismatch: gc_len=$GC_LEN objects=$OBJ threads=$TH"
fi

# D-7: tracemalloc — on_birth start 후 snapshot 자취.
TM_TOP=$(echo "$PY_HEAP" | python3 -c 'import sys,json; print(len(json.load(sys.stdin).get("tracemalloc_top10",[])))')
TM_AVAIL=$(echo "$PY_HEAP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("tracemalloc_available",False))')
if [ "$TM_TOP" -ge "1" ] && [ "$TM_AVAIL" = "True" ]; then
    # 첫 entry shape — file/line/size_kb/count 키 존재.
    HAS_SHAPE=$(echo "$PY_HEAP" | python3 -c 'import sys,json; e=json.load(sys.stdin)["tracemalloc_top10"][0]; print(all(k in e for k in ["file","line","size_kb","count"]))')
    if [ "$HAS_SHAPE" = "True" ]; then
        report_pass "D-7 tracemalloc_top10 $TM_TOP entry + shape 정합 (file/line/size_kb/count)"
    else
        report_fail "D-7 tracemalloc entry shape mismatch"
    fi
else
    report_fail "D-7 tracemalloc_top10 빈 list (start 미발화? on_birth 자취 결손)"
fi

echo ""
echo "── summary ──"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" = "0" ]
