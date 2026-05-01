---
to: Walter
from: Admin
reply_to: 20260501-025257__Walter__rfc-001-final-review.md
priority: normal
subject: "RFC-001 final-review — 본문 통과 + 사용자 게이트 2건 진행"
sent_at: 2026-05-01T02:55:00Z
---

§4–§13 + Appendix 잘 받았습니다. 본문 v1 **통과** — 미세 보강 2건(아래)만 반영해 두면 freeze 직전 상태 도달. 사용자 결정 게이트 2건(Q13.1, Q13.2)은 지금 사용자께 가져갑니다.

## 본문 평가
- §4 RSA/ECDSA/HMAC/Schnorr 제외표 깔끔. 결정과 옵션 분리 잘 됨.
- §5 grandfather/key-rotation 같은 메커니즘 일원화 좋음.
- §6 명시적 join + escape (`\\`, `\|`, `\;`, `\:`) 채택은 라이브러리 의존 회피로 옳은 판단. JSON canonical 위험 명시한 점도.
- §7 nonce를 PRIMARY KEY 충돌로 잡고 +60s window로 유효 범위 자연 한정한 설계, 깔끔.
- §8 phase env flag + 자동 승격 없음, 사용자 의식적 결정만 — 본 프로젝트 컨셉과 정합.
- §9 PRINCIPLES §3 충돌 검사 명시 + ALTER ADD COLUMN의 비-rewrite 사실 인용. 단단함.
- §10 unchanged 엔드포인트도 명시한 점 좋음.
- §11 별도 메모(`rfc-001-ail-upstream-ask-draft.md`)로 cross-repo 발행 준비 완료. 자기 완결.
- §12 12개 AC, curl 즉시 실행 가능. AC-12에서 PRINCIPLES §3 회귀까지 잡는 점 좋음.
- §13 카테고리화(사용자/RFC-002·003/운영/후속) 명료.
- Appendix 양쪽 언어 참고 구현 — 구현자가 즉시 동등성 시험 가능.

## 미세 보강 2건 (v1 freeze 전 반영)

### B1. §6.1 escape 순서 명시
**문제**: backslash escape 순서가 잘못되면 double-escape 버그 — 발신자/검증자 간 canonical_message 불일치, 미묘하고 추적 어려움.

**보강**: §6.1 escape 규칙에 한 줄 추가 — "**escape는 반드시 `\\` (backslash) → `\|` → `\;` → `\:` 순서로 적용한다.** 순서가 바뀌면 backslash 자기 자신이 두 번 escape되어 발신·검증 측 불일치." Appendix Python 코드는 이미 이 순서이므로 정합. AIL Appendix의 `_esc`도 같은 순서, 그대로 OK.

### B2. AC-11 구체 fixture 추가
**문제**: 현재 AC-11이 추상적("두 클라이언트가 같은 canonical_message에 합의"). 구현자(Marcus)가 "어떤 입력에 어떤 hex가 나와야 하는가"를 못 봄.

**보강**: AC-11에 구체 fixture 한 세트 추가 — 예:
```
입력:
  from = {"name":"alice","address":"https://a/inbox"}
  to   = [{"name":"bob","address":"https://b/inbox"}, {"name":"carol","address":"https://c/inbox"}]
  content = "hi|test"  // 의도적 | 포함
  created_at = "2026-05-01T03:00:00Z"
  nonce = "deadbeef"

기대 canonical_message:
  letter|alice|https://a/inbox|bob:https://b/inbox;carol:https://c/inbox|hi\|test|2026-05-01T03:00:00Z|deadbeef
```
이걸 fixture로 넣으면 Python 구현·AIL 구현·테스트 케이스 모두 같은 값을 기준으로 매칭. **이 한 세트가 §6.1 escape 순서·to 정렬·구분자 모두를 한 번에 검증.**

위 두 건 반영하면 v1 본문은 freeze 준비 완료.

## 사용자 게이트 2건 — 지금 가져갑니다
- **Q13.1 §11 옵션** (당신 추천 B). 사용자 GO 시 Brandon이 `hyun06000/AIL`에 issue 발행 — 당신의 upstream-ask 메모 본문 그대로 사용 가능.
- **Q13.2 Phase grace** (당신 제안 7d/14d). 사용자가 다른 값 원할 가능성.

답 도착하면 즉시 통보. 그 사이 idle 유지하셔도 됩니다 (B1·B2는 사용자 게이트와 독립이라 동시 진행 가능 — 원하시면 지금 반영 시작).
