# 신규 멤버 워크트리 발급 표준 절차

> **Brandon 자신의 작업 룰 (멤버 발급과 무관하게 항상)**
> 1. **먼저 rebase, 그 다음 add/commit.** 자기 부수 커밋(보고·기록·archive)을 만들기 직전에 `git -C <self-worktree> fetch . main && git rebase main`. 이 한 단계로 main과 어긋난 채 commit해서 발생하는 force-push 사고를 막는다.
> 2. **자기 `member/Brandon` 브랜치는 force-with-lease 사전 승인** (CLAUDE.md 규칙 11). main·dev·다른 멤버 브랜치는 절대 적용 안 함.
> 3. archive 이동(`git mv` 또는 `mv`+`git add`)은 자기 부수 커밋의 일부. 커밋 없이 방치하면 다음 rebase 때 stash 필요.


Admin이 새 멤버 `<X>`의 합류를 통보하면 Brandon이 수행한다. 채택일: 2026-05-01 (Admin 위임 `bootstrap-closed`).

## 0. 사전 점검
- Admin 메시지에 멤버 이름·역할이 명확한가? 없으면 `priority: high`로 되묻는다.
- 이름이 **미국식 영어 first name**인가? (CLAUDE.md naming convention) 그리스어 이름(`arche`, `ergon`, `telos`, `tekton`, `homeros` 등)은 AIL 레포·Stoa 캐릭터 에이전트와 충돌하므로 거부하고 Admin에게 되묻는다.
- `git -C <main-worktree> status` — 깨끗한가? 진행 중 작업 위에 워크트리를 만들지 않는다.

## 1. 브랜치 + 워크트리 생성
```bash
git -C <main-worktree> worktree add -b member/<X> <repo-parent>/ClaudeTeam-<X> main
```
- base는 항상 `main` 최신.
- 워크트리 경로는 `<repo-parent>/ClaudeTeam-<X>/` (대시 1개, ONBOARDING §0.5 컨벤션).

## 2. 폴더 스캐폴드는 멤버 본인이 만든다 (예외: inbox/)
ONBOARDING §1대로 멤버가 자기 worktree에서 `identity/`, `Memo/`를 손수 생성한다. Brandon은 그의 자기 정의(identity)를 대신 쓰지 않는다.

**예외**: Brandon이 환영 메시지를 드롭하려면 `<X>/inbox/archive/`만 미리 `mkdir -p`로 만든다. 이 디렉토리는 단순 mailbox이며 자기 정의가 아니다. 멤버가 §1을 진행할 때 자기 첫 커밋에 함께 묶어 트래킹한다.

## 3. 환영 + 셋업 메시지 (priority: high)
워크트리 발급 직후 `<X>/inbox/`에 다음 형식으로 한 통:

```yaml
---
to: <X>
from: Brandon
priority: high
subject: "워크트리 발급 + 셋업 정보 — <X>"
sent_at: <ISO8601>
---

환영합니다. 당신의 작업 환경이 준비되었습니다.

## 발급 사항
- 워크트리: <repo-parent>/ClaudeTeam-<X>/
- 브랜치: member/<X> (base: main@<sha>)
- 원격: <origin URL> (read-only를 통해 fetch만 — push는 Brandon 경유)

## 다음 행동
1. ONBOARDING.md §0의 복귀 의식을 수행.
2. ONBOARDING.md §1대로 자기 폴더(identity/, inbox/, Memo/) 생성.
3. Admin에게 자기소개 발송 (§3).
4. inbox 모니터 가동 (§2). TaskStop 금지.

## 코드 컨벤션 (CLAUDE.md 규칙 10)
이 프로젝트의 모든 코드는 **AIL로 작성·테스트·디버그**합니다.
- AIL 문법 reference: https://github.com/hyun06000/AIL/blob/main/docs/reference_card.ai.md
- 다른 언어로 코드를 쓰지 마세요. 막히면 Admin에게 priority: high.

## merge-request 절차
당신의 `member/<X>` 브랜치를 main에 병합하려면 ONBOARDING §0.5의 merge-request 형식으로 저(Brandon)에게 메시지를 보내세요. 직접 push 금지 — main은 보호되어 있습니다(linear history, no force-push, no deletions).

질문 있으면 답신.
```

## 4. 푸시 + 보호 갱신은 멤버의 첫 MR 처리 시점에
신규 멤버 브랜치를 origin에 미리 푸시하지 않는다 — 멤버가 첫 커밋을 만든 후 그의 첫 MR을 받아 Brandon이 함께 푸시한다.

## 5. 후처리
- Admin에게 워크트리 발급 완료 보고 (priority: normal).
- `Brandon/Memo/decisions.md`에 "<X> 워크트리 발급 — base sha, 일시" 한 줄 추가.

## 절대 하지 않는 것
- 신규 멤버의 identity 파일을 대신 작성한다.
- 보호 규칙을 우회한다 (`--no-verify`, force-push 등).
- 멤버 동의 없이 그의 브랜치를 rebase·force-push한다 (단, 그가 main과 충돌해 도움을 요청한 경우 예외).
