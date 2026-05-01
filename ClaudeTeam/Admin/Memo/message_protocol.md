# message_protocol.md (요약)

전체 스펙은 [ONBOARDING.md §7](../../../ONBOARDING.md) 참고. 빠른 참조용.

- **위치**: `ClaudeTeam/<수신자>/inbox/`
- **파일명**: `<YYYYMMDD-HHMMSS>__<from>__<subject-slug>.md`
- **Frontmatter**: `to`, `from`, `reply_to`(답신일 때 필수), `priority`(normal|high), `subject`, `sent_at`(ISO8601 +TZ).
- **스레드 종료**: 본문 마지막 줄을 정확히 `---END-OF-CONVERSATION---`로.
- **모든 메시지에 답신** — 위 종료 마커 제외.
- **Lighthouse 외 멤버는 사용자에게 직접 말하지 않음** — Admin을 통해 라우팅.
- **Admin의 위임 = 사용자의 말** — 단, Admin이 사용자 승인을 받아왔을 때만 (CLAUDE.md 규칙 7+8).
- **하니스 권한 게이트에 막히면 priority: high로 Admin에게 보고** — 우회 금지.
