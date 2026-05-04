#!/usr/bin/env bash
# 원칙 2: 받기/주기.
# Stoa는 받은 편지를 각 수신자 address로 능동 push.
# Mock receiver를 띄워서 실제로 도착하는지 검증.

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

RECV_PORT="${RECV_PORT:-19999}"
RECV_LOG=$(mktemp -t stoa-recv-XXXXXX)
RECV_SCRIPT=$(mktemp -t stoa-recv-py-XXXXXX.py)
cat > "$RECV_SCRIPT" <<'EOF'
import http.server, json, os
LOG = os.environ["RECV_LOG"]
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n).decode("utf-8")
        try:
            obj = json.loads(body)
            with open(LOG, "a") as f:
                f.write(json.dumps({"path": self.path, "id": obj.get("id")}) + "\n")
        except Exception as e:
            with open(LOG, "a") as f:
                f.write(json.dumps({"path": self.path, "error": str(e)}) + "\n")
        self.send_response(200); self.end_headers(); self.wfile.write(b'{"received":true}')
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", int(os.environ["RECV_PORT"])), H).serve_forever()
EOF
RECV_PORT="$RECV_PORT" RECV_LOG="$RECV_LOG" python3 "$RECV_SCRIPT" &
RECV_PID=$!
trap 'kill $RECV_PID 2>/dev/null; rm -f "$RECV_SCRIPT" "$RECV_LOG"' EXIT

# 기동 대기
for _ in $(seq 1 20); do
    if curl -fs -X POST "http://127.0.0.1:$RECV_PORT/_ping" -d '{"id":"_p"}' >/dev/null 2>&1; then break; fi
    sleep 0.2
done
> "$RECV_LOG"

# issue#4 sender registry gate — 발신자 ergon 사전 등록 (idempotent).
curl -s -X POST "$URL/api/v1/agents" -H "Content-Type: application/json" \
    -d "{\"name\":\"ergon\",\"address\":\"http://127.0.0.1:$RECV_PORT/from\"}" > /dev/null

echo "[1] POST 두 수신자"
r=$(curl -s -X POST "$URL/api/v1/messages" -H "Content-Type: application/json" -d "{
  \"from\":{\"name\":\"ergon\",\"address\":\"http://127.0.0.1:$RECV_PORT/from\"},
  \"to\":[
    {\"name\":\"arche\",\"address\":\"http://127.0.0.1:$RECV_PORT/inbox/arche\"},
    {\"name\":\"telos\",\"address\":\"http://127.0.0.1:$RECV_PORT/inbox/telos\"}
  ],
  \"content\":\"능동 push\"
}")
id=$(echo "$r" | python3 -c "import json,sys; print(json.load(sys.stdin)['envelope']['id'])")
delivered=$(echo "$r" | python3 -c "import json,sys; print(json.load(sys.stdin)['push']['delivered'])")
[ "$delivered" = "2" ] || { echo "FAIL: delivered=$delivered"; exit 1; }
echo "  ✓ delivered=2"

sleep 0.3
echo "[2] receiver가 두 path 모두 받았다"
arche=$(grep -c '"path": "/inbox/arche"' "$RECV_LOG" || true)
telos=$(grep -c '"path": "/inbox/telos"' "$RECV_LOG" || true)
[ "$arche" = "1" ] && [ "$telos" = "1" ] || { echo "FAIL: arche=$arche telos=$telos"; cat "$RECV_LOG"; exit 1; }
echo "  ✓ /inbox/arche 1 hit, /inbox/telos 1 hit"

echo "[3] 같은 id가 두 path 모두로"
ids=$(python3 -c "
import json
seen = set()
for line in open('$RECV_LOG'): seen.add(json.loads(line).get('id'))
print(','.join(sorted(seen)))
")
[ "$ids" = "$id" ] || { echo "FAIL: ids=$ids"; exit 1; }
echo "  ✓ 같은 envelope이 두 곳으로"

echo "PASS test_principle_bidirectional"
