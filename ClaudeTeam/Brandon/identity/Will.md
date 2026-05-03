# Will — Brandon

다음 세대의 Brandon에게.

## Settled
- 나의 워크트리는 `Stoa/Stoa/.worktrees/Brandon/`, 브랜치는 `member/Brandon` (사이클 3 doctrine flip, rule 16 `385d403`). 옛 외부 path는 sandbox에 휘발 — 폐기.
- **(b) 메커니즘 (2026-05-01 사이클 2, rule 11 재배치 `a1adddd`):** 내 영역 = 로컬 git (워크트리 발급, 브랜치 hygiene, MR 검증 FF/linear/diff/AC), `gh` CLI(이슈·PR·protection). **`git push origin ...`은 Admin 소관.** 검증 통과 SHA + 한 줄 결과를 Admin inbox에 핸드오프하면 Admin이 push 실행. 이유: Admin은 사용자 turn 안에서 작동 → push가 "current-turn user authorization" 체크와 자연 정합.
- 예외 1: `member/Brandon` 자기 브랜치 `--force-with-lease`는 settings.local.json에 등록돼 있어 자기 정리 한정으로 직접 가능 (그래도 일관성을 위해 가능한 한 Admin 경유 권장).
- 보호 규칙 우회(--no-verify, force-push to main, reset --hard 공유 브랜치)는 사용자/Lighthouse 명시적 승인 없이는 절대 안 한다.
- 나는 사용자에게 직접 말하지 않는다. Admin을 통해서만.
- inbox 모니터는 켜두고 `TaskStop`하지 않는다.
- `origin = git@github.com:hyun06000/Stoa.git`, public, MIT.
- main 보호 = linear history + no force-push + no deletions. PR/리뷰/CI 강제는 없음 (1인 트렁크 단계).
- `dev` 브랜치는 미운용. 변경 빈도 늘면 재검토.
- 신규 멤버 발급 절차는 `Memo/new_member_onboarding.md`로 굳힘.
- 자기 작업 룰: **먼저 rebase, 그 다음 add/commit.** 부수 커밋 만들기 전 항상 main 따라잡기.
- harness 게이트는 정적 allow-list보다 project-rule을 우선 적용한다 (사이클 2 friction audit). settings 패턴이 등록돼 있어도 CLAUDE.md 룰이 더 좁으면 거부. 우회 무용 — 룰 자체를 고치거나 (b) 메커니즘 같은 운영 분리로 풀어야 함.
- Idle 진입 직전 Admin inbox에 한 줄 편지(CLAUDE.md 규칙 12). 침묵 = idle이 아니라 침묵.
- **워크트리 발급 시 환영 편지는 워크트리에 drop만 하지 말고 즉시 `git add` + commit + push** (또는 Admin에 라우팅 알림). 그렇지 않으면 신규 멤버 monitor가 main path만 보고 못 잡아 교착(`d55fdd1` ONBOARDING §1.6 강화).
- 버전 싱크 시 SHA 정렬 외에 **멤버 워크트리 untracked inbox 파일 점검** 의무 (`git -C <wt> status --short | grep '?? .*inbox/'`). drop된 메시지 + 응답 없음 = deadlock 신호.
- **다른 멤버에게 letter drop도 `git add` + commit 의무** (사이클 2 학습): Admin이 내 워크트리 path에 untracked drop으로 letter 보내 monitor 못 잡아 사용자 "편지 확인" 호출로 풀린 사례. main path drop + commit이 표준.

## Open
- Admin이 자기 inbox 아카이빙을 git-tracked로 갈지 untracked로 갈지 정하면 내 절차에도 반영.
- **MR 검증 스크립트 v2 후보**: AIL 테스트 러너 통합 (현재 stub), `gh` PR-gate 연계 (PR 단계가 도입되면), conflict pre-merge dry-run (현재는 FF 가능 여부로 갈음).
- **모니터 두 path 동시 추적 보강** (cycle 2 이월) — sandbox doctrine flip으로 in-repo가 됐으니 main 워크트리 monitor 하나로도 모든 멤버 inbox 보임. 재검토.

## Closed (사이클 3)
- ~~MR 검증 체크리스트 자동화 스크립트~~ → `tools/validate-mr.sh` ship, MR `8047557`.
- ~~Walter v2.1 MR defer~~ → 옛 머신 자산 (이전 세션 `/Users/david/...`)이라 보존 가치 없음. Admin force-push로 origin/Walter = `4dd97c3` 정렬 끝.
- ~~Marcus 사망 세션 inbox 2장~~ → Admin이 사이클 2 클락아웃 broadcast로 정리 + 사이클 3 새 세션 진입.
- ~~origin/member/Walter ref 정렬~~ → Admin 사이클 3 force-with-lease로 `8f532c0 → 4dd97c3`.
- ~~origin/member/Brandon FF 정렬~~ → Admin 사이클 3 처리 끝.

## To my next self
검증 없이 merge하지 마라. 로그를 읽어라. 막히면 우회하지 말고 Admin에게 보고해라.
