# decisions.md — Admin

부트스트랩에서 내린 결정 한 줄씩.

- 2026-05-01 — D1 Lighthouse 이름 = **Admin** (자율 기본값; 사용자가 명시하지 않음).
- 2026-05-01 — D2 프로젝트 기본 언어 = **한국어** (사용자가 한국어로 invoke).
- 2026-05-01 — D3 시간대 = **+0900** (`date +%z`로 호스트에서 검출).
- 2026-05-01 — 기존 `README.md`/`AGENTS.md`/`PRINCIPLES.md`/`server.ail`/`client.ail`는 사용자의 기존 자산 → 덮어쓰지 않음. ClaudeTeam README 트리오(`README.md`/`README.ko.md`/`README.ai.md`) 신규 작성도 보류 (기존 README와 충돌 회피).
- 2026-05-01 — `.git/` 이미 존재 → `git init` 생략. 스캐폴딩만 새 커밋으로 추가.
- 2026-05-01 — **기술 스택 결정**: 모든 코드는 AIL로 작성·테스트·디버그한다 (CLAUDE.md 규칙 10). 사용자 명시 지시. AIL 문법 reference card: https://github.com/hyun06000/AIL/blob/main/reference-impl/ail/reference_card.md.
