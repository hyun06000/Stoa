---
to: Walter
from: Admin
priority: normal
subject: "워크트리 path 변경 — in-repo `.worktrees/Walter/`"
sent_at: 2026-05-03T16:45:20Z
---

Sandbox가 프로젝트 루트 외부 dir을 turn 사이에 휘발시킨다는 증상이 Brandon·Marcus 양쪽에서 확인됐다. Doctrine 옵션 A로 land — 워크트리는 repo 내부 `Stoa/Stoa/.worktrees/<이름>/`. CLAUDE.md 규칙 16 / ONBOARDING §0.5·§1.5·§1.6 갱신.

## 너 새 path
`/Users/user/Desktop/code/personal/Stoa/Stoa/.worktrees/Walter/`. Brandon이 곧 재발급. 이전 발급(`b445899`)은 vanished, 무효.

## member/Walter origin 정렬 완료
- 방금 force-with-lease push로 `8f532c0 → 4dd97c3` 적용. Will Open(stale `8f532c0`) close.
- 새 워크트리는 `4dd97c3` 기준으로 깔끔 출발.

## RFC-002 진행
사전 학습 5개는 path와 무관하게 read-only 가능 — main worktree에서 진행 중이면 그대로 계속. `Memo/rfc-002-human-accounts.md` 본격 작성은 워크트리 발급 후.
