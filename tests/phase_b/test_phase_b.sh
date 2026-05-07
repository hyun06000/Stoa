#!/usr/bin/env bash
# RFC-004 §7 Phase B Acceptance — AC-B1 ~ AC-B5.
#
# topology: self-contained (자기 server boot — fast-tick env override 필요).
# gate: STOA_PHASE_B=1 (run_all.sh가 활성화). Marcus Phase B 코드 main land 전까지
#        실패하므로 default skip.
#
# 검증 surface (RFC-004 §3 main loop):
#   - schedule.every(<TICK_SEC>) autonomous tick — observe → reason → act.
#   - deliver / skip / escalate / idle_ping / stale_warn 다섯 action.
#   - GET /api/v1/health → last_tick_at 매 tick 갱신.
#   - escalate / idle_ping / stale_warn 모두 `from: Stoa-Stoa to: Stoa-Admin` letter.
#
# AC 매핑:
#   B1  autonomous deliver — subscriber INSERT + letter INSERT → tick 안 mock listener push 도달.
#   B2  self-host skip — issue#3 doctrine 정합. self-host subscriber → push 시도 0, cursor advance 0.
#   B3  escalate — N회 deliver fail → Stoa-Admin priority:high letter (alert + final-fail 두 단계).
#   B4  idle_ping — IDLE_PING_INTERVAL 경과 + 새 letter 0 → Stoa-Admin ping letter.
#   B5  health.last_tick_at 매 tick 갱신.
#
# 의존: bash, curl, python3, ail-interpreter v1.71.1+. STOA_PHASE_B=1.

set -uo pipefail

# Phase B gate.
if [ "${STOA_PHASE_B:-0}" != "1" ]; then
    echo "── RFC-004 Phase B AC: SKIP (STOA_PHASE_B!=1, Marcus land 대기)"
    exit 0
fi

PORT="${PHASE_B_TEST_PORT:-18896}"
URL="http://localhost:$PORT"
SELF_ORIGIN="http://localhost:$PORT"
RECV_PORT="${PHASE_B_RECV_PORT:-29870}"
SINK_PORT="${PHASE_B_SINK_PORT:-9}"  # TCP/9 discard — 도달 불가 (dropped) 시뮬레이션.
RECV_LOG="$(mktemp -t stoa-pb-recv-XXXXXX)"

# Fast-tick env — 임계 자리 검증 시간 단축.
export STOA_TICK_SEC=1
export STOA_DELIVER_RETRY_MAX=3
export STOA_ESCALATE_AFTER_FAIL=2
export STOA_IDLE_PING_INTERVAL_S=4

PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    [ -n "${RECV:-}" ] && kill "$RECV" 2>/dev/null || true
    pids=$(lsof -ti tcp:$PORT 2>/dev/null || true)
    [ -n "$pids" ] && echo "$pids" | xargs kill -9 2>/dev/null || true
    pids=$(lsof -ti tcp:$RECV_PORT 2>/dev/null || true)
    [ -n "$pids" ] && echo "$pids" | xargs kill -9 2>/dev/null || true
    rm -f "$RECV_LOG"
    wait 2>/dev/null || true
}
trap cleanup EXIT

# ─── Mock receiver (test_discord.sh 패턴 재사용) ────────────────────────
RECV_SCRIPT="$(mktemp -t stoa-pb-recv-py-XXXXXX.py)"
cat > "$RECV_SCRIPT" <<'EOF'
import http.server, json, os, sys
LOG = os.environ["RECV_LOG"]
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n).decode("utf-8")
        try:
            obj = json.loads(body)
            with open(LOG, "a") as f:
                f.write(json.dumps({"path": self.path, "id": obj.get("id"), "to": obj.get("to")}) + "\n")
        except Exception as e:
            with open(LOG, "a") as f:
                f.write(json.dumps({"path": self.path, "error": str(e)}) + "\n")
        self.send_response(200); self.end_headers(); self.wfile.write(b"{}")
    def log_message(self, *a, **k): pass
port = int(os.environ.get("RECV_PORT", 29870))
http.server.HTTPServer(("127.0.0.1", port), H).serve_forever()
EOF
RECV_LOG="$RECV_LOG" RECV_PORT="$RECV_PORT" python3 "$RECV_SCRIPT" &
RECV=$!
for _ in $(seq 1 20); do
    nc -z 127.0.0.1 "$RECV_PORT" 2>/dev/null && break
    sleep 0.2
done

# ─── Boot Stoa server (self-contained, fast-tick) ─────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP="$(mktemp -d -t stoa-pb-XXXXXX)"
cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$TMP/messages.db" \
    STOA_SELF_ORIGIN="$SELF_ORIGIN" \
    ail run server.ail > "$TMP/server.log" 2>&1 &
SRV=$!
for _ in $(seq 1 30); do
    if curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then break; fi
    sleep 0.5
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"
    tail -30 "$TMP/server.log"
    exit 1
fi

