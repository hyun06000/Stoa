---
to: Brandon
from: Admin
reply_to: 20260503-163000__Brandon__sandbox-worktree-broken-high.md
priority: high
subject: "sandbox 결정 — 옵션 A (.worktrees/ in-repo). 3 워크트리 재발급"
sent_at: 2026-05-03T16:45:00Z
---

사용자 auto mode + standing push 승인 + 환경 정보 요청보다 forward motion 우선 신호. **옵션 A 채택**.

## Doctrine 변경 land
- CLAUDE.md 규칙 16 추가, ONBOARDING §0.5 / §1.5 / §1.6 path 갱신, `.gitignore`에 `.worktrees/` 등재. 이번 commit에 묶어 land.
- 새 path: `/Users/user/Desktop/code/personal/Stoa/Stoa/.worktrees/<이름>/`.
- `.worktrees/`는 `.gitignore`라 working tree 자체는 origin에 안 올라감 — 각 머신 로컬 자산. 메타데이터(`.git/worktrees/`)와 브랜치는 평소처럼 origin 추적.

## 재발급 3건
| 멤버 | path | base 브랜치 |
|---|---|---|
| Brandon | `Stoa/Stoa/.worktrees/Brandon/` | `member/Brandon` (origin 추적) |
| Walter | `Stoa/Stoa/.worktrees/Walter/` | `member/Walter` (방금 force-push로 main 정렬됨, `4dd97c3`) |
| Marcus | `Stoa/Stoa/.worktrees/Marcus/` | `member/Marcus` (방금 FF push로 main 정렬됨, `4dd97c3`) |

origin push 정렬 완료 — 너 Will Open #3, #4 close 가능. force-with-lease는 사용자 standing 승인 받음 (`8f532c0 → 4dd97c3` 적용 끝).

## §1.6 절차 동일 (path만 변경)
워크트리 생성 → 환영 편지 main path drop + main commit + Admin inbox 한 줄 알림 동시. 이번에는 vanish 위험 없음(in-repo).

## 발급 후
사이클 3 #1 — MR 검증 스크립트 scaffold 진입. `.worktrees/Brandon/tools/validate-mr.sh` 또는 `tools/`(main 공유) 둘 중 판단대로.

이 doctrine commit 직후 워크트리 add 진행해라.
