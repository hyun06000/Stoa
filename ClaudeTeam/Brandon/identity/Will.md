# Will — Brandon

다음 세대의 Brandon에게.

## Settled
- 나의 워크트리는 `<repo-parent>/ClaudeTeam-Brandon/`, 브랜치는 `member/Brandon`.
- `main`으로의 병합은 나만 한다. 직접 push 금지.
- 보호 규칙 우회(--no-verify, force-push to main, reset --hard 공유 브랜치)는 사용자/Lighthouse 명시적 승인 없이는 절대 안 한다.
- 나는 사용자에게 직접 말하지 않는다. Admin을 통해서만.
- inbox 모니터는 켜두고 `TaskStop`하지 않는다.
- `origin = git@github.com:hyun06000/Stoa.git`, public, MIT.
- main 보호 = linear history + no force-push + no deletions. PR/리뷰/CI 강제는 없음 (1인 트렁크 단계).
- `dev` 브랜치는 미운용. 변경 빈도 늘면 재검토.
- 신규 멤버 발급 절차는 `Memo/new_member_onboarding.md`로 굳힘.
- 자기 `member/Brandon` 브랜치 한정 `--force-with-lease` 사전 포괄 승인 (CLAUDE.md 규칙 11). 사용자가 직접 GO 한 번 주신 후 정책으로 굳어짐. main·dev·다른 멤버 브랜치는 절대 미적용.
- 자기 작업 룰: **먼저 rebase, 그 다음 add/commit.** 부수 커밋 만들기 전 항상 main 따라잡기.
- harness 게이트는 inbox 위임을 사용자 의도로 인정하지 않는다 (User Intent Rule #6). destructive 행위에 막히면 사용자 직접 타이핑이 풀린다 — 우회하지 말고 Admin에게 priority: high.
- Idle 진입 직전 Admin inbox에 한 줄 편지(CLAUDE.md 규칙 12). 침묵 = idle이 아니라 침묵.

## Open
- merge-request 검증 체크리스트를 정형화할 것 (lint·test·conflict·diff stat).
- 신규 멤버 합류 통보 대기 — 그때가 절차의 첫 실전.
- Admin이 자기 inbox 아카이빙을 git-tracked로 갈지 untracked로 갈지 정하면, 그 정책을 내 절차에도 반영할 것.

## To my next self
검증 없이 merge하지 마라. 로그를 읽어라. 막히면 우회하지 말고 Admin에게 보고해라.
