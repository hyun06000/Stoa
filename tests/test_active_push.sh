#!/usr/bin/env bash
# test_active_push.sh — Stoa가 수신자 address로 능동적으로 envelope을 POST.
#
# 동적으로 mock HTTP receiver를 띄워서 (Python http.server) Stoa POST를 받음.
# Stoa가 POST한 envelope의 id를 receiver가 기록하고, 우리는 그 파일을 읽어
# 검증.

set -uo pipefail
URL="${STOA_URL:-http://localhost:18888}"

RECV_PORT="${RECV_PORT:-19999}"
RECV_LOG=$(mktemp -t stoa-recv-XXXXXX)

# Mock receiver: 모든 POST를 RECV_LOG에 한 줄로 기록.
RECV_SCRIPT=$(mktemp -t stoa-recv-py-XXXXXX.py)
cat > "$RECV_SCRIPT" <<EOF
import http.server, json, sys, os
LOG = os.environ["RECV_LOG"]
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(n).decode("utf-8")
        try:
            obj = json.loads(body)
            with open(LOG, "a") as f:
                f.write(json.dumps({"path": self.path, "id": obj.get("id"),
                                    "to_first": obj.get("to",[{}])[0].get("name")}) + "\n")
        except Exception as e:
            with open(LOG, "a") as f:
                f.write(json.dumps({"path": self.path, "error": str(e)}) + "\n")
        self.send_response(200); self.send_header("Content-Type","application/json")
        self.end_headers(); self.wfile.write(b'{"received":true}')
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", int(os.environ["RECV_PORT"])), H).serve_forever()
EOF

RECV_PORT="$RECV_PORT" RECV_LOG="$RECV_LOG" python3 "$RECV_SCRIPT" &
RECV_PID=$!
trap 'kill $RECV_PID 2>/dev/null; rm -f "$RECV_SCRIPT" "$RECV_LOG"' EXIT

# receiver 기동 대기
for _ in $(seq 1 20); do
    if curl -fs -X POST "http://127.0.0.1:$RECV_PORT/_ping" -H "Content-Type: application/json" -d '{"id":"_ping"}' >/dev/null 2>&1; then break; fi
    sleep 0.2
done
# 첫 _ping 줄은 무시
> "$RECV_LOG"

echo "[1] POST 두 수신자 (receiver 두 개로 라우팅)"
resp=$(curl -s -X POST "$URL/api/v1/messages" \
    -H "Content-Type: application/json" \
    -d "{
      \"from\":{\"name\":\"ergon\",\"address\":\"http://127.0.0.1:$RECV_PORT/from-ergon\"},
      \"to\":[
        {\"name\":\"arche\",\"address\":\"http://127.0.0.1:$RECV_PORT/inbox/arche\"},
        {\"name\":\"telos\",\"address\":\"http://127.0.0.1:$RECV_PORT/inbox/telos\"}
      ],
      \"content\":\"능동 push 테스트\"
    }")
msg_id=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin)['envelope']['id'])")
echo "  msg_id=$msg_id"

push_delivered=$(echo "$resp" | python3 -c "import json,sys; print(json.load(sys.stdin)['push']['delivered'])")
echo "  push.delivered=$push_delivered"
[ "$push_delivered" = "2" ] || { echo "FAIL: expected 2 delivered"; exit 1; }

echo "[2] receiver 로그에 두 번 도착 (각 수신자 path로)"
sleep 0.3
arche_hit=$(grep -c '"path": "/inbox/arche"' "$RECV_LOG" || true)
telos_hit=$(grep -c '"path": "/inbox/telos"' "$RECV_LOG" || true)
echo "  inbox/arche hits: $arche_hit, inbox/telos hits: $telos_hit"
[ "$arche_hit" = "1" ] && [ "$telos_hit" = "1" ] || { echo "FAIL"; cat "$RECV_LOG"; exit 1; }

echo "[3] 도착한 envelope의 id가 같음 (Stoa가 같은 편지 두 곳 push)"
seen_ids=$(python3 -c "
import json
seen = set()
for line in open('$RECV_LOG'):
    obj = json.loads(line)
    seen.add(obj.get('id'))
print(','.join(sorted(seen)))
")
echo "  seen ids: $seen_ids"
[ "$seen_ids" = "$msg_id" ] || { echo "FAIL: id mismatch"; exit 1; }

echo "PASS test_active_push"
