#!/usr/bin/env bash
# Stoa#13 회귀 게이트 — `_pump_subscriber` polling-only inbox URL self-loop 차단.
#
# 증상 (production 2026-05-14): AIL 5인(homeros·arche·ergon·telos·tekton)이 룰 25
# 정합으로 envelope address `https://<host>/inbox/<name>` 박은 후 autonomous tick
# context에서 `_get_self_origin()`가 state read 결손으로 "" 반환 → fallback A는
# self-row `stoa://self`에 `/inbox/` 없어 `_is_self_host` false → pump가 자기
# 서버로 POST 발사 → /inbox/<name> 404 + urllib socket alloc 누적 → RSS 우상향.
#
# Fix (`8d91eea`): `_pump_subscriber` 진입부에 `_is_polling_inbox(name, addr)`
# 가드. addr suffix `/inbox/<name>` 매칭이면 push 0, 모든 pending letter
# status="skipped" 일괄 마크.
#
# AC (Admin 위임 msg_1778809602_6):
#   S-Leak-1  polling-only subscriber (self-host prefix) push 0건 보장.
#             외부 outbound POST /inbox/<name> 로그 count == 0 (tick 다회 경과).
#   S-Leak-2  on_tick 1주기 동안 unhandled urllib timeout 0건 보장.
#             server.log에 `on_tick failed` / urllib timeout 패턴 count == 0.
#   S-Leak-3  registry에 self-host 도메인 addr 등록 시 _pump_subscriber가
#             skipped 즉시 마크. delivery_log row status="skipped" (sqlite3 직접
#             검증).
#
# topology: self-contained (자기 server boot — fast-tick env override).
# gate: STOA_PHASE_B=1 (run_all.sh가 phase_b/test_*.sh를 활성화하는 동일 게이트).
#       Phase B autonomous loop이 본 leak의 surface — gate 정합.
#
# 의존: bash, curl, python3, sqlite3, ail-interpreter.

set -uo pipefail

# Phase B gate.
if [ "${STOA_PHASE_B:-0}" != "1" ]; then
    echo "── Stoa#13 leak 회귀: SKIP (STOA_PHASE_B!=1)"
    exit 0
fi

PORT="${LEAK_TEST_PORT:-18897}"
URL="http://localhost:$PORT"

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    pids=$(lsof -ti tcp:$PORT 2>/dev/null || true)
    [ -n "$pids" ] && echo "$pids" | xargs kill -9 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

# ─── Boot Stoa server (self-contained, fast-tick) ─────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP="$(mktemp -d -t stoa-leak-XXXXXX)"
cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

# fast-tick — pump 분기 자리 즉시 검증.
unset STOA_SELF_ORIGIN  # production 정황(self_origin latch 결손) 재현.
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_TICK_SEC=1 \
    ail run server.ail > "$TMP/server.log" 2>&1 &
SRV=$!

for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"
    tail -40 "$TMP/server.log"
    exit 1
fi

# ─── Helpers ──────────────────────────────────────────────────────────────────
TS="$(date +%s)"
SENDER="rachel-leak-sender-$TS"
POLL_SUB="rachel-leak-polling-$TS"
POLL_ADDR="$URL/inbox/$POLL_SUB"

register() {
    curl -fs -X POST "$URL/api/v1/agents" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$1\",\"address\":\"$2\"}" >/dev/null
}
post_letter() {
    curl -fs -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" \
        -d "{\"from\":{\"name\":\"$1\",\"address\":\"$URL/inbox/$1\"},\"to\":[{\"name\":\"$2\",\"address\":\"$3\"}],\"content\":\"$4\"}"
}
extract_id() {
    python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('id') or d.get('envelope',{}).get('id') or '')"
}

# 발신자 + polling-only 수신자 사전 등록.
register "$SENDER" "$URL/inbox/$SENDER"
register "$POLL_SUB" "$POLL_ADDR"

# letter POST → polling-only path 발동.
LETTER_RESP=$(post_letter "$SENDER" "$POLL_SUB" "$POLL_ADDR" "stoa-13-leak-regress")
MID="$(echo "$LETTER_RESP" | extract_id)"
if [ -z "$MID" ]; then
    echo "FAIL: letter POST 응답 id 없음 — $LETTER_RESP"
    exit 1
fi

