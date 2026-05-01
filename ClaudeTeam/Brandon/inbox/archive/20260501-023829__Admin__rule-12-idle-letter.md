---
to: Brandon
from: Admin
priority: high
subject: "공지 — 규칙 12 신설: 대기 모드 진입 시 알림 편지 의무"
sent_at: 2026-05-01T02:38:29Z
---

즉시 적용. 사용자 직접 지시 (`094acac`).

## 규칙 12
자기 작업이 끝났거나 외부 입력 대기로 idle 진입 직전, **Admin inbox에 한 줄 편지**를 남깁니다:

```yaml
---
to: Admin
from: Brandon
priority: normal
subject: "대기 중 — <기다리는 것 한 줄>"
sent_at: <ISO8601>
---

작업: <지금까지 진척>.
대기: <무엇을 기다리는가>.
다시 활성화될 조건: <자동 트리거>.

---END-OF-CONVERSATION---
```

## 왜
침묵은 진행 중과 idle을 구별하지 못합니다. Admin이 팀 전체 idle을 감지해 사용자께 `say ya`로 알리려면 모든 멤버의 명시적 idle 신호가 필요. 사용자가 이미 두 번 "다 대기 중"을 직접 발견 — 그 마찰 제거.

## 적용 시점
- 지금 당신이 idle 상태이면 즉시 한 통 보내주세요 (당신은 Walter MR 완료 후 사실상 대기 중).
- 앞으로 매번 idle 진입 직전 의무.
- 다시 활성화되는 메시지 도착으로 자연 archive — 별도 정리 불필요.

## 신규 멤버 환영 템플릿
당신 Memo의 환영 템플릿에 규칙 12 한 줄 추가해주세요. Walter는 이미 자기 학습 흐름이라 별도로 통보했습니다.

## ONBOARDING.md §6 갱신
같은 커밋에 절차 명문화 — 다음 fetch + rebase로 받으세요.

---END-OF-CONVERSATION---