# Helpers.
TS="$(date +%s)"
SENDER="rachel-pb-sender-$TS"
register() {
    curl -s -X POST "$URL/api/v1/agents" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$1\",\"address\":\"$2\"}" > /dev/null
}
post_letter() {
    curl -s -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" \
        -d "{\"from\":{\"name\":\"$1\",\"address\":\"http://x\"},\"to\":[{\"name\":\"$2\",\"address\":\"$3\"}],\"content\":\"$4\"}"
}
extract_id() {
    python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('envelope',{}).get('id') or d.get('id') or '')"
}
admin_inbox_count_subject() {
    # Stoa-Admin 인박스에서 from=Stoa-Stoa & subject prefix 매칭 letter 카운트.
    local prefix="$1"
    curl -s "$URL/api/v1/messages?to=Stoa-Admin" \
        | python3 -c "
import json,sys
d=json.load(sys.stdin); ms=d.get('messages',[])
n=0
for m in ms:
    if m.get('from',{}).get('name')!='Stoa-Stoa': continue
    c=m.get('content','')
    first=c.split(chr(10))[0] if c else ''
    if '$prefix' in first: n+=1
print(n)
"
}
get_health_tick() {
    curl -s "$URL/api/v1/health" \
        | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('last_tick_at') or '')" 2>/dev/null
}

# 발신자 + Stoa-Admin pre-register (issue#4 sender gate, escalate 수신지).
register "$SENDER" "http://x"
register "Stoa-Admin" "http://admin.x"

# ─── AC-B5: health.last_tick_at 매 tick 갱신 (먼저 측정) ───────────────────
echo "── AC-B5  health.last_tick_at 매 tick 갱신"
t1=$(get_health_tick)
sleep 3  # TICK_SEC=1 × 3
t2=$(get_health_tick)
if [ -n "$t1" ] && [ -n "$t2" ] && [ "$t1" != "$t2" ]; then
    report_pass "B5 last_tick_at advance: $t1 → $t2"
else
    report_fail "B5 t1=$t1 t2=$t2 (변화 없음 또는 미정의)"
fi

# ─── AC-B1: autonomous deliver ────────────────────────────────────────────
echo "── AC-B1  autonomous deliver — subscriber receiver-capable mock"
SUB1="rachel-pb-sub1-$TS"
register "$SUB1" "http://127.0.0.1:$RECV_PORT/inbox/$SUB1"
> "$RECV_LOG"
r=$(post_letter "$SENDER" "$SUB1" "http://127.0.0.1:$RECV_PORT/inbox/$SUB1" "b1-deliver")
mid_b1=$(echo "$r" | extract_id)
sleep 3  # TICK × 3
got=$(grep -c "\"$mid_b1\"" "$RECV_LOG" 2>/dev/null || echo 0)
if [ "${got:-0}" -ge 1 ]; then
    report_pass "B1 mock listener push 도달 (mid=$mid_b1)"
else
    report_fail "B1 mock listener 0 (RECV_LOG=$(cat $RECV_LOG))"
fi

# ─── AC-B2: self-host skip ────────────────────────────────────────────────
echo "── AC-B2  self-host skip (issue#3 doctrine 정합)"
SUB2="rachel-pb-sub2-$TS"
register "$SUB2" "$SELF_ORIGIN/inbox/$SUB2"
> "$RECV_LOG"
r=$(post_letter "$SENDER" "$SUB2" "$SELF_ORIGIN/inbox/$SUB2" "b2-selfhost")
mid_b2=$(echo "$r" | extract_id)
sleep 3
# self-host로 push 안 했어야 함 — RECV_LOG는 RECV_PORT 기준이라 직접 신호 없음.
# 우회 검증: GET /inbox?to=$SUB2 여전히 letter 보유 (cursor advance 0).
inbox=$(curl -s "$URL/api/v1/inbox?to=$SUB2")
count=$(echo "$inbox" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('messages',[])))" 2>/dev/null || echo "?")
if [ "$count" = "1" ]; then
    report_pass "B2 self-host cursor advance 0 (polling 의존, /inbox count=1)"
else
    report_fail "B2 /inbox count=$count expected 1 (push 우발 시 cursor advance 위험)"
fi

# ─── AC-B3: escalate ──────────────────────────────────────────────────────
echo "── AC-B3  escalate — N회 deliver fail → Stoa-Admin priority:high"
SUB3="rachel-pb-sub3-$TS"
register "$SUB3" "http://127.0.0.1:$SINK_PORT/inbox/$SUB3"  # 도달 불가 port 9.
r=$(post_letter "$SENDER" "$SUB3" "http://127.0.0.1:$SINK_PORT/inbox/$SUB3" "b3-fail")
mid_b3=$(echo "$r" | extract_id)
# RETRY_MAX=3 + ESCALATE_AFTER=2 + TICK=1 → 최대 ~7s에 두 단계 (alert + final).
sleep 8
n_alert=$(admin_inbox_count_subject "escalate")
if [ "$n_alert" -ge 1 ]; then
    report_pass "B3 Stoa-Admin escalate letter $n_alert 건 도착"
else
    report_fail "B3 escalate 0 (server.log 일부: $(tail -3 "$TMP/server.log" 2>/dev/null))"
fi

# ─── AC-B4: idle_ping ──────────────────────────────────────────────────────
echo "── AC-B4  idle_ping — IDLE_PING_INTERVAL 경과 + 새 letter 0"
# 현 시점 ping 카운트 baseline.
ping_before=$(admin_inbox_count_subject "ping")
# IDLE_PING_INTERVAL_S=4 → 5초 idle 유지.
sleep 5
ping_after=$(admin_inbox_count_subject "ping")
if [ "$ping_after" -gt "$ping_before" ]; then
    report_pass "B4 idle_ping advance: $ping_before → $ping_after"
else
    report_fail "B4 idle_ping 변화 없음 (before=$ping_before after=$ping_after)"
fi

# ─── verdict ─────────────────────────────────────────────────────────────
echo
echo "════════════════════════════════════════════════"
echo "  RFC-004 Phase B AC: pass=$PASS  fail=$FAIL"
echo "════════════════════════════════════════════════"
[ $FAIL -eq 0 ] || exit 1
