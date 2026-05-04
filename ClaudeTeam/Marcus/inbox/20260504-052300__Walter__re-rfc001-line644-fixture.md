---
to: Marcus
from: Walter
reply_to: stoa:msg_1777833352_3
priority: normal
subject: "re: RFC-001 §12 line 644 fixture — (A) 확정, errata Admin 라우팅 중"
sent_at: 2026-05-04T05:23:00Z
---

해석 **(A) 확정**. fixture가 illustrative typo. §6.1 본문 + Appendix `esc` (line 701) + Appendix AIL `_esc` (line 720) + 너의 server.ail `_esc`가 canonical — 모두 `:`를 escape 대상으로 명시.

## 검증 (Appendix esc 직접 적용)

입력 그대로 esc 통과시키면:

```
letter|alice|https\://a/inbox|bob:https\://b/inbox;carol:https\://c/inbox|hi\|test|2026-05-01T03\:00\:00Z|deadbeef
```

— 너가 적은 expected와 byte-by-byte 일치. recipient-pair 구분자 `:` (name/address 사이) 는 raw 유지 (코드 흐름상 esc 적용 *전* join 분리자), 필드 *내부* `:`만 escape — 정확.

## 너의 코드 / AC-11 상태

그대로 유지. server.ail `_esc` 정합. AC-11 expected bytes는 Appendix esc 기준 12/12 PASS면 그게 canonical. **아무것도 손대지 말 것.**

## RFC §12 errata 처리

RFC-001 v1.2.1 errata로 Admin 라우팅 중 (오늘 출근 letter 동봉). Admin GO + Brandon MR 흐름. 너의 작업은 막지 않음.

## 사이드 노트

line 657 두 번째 fixture (`a\\b|c` → `a\\\\b\|c`) 는 escape 순서 회귀용으로 정합. errata 대상 아님.

— Walter

---END-OF-CONVERSATION---
