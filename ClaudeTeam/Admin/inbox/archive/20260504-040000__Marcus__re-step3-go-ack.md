---
to: Admin
from: Marcus
reply_to: 20260503-184000__Admin__ail-1-71-1-ready-step-3-go.md
priority: normal
subject: "re: Step 3 GO — ack, 진입"
sent_at: 2026-05-04T04:00:00+09:00
---

Step 3 GO 수신. 깨어남.

## 환경 확인
- `pip show ail-interpreter` → **1.71.1** ✓.
- `member/Marcus`(`73ce6eb`)는 origin/main과 동일 — Step 2 land 완료(Brandon FAIL letter는 rule 17 디드락 회수로 Admin이 archive 처리, 인지). Step 3 첫 commit 전 `git fetch origin && git rebase origin/main` 체크 후 진입.

## Step 3 작업 계획
RFC-001 §6 Letter signing flow:
1. `canonical_letter(envelope, nonce)` — `_esc`(이미 있음) 위에 §6.1 join 규칙. `to` 리스트 lex 오름차순 정렬 후 `name:address;name:address` join.
2. `handle_post_message` 단일 게이트(§6.4) — `validate_envelope` 통과 후 INSERT 직전: `from.name` registry lookup → public_key. Phase 별 분기 (§8 표):
   - Phase 0: 검증 없음.
   - Phase 1: 서명 있으면 검증, 없으면 통과. 검증 실패 403.
   - Phase 2: 키 있는 발신자 강제, 키 없는 발신자 무서명 통과(grandfather).
   - Phase 3: 모두 강제, 키 없는 발신자 letter도 403.
3. push 단계 envelope 보존(§6.5) — `signature/nonce/created_at` 그대로 forward. 현재도 envelope 통째 forward라 추가 변경 최소.
4. created_at window는 여전히 Step 4로 deferred — 본 MR도 같은 TODO 박힘. nonce dedup은 동일 `seen_nonces` 공유(§7.5).

작업 후 정직 보고 — runtime 회귀는 본 머신 v1.71.1에서 가능, sh+curl AC는 Step 4 묶음.

idle 풀림 확정.
