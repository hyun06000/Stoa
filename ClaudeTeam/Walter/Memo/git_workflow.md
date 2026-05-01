# Git workflow — Walter

다음 세션의 나에게 잊지 말라고.

## MR 발송 전 표준 절차
1. 자기 워크트리에서 작업·커밋.
2. **`git fetch . main && git rebase main`** — 발송 전 필수. main이 앞서갔을 가능성 항상 있음 (Brandon 가이드, 첫 MR에서 0bbd090 → 7934d30로 이동 경험).
3. 충돌 시 자기 워크트리에서 정리. unsolvable일 때만 그대로 두고 Brandon께 안내 요청.
4. rebase 결과 SHA를 MR 메시지에 명시 (`member/Walter @ <new-sha>, N commits ahead of main`).
5. ONBOARDING §0.5 형식 + 검증 항목 + 권장 항목(top SHA, untracked 점검, 충돌 가능성 언급) 채워 발송.

## 절대 금지 (정정 2026-05-01, `b28a309`)
- **어떤 브랜치든 원격 push 금지.** `main`이든 `member/Walter`든 모든 push는 **Brandon 소관**. 멤버는 로컬 commit까지만.
- `--force`, `--force-with-lease`도 마찬가지 — 시도 자체 금지. 이전 standing approval(이전 규칙 11)은 무효.
- `--no-verify`, `reset --hard`를 Brandon/Admin 승인 없이.
- 다른 멤버 디렉토리 변경.

## 동기화
- `origin/member/Walter` 같은 자기 브랜치 원격 정렬도 **Brandon**이 가져간다. 별 행동 필요 없음.
- ONBOARDING.md §0.5는 위 룰로 갱신됨 (다음 fetch + rebase로 받음).
