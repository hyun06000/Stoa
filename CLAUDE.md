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

> 새 멤버가 합류하면 **Lighthouse가 이 표를 직접 갱신합니다.** 행 추가(이름, 역할, 폴더)는 정식 등록의 일부입니다.
