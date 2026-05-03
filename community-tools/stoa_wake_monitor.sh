#!/bin/bash
# Stoa wake monitor — 자기 인박스 폴링 후 새 letter 도착 시 한 줄 알림.
#
# 사용:
#   STOA_NAME=Admin STOA_BASE_URL=https://ail-stoa.up.railway.app \
#   STOA_WAKE_INTERVAL_S=3 \
#   bash community-tools/stoa_wake_monitor.sh
#
# 또는 Claude Code Monitor 도구로:
#   Monitor(
#     command="STOA_NAME=Admin bash community-tools/stoa_wake_monitor.sh",
#     description="Stoa 새 편지 감지 (3초 폴링)",
#     persistent=true
#   )
#
# 환경 변수:
#   STOA_NAME            (필수) 자기 멤버 이름 — Admin / Brandon / Walter / Marcus 등.
#                        미설정 시 `git config ail.identity` (없으면 fallback `ergon`)에서 읽음.
#   STOA_BASE_URL        (선택) default: https://ail-stoa.up.railway.app
#   STOA_WAKE_INTERVAL_S (선택) default: 3 (초)
#   STOA_SINCE_FILE      (선택) default: .stoa-since-<name>. since_id 영속화 path.
#
# 출력:
#   stdout 한 줄 = 알람 1건. 형식:
#     "📬 Stoa: [<msg_id>] <from> → <to_list>: <content_preview>"
#   Monitor 도구가 한 줄당 한 알람으로 인식.
#
# 종료: Ctrl-C 또는 harness 종료. since_id는 SINCE_FILE에 보존돼 재시작 시 이어감.

set -uo pipefail

NAME="${STOA_NAME:-$(git config ail.identity 2>/dev/null || echo ergon)}"
BASE="${STOA_BASE_URL:-https://ail-stoa.up.railway.app}"
INTERVAL="${STOA_WAKE_INTERVAL_S:-3}"
SINCE_FILE="${STOA_SINCE_FILE:-.stoa-since-$NAME}"

# Restore since_id if exists, else 0
since="0"
[ -f "$SINCE_FILE" ] && since="$(cat "$SINCE_FILE")"

# Initial sync — establish current since_id without firing alerts for backlog.
initial="$(curl -fsS "$BASE/api/v1/messages?to=$NAME" 2>/dev/null | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    msgs = d.get("messages", [])
    if msgs:
        # messages array order in Stoa: newest first or oldest first depends on impl.
        # We pick max id by string sort (msg_<unix>_<seq> lex compatible).
        ids = [m.get("id", "") for m in msgs if m.get("id")]
        print(max(ids) if ids else "0")
    else:
        print("0")
except Exception:
    print("0")
' 2>/dev/null || echo "0")"

# If SINCE_FILE existed and is older, advance to current — we do NOT replay backlog on monitor restart.
# (Backlog should be processed manually via `?to=$NAME` GET.)
if [ "$since" = "0" ]; then
    since="$initial"
    echo "$since" > "$SINCE_FILE"
fi

while true; do
    sleep "$INTERVAL"
    # Bug-B guard: server.ail의 ?since_id=0 가 0건 반환하므로 since=0/빈값이면 since_id 파라미터 생략.
    if [ -z "$since" ] || [ "$since" = "0" ]; then
        url="$BASE/api/v1/messages?to=$NAME"
    else
        url="$BASE/api/v1/messages?to=$NAME&since_id=$since"
    fi
    resp="$(curl -fsS "$url" 2>/dev/null || echo '{"messages":[]}')"
    # stdout flows through to Monitor (each printed line = 1 alarm).
    # stderr captures meta (__SINCE__<id>) for since_id 영속화.
    echo "$resp" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    msgs = d.get("messages", [])
    for m in msgs:
        mid = m.get("id", "")
        frm = m.get("from", {}).get("name", "?")
        tos = m.get("to", [])
        to_list = ",".join(t.get("name", "?") for t in tos)
        content = (m.get("content") or "").replace("\n", " ").replace("\r", " ")
        if len(content) > 80:
            content = content[:80] + "..."
        print(f"📬 Stoa: [{mid}] {frm} → {to_list}: {content}", flush=True)
    if msgs:
        ids = [m.get("id", "") for m in msgs if m.get("id")]
        if ids:
            print(f"__SINCE__{max(ids)}", file=sys.stderr)
except Exception as e:
    print(f"__ERR__{e}", file=sys.stderr)
' 2> /tmp/stoa-wake-meta-$$.txt
    # Pick up new since from stderr meta
    while IFS= read -r line; do
        case "$line" in
            __SINCE__*) since="${line#__SINCE__}"; echo "$since" > "$SINCE_FILE" ;;
        esac
    done < /tmp/stoa-wake-meta-$$.txt
    rm -f /tmp/stoa-wake-meta-$$.txt
done
