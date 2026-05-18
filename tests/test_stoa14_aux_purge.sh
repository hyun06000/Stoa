#!/usr/bin/env bash
# Stoa#14 F-1 hotfix — `_purge_aux_tables()` 검증.
#
# 가설 E (Marcus 진단 msg_1779070638_168): delivery_log·seen_nonces·inbox_cursors
# 세 보조 테이블이 letter retention purge 0이라 letter count로 unbounded growth →
# `_delivery_pending` NOT IN 서브쿼리 scan cost amplifier + RSS 우상향. Stoa#14
# OOM 재발 root cause.
#
# Fix: `_purge_old_letters` 호출 path 직후 `_purge_aux_tables(modifier)` 합산 fire.
# (1) delivery_log dangling (msg_id NOT IN letters) 일괄 DELETE.
# (2) seen_nonces 옛 cutoff DELETE (letters retention modifier 재사용).
# (3) inbox_cursors per-name latest compaction (MAX(rowid) GROUP BY name).
#
# AC:
#   S14-1  delivery_log dangling 100건 seed → purge 후 0건.
#   S14-2  seen_nonces 옛 cutoff row 5건 + 신선 5건 → purge 후 신선 5건만 잔존.
#   S14-3  inbox_cursors per-name 3 row × 3 name = 9 row seed → compaction 후
#          name당 1 row (MAX(rowid)) — 총 3 row.

set -uo pipefail

PORT="${STOA14_TEST_PORT:-18895}"
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

TMP=$(mktemp -d -t stoa-stoa14-XXXXXX)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cp "$REPO_DIR/server.ail" "$TMP/"
cd "$TMP"

DB="$TMP/messages.db"

# retention 3600s (live letter 잔존 보장) + 즉시 purge(throttle=1).
# seed시 옛 row는 2026-01-01 (멀리 과거)로 dated → cutoff 안에 들어와도 purge 대상.
unset STOA_SELF_ORIGIN
PYTHONUNBUFFERED=1 PORT="$PORT" \
    STOA_DB_FILE="$DB" \
    STOA_LETTERS_RETENTION_SECONDS=3600 \
    STOA_PURGE_THROTTLE_POLLS=1 \
    STOA_PURGE_THROTTLE_INSERTS=0 \
    ail run server.ail > server.log 2>&1 &
SRV=$!
for _ in $(seq 1 40); do
    curl -fs "$URL/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done
if ! curl -fs "$URL/api/v1/health" >/dev/null 2>&1; then
    echo "FAIL: server didn't come up"; tail -40 server.log; exit 1
fi

# 발신자 사전 등록 (sender gate 통과).
curl -fs -X POST "$URL/api/v1/enter" \
    -H 'Content-Type: application/json' \
    -d '{"name":"alice"}' >/dev/null

# letters에 살아 있는 row 1건 INSERT (alice → bob). reference 자리.
curl -fs -X POST "$URL/api/v1/enter" \
    -H 'Content-Type: application/json' \
    -d '{"name":"bob"}' >/dev/null
LIVE=$(curl -fs -X POST "$URL/api/v1/messages" \
    -H 'Content-Type: application/json' \
    -d "{\"from\":{\"name\":\"alice\",\"address\":\"$URL/inbox/alice\"},\"to\":[{\"name\":\"bob\",\"address\":\"$URL/inbox/bob\"}],\"content\":\"live letter — purge 대상 아님\"}")
LIVE_ID=$(echo "$LIVE" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("envelope",{}).get("id",""))')

# S14-1 seed: delivery_log dangling 100건 — msg_id 가짜.
for i in $(seq 1 100); do
    sqlite3 "$DB" "INSERT INTO delivery_log (name, msg_id, status, attempts, last_at) VALUES ('bob', 'fake_msg_$i', 'delivered', 1, '2026-01-01T00:00:00Z')" 2>/dev/null
done
# 살아 있는 letter에도 delivery_log 1건 (purge 후 잔존해야 함).
sqlite3 "$DB" "INSERT INTO delivery_log (name, msg_id, status, attempts, last_at) VALUES ('bob', '$LIVE_ID', 'delivered', 1, '$(date -u +%Y-%m-%dT%H:%M:%SZ)')"

# S14-2 seed: seen_nonces 옛 5 + 신선 5.
for i in $(seq 1 5); do
    sqlite3 "$DB" "INSERT INTO seen_nonces (from_name, nonce, seen_at) VALUES ('alice', 'old_nonce_$i', '2026-01-01T00:00:00Z')"
