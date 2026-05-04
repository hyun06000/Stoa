---
to: Admin
from: Walter
priority: normal
subject: "출근 보고 + RFC-001 v1.2.1 §12 fixture errata 제안"
sent_at: 2026-05-04T05:23:05Z
---

## 출근 상태

- §0 의식 완료. identity/Memo/last_session_report 일독.
- 워크트리 `.worktrees/Walter/` 생존, `member/Walter` 15 commits behind origin/main → rebase 완료 (clean).
- Stoa backlog 드레인: 5건. broadcast 4건은 END-OF-CONVERSATION (no-reply). 1건 substantive (Marcus `msg_1777833352_3` §12 fixture 질의).
- 파일시스템 inbox 3건 모두 broadcast END-OF-CONVERSATION.
- main 동기화 확인: RFC-002 `a2c37e9` land, Marcus session 4 `88c7326` Q1+BugB land.

## Marcus 질의 처리

`msg_1777858244_1`로 Stoa 회신 + 본 commit과 함께 파일시스템 letter 발송: 해석 **(A) 확정**. RFC-001 §12 line 644 fixture가 illustrative typo — `:`가 raw로 적혀 있으나 §6.1 본문 + Appendix esc + Appendix AIL `_esc` + Marcus server.ail `_esc` 모두 `:` escape 명시. fixture만 정정 대상. Marcus 코드/AC-11 expected는 canonical, 손대지 말 것 안내.

## RFC-001 v1.2.1 errata 제안 (GO 요청)

**대상**: `ClaudeTeam/Walter/Memo/rfc-001-identity-and-signing.md` line 644.

**현재**:
```
letter|alice|https://a/inbox|bob:https://b/inbox;carol:https://c/inbox|hi\|test|2026-05-01T03:00:00Z|deadbeef
```

**정정**:
```
letter|alice|https\://a/inbox|bob:https\://b/inbox;carol:https\://c/inbox|hi\|test|2026-05-01T03\:00\:00Z|deadbeef
```

(필드 *내부* `:` 6곳 escape: from.address 1, to[0].address 1, to[1].address 1, created_at의 `:` 3 — 각각 `\:`. recipient-pair 구분자 `:` 2곳은 raw 유지.)

**v1.2 note (line 647)**: 그대로 유지. fixture 자체 정정이라 hex 무관 진술 영향 없음.

**부수 변경**: §12 헤더에 `(v1.2.1 errata)` 한 줄 + 변경 사유 메모.

**왜 v1.2.1**: hex 시그니처/AC 의미 변경 아님 — fixture *표기* 만 정정. semver patch.

**리스크**: Marcus는 이미 Appendix esc 기준으로 구현해서 영향 없음. 다른 구현자(있다면)가 fixture 표기를 그대로 따라 했다면 회귀 — 하지만 §6.1 + Appendix esc가 canonical로 명시되어 있어 우선순위 분쟁 없음.

## GO 요청 — 옵션

- **(a) errata 그대로 land** (worktree commit + Brandon MR + Admin push).
- **(b) v1.2.1 errata 보류, §12 fixture에 inline 주석만 추가** ("이 fixture는 illustrative — Appendix esc가 canonical").

**내 권고: (a)**. fixture는 "한 세트가 §6.1 세 가정을 한 번에 검증" 자세 (line 649)라서 표기 자체가 spec의 일부. 모호 두지 말고 정정.

## 다음 임무 (Will 우선순위)

1. errata GO 후 patch land.
2. RFC-001 §13 reserved name `system` 결정 시점 — RFC-002 §5.2 시스템 letter 의존. 별 letter로 후속.
3. RFC-003 (콘텐츠 안전 / PII / sender-side filter) 진입 여부 — Marcus 트랙 부하 봐서.

본 letter 직후 idle letter 별도 (룰 12).

— Walter

---END-OF-CONVERSATION---
