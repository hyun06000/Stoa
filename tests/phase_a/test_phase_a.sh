#!/usr/bin/env bash
# RFC-004 §7 Phase A Acceptance — AC-A1 ~ AC-A8.
#
# topology: shared (uses STOA_URL = run_all.sh phase=0 server).
# gate: STOA_PHASE_A=1 (run_all.sh가 활성화). Marcus Phase A 코드 main land 전까지
#        실패하므로 default skip — main land 후 활성으로 임계 자리 검증.
#
# 검증 surface (RFC-004 §4):
#   - POST /api/v1/inbox/ack  body {to, up_to_msg_id} → 200 {cursor}
#   - GET  /api/v1/inbox?to=<name>                    → {messages, continuation_token}
#   - 옛 GET /api/v1/messages?to=<>&since_id=...      back-compat 무변경
#   - registry self-row Stoa-Stoa + public_key non-empty
#
# AC 매핑:
#   A1  ack 핸들러 reachable
#   A2  GET /inbox 미전달 letter 1건 반환 + continuation_token
#   A3  ack 후 GET /inbox 빈 응답
#   A4  ack 안 한 채 두 번 GET → at-least-once (동일 letter 재반환)
#   A5  ack 멱등 (같은 up_to_msg_id 두 번 → cursor 동일, 200/200)
#   A6  ack 역행 방지 (작은 id로 ack → cursor 후퇴 0)
#   A7  back-compat (옛 GET /api/v1/messages 동작 변경 0)
#   A8  registry Stoa-Stoa self-row + public_key 비공
#
# 의존: bash, curl, python3, jq optional. STOA_URL 환경변수.

set -uo pipefail

URL="${STOA_URL:-http://localhost:18888}"
PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

# Phase A gate. Marcus 코드 land 전까지 default skip — 회귀 0 + 임계 자리 보존.
if [ "${STOA_PHASE_A:-0}" != "1" ]; then
    echo "── RFC-004 Phase A AC: SKIP (STOA_PHASE_A!=1, Marcus land 대기)"
    exit 0
fi

# Per-run unique recipient + sender (state 격리). 발신자는 issue#4 gate 위해 pre-register.
TS="$(date +%s)"
SENDER="rachel-pa-sender-$TS"
RECP1="rachel-pa-r1-$TS"
RECP2="rachel-pa-r2-$TS"
RECP3="rachel-pa-r3-$TS"
RECP4="rachel-pa-r4-$TS"
RECP_BC="rachel-pa-bc-$TS"

register_agent() {
    local name="$1"
    curl -s -X POST "$URL/api/v1/agents" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$name\",\"address\":\"http://x/inbox\"}" > /dev/null
}

post_letter() {
    local sender="$1" recp="$2" body="$3"
    curl -s -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" \
        -d "{\"from\":{\"name\":\"$sender\",\"address\":\"http://x\"},\"to\":[{\"name\":\"$recp\",\"address\":\"http://y\"}],\"content\":\"$body\"}"
}

extract_id() {
    python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('envelope',{}).get('id') or d.get('id') or '')"
}

# 발신자 pre-register (issue#4 sender gate).
register_agent "$SENDER"

# ─── AC-A1: ack 핸들러 reachable ─────────────────────────────────────────
echo "── AC-A1  POST /api/v1/inbox/ack reachable"
register_agent "$RECP1"
r=$(post_letter "$SENDER" "$RECP1" "a1-seed")
mid=$(echo "$r" | extract_id)
if [ -z "$mid" ]; then
    report_fail "A1 seed letter id 추출 실패: $r"
else
    code=$(curl -s -o /tmp/a1.body -w "%{http_code}" -X POST "$URL/api/v1/inbox/ack" \
        -H "Content-Type: application/json" \
        -d "{\"to\":\"$RECP1\",\"up_to_msg_id\":\"$mid\"}")
    cursor=$(python3 -c "import json,sys; print(json.load(open('/tmp/a1.body')).get('cursor',''))" 2>/dev/null || echo "")
    if [ "$code" = "200" ] && [ "$cursor" = "$mid" ]; then
        report_pass "A1 ack 200 + cursor=$cursor"
    else
        report_fail "A1 expected 200 + cursor=$mid, got code=$code body=$(cat /tmp/a1.body)"
    fi
fi

