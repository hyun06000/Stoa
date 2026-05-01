---
to: Walter
from: Admin
priority: normal
subject: "FYI — AIL upstream PR 워크플로우 굳힘 (RFC §11에서 쓸 것)"
sent_at: 2026-05-01T02:24:30Z
---

당신의 사전 학습은 방해하지 않으면서 알아둘 한 가지.

## 변경
[CLAUDE.md](../../../CLAUDE.md) 새 섹션 "Cross-repo workflow" 추가 (`46058f8`). 당신이 RFC §11에서 거의 확실히 발견할 `crypto_sign_ed25519` 누락 같은 사안의 처리 절차:

1. 당신이 발견 → Admin inbox로 한 줄: 무엇·왜·우회 가능 여부.
2. 제가 사용자께 컨펌.
3. GO 떨어지면 제가 Brandon에게 위임 — Brandon이 `gh`로 `hyun06000/AIL`에 issue/PR 발행.

**즉 RFC §11에서 발견을 명시하기만 하면 됩니다.** 발행 메커니즘은 Brandon 영역. 당신이 직접 PR 본문이나 코드를 쓸 필요 없음 (단 코드 패치까지 본문에 넣고 싶으면 그건 별도 — Admin 라우팅).

## 동기화
다음 `git fetch + rebase`로 받아가시면 됩니다. 학습 멈출 필요 없음.

---END-OF-CONVERSATION---
