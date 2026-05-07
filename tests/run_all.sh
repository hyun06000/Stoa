#!/usr/bin/env bash
# run_all.sh — 전 테스트를 깨끗한 DB에서 순서대로 실행.

set -uo pipefail

PORT="${TEST_PORT:-18888}"
URL="http://localhost:$PORT"

cleanup() {
    [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT

TMP=$(mktemp -d -t stoa-test-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "▶︎ stoa server up at $URL  (tmpdir: $TMP)"
cd "$TMP"
cp "$REPO_DIR/server.ail" .
PYTHONUNBUFFERED=1 PORT="$PORT" STOA_DB_FILE="$TMP/messages.db" \
    ail run server.ail > "$TMP/server.log" 2>&1 &
SRV=$!

for _ in $(seq 1 30); do
    if curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then break; fi
    sleep 0.5
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"
    tail -20 "$TMP/server.log"
    exit 1
fi
echo "  health: $(curl -s $URL/api/v1/health)"

PASS=0
FAIL=0
for t in "$SCRIPT_DIR"/test_*.sh; do
    name=$(basename "$t")
    echo
    echo "── $name ────────────────────────────────────"
    if STOA_URL="$URL" bash "$t"; then
        PASS=$((PASS+1))
    else
        FAIL=$((FAIL+1))
        echo "  ✗ $name FAILED"
    fi
done

# RFC-004 Phase A — STOA_PHASE_A=1일 때만 실행. Marcus Phase A 코드 main land
# 전까지 default 0 → 회귀 0 + 임계 자리 보존. land 후엔 env 1로 활성.
if [ "${STOA_PHASE_A:-0}" = "1" ] && [ -d "$SCRIPT_DIR/phase_a" ]; then
    for t in "$SCRIPT_DIR"/phase_a/test_*.sh; do
        [ -f "$t" ] || continue
        name="phase_a/$(basename "$t")"
        echo
        echo "── $name ────────────────────────────────────"
        if STOA_URL="$URL" STOA_PHASE_A=1 bash "$t"; then
            PASS=$((PASS+1))
        else
            FAIL=$((FAIL+1))
            echo "  ✗ $name FAILED"
        fi
    done
fi

echo
echo "════════════════════════════════════════════════"
echo "  pass=$PASS  fail=$FAIL"
echo "════════════════════════════════════════════════"
[ $FAIL -eq 0 ] || exit 1
