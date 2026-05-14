#!/usr/bin/env bash
# fallback B — 첫 request Host header를 server.self_origin state로 latch.
# 사이클 9: STOA_SELF_ORIGIN env 의존 제거. autonomous tick path가 state read로
# 회수해 self-host detect 수행.
#
# AC:
#   B-1  cold-start 직후 health.self_origin == "" (request 0건, latch 미발화).
#   B-2  POST /api/v1/messages 한 번 후 health.self_origin == "http://localhost:$PORT"
#        (Host header latch 완료).
#   B-3  같은 인스턴스에 후속 request가 들어와도 latched 값 불변 (once-only flag).
#   B-4  STOA_SELF_ORIGIN env 미설정 시 fallback A(registry self-row) 그대로
#        작동 — self-host recipient skip 정합 (issue#3 회귀 0).

set -uo pipefail

PORT="${FALLBACK_B_TEST_PORT:-18893}"
URL="http://localhost:$PORT"
EXPECTED_ORIGIN="http://localhost:$PORT"

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-fallback-b-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

# STOA_SELF_ORIGIN 명시적 unset — fallback B latch 경로 단독 검증.
unset STOA_SELF_ORIGIN
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

# B-1: cold-start health — health endpoint 자체가 request이므로 latch가 이미
# 발화. 별 path가 필요한데 health 호출 자체가 첫 request라 _stoa_origin 안 탐
# (handle_health는 req를 받지만 _stoa_origin은 호출 안 함). 즉 health만으로는
# latch 0 — 이걸 검증.
H1=$(curl -fs "$URL/api/v1/health")
SO1=$(echo "$H1" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("self_origin",""))')
if [ "$SO1" = "" ]; then
    report_pass "B-1 cold-start health.self_origin == '' (request 0건 latch 미발화)"
else
    report_fail "B-1 cold-start latch 조기 발화: '$SO1'"
fi

# 발신자 사전 등록 (issue#4 sender gate).
curl -fs -X POST "$URL/api/v1/enter" \
    -H 'Content-Type: application/json' \
    -d '{"name":"alice"}' >/dev/null

curl -fs -X POST "$URL/api/v1/enter" \
    -H 'Content-Type: application/json' \
    -d '{"name":"bob"}' >/dev/null

# B-2: POST /api/v1/messages — _stoa_origin(req) 호출 path. latch trigger.
curl -fs -X POST "$URL/api/v1/messages" \
    -H 'Content-Type: application/json' \
    -d '{
        "from": {"name":"alice","address":"'"$URL"'/inbox/alice"},
        "to": [{"name":"bob","address":"'"$URL"'/inbox/bob"}],
        "content": "fallback B latch trigger"
    }' >/dev/null

H2=$(curl -fs "$URL/api/v1/health")
SO2=$(echo "$H2" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("self_origin",""))')
if [ "$SO2" = "$EXPECTED_ORIGIN" ]; then
    report_pass "B-2 POST 후 health.self_origin == '$EXPECTED_ORIGIN' (latch 완료)"
else
    report_fail "B-2 latch 결과 mismatch: got='$SO2' expected='$EXPECTED_ORIGIN'"
fi

# B-3: 두 번째 POST — latched 값 불변.
curl -fs -X POST "$URL/api/v1/messages" \
    -H 'Content-Type: application/json' \
    -d '{
        "from": {"name":"alice","address":"'"$URL"'/inbox/alice"},
        "to": [{"name":"bob","address":"'"$URL"'/inbox/bob"}],
        "content": "second post — latch 불변 확인"
    }' >/dev/null

H3=$(curl -fs "$URL/api/v1/health")
SO3=$(echo "$H3" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("self_origin",""))')
if [ "$SO3" = "$EXPECTED_ORIGIN" ]; then
    report_pass "B-3 후속 request에서 latched 값 불변"
else
    report_fail "B-3 latch 후 값 변동: got='$SO3'"
fi

# B-4: self-host recipient skip 회귀 — bob 주소가 self host prefix 시작.
RESP=$(curl -fs -X POST "$URL/api/v1/messages" \
    -H 'Content-Type: application/json' \
    -d '{
        "from": {"name":"alice","address":"'"$URL"'/inbox/alice"},
        "to": [{"name":"bob","address":"'"$URL"'/inbox/bob"}],
        "content": "self-host skip 회귀"
    }')
SKIPPED=$(echo "$RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("push",{}).get("skipped",-1))')
if [ "$SKIPPED" = "1" ]; then
    report_pass "B-4 self-host recipient → push.skipped=1 (issue#3 회귀 0)"
else
    report_fail "B-4 self-host skip mismatch: skipped='$SKIPPED'"
fi

echo ""
echo "── summary ──"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" = "0" ]