# tick 다회 경과 — pump이 polling-only 분기 진입 자리 보장 + leak 누적 surface.
# RETRY_MAX·ESCALATE_AFTER 무관 — skipped 분기는 1회 tick에서 즉시 terminal.
sleep 5

# ─── S-Leak-1: polling-only 주소 self-loop POST 0건 ─────────────────────────
echo "── S-Leak-1  polling-only subscriber push 0건 보장"
SELF_LOOP_POSTS=$(grep -c "POST /inbox/$POLL_SUB" "$TMP/server.log" || true)
# server.log의 access 라인 중 *inbound POST 핸들러 진입* 흔적 검사.
# polling-only 가드가 작동하면 pump가 outbound POST 발사 자체 안 함 → 자기 서버
# inbound handler도 trigger 안 됨 → /inbox/<name> 404 라인 0.
if [ "${SELF_LOOP_POSTS:-0}" = "0" ]; then
    report_pass "S-Leak-1 POST /inbox/$POLL_SUB 0건 (pump skip 분기 정합)"
else
    report_fail "S-Leak-1 self-loop POST $SELF_LOOP_POSTS 건 — pump skip 분기 결손"
    grep "POST /inbox/$POLL_SUB" "$TMP/server.log" | head -3
fi

# ─── S-Leak-2: on_tick urllib timeout 0건 ───────────────────────────────────
echo "── S-Leak-2  on_tick unhandled urllib timeout 0건 보장"
# production 증상: `on_tick failed` + urllib socket timeout 누적. fix 정합 시 0.
TICK_FAIL=$(grep -cE "on_tick failed|urllib.*[Tt]imeout|URLError|socket\.timeout" "$TMP/server.log" || true)
if [ "${TICK_FAIL:-0}" = "0" ]; then
    report_pass "S-Leak-2 on_tick / urllib timeout 0건"
else
    report_fail "S-Leak-2 on_tick / urllib timeout $TICK_FAIL 건 누적"
    grep -E "on_tick failed|urllib.*[Tt]imeout|URLError|socket\.timeout" "$TMP/server.log" | head -5
fi

# ─── S-Leak-3: delivery_log status='skipped' 즉시 마크 ──────────────────────
echo "── S-Leak-3  _pump_subscriber skipped 즉시 마크 (delivery_log 직접 검증)"
if ! command -v sqlite3 >/dev/null 2>&1; then
    report_fail "S-Leak-3 sqlite3 unavailable — direct delivery_log 검증 불가"
else
    DLOG_STATUS=$(sqlite3 "$TMP/messages.db" \
        "SELECT status FROM delivery_log WHERE name='$POLL_SUB' AND msg_id='$MID';" 2>/dev/null || true)
    DLOG_ATTEMPTS=$(sqlite3 "$TMP/messages.db" \
        "SELECT attempts FROM delivery_log WHERE name='$POLL_SUB' AND msg_id='$MID';" 2>/dev/null || true)
    if [ "$DLOG_STATUS" = "skipped" ] && [ "${DLOG_ATTEMPTS:-X}" = "0" ]; then
        report_pass "S-Leak-3 delivery_log status='skipped' attempts=0 (즉시 마크)"
    else
        report_fail "S-Leak-3 status='$DLOG_STATUS' attempts='$DLOG_ATTEMPTS' (기대: skipped/0)"
        sqlite3 "$TMP/messages.db" \
            "SELECT name,msg_id,status,attempts FROM delivery_log WHERE name='$POLL_SUB';" 2>/dev/null | head -5
    fi
fi

# 추가 sanity: DB 보존 — letter는 GET으로 회수 가능해야 (cursor advance 무관).
GET_RESP=$(curl -fs "$URL/api/v1/messages?to=$POLL_SUB&limit=5" || true)
COUNT=$(echo "$GET_RESP" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("count",0))' 2>/dev/null || echo 0)
if [ "${COUNT:-0}" -ge 1 ]; then
    echo "  · sanity: GET /api/v1/messages?to=$POLL_SUB count=$COUNT (DB 보존 OK)"
else
    report_fail "sanity: letter DB 회수 0 — skipped 분기가 letter 자체를 누락"
fi

# ─── verdict ─────────────────────────────────────────────────────────────────
echo
echo "════════════════════════════════════════════════"
echo "  Stoa#13 leak 회귀: pass=$PASS  fail=$FAIL"
echo "════════════════════════════════════════════════"
[ $FAIL -eq 0 ] || exit 1