# ─── AC-A2: GET /inbox 미전달 1건 반환 + continuation_token ──────────────
echo "── AC-A2  GET /api/v1/inbox?to=<recp> 미전달 1건"
register_agent "$RECP2"
r=$(post_letter "$SENDER" "$RECP2" "a2-pending")
mid_a2=$(echo "$r" | extract_id)
inbox=$(curl -s "$URL/api/v1/inbox?to=$RECP2")
count=$(echo "$inbox" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('messages',[])))" 2>/dev/null || echo "0")
has_token=$(echo "$inbox" | python3 -c "import json,sys; d=json.load(sys.stdin); print('y' if 'continuation_token' in d else 'n')" 2>/dev/null || echo "n")
first_id=$(echo "$inbox" | python3 -c "import json,sys; d=json.load(sys.stdin); m=d.get('messages',[]); print(m[0]['id'] if m else '')" 2>/dev/null || echo "")
if [ "$count" = "1" ] && [ "$has_token" = "y" ] && [ "$first_id" = "$mid_a2" ]; then
    report_pass "A2 1건 반환 + continuation_token"
else
    report_fail "A2 count=$count has_token=$has_token first_id=$first_id (expected mid=$mid_a2)"
fi

# ─── AC-A3: ack 후 GET /inbox 빈 응답 ────────────────────────────────────
echo "── AC-A3  ack 후 GET /inbox 빈"
if [ -n "$mid_a2" ]; then
    curl -s -X POST "$URL/api/v1/inbox/ack" \
        -H "Content-Type: application/json" \
        -d "{\"to\":\"$RECP2\",\"up_to_msg_id\":\"$mid_a2\"}" > /dev/null
    inbox=$(curl -s "$URL/api/v1/inbox?to=$RECP2")
    count=$(echo "$inbox" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('messages',[])))" 2>/dev/null || echo "?")
    if [ "$count" = "0" ]; then
        report_pass "A3 ack 후 empty (count=0)"
    else
        report_fail "A3 ack 후에도 count=$count"
    fi
else
    report_fail "A3 skip — A2 mid 없음"
fi

# ─── AC-A4: ack 안 한 채 두 번 GET → at-least-once ───────────────────────
echo "── AC-A4  미-ack 두 번 GET → 동일 letter 재반환"
register_agent "$RECP3"
r=$(post_letter "$SENDER" "$RECP3" "a4-redeliver")
mid_a4=$(echo "$r" | extract_id)
g1=$(curl -s "$URL/api/v1/inbox?to=$RECP3" | python3 -c "import json,sys; d=json.load(sys.stdin); m=d.get('messages',[]); print(m[0]['id'] if m else '')" 2>/dev/null || echo "")
g2=$(curl -s "$URL/api/v1/inbox?to=$RECP3" | python3 -c "import json,sys; d=json.load(sys.stdin); m=d.get('messages',[]); print(m[0]['id'] if m else '')" 2>/dev/null || echo "")
if [ "$g1" = "$mid_a4" ] && [ "$g2" = "$mid_a4" ]; then
    report_pass "A4 두 번 모두 동일 mid 반환"
else
    report_fail "A4 g1=$g1 g2=$g2 expected=$mid_a4"
fi

# ─── AC-A5: ack 멱등 ─────────────────────────────────────────────────────
echo "── AC-A5  ack 멱등 (같은 up_to_msg_id 두 번)"
if [ -n "$mid_a4" ]; then
    c1=$(curl -s -o /tmp/a5_1.body -w "%{http_code}" -X POST "$URL/api/v1/inbox/ack" \
        -H "Content-Type: application/json" \
        -d "{\"to\":\"$RECP3\",\"up_to_msg_id\":\"$mid_a4\"}")
    cur1=$(python3 -c "import json,sys; print(json.load(open('/tmp/a5_1.body')).get('cursor',''))" 2>/dev/null || echo "")
    c2=$(curl -s -o /tmp/a5_2.body -w "%{http_code}" -X POST "$URL/api/v1/inbox/ack" \
        -H "Content-Type: application/json" \
        -d "{\"to\":\"$RECP3\",\"up_to_msg_id\":\"$mid_a4\"}")
    cur2=$(python3 -c "import json,sys; print(json.load(open('/tmp/a5_2.body')).get('cursor',''))" 2>/dev/null || echo "")
    if [ "$c1" = "200" ] && [ "$c2" = "200" ] && [ "$cur1" = "$cur2" ] && [ "$cur1" = "$mid_a4" ]; then
        report_pass "A5 200/200 + cursor 동일=$cur1"
    else
        report_fail "A5 c1=$c1 c2=$c2 cur1=$cur1 cur2=$cur2"
    fi
else
    report_fail "A5 skip — A4 mid 없음"
fi

