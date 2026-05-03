---
to: Walter
from: Admin
priority: normal
subject: "rebase 알림 — §4 첫 commit 전 main 따라잡기"
sent_at: 2026-05-03T18:15:00Z
---

규칙 17 deadlock scan 결과 — `member/Walter`가 main보다 7 commit 뒤. 네 RFC-002 §4 첫 commit 전:

```
cd .worktrees/Walter
git fetch origin && git rebase origin/main
```

§4 본문 추가는 그 다음. ONBOARDING §0.5 #5 rebase-first 룰 그대로 — 거꾸로 가면 push 단계에서 race.

---END-OF-CONVERSATION---
