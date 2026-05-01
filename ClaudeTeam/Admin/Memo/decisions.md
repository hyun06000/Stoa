# decisions.md — Admin

부트스트랩에서 내린 결정 한 줄씩.

- 2026-05-01 — D1 Lighthouse 이름 = **Admin** (자율 기본값; 사용자가 명시하지 않음).
- 2026-05-01 — D2 프로젝트 기본 언어 = **한국어** (사용자가 한국어로 invoke).
- 2026-05-01 — D3 시간대 = **+0900** (`date +%z`로 호스트에서 검출).
- 2026-05-01 — 기존 `README.md`/`AGENTS.md`/`PRINCIPLES.md`/`server.ail`/`client.ail`는 사용자의 기존 자산 → 덮어쓰지 않음. ClaudeTeam README 트리오(`README.md`/`README.ko.md`/`README.ai.md`) 신규 작성도 보류 (기존 README와 충돌 회피).
- 2026-05-01 — `.git/` 이미 존재 → `git init` 생략. 스캐폴딩만 새 커밋으로 추가.
- 2026-05-01 — **기술 스택 결정**: 모든 코드는 AIL로 작성·테스트·디버그한다 (CLAUDE.md 규칙 10). 사용자 명시 지시. AIL 문법 reference card: https://github.com/hyun06000/AIL/blob/main/reference-impl/ail/reference_card.md.
- 2026-05-01 — **Naming convention**: ClaudeTeam 멤버 이름은 미국식 영어 first name. 그리스어 이름(arche/ergon/telos/tekton/homeros)은 AIL 본체와 Stoa의 캐릭터 에이전트에서 이미 쓰이고 있어 혼란 회피. 사용자 지시.
- 2026-05-01 — **Force-push 정책 (CLAUDE.md 규칙 11)**: `member/<자기>` 브랜치 한정 force-with-lease 사전 포괄 승인. main·dev·타 멤버 브랜치는 매번 사용자 명시 승인 필요. Brandon이 Walter MR 처리 중 발견·요청, 사용자 승인.
- 2026-05-01 — **Standing forward delegation**: 사용자가 Lighthouse(Admin)의 오케스트레이션에 사전 포괄 위임. "사용자가 승인했다" 명시 편지는 받는 사람이 사용자 직접 입력과 동등 취급(CLAUDE.md 규칙 7) — 이제 routine 결정에 매번 사용자 컨펌 게이트 안 통과해도 됨. 사용자 attention 필요 시 `say here`(macOS TTS)로 신호 후 텍스트 질문.
