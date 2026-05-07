#!/usr/bin/env bash
# RFC-004 Phase A — recipient gate 회귀.
#
# Marcus 사이클 8 hardening: _advance_cursor가 mid의 recipient 매칭을 검증.
# 다른 이름 앞 letter id로 ack 시도하면 cursor advance 0 — cross-recipient
# rowid skip 차단 (cursor model 정합).
#
# topology: shared (run_all.sh phase=0 server). STOA_URL.
#
# 시나리오:
#   R1  cross-recipient ack 무시 — A의 letter id로 B가 ack → B cursor 변화 0.
#   R2  cross-recipient ack 후 정상 ack 가능 — B의 letter id로 B가 ack → 정상 advance.

set -uo pipefail

URL="${STOA_URL:-http://localhost:18888}"
PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

TS="$(date +%s)"
SENDER="rcpgate-sender-$TS"
A="rcpgate-a-$TS"
B="rcpgate-b-$TS"

register_agent() {
    curl -s -X POST "$URL/api/v1/agents" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$1\",\"address\":\"http://x/inbox\"}" > /dev/null
}
post_letter() {
    curl -s -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" \
        -d "{\"from\":{\"name\":\"$1\",\"address\":\"http://x\"},\"to\":[{\"name\":\"$2\",\"address\":\"http://y\"}],\"content\":\"$3\"}"
}
extract_id() {
    python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('envelope',{}).get('id') or d.get('id') or '')"
}
ack() {
    curl -s -X POST "$URL/api/v1/inbox/ack" \
        -H "Content-Type: application/json" \
        -d "{\"to\":\"$1\",\"up_to_msg_id\":\"$2\"}"
}

register_agent "$SENDER"
register_agent "$A"
register_agent "$B"

# A 앞 letter 1건. B 앞 letter 1건 (B가 정상 ack 사용).
ra=$(post_letter "$SENDER" "$A" "for-a-only")
mid_a=$(echo "$ra" | extract_id)
rb=$(post_letter "$SENDER" "$B" "for-b-only")
mid_b=$(echo "$rb" | extract_id)

# ─── R1: B가 A의 letter id로 ack → B cursor 변화 0 ────────────────────────
echo "── R1  cross-recipient ack 무시 (B가 mid_a로 ack)"
resp=$(ack "$B" "$mid_a")
cur=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('cursor',''))" 2>/dev/null || echo "?")
if [ "$cur" = "" ]; then
    report_pass "R1 cross-recipient ack 거절: cursor 비어있음 (advance 0)"
else
    report_fail "R1 cursor=$cur expected 빈 문자열"
fi

# ─── R2: B의 letter id로 정상 ack ──────────────────────────────────────────
echo "── R2  같은 B에 정상 ack 가능 (mid_b)"
resp=$(ack "$B" "$mid_b")
cur=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('cursor',''))" 2>/dev/null || echo "?")
if [ "$cur" = "$mid_b" ]; then
    report_pass "R2 정상 ack: cursor=$cur"
else
    report_fail "R2 cursor=$cur expected=$mid_b"
fi

# ─── verdict ─────────────────────────────────────────────────────────────
echo
echo "  inbox-recipient-gate: pass=$PASS  fail=$FAIL"
[ $FAIL -eq 0 ] || exit 1
