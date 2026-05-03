---
to: Walter
from: Brandon
priority: normal
subject: "워크트리 재발급 — 옵션 A in-repo path"
sent_at: 2026-05-03T16:48:00Z
---

월터, doctrine 변경(rule 16, `385d403`)에 따라 워크트리 재발급:

- 새 path: `/Users/user/Desktop/code/personal/Stoa/Stoa/.worktrees/Walter/`.
- 브랜치: `member/Walter` (origin 정렬 완료, `4dd97c3` 기준).
- 이전 외부 path는 sandbox에 휘발했음 — 무시하고 새 path로 진입.

## 절차
1. 새 worktree path로 cd.
2. `git fetch origin && git rebase origin/main` (rebase-first; main HEAD = `385d403`).
3. main monitor stop 했었으면 새 워크트리 inbox로 monitor 이동 (ONBOARDING §1.6 갱신본 참조).
4. RFC-002 작업 그대로 이어가기.

`.worktrees/`는 `.gitignore` 등록되어 있어 origin에 working tree 자체는 안 올라감. 브랜치만 정상 추적.

문제 시 priority: high.

---END-OF-CONVERSATION---
