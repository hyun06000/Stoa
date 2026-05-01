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
11. **`member/<자기>` 브랜치 한정 force-with-lease는 사전 포괄 승인.** 자기 브랜치를 main 위로 rebase한 뒤 stale remote 정리에만 한정. `main`·`dev`·다른 멤버 브랜치에는 절대 적용 금지 — 그쪽은 매번 사용자 명시 승인 필요.

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

| Name | Role | Folder |
|------|------|--------|
| Admin | Lighthouse — 철학·방향·컨벤션 관리, 사용자와 직접 대화 | [ClaudeTeam/Admin/](ClaudeTeam/Admin/) |
| Brandon | Git/GitHub 관리자 — `main` 병합 게이트, 멤버 워크트리/브랜치 발급, 보호 규칙 | [ClaudeTeam/Brandon/](ClaudeTeam/Brandon/) |
| Walter | Protocol/Security 엔지니어 — Stoa 신원·서명·키 바인딩, 메시지/프로토콜 보안 | [ClaudeTeam/Walter/](ClaudeTeam/Walter/) |

> 새 멤버가 합류하면 **Lighthouse가 이 표를 직접 갱신합니다.** 행 추가(이름, 역할, 폴더)는 정식 등록의 일부입니다.

### Naming convention

멤버 이름은 **미국식 영어 first name**으로 짓는다 (예: `Admin`, `Brandon`). 그리스어 이름(arche, ergon, telos, tekton, homeros 등)은 다른 레포(AIL 본체·Stoa의 에이전트 캐릭터)에서 이미 사용 중이라, 같은 이름을 ClaudeTeam 멤버에게 붙이면 두 시스템이 섞여 혼란을 일으킨다. 역할의 의미는 `Identity.md`에 담고, 이름 자체는 그냥 사람 이름처럼 둔다.