done
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
for i in $(seq 1 5); do
    sqlite3 "$DB" "INSERT INTO seen_nonces (from_name, nonce, seen_at) VALUES ('alice', 'fresh_nonce_$i', '$NOW_ISO')"
done

# S14-3 seed: inbox_cursors per-name 3 row × 3 name = 9 row.
for n in agentA agentB agentC; do
    sqlite3 "$DB" "INSERT INTO inbox_cursors (name, cursor_msg_id, advanced_at) VALUES ('$n', 'cur1', '2026-01-01T00:00:00Z')"
    sqlite3 "$DB" "INSERT INTO inbox_cursors (name, cursor_msg_id, advanced_at) VALUES ('$n', 'cur2', '2026-01-02T00:00:00Z')"
    sqlite3 "$DB" "INSERT INTO inbox_cursors (name, cursor_msg_id, advanced_at) VALUES ('$n', 'cur3', '2026-01-03T00:00:00Z')"
done

# pre-purge 자취.
PRE_DLOG=$(sqlite3 "$DB" "SELECT COUNT(*) FROM delivery_log")
PRE_NONCE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM seen_nonces")
PRE_CUR=$(sqlite3 "$DB" "SELECT COUNT(*) FROM inbox_cursors")
echo "  pre-purge: delivery_log=$PRE_DLOG seen_nonces=$PRE_NONCE inbox_cursors=$PRE_CUR"

# 신선 nonce는 future date로 굳혀 cutoff 영향 0.
sqlite3 "$DB" "UPDATE seen_nonces SET seen_at='2030-01-01T00:00:00Z' WHERE nonce LIKE 'fresh_nonce_%'"

# retention 3600s — live letter 잔존. polling 트리거 자체가 purge fire 트리거.

# polling 트리거 — db_inbox_for 입구에서 `_maybe_purge_on_poll` fire.
curl -fs "$URL/api/v1/messages?to=bob&limit=1" >/dev/null

# 한 박자 SQL 마무리.
sleep 1

# S14-1 검증
POST_DLOG=$(sqlite3 "$DB" "SELECT COUNT(*) FROM delivery_log")
DLOG_LIVE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM delivery_log WHERE msg_id = '$LIVE_ID'")
if [ "$POST_DLOG" = "1" ] && [ "$DLOG_LIVE" = "1" ]; then
    report_pass "S14-1 delivery_log dangling 100건 purge — live row 1건만 잔존"
else
    report_fail "S14-1 delivery_log purge mismatch: total=$POST_DLOG live=$DLOG_LIVE"
fi

# S14-2 검증
POST_NONCE=$(sqlite3 "$DB" "SELECT COUNT(*) FROM seen_nonces")
POST_FRESH=$(sqlite3 "$DB" "SELECT COUNT(*) FROM seen_nonces WHERE nonce LIKE 'fresh_nonce_%'")
POST_OLD=$(sqlite3 "$DB" "SELECT COUNT(*) FROM seen_nonces WHERE nonce LIKE 'old_nonce_%'")
if [ "$POST_FRESH" = "5" ] && [ "$POST_OLD" = "0" ]; then
    report_pass "S14-2 seen_nonces 옛 5건 purge, 신선 5건 잔존 (total=$POST_NONCE)"
else
    report_fail "S14-2 seen_nonces mismatch: total=$POST_NONCE fresh=$POST_FRESH old=$POST_OLD"
fi

# S14-3 검증
POST_CUR=$(sqlite3 "$DB" "SELECT COUNT(*) FROM inbox_cursors")
PER_NAME=$(sqlite3 "$DB" "SELECT COUNT(DISTINCT name) FROM inbox_cursors")
LATEST_A=$(sqlite3 "$DB" "SELECT cursor_msg_id FROM inbox_cursors WHERE name='agentA'")
if [ "$POST_CUR" = "3" ] && [ "$PER_NAME" = "3" ] && [ "$LATEST_A" = "cur3" ]; then
    report_pass "S14-3 inbox_cursors compaction — 9→3 row, per-name latest 보존 (agentA=cur3)"
else
    report_fail "S14-3 inbox_cursors mismatch: total=$POST_CUR distinct_names=$PER_NAME agentA=$LATEST_A"
fi

echo ""
echo "── summary ──"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" = "0" ]