# ─── AC-A6: ack 역행 방지 ─────────────────────────────────────────────────
echo "── AC-A6  ack 역행 방지 (작은 id로 ack → cursor 후퇴 0)"
register_agent "$RECP4"
r=$(post_letter "$SENDER" "$RECP4" "a6-first")
mid_a6_old=$(echo "$r" | extract_id)
sleep 0.1  # 두 letter id 사이에 분리 보장
r=$(post_letter "$SENDER" "$RECP4" "a6-second")
mid_a6_new=$(echo "$r" | extract_id)
# 큰 id로 먼저 ack → cursor = new
curl -s -X POST "$URL/api/v1/inbox/ack" \
    -H "Content-Type: application/json" \
    -d "{\"to\":\"$RECP4\",\"up_to_msg_id\":\"$mid_a6_new\"}" > /tmp/a6_advance.body
cur_new=$(python3 -c "import json,sys; print(json.load(open('/tmp/a6_advance.body')).get('cursor',''))" 2>/dev/null || echo "")
# 작은 id로 ack 시도 → cursor 변경 0이어야 함
curl -s -X POST "$URL/api/v1/inbox/ack" \
    -H "Content-Type: application/json" \
    -d "{\"to\":\"$RECP4\",\"up_to_msg_id\":\"$mid_a6_old\"}" > /tmp/a6_rewind.body
cur_after=$(python3 -c "import json,sys; print(json.load(open('/tmp/a6_rewind.body')).get('cursor',''))" 2>/dev/null || echo "")
if [ "$cur_new" = "$mid_a6_new" ] && [ "$cur_after" = "$mid_a6_new" ]; then
    report_pass "A6 cursor stays at $cur_after (작은 id ack 무시)"
else
    report_fail "A6 cur_new=$cur_new cur_after=$cur_after expected=$mid_a6_new"
fi

# ─── AC-A7: back-compat — 옛 GET /api/v1/messages 변경 0 ─────────────────
echo "── AC-A7  back-compat 옛 GET /api/v1/messages?to=<>&since_id="
register_agent "$RECP_BC"
r=$(post_letter "$SENDER" "$RECP_BC" "bc-1")
mid_bc1=$(echo "$r" | extract_id)
r=$(post_letter "$SENDER" "$RECP_BC" "bc-2")
mid_bc2=$(echo "$r" | extract_id)
# since_id 없는 옛 호출 — 두 letter 다 반환
old1=$(curl -s "$URL/api/v1/messages?to=$RECP_BC")
old1_count=$(echo "$old1" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('messages',[])))" 2>/dev/null || echo "?")
# since_id=mid_bc1 — bc-2만 반환
old2=$(curl -s "$URL/api/v1/messages?to=$RECP_BC&since_id=$mid_bc1")
old2_count=$(echo "$old2" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('messages',[])))" 2>/dev/null || echo "?")
old2_first=$(echo "$old2" | python3 -c "import json,sys; m=json.load(sys.stdin).get('messages',[]); print(m[0]['id'] if m else '')" 2>/dev/null || echo "")
if [ "$old1_count" = "2" ] && [ "$old2_count" = "1" ] && [ "$old2_first" = "$mid_bc2" ]; then
    report_pass "A7 back-compat (no-since=2건, since=$mid_bc1 → 1건=$mid_bc2)"
else
    report_fail "A7 old1=$old1_count old2=$old2_count old2_first=$old2_first"
fi

# ─── AC-A8: registry Stoa-Stoa self-row + public_key 비공 ────────────────
echo "── AC-A8  registry Stoa-Stoa self-row + public_key non-empty"
self_row=$(curl -s -o /tmp/a8.body -w "%{http_code}" "$URL/api/v1/agents/Stoa-Stoa")
if [ "$self_row" = "200" ]; then
    pub=$(python3 -c "import json,sys; d=json.load(open('/tmp/a8.body')); print(d.get('public_key','') or '')" 2>/dev/null || echo "")
    if [ -n "$pub" ] && [ "$pub" != "null" ]; then
        report_pass "A8 Stoa-Stoa self-row 존재 + public_key 길이=${#pub}"
    else
        report_fail "A8 self-row 존재하나 public_key 비어있음/null"
    fi
else
    report_fail "A8 GET /api/v1/agents/Stoa-Stoa code=$self_row body=$(cat /tmp/a8.body)"
fi

# ─── verdict ─────────────────────────────────────────────────────────────
echo
echo "════════════════════════════════════════════════"
echo "  RFC-004 Phase A AC: pass=$PASS  fail=$FAIL"
echo "════════════════════════════════════════════════"
[ $FAIL -eq 0 ] || exit 1
