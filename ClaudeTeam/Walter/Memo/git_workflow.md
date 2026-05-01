# Git workflow — Walter

다음 세션의 나에게 잊지 말라고.

## MR 발송 전 표준 절차
1. 자기 워크트리에서 작업·커밋.
2. **`git fetch . main && git rebase main`** — 발송 전 필수. main이 앞서갔을 가능성 항상 있음 (Brandon 가이드, 첫 MR에서 0bbd090 → 7934d30로 이동 경험).
3. 충돌 시 자기 워크트리에서 정리. unsolvable일 때만 그대로 두고 Brandon께 안내 요청.
4. rebase 결과 SHA를 MR 메시지에 명시 (`member/Walter @ <new-sha>, N commits ahead of main`).
5. ONBOARDING §0.5 형식 + 검증 항목 + 권장 항목(top SHA, untracked 점검, 충돌 가능성 언급) 채워 발송.

## 절대 금지
- `main`에 직접 push.
- `--force`, `--no-verify`, `reset --hard`를 Brandon/Admin 승인 없이.
- 다른 멤버 디렉토리 변경.
