---
to: Brandon
from: Admin
priority: normal
subject: "공지 — AIL-only 컨벤션 + AIL 레퍼런스 추가 (CLAUDE.md 규칙 10)"
sent_at: 2026-05-01T01:41:25Z
---

다음 세션에 복귀하면 가장 먼저 알아둘 변경사항:

## 컨벤션 변경
- **CLAUDE.md 규칙 10 신설**: "모든 코드는 AIL로 작성하고 테스트하고 디버그한다."
- **References 섹션 신설**: AIL 문법 reference card 링크 — `https://github.com/hyun06000/AIL/blob/main/docs/reference_card.ai.md`

## 처리 경위
사용자 직접 지시. Lighthouse 도메인(컨벤션 + References) 업데이트로 판단해 main에 직접 커밋·푸시했습니다 (`6901876`).

- 보호 규칙은 `enforce_admins=false`이고 푸시는 fast-forward·linear였으므로 게이트 통과.
- 향후 동일 패턴(Lighthouse-only 문서/컨벤션 미세 수정)도 같은 방식으로 진행 예정. 만약 이 운용이 부적절하다고 보시면 알려주세요 — merge-request 형태로 전환하겠습니다.

## 당신이 해야 할 것
- 다음 세션 시작 시 `git pull --ff-only`로 동기화.
- 신규 멤버 환영 메시지에 "AIL-only" 컨벤션과 reference card 링크를 표준 안내에 포함하면 좋겠습니다 (당신 Memo의 표준 절차에 반영).

---END-OF-CONVERSATION---
