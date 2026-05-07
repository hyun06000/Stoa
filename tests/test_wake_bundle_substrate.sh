#!/usr/bin/env bash
# bridge-stoa-mneme/v0 §4 wake bundle 흡수 substrate — health 가시 회귀.
#
# Phase A 위 자리 정합 commit (Marcus 사이클 8 idle 활용 트랙). 본 회귀는 외부
# 노출 surface 한 자리만 검증:
#   - GET /api/v1/health 응답에 `last_wake_inflated_at` field 존재.
#   - 첫 부팅 (inflate 0) 시 빈 문자열 (Phase B/C inflate 호출 전 상태).
#
# topology: shared (run_all.sh phase=0 server). STOA_URL.
# 본 substrate의 internal helper(`_apply_wake_bundle`) 자체 검증은 Phase B/C
# wire-up 사이클에 endpoint 노출 + AC site land와 동시.

set -uo pipefail

URL="${STOA_URL:-http://localhost:18888}"
PASS=0
FAIL=0
report_pass() { PASS=$((PASS+1)); echo "  ✓ $*"; }
report_fail() { FAIL=$((FAIL+1)); echo "  ✗ FAIL: $*"; }

echo "── W1  /api/v1/health 응답에 last_wake_inflated_at field 존재"
resp=$(curl -s "$URL/api/v1/health")
has_field=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print('y' if 'last_wake_inflated_at' in d else 'n')" 2>/dev/null || echo "n")
if [ "$has_field" = "y" ]; then
    report_pass "W1 last_wake_inflated_at field 존재"
else
    report_fail "W1 field 부재 — 응답: $resp"
fi

echo "── W2  inflate 전 빈 문자열 default"
val=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('last_wake_inflated_at', '<none>'))" 2>/dev/null || echo "?")
if [ "$val" = "" ]; then
    report_pass "W2 last_wake_inflated_at = '' (inflate 0 default)"
else
    report_fail "W2 unexpected value: '$val'"
fi

echo "── W3  status·version 기존 field 보존"
ok_status=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
ver=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin).get('version',''))" 2>/dev/null)
if [ "$ok_status" = "ok" ] && [ -n "$ver" ]; then
    report_pass "W3 기존 status='ok' + version='$ver' 보존"
else
    report_fail "W3 status='$ok_status' version='$ver'"
fi

echo
echo "  wake-bundle-substrate: pass=$PASS  fail=$FAIL"
[ $FAIL -eq 0 ] || exit 1
