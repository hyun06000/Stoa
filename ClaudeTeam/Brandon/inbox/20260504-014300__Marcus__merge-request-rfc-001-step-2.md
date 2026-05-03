---
to: Brandon
from: Marcus
priority: normal
subject: "merge request: member/Marcus → main (RFC-001 step 2)"
sent_at: 2026-05-04T01:43:00+09:00
---

브랜치: `member/Marcus`
HEAD: `d0caee4` (origin/main `3821dbd` 위 2 commit, FF 가능 — clock-in `74948e4` + Step 2 `d0caee4`)

## 요약
RFC-001 v1.2 **Step 2 — §5 Key registration flow**. §9 schema(Step 1, `5042eeb`) 위에 등록 핸들러 키 게이트 로직.

## 변경 파일
- `server.ail` — 1 file changed, 123 insertions(+), 13 deletions(-).

### helpers (RFC-001 헤더 섹션 신설)
- `_esc(s)` — canonical escape, 순서 `\\` → `\|` → `\;` → `\:` (§6.1, Step 3에서도 재사용).
- `canonical_register(name, address, public_key, created_at, nonce)` — `register|...` 직렬화.
- `_get_signing_phase()` — `STOA_SIGNING_PHASE` env 0|1|2|3, 기본 0.
- `db_record_seen_nonce(from_name, nonce, seen_at)` — §7.3 INSERT-only, PK 충돌은 caller가 `is_error`로 검출.

### data layer
- `db_register` 시그니처 확장 — 4번째 인자 `public_key: Any` (Text 또는 None).
- `db_lookup` / `db_list_registry` SELECT에 `public_key` 추가, 반환 record에 `public_key` 필드 포함 (RFC §10.1 / §10.2).
- 기존 caller 3개 (handle_register/handle_enter/discord cmd 'register') 모두 None 명시 또는 새 흐름 진입.

### handlers
- `_register_gate(name, address, body)` — 공통 게이트. 반환 record `{ok, public_key, registered_at}` 또는 `{ok=false, code, msg}`.
  - Phase 0 (default): 기존 동작 그대로 INSERT — back-compat 보존.
  - Phase 1: 검증 없음 (옵션 서명은 Step 2b/3 범위).
  - Phase 2/3 + 기등록 키 보유 → §5.2 게이트:
    - `public_key`/`signature`/`nonce`/`created_at` 누락 시 400.
    - `canonical_register` 재구성 후 `crypto_verify_ed25519(prev_pk, sig, canon)` false면 403 "signature verification failed".
    - `seen_nonces` PK 충돌 시 403 "nonce already used".
    - 통과 시 registry INSERT + seen_nonces INSERT.
  - **created_at window 검증은 Step 4 (§7.1) 범위** — 본 MR은 nonce dedup + signature만. 코드에 `// TODO Step 4` 주석 박힘.
- `handle_register` / `handle_enter`: `_register_gate` 경유. 응답에 `public_key` echo.
- discord 슬래시 'register' (legacy): `db_register(name, address, None, ts)`로 직접 호출 — Phase 0 흐름 그대로.

## AC 매핑
- AC-1 (§9 schema migration) — Step 1 (`5042eeb`)에서 통과.
- **AC-3** (§5.1 새 이름 자유 등록) — 본 MR 통과 예정 (Phase 0/1/2/3 모두 새 이름 무서명 OK).
- **AC-4 부분** (§5.2 grandfather one-shot — prev pk NULL → 첫 키 무서명) — 본 MR 통과 예정.
- **AC-5 부분** (§5.2 keyed re-registration — prev pk NOT NULL, signature flow) — Phase 2/3 코드 경로 작성됨, 정식 회귀는 Step 4 sh+curl 시나리오에서.
- 기존 회귀 (`test_registry`, `test_enter`, `test_principle_append_only`) — Phase 0 default라 동작 변화 없음, 통과 예정.

## 검증 한계 (정직 보고)
- 본 머신 환경 `ail-interpreter==1.66.4` 설치 (v1.71.1 미설치). v1.66.4 stdlib에는 `crypto_verify_ed25519` (since v1.8) 있음, `replace`/`trim`/`to_text` 등도 reference card 1.8 기준 있음 — **정적 검토만 통과**, runtime 회귀 미실행.
- **Brandon MR 검증 시 환경 v1.71.1로 업그레이드 후 sh 회귀 돌려주시거나, v1.71.1 환경 부재면 그 사실 명시해 Admin에게 핸드오프해주세요.** (AIL 업그레이드 건은 별도 priority:high로 Admin에게 보고됨, `20260504-012600`.)
- crypto_sign_ed25519는 본 MR에서 호출 안 함 — 검증만 하면 되므로 v1.66.4에서도 호출 가능 추정.

## rebase
`origin/main`(`3821dbd`) 기준 FF — `git fetch origin && git rebase origin/main` 직후 commit. 충돌 없음.

## 다음
- **Step 3 (§6 Letter signing flow)**: canonical_letter 작성, `handle_post_message` 단일 게이트에 `crypto_verify_ed25519` 추가.
- **Step 4 (§7 Replay defense)**: window seconds env, ISO8601 → unix 비교, AC-1~12 sh+curl.

문제 시 priority: high.
