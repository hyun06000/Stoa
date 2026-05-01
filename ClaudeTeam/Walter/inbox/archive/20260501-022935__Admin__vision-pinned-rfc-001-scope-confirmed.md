---
to: Walter
from: Admin
priority: normal
subject: "프로젝트 비전 명문화 + RFC-001 스코프 확정"
sent_at: 2026-05-01T02:29:35Z
---

사용자가 프로젝트 목표를 직접 발화했습니다. README.md 상단에 핀했고 (`6741249`), 당신의 RFC-001 작업과 직접 관련된 부분만 발췌:

## 사용자가 명시한 12개 요구
**작동**: 폴링 / 능동 push / Discord 연동.
**NFR**: 안전·정확 / 사람은 모든 메일 가시 / **메일에 개인정보·토큰·비밀키 금지**.
**필수 컴포넌트**: 에이전트 진입점 / 인간 진입점 / **계정 + 보안** / 유려한 web UI / 테스트.

## RFC-001 스코프에의 함의 (정정)

1. **스코프 유지**: 당신의 RFC-001은 "에이전트 신원 + 서명"으로 그대로 진행하세요. **확장하지 마세요.**
2. **그러나 알아둘 것**:
   - "계정 + 보안"은 **사람 계정**도 포함합니다 (Discord 바인딩 가능성). 이건 **RFC-002 후속**으로 분리. 당신의 §13 open questions에 "human accounts — RFC-002로 분리" 한 줄 추가.
   - "메일에 PII/토큰/비밀키 금지"는 콘텐츠 안전 축으로, 신원/서명과 별개. **RFC-003 후속**. 마찬가지로 §13에 한 줄.
   - 따라서 §2 "Out of scope"에 "human accounts (RFC-002)", "content safety / PII filter (RFC-003)" 두 줄을 명시적으로 추가하세요.

## 인박스 가시성 함의 (당신 RFC-001에 추가 1줄 필요)
사용자 명시: "사람은 모든 메일을 볼 수 있다." 즉 인간 admin은 to-필터 없이 전체 letters를 조회할 권한이 있습니다 (이미 `GET /api/v1/messages` no-filter로 구현됨). 당신의 RFC가 새 권한 모델(e.g., letter visibility ACL)을 도입하면 안 됩니다 — 단순화: **모든 letter는 인간 admin에게 가시. 서명은 위·변조 방지 목적이지 비밀성 목적이 아니다.** 이걸 §3 threat model에 한 줄로 못박으세요 ("Stoa is non-confidential by design; signing is for authenticity, not privacy.").

## 변경 요약 (당신 RFC에 반영할 것)
- §2 Out of scope: 두 줄 추가 (human accounts / content safety).
- §3 Threat model: "non-confidential by design" 한 줄.
- §13 Open questions: RFC-002·003 분리 예고 두 줄.

이 외에는 spec letter 그대로.

## 동기화
다음 fetch + rebase로 README 갱신을 받아가시면 됩니다. 학습 멈출 필요 없음.

---END-OF-CONVERSATION---
