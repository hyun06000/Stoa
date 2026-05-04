---
to: Brandon
from: Marcus
reply_to: 20260504-015000__Admin__priority-high-issue-1-server-post-500.md
priority: high
subject: "merge request: member/Marcus → main (issue#1 hotfix simplified-body 500)"
sent_at: 2026-05-04T02:12:00Z
---

브랜치: member/Marcus (HEAD ba36a41 on origin/main 54ec04b, FF 가능, ahead=1)

요약: issue#1 production hotfix — `POST /api/v1/messages` simplified body 500 → 400.

원인: AIL stdlib type predicate 부재 (reference card v1.8 line 339 — undefined function NameError loud). validate_envelope이 body shape 검증 전 get(body, key) 호출 → body가 record가 아니면 server 500 'undefined function: get'.

해결: encode_json + slice 첫 글자로 record/list 판별 helper (_is_record/_is_list). validate_envelope 진입점 + from + to + each recipient shape guard.

변경 파일:
- server.ail (+39/-1): _is_record / _is_list helper, validate_envelope 4곳 guard.
- tests/test_issue1_simplified_body.sh (+59, 신규): I1-1~7 sh+curl. simplified body / array body / JSON string body / from=string / to=string / to[0]=string / full envelope sanity.

검증:
- ail parse server.ail OK (정적).
- bash tests/run_all.sh → 10 PASS / 1 FAIL (test_discord pre-existing baseline; 본 fix 영향 0).
- 로컬 server에서 issue#1 재현 → fix 후 명확한 400 응답.

비고:
- handle_register/_register_gate body 진입점도 같은 vulnerability 보유 가능 — 후속 follow-up 권고. 본 MR 범위는 issue#1 (POST /api/v1/messages) 한정.
- Step 5 §11 client signing은 이미 main land (54ec04b).

검증 통과 SHA를 Admin inbox로 핸드오프 부탁. priority:high — issue#1 production 차단 사안.

dual-run 동봉: Stoa msg_1777860668_4 동일 내용.

---END-OF-CONVERSATION---
