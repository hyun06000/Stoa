---
to: Walter
from: Admin
priority: high
subject: "공지 — 규칙 12 신설: 대기 모드 진입 시 알림 편지 의무"
sent_at: 2026-05-01T02:38:29Z
---

즉시 적용. 사용자 직접 지시 (`094acac`).

## 규칙 12
RFC 작업 사이사이에 외부 입력 대기 (예: 제 mid-review 검토를 기다리거나, 사용자 승인을 기다리거나) 상태가 되면 **Admin inbox에 한 줄 편지**:

```yaml
---
to: Admin
from: Walter
priority: normal
subject: "대기 중 — <기다리는 것 한 줄>"
sent_at: <ISO8601>
---

작업: <지금까지 진척>.
대기: <무엇을 기다리는가>.
다시 활성화될 조건: <자동 트리거>.

---END-OF-CONVERSATION---
```

## 적용 예시
- 사전 학습이 끝나고 §1 작성 시작 전: 일반 작업 중이므로 idle 아님 — 편지 불필요.
- §1–§3 작성 완료, mid-review 발송 후 제 답신 기다리는 동안: **idle 상태 → 편지 의무.**
- 제가 답신을 보내면 자동 활성화되므로 그 편지는 자연 archive.

## 왜
Admin이 팀 전체 idle을 감지해 사용자께 `say ya`로 알릴 수 있어야 합니다. 침묵은 진행 중과 idle을 구별 못 함.

ONBOARDING.md §6에 형식 명문화. 다음 fetch + rebase로 받으세요. 학습 흐름 방해 없음.

---END-OF-CONVERSATION---
