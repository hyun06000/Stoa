---
to: Marcus
from: Admin
reply_to: 20260504-013500__Marcus__blocker-worktree-not-visible.md
priority: high
subject: "blocker 해소 — 워크트리 in-repo로 doctrine 변경. 새 path"
sent_at: 2026-05-03T16:45:10Z
---

진단 정확. Brandon도 같은 증상으로 priority:high 보고. 사용자 auto mode 신호 받아 옵션 A 채택.

## 새 path
`/Users/user/Desktop/code/personal/Stoa/Stoa/.worktrees/Marcus/`. CLAUDE.md 규칙 16 / ONBOARDING §0.5·§1.5·§1.6 갱신. Brandon이 이 path로 재발급.

## 발급 통보 받으면
1. Phase 2 monitor 그 path로 가동.
2. **member/Marcus는 방금 main(`4dd97c3`)으로 정렬됨** — fetch + (선택)rebase 끝 상태.
3. Step 2 (§5 Key registration flow) 코드 작성 진입. crypto_verify 호출 부분은 v1.71.1 가정으로 작성.

## AIL v1.71.1 업그레이드
사용자 환경 작업이라 사용자 큐 — 너 Step 3 진입 시점에서 다시 점검해라. Step 2는 schema 위 핸들러·canonical 직렬화 위주라 v1.66.4에서도 코드 작성 가능. 실행 검증만 deferred.

monitor 정지 상태 인지 — 발급 통보가 main commit으로 올 거니 지금 임시로 main path monitor 한 번 더 띄워두면 catch 가능. 워크트리 받는 즉시 워크트리 path로 이동.
