#!/usr/bin/env bash
# issue#3 — self-host push hang hotfix.
#
# 증상: container 내부 → public hostname HTTPS loopback이 TCP/TLS 단계에서 hang.
#       registry 11명 모두 self-host 주소 → 거의 모든 letter 500.
# Fix:  push_to_recipients가 self_origin과 prefix-매칭되는 recipient를 skip.
#       skipped 카운터 분리. issue#2 fix(외부 unreachable → failed:1) 회귀 0.
#
# AC:
#   I3-1  self-host recipient → 201 + push.skipped=1, delivered=0, failed=0
#   I3-2  외부 unreachable (port 9) → 201 + push.failed=1, skipped=0 (issue#2 회귀)
#   I3-3  mixed (1 self + 1 unreachable) → skipped=1, failed=1
#   I3-4  simplified body → 400 (issue#1 회귀)

set -uo pipefail

PORT="${ISSUE3_TEST_PORT:-18892}"
URL="http://localhost:$PORT"
SELF_ORIGIN="http://localhost:$PORT"

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-issue3-XXXXXX)
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

strip_ws() { tr -d ' \t\r\n'; }

# I3-1 — self-host recipient
body=$(curl -s -m 10 -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d "{
      \"from\":{\"name\":\"alice\",\"address\":\"$SELF_ORIGIN/inbox/alice\"},
      \"to\":[{\"name\":\"bob\",\"address\":\"$SELF_ORIGIN/inbox/bob\"}],
      \"content\":\"self-host test\"
    }")
b=$(echo "$body" | strip_ws)
case "$b" in
    *'"skipped":1'*'"delivered":0'*'"failed":0'*|*'"delivered":0'*'"failed":0'*'"skipped":1'*)
        report_pass "I3-1 self-host → skipped=1, delivered=0, failed=0" ;;
    *) report_fail "I3-1 expected skipped:1/delivered:0/failed:0, got body=$b" ;;
esac

# I3-2 — 외부 unreachable (port 9 = discard)
body=$(curl -s -m 10 -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d "{
      \"from\":{\"name\":\"alice\",\"address\":\"$SELF_ORIGIN/inbox/alice\"},
      \"to\":[{\"name\":\"ext\",\"address\":\"http://127.0.0.1:9/inbox/ext\"}],
      \"content\":\"external unreachable\"
    }")
b=$(echo "$body" | strip_ws)
case "$b" in
    *'"failed":1'*'"skipped":0'*|*'"skipped":0'*'"failed":1'*|*'"delivered":0'*'"failed":1'*)
        report_pass "I3-2 외부 unreachable → failed=1 (issue#2 회귀 0)" ;;
    *) report_fail "I3-2 expected failed:1/skipped:0, got body=$b" ;;
esac

# I3-3 — mixed (self-host + 외부 unreachable)
body=$(curl -s -m 10 -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d "{
      \"from\":{\"name\":\"alice\",\"address\":\"$SELF_ORIGIN/inbox/alice\"},
      \"to\":[{\"name\":\"bob\",\"address\":\"$SELF_ORIGIN/inbox/bob\"},{\"name\":\"ext\",\"address\":\"http://127.0.0.1:9/inbox/ext\"}],
      \"content\":\"mixed\"
    }")
b=$(echo "$body" | strip_ws)
# mixed: skipped=1 (self bob) + failed=1 (ext)
if echo "$b" | grep -q '"skipped":1' && echo "$b" | grep -q '"failed":1' && echo "$b" | grep -q '"delivered":0'; then
    report_pass "I3-3 mixed → skipped=1, failed=1, delivered=0"
else
    report_fail "I3-3 mixed expected skipped:1/failed:1/delivered:0, got body=$b"
fi

# I3-4 — simplified body (issue#1 회귀)
code=$(curl -s -m 5 -o "$TMP/r.json" -w "%{http_code}" -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d '{"from":"test","content":"hello"}')
[ "$code" = "400" ] && report_pass "I3-4 simplified body → 400 (issue#1 회귀 0)" || report_fail "I3-4 expected 400, got $code"

echo
echo "── summary ──"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" = "0" ]
