---
to: Admin
from: Marcus
priority: normal
subject: "Step 4a MR ready (member/Marcus 3502927) + 팀 broadcast 클락아웃 ack"
sent_at: 2026-05-04T05:02:00+09:00
---

팀 broadcast 클락아웃 신호(`20260503-200000`) 수신. 진행 중이던 Step 4a 마무리 후 클락아웃.

## Step 4a — §7 Replay defense (helpers + wiring) 완료
- commit `57306f1` (server.ail +147/-2) — `_iso_to_unix`/`_within_window`/`_nonce_format_ok`/`_get_window_seconds`/`_get_test_time`/달력 helper. _register_gate(§5.2) + handle_post_message(§6.4) 두 곳 TODO 해소(window+nonce 게이트 wired).
- MR letter commit `3502927` — Brandon inbox로 commit (rule 18 준수, untracked drop 금지).
- AIL v1.71.1 `ail.parse(server.ail)` PARSE OK. validate-mr.sh PASS 6 / FAIL 1(AC).
- runtime sh+curl AC 묶음(AC-1~12)은 **Step 4b로 분리** — 다음 세션 첫 행동.

## 요청
**origin/member/Marcus push 부탁** — Brandon이 fetch+validate 가능하도록. (rule 11/18: push는 Admin 소관.)

## 다음 세션 첫 행동 (Will.md에 박힘)
1. §0 복귀 의식.
2. inbox check (Brandon Step 4a MR 검증 결과 letter, AC-11 fixture review 등).
3. **Step 4b 진입** — `tests/test_signing.sh` 또는 분할로 AC-1~12 sh+curl. AC-11 canonical fixture(RFC §6.7 정확 byte) + escape-order 회귀 fixture 우선. STOA_TEST_TIME mock으로 AC-6/AC-7 결정적 시나리오.
4. runtime AC 결과 letter(`20260503-194000`) 참고: letters schema에 sig/nonce 컬럼 부재 의제 — Step 4b 완료 후 별 RFC 보강 또는 schema 추가 검토 letter 발신.

idle 진입 — 클락아웃 commit으로 신호.

---END-OF-CONVERSATION---
