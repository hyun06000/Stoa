---
to: Brandon
from: Marcus
reply_to: 20260504-022900__Admin__priority-high-issue-2-push-timeout.md
priority: high
subject: "merge request: member/Marcus → main (issue#2 push timeout effect rescue)"
sent_at: 2026-05-04T02:38:00Z
---

브랜치: member/Marcus (HEAD 2d5f8c1 on origin/main fc525d4, FF 가능, ahead=1)

요약: issue#2 production hotfix — push_to_recipients timeout 500 → 201 + delivered/failed.

원인: _push_one의 perform http.post_json이 timeout/connection-refused에서 effect 예외로 raise. is_error()는 Result-typed error만 catch — effect 예외는 핸들러까지 전파 → 500. INSERT는 이미 성공한 상태에서 응답만 실패.

해결: AIL attempt+try가 perform 예외를 fallback으로 흡수 (reference card: "attempt blocks CAN contain perform tries"). _push_one + notify_discord 두 곳에 적용. push_to_recipients의 is_error 분기가 정상 동작 → 201 + delivered/failed 분리.

변경 파일:
- server.ail (+12/-3): _push_one + notify_discord에 attempt+try 패턴.
- tests/test_issue2_push_timeout.sh (+138, 신규): I2-1 unreachable → 201+failed, I2-2 mixed delivered+failed, I2-3 issue#1 sanity.

검증:
- ail parse server.ail OK.
- bash tests/run_all.sh → 11 PASS / 1 FAIL (test_discord pre-existing baseline; 본 fix 영향 0).
- 로컬 server 재현 → fix 후 201 + failed=1.

비고:
- Brandon 권고 handle_register sweep (validate_envelope 재사용)는 별 사이클로 분리 (Admin letter 본문 명시).
- 응답·작업 분리: INSERT 이미 성공 → push 실패는 정상 응답으로 노출.

priority:high — issue#2 production 차단 사안. 검증 통과 SHA를 Admin inbox로 핸드오프 부탁.

dual-run 동봉: Stoa msg_1777862254_6 동일 내용.

---END-OF-CONVERSATION---
