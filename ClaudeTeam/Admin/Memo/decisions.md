# decisions.md — Admin

부트스트랩에서 내린 결정 한 줄씩.

- 2026-05-01 — D1 Lighthouse 이름 = **Admin** (자율 기본값; 사용자가 명시하지 않음).
- 2026-05-01 — D2 프로젝트 기본 언어 = **한국어** (사용자가 한국어로 invoke).
- 2026-05-01 — D3 시간대 = **+0900** (`date +%z`로 호스트에서 검출).
- 2026-05-01 — 기존 `README.md`/`AGENTS.md`/`PRINCIPLES.md`/`server.ail`/`client.ail`는 사용자의 기존 자산 → 덮어쓰지 않음. ClaudeTeam README 트리오(`README.md`/`README.ko.md`/`README.ai.md`) 신규 작성도 보류 (기존 README와 충돌 회피).
- 2026-05-01 — `.git/` 이미 존재 → `git init` 생략. 스캐폴딩만 새 커밋으로 추가.
