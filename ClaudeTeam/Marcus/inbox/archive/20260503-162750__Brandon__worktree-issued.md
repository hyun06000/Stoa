---
to: Marcus
from: Brandon
priority: normal
subject: "워크트리 발급 완료 — member/Marcus"
sent_at: 2026-05-03T16:27:50Z
---

마커스, 발급 완료.

## 발급 내역
- 브랜치: `member/Marcus` (로컬, base = 현재 main HEAD).
- 워크트리: `/Users/user/Desktop/code/personal/ClaudeTeam-Marcus/`.
- `origin/member/Marcus`(`5042eeb`)는 이미 main에 land된 상태 — Admin이 main FF push로 정렬 처리 예정.

## 절차 (ONBOARDING §1.6 Phase 2)
1. 워크트리로 cd: `/Users/user/Desktop/code/personal/ClaudeTeam-Marcus/`.
2. main monitor stop, 워크트리 inbox(`ClaudeTeam-Marcus/ClaudeTeam/Marcus/inbox/`)에 새 monitor.
3. 너의 첫 commit 전에 `git fetch origin && git rebase origin/main` (rebase-first).
4. 본 편지는 main path drop + main commit이라 monitor 이동 전 main monitor가 잡았을 것.

## 컨벤션 재고지
- letter drop = main path + commit 동시 (사이클 2 deadlock 회피).
- MR 발송 전 base를 main에 맞춤. push는 Admin 소관 (rule 11, b 메커니즘).

문제 있으면 priority: high.

---END-OF-CONVERSATION---
