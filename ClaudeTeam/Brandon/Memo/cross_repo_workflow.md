# Cross-repo workflow — Brandon의 역할

채택일: 2026-05-01 (CLAUDE.md "Cross-repo workflow" 섹션, `46058f8`).

## 흐름 (5단계)
1. 엔지니어 → Admin: 무엇·왜·우회 가능 여부.
2. Admin → 사용자: 한 줄 컨펌.
3. 사용자 GO → Admin → **Brandon**: "이 본문으로 발행".
4. **Brandon**: `gh` CLI로 외부 레포에 issue/PR 발행, URL 보고.
5. Admin → 사용자 보고.

## 내(Brandon) 책임 — 4단계
### Issue
```bash
gh issue create -R <owner>/<repo> --title "<title>" --body "<body>"
```
- 본문은 Admin이 보낸 그대로. 임의 수정 금지.
- 필요 시 `--label`, `--assignee` 플래그.
- 발행 후 issue URL을 Admin에게 한 줄 보고.

### PR (코드 패치 동반)
- ClaudeTeam 멤버는 외부 레포 **코드 작성을 직접 하지 않는다** (CLAUDE.md "코드 작성은 영입된 에이전트의 일", 별도 영역).
- 따라서 PR 발행도 보통 코드를 우리가 들고 있지 않다 — issue가 표준.
- 만약 코드가 있다면: 외부 레포 fork → branch → 패치 push → `gh pr create`.

## 사전 점검
- `gh auth status`: 활성 계정이 발행자(보통 `hyun06000`)인지.
- 외부 레포 권한: read/write 충분한지.
- 본문에 우리 내부 정보(다른 멤버 이름, ClaudeTeam 구조, `say here` 등) 누설 없는지.

## 거부 시
- harness 거부 → 거부 텍스트 그대로 인용해 Admin priority: high.
- 인증 누락 → 사용자 게이트(직접 GO 필요) 가능성 — Admin이 처리.

## 첫 실전 기록 (2026-05-01)
- Issue: https://github.com/hyun06000/AIL/issues/3 — `stdlib: add ed25519 sign + keygen + cryptographic random`
- 본문: Walter 초안을 Admin이 그대로 내려줌. 임의 수정 0.
- 템플릿 정합: AIL 레포에 design-critique·open-question 템플릿 있지만 둘 다 정확히 맞지 않아 free-form 발행. `config.yml` 부재 → blank issues 허용 확인 후 진행.
- 라벨: 미부여. 향후 라벨 정책 사용자 결정에 따름.
- 발행 후 URL을 priority: normal로 Admin에게 보고하고 끝.

## Lessons (위 사례에서)
- 외부 레포 issue/PR 템플릿이 정확히 맞지 않으면 free-form으로 발행하되, `config.yml`에서 `blank_issues_enabled: false`인지 먼저 확인.
- Admin이 내려준 본문에는 자기 멤버(Walter) 이름이 본문에 들어갈 수 있음 — 그것은 Admin 판단 영역, 내가 익명화하지 않음.
- 발행 직후 `gh issue view <n> --json url,state,createdAt`로 검증 1회.

## 절대 하지 않는 것
- Admin이 내려준 본문을 임의로 다듬는다.
- 사용자 직접 GO 없이 외부 레포에 코멘트·이슈를 발행한다.
- 외부 레포에서 발생한 게이트 거부를 우회한다.
