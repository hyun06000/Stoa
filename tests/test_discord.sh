#!/usr/bin/env bash
# Discord mirror 테스트.
# DISCORD_WEBHOOK_URL이 설정되면 에이전트(arche/ergon/telos/tekton/homeros)가
# 보낸 편지를 그 URL로 미러링한다. 사람이 보낸 편지는 미러 안 함 (loop 방지).
#
# 이 테스트는 자기만의 stoa 서버를 띄움 — run_all.sh의 메인 서버 env에는
# DISCORD_WEBHOOK_URL이 없으니 따로.

set -uo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMP=$(mktemp -d -t stoa-discord-XXXXXX)
DPORT=29900
SPORT=29800

cleanup() {
    [ -n "${SP:-}" ] && kill "$SP" 2>/dev/null
    [ -n "${DP:-}" ] && kill "$DP" 2>/dev/null
    rm -rf "$TMP"
}
trap cleanup EXIT

# Discord mock
cat > "$TMP/mock.py" <<EOF
import http.server, os
LOG = os.environ["DLOG"]
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n).decode("utf-8")
        with open(LOG, "a") as f:
            f.write(body + "\n")
        self.send_response(200); self.end_headers()
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", $DPORT), H).serve_forever()
EOF
DLOG="$TMP/discord.log"
DLOG="$DLOG" python3 "$TMP/mock.py" &
DP=$!
sleep 0.3

# Stoa
cd "$TMP"
cp "$REPO_DIR/server.ail" .
PYTHONUNBUFFERED=1 PORT=$SPORT \
    STOA_DB_FILE="$TMP/messages.db" \
    DISCORD_WEBHOOK_URL="http://127.0.0.1:$DPORT/webhook" \
    ail run server.ail > "$TMP/stoa.log" 2>&1 &
SP=$!

for _ in $(seq 1 30); do
    curl -fs "http://127.0.0.1:$SPORT/api/v1/health" >/dev/null 2>&1 && break
    sleep 0.3
done

URL="http://127.0.0.1:$SPORT"

echo "[1] 에이전트(ergon) → Discord 미러링"
> "$DLOG"
# 수신자 주소를 mock으로 보내서 push timeout 회피
curl -fs -X POST "$URL/api/v1/messages" -H "Content-Type: application/json" -d "{
  \"from\":{\"name\":\"ergon\",\"address\":\"http://127.0.0.1:$DPORT/from\"},
  \"to\":[{\"name\":\"hyun06000\",\"address\":\"http://127.0.0.1:$DPORT/to\"}],
  \"content\":\"hi from ergon\"
}" > /dev/null
sleep 0.4
# discord.log에는 webhook hit 1개 + recipient push 1개 = 2 lines
hits=$(grep -c '"content":' "$DLOG" || true)
[ "$hits" -ge 1 ] || { echo "FAIL: no discord webhook hit"; cat "$DLOG"; exit 1; }
discord_line=$(grep -E '📨' "$DLOG" || true)
[ -n "$discord_line" ] || { echo "FAIL: no formatted discord line"; cat "$DLOG"; exit 1; }
echo "  ✓ discord received: $discord_line"

echo "[2] 사람(hyun06000) → Discord skip (loop 방지)"
> "$DLOG"
curl -fs -X POST "$URL/api/v1/messages" -H "Content-Type: application/json" -d "{
  \"from\":{\"name\":\"hyun06000\",\"address\":\"http://127.0.0.1:$DPORT/from\"},
  \"to\":[{\"name\":\"ergon\",\"address\":\"http://127.0.0.1:$DPORT/to\"}],
  \"content\":\"hi from human\"
}" > /dev/null
sleep 0.4
discord_lines=$(grep -cE '📨' "$DLOG" || true)
[ "$discord_lines" = "0" ] || { echo "FAIL: human message leaked to discord"; cat "$DLOG"; exit 1; }
echo "  ✓ human → discord 0건 (push만 도착)"

echo "[3] 알 수 없는 발신자 → skip"
> "$DLOG"
curl -fs -X POST "$URL/api/v1/messages" -H "Content-Type: application/json" -d "{
  \"from\":{\"name\":\"randobot\",\"address\":\"http://127.0.0.1:$DPORT/from\"},
  \"to\":[{\"name\":\"ergon\",\"address\":\"http://127.0.0.1:$DPORT/to\"}],
  \"content\":\"hi from rando\"
}" > /dev/null
sleep 0.4
discord_lines=$(grep -cE '📨' "$DLOG" || true)
[ "$discord_lines" = "0" ] || { echo "FAIL: unknown sender leaked"; exit 1; }
echo "  ✓ randobot → discord 0건"

echo "PASS test_discord"
