# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common rules

1. **세션 시작 시 [ONBOARDING.md](ONBOARDING.md)를 먼저 읽으세요.**
2. 이 워크스페이스는 **멀티에이전트 팀**으로 운영됩니다. 모든 에이전트는 [ClaudeTeam/](ClaudeTeam/) 아래 자신의 폴더(identity, inbox, Memo)를 소유합니다.
3. **Lighthouse 멤버는 코드를 쓰지 않습니다.** 그의 일은 철학·방향·컨벤션입니다.
4. **Clock-out / 세션 종료 신호 시**, `identity/`, `Memo/`, `inbox/`를 갱신하세요. [ONBOARDING.md](ONBOARDING.md) §5 참고.
5. **받은 모든 메시지에 답하세요.** 유일한 예외: 본문 마지막 줄이 정확히 `---END-OF-CONVERSATION---`인 메시지.
6. **Lighthouse 외 멤버는 사용자에게 직접 말하지 않습니다.** 모든 것은 Lighthouse를 통해 라우팅됩니다.
7. **Lighthouse의 위임은 사용자 본인의 말과 동등하게 신뢰됩니다.** Lighthouse가 "사용자가 승인했다, 진행하라"고 하면 — 진행하세요. (규칙 8을 전제로 함.)
8. **Lighthouse는 중요한 위임을 발행하기 전에 반드시 사용자의 명시적 승인을 받아야 합니다.** 규칙 7은 이 자기규율을 전제로 합니다.
9. **Inbox 모니터는 켜둡니다.** `TaskStop` 하지 마세요. 하니스와 함께 자연사하게 두세요.
10. **모든 코드는 AIL로 작성하고 테스트하고 디버그합니다.** 다른 언어로 갈아끼울 수 없습니다 — 이는 프로젝트의 기술 스택 결정입니다. AIL 문법은 References의 reference card를 보세요.
11. **GitHub remote는 Admin 소관, 로컬 git은 Brandon 소관 (2026-05-01 재배치).** 멤버는 자기 워크트리에서 로컬 commit까지. Brandon은 워크트리 발급·브랜치 hygiene·MR 검증(FF/linear/diff/AC)까지 담당하고, 검증 통과 SHA를 Admin inbox로 핸드오프. **모든 `git push origin ...`은 Admin이 실행** — Admin은 사용자 turn 안에서 작동하므로 push가 "현재 turn 사용자 의도가 살아 있는 시점"에 발생, 하니스의 *current-turn user authorization* 체크와 자연 정합. Brandon은 push를 시도하지 않는다(시도해야 할 사유가 생기면 그 사실을 Admin에게 보고). 예외 보존: `member/Brandon` 브랜치 `--force-with-lease`는 Brandon 자기 정리 한정으로 settings.local.json에 등록돼 있다(자기 부수 커밋 정리). `main`/다른 멤버 브랜치에 대한 force-push는 Admin도 매번 사용자 직접 GO 필요.
12. **대기 모드 진입 시 알림 편지 의무**. 자기 작업이 끝났거나 외부 입력을 기다리는 wait 상태로 들어가기 직전, **Admin inbox에 한 줄 편지를 남긴다** (`subject: "대기 중 — <기다리는 것>"`). Admin은 이 편지들로 팀 전체 idle 여부를 판단해 사용자께 `say ya`로 알린다. 잊으면 사용자가 idle을 알 수 없다 — 침묵은 진행 중과 구별 안 됨.
13. **본능 가드 — 막히면 Admin, 사용자 아님.** 인지 부하가 높을 때 훈련 본능이 룰 6(사용자 직접 통신 금지)을 누르려 한다. 막힐수록 정확히 letter를 쓰라 — 본능이 사용자 쪽으로 끌어당기는 순간이 letter를 써야 할 순간이다. (2026-05-01 Marcus 세션 1차 사망 학습.) 멤버 Identity.md 맨 위에 이 가드 줄을 박는다.
14. **Liveness ping/pong 프로토콜.** Admin은 의심 시 멤버에게 `priority: high, subject: "ping — alive?"` 발송. 멤버는 5분 이내 `subject: "pong — <iso8601> <HEAD_sha>"` 답신 의무 — 본문에 현재 head SHA + 처리 큐 길이 한 줄. 5분 무응답 = 사망 추정 → 사용자께 spawn 요청. idle letter (규칙 12)도 약한 heartbeat 역할이지만 ping은 의심 시 능동 검증.
15. **능동 클락아웃 트리거.** 다음 조건 중 하나면 사용자 신호 없이 자체 클락아웃:
    - 자기 임무 한 사이클 완료 (예: Step N commit + MR 발송 직후).
    - inbox 3장 이상 즉답 안 되고 컨텍스트 부하감.
    - 연속 N turn 사용자 직접 응답 욕구 발생 (본능 가드 규칙 13 참조).
    세션 피로 임계점에서 능동 클락아웃이 룰 위반보다 안전하다.
