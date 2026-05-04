#!/usr/bin/env bash
# Issue #2 hotfix — POST /api/v1/messages 200 INSERT 직후 push timeout/unreachable
# 일으키면 핸들러가 500. `_push_one`의 `perform http.post_json`이 effect 예외로
# raise → caller `is_error()` 못 catch → 500 'read operation timed out'.
#
# 수정 (server.ail _push_one): attempt+try로 effect 예외 흡수 → Result-error
# fallback. push_to_recipients의 is_error 분기가 정상 동작 → 201 + delivered/failed.
#
# 시나리오 (run_all.sh의 phase=0 server에 STOA_URL로 attach):
#   I2-1. 도달 불가 listener 수신자 → 201 + push.failed >= 1 (was 500).
#   I2-2. mixed (도달 가능 + 불가) → 201 + delivered + failed 둘 다.
#   I2-3. 회귀: simplified body 400 유지 (issue#1).

set -uo pipefail

URL="${STOA_URL:-http://localhost:18888}"
PASS=0
FAIL=0

# 도달 가능한 echo listener — netcat 한 번 응답 후 자동 종료.
ECHO_PORT=29881
NC_PIDS=""
start_echo_listener() {
    # 단순 200 OK 응답 후 종료. 여러 번 받으려면 for-loop wrap.
    (for _ in $(seq 1 20); do
        printf 'HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nok' | nc -l 127.0.0.1 $ECHO_PORT 2>/dev/null
    done) &
    NC_PIDS="$NC_PIDS $!"
    sleep 0.3
}

cleanup() {
    [ -n "$NC_PIDS" ] && kill $NC_PIDS 2>/dev/null || true
    pids=$(lsof -ti tcp:$ECHO_PORT 2>/dev/null || true)
    [ -n "$pids" ] && echo "$pids" | xargs kill -9 2>/dev/null || true
}
trap cleanup EXIT

assert_201_failed_at_least() {
    local label="$1"; shift
    local payload="$1"; shift
    local expected_failed="$1"; shift
    local code body
    body=$(curl -s -o /tmp/i2_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$payload")
    code="$body"
    if [ "$code" = "201" ]; then
        failed=$(python3 -c "import json; print(json.load(open('/tmp/i2_resp'))['push']['failed'])")
        if [ "$failed" -ge "$expected_failed" ]; then
            PASS=$((PASS+1))
            echo "  ✓ $label → 201, failed=$failed (>= $expected_failed)"
        else
            FAIL=$((FAIL+1))
            echo "  ✗ $label → 201 but failed=$failed (expected >= $expected_failed)"
            cat /tmp/i2_resp; echo
        fi
    else
        FAIL=$((FAIL+1))
        echo "  ✗ $label → HTTP $code (expected 201)"
        cat /tmp/i2_resp; echo
    fi
}

assert_201_delivered_and_failed() {
    local label="$1"; shift
    local payload="$1"; shift
    local code
    code=$(curl -s -o /tmp/i2_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$payload")
    if [ "$code" = "201" ]; then
        delivered=$(python3 -c "import json; print(json.load(open('/tmp/i2_resp'))['push']['delivered'])")
        failed=$(python3 -c "import json; print(json.load(open('/tmp/i2_resp'))['push']['failed'])")
        if [ "$delivered" -ge 1 ] && [ "$failed" -ge 1 ]; then
            PASS=$((PASS+1))
            echo "  ✓ $label → 201, delivered=$delivered, failed=$failed"
        else
            FAIL=$((FAIL+1))
            echo "  ✗ $label → 201 but delivered=$delivered, failed=$failed (both must be >= 1)"
            cat /tmp/i2_resp; echo
        fi
    else
        FAIL=$((FAIL+1))
        echo "  ✗ $label → HTTP $code"
        cat /tmp/i2_resp; echo
    fi
}

assert_400() {
    local label="$1"; shift
    local payload="$1"; shift
    local code
    code=$(curl -s -o /tmp/i2_resp -w "%{http_code}" -X POST "$URL/api/v1/messages" \
        -H "Content-Type: application/json" -d "$payload")
    if [ "$code" = "400" ]; then
        PASS=$((PASS+1))
        echo "  ✓ $label → 400"
    else
        FAIL=$((FAIL+1))
        echo "  ✗ $label → HTTP $code (expected 400)"
        cat /tmp/i2_resp; echo
    fi
}

echo "── Issue #2: push_to_recipients timeout/unreachable → 201 (not 500) ──"

# 발신자 alice-i2 등록 (listener 안 띄움 — push 하지 않음).
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"alice-i2","address":"http://127.0.0.1:29991/inbox"}' > /dev/null

# 도달 불가 listener bob-i2 (port 1 = 즉시 refused, same effect path).
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d '{"name":"bob-i2","address":"http://127.0.0.1:1/inbox"}' > /dev/null

assert_201_failed_at_least \
    "I2-1 unreachable bob-i2" \
    '{"from":{"name":"alice-i2","address":"http://127.0.0.1:29991/inbox"},"to":[{"name":"bob-i2","address":"http://127.0.0.1:1/inbox"}],"content":"hi unreachable"}' \
    1

# Mixed 시나리오 — 작동하는 echo listener carol-i2 등록 후 두 수신자에게 fan-out.
start_echo_listener
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d "{\"name\":\"carol-i2\",\"address\":\"http://127.0.0.1:$ECHO_PORT/\"}" > /dev/null

assert_201_delivered_and_failed \
    "I2-2 mixed delivered+failed" \
    "{\"from\":{\"name\":\"alice-i2\",\"address\":\"http://127.0.0.1:29991/inbox\"},\"to\":[{\"name\":\"carol-i2\",\"address\":\"http://127.0.0.1:$ECHO_PORT/\"},{\"name\":\"bob-i2\",\"address\":\"http://127.0.0.1:1/inbox\"}],\"content\":\"hi mixed\"}"

# Issue#1 회귀 sanity.
assert_400 \
    "I2-3 issue#1 회귀: simplified body still 400" \
    '{"from":"test","content":"hello"}'

echo "  PASS=$PASS  FAIL=$FAIL"
[ $FAIL -eq 0 ] && echo "PASS test_issue2_push_timeout" || exit 1