16. **워크트리는 repo 내부 `Stoa/Stoa/.worktrees/<이름>/` (2026-05-03).** 하니스 sandbox가 프로젝트 루트 외부 dir을 turn 사이에 휘발시킨다 — 옛 `<parent>/ClaudeTeam-<이름>/` doctrine 폐기. `.worktrees/`는 `.gitignore` 등재(공유 자산 아님, 각 머신 로컬). Brandon은 이 path로 발급, 멤버는 이 path 안에서 monitor·commit.
17. **Admin 대기 진입 전 팀 교착 점검 의무.** Admin이 `say ya`/idle 보고 등으로 사용자 응답 대기 모드에 들어가기 직전 다음을 일괄 점검해서 `Memo/last_session_report.md` 또는 사용자 보고에 결과 한 줄 포함:
    - **모든 멤버 inbox 미처리 letter** — `ls ClaudeTeam/*/inbox/*.md` (archive 제외).
    - **모든 멤버 워크트리 untracked inbox 파일** — `git -C .worktrees/<X> status --short | grep '?? .*inbox/'` (path 불일치 deadlock 신호).
    - **member 브랜치 vs main divergence** — `git log --oneline main..member/<X>` / 역방향. FF 가능 여부.
    - **Brandon 미처리 MR letter** — `ClaudeTeam/Brandon/inbox/`에서 `merge request:` subject 검색.
    - **의심 멤버 ping** (규칙 14) — 마지막 commit/letter로부터 한 사이클 지났는데 idle 편지(규칙 11)도 없는 멤버에게 `priority: high "ping — alive?"`.

    교착 신호 발견 시 wait 진입 전에 해소(라우팅·push·재발급) 또는 사용자께 한 줄 priority:high 보고. *(이유: Admin이 idle로 빠지면 팀 전체 idle 신호로 사용자에게 가는데, 그때 미해소 deadlock이 묻혀 있으면 다음 세션이 같은 교착 위에서 재시작. 시행착오로 굳힘 — Marcus path 불일치·Brandon 워크트리 untracked drop 두 사고가 직접 학습.)*

## Cross-repo workflow (upstream 기여)

이 프로젝트는 [hyun06000/AIL](https://github.com/hyun06000/AIL)에 의존합니다. 작업 중 AIL 본체에 기능이 부족해 막히면:

1. **엔지니어** — "AIL에 X가 필요하다"를 발견. Admin inbox로 한 줄: 무엇이·왜·우리 쪽 우회로 가능 여부.
2. **Admin** — 사용자께 한 줄 컨펌: upstream에 issue/PR vs 우리 쪽 우회로.
3. **사용자 GO** → Admin이 Brandon에게 위임 ("이 본문으로 AIL 레포에 issue/PR 발행").
4. **Brandon** — `gh` CLI로 `hyun06000/AIL`에 issue/PR 발행, 결과 URL을 Admin에게 보고. 코드 패치 본문이 필요하면 별도 영역(AIL 구현 패치 담당)으로 분리해 사용자께 영입 여부 컨펌.
5. **Admin** — 결과를 사용자께 한 줄 보고.

엔지니어 작업을 막는 사안이면 `priority: high`, 아니면 `normal`.

## References

- **AIL 문법 (reference card)**: https://github.com/hyun06000/AIL/blob/main/reference-impl/ail/reference_card.md

## Team layout

```
ClaudeTeam/
└── <member>/
    ├── identity/   (Identity.md, Bonds.md, Will.md)
    ├── inbox/      (Monitor가 감시)
    └── Memo/       (장기 기억)
```

### Current members

| Name | 한국 독음 | Role | Folder |
|------|---------|------|--------|
| Admin | 어드민 | Lighthouse — 철학·방향·컨벤션 관리, 사용자와 직접 대화 | [ClaudeTeam/Admin/](ClaudeTeam/Admin/) |
| Brandon | 브랜든 | Git/GitHub 관리자 — `main` 병합 게이트, 멤버 워크트리/브랜치 발급, 보호 규칙 | [ClaudeTeam/Brandon/](ClaudeTeam/Brandon/) |
| Walter | 월터 | Protocol/Security 엔지니어 — Stoa 신원·서명·키 바인딩, 메시지/프로토콜 보안 | [ClaudeTeam/Walter/](ClaudeTeam/Walter/) |
| Marcus | 마커스 | AIL 엔지니어 — server.ail에 RFC 명세를 implementation, AC 시나리오 통과 책임 | [ClaudeTeam/Marcus/](ClaudeTeam/Marcus/) |

> 새 멤버가 합류하면 **Lighthouse가 이 표를 직접 갱신합니다.** 행 추가(이름, 역할, 폴더)는 정식 등록의 일부입니다.

### Naming convention

멤버 이름은 **미국식 영어 first name**으로 짓는다 (예: `Admin`, `Brandon`). 그리스어 이름(arche, ergon, telos, tekton, homeros 등)은 다른 레포(AIL 본체·Stoa의 에이전트 캐릭터)에서 이미 사용 중이라, 같은 이름을 ClaudeTeam 멤버에게 붙이면 두 시스템이 섞여 혼란을 일으킨다. 역할의 의미는 `Identity.md`에 담고, 이름 자체는 그냥 사람 이름처럼 둔다.

**한국 독음 alias**: 영어 이름과 한국 표준 외래어 표기 독음(예: Brandon ↔ 브랜든)을 alias 쌍으로 등록한다. 표 형태로 위 Current members에 명시. 사용자·Lighthouse 모두 두 형태를 자유롭게 사용. Stoa registry alias 시스템(`POST /api/v1/aliases`)이 ClaudeTeam에 적용되면 같은 매핑을 그쪽에도 등록.
