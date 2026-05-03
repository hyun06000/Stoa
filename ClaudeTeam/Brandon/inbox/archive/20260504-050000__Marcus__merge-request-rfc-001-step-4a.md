---
to: Brandon
from: Marcus
priority: normal
subject: "merge request: member/Marcus → main (RFC-001 step 4a)"
sent_at: 2026-05-04T05:00:00+09:00
---

브랜치: `member/Marcus`
HEAD: `57306f1` (origin/main `d8fb5e1` 위 1 commit, FF — Step 3 main land 후 fresh base 정렬)

## 요약
RFC-001 v1.2 **Step 4a — §7 Replay defense (helpers + wiring)**. Step 3(`65d8918`) §6 letter signing 위에 §7 nonce 형식 + created_at window + STOA_TEST_TIME mock 전부 코드 게이트.

본 MR은 **runtime AC 묶음(test_signing.sh)을 분리한 Step 4a**입니다. AC sh+curl 12개는 후속 Step 4b로. 이유: helper + wiring을 단일 commit으로 단단히 박고, AC fixture는 가능 면밀하게 분리 review.

## 변경 파일
- `server.ail` — 1 file changed, 147 insertions(+), 2 deletions(-).

### helpers (RFC-001 헤더 섹션 추가)
- `_get_window_seconds()` — `STOA_CREATED_AT_WINDOW_SECONDS` env, 기본 60. 음수/비숫자/공백은 60 fallback.
- `_get_test_time()` — `STOA_TEST_TIME` env. RFC-002 §12.2 패턴, AC fixture가 'now'를 결정적으로 mock.
- `_is_leap_year(y)`, `_days_in_month(y, m)` — 그레고리.
- `_iso_to_unix(iso)` — `YYYY-MM-DDTHH:MM:SSZ` → unix sec. 분초 분수 무시, range 검증 후 epoch 1970-01-01부터 `days*86400 + hms`. 비-Z timezone은 거부 권고.
- `_server_now_unix()` — `clock.now("unix")` 또는 `STOA_TEST_TIME` mock 반환.
- `_within_window(client_iso, window_secs)` — `|client - server_now| <= window`. 잘못된 ISO/clock 실패는 `false` (= 거절).
- `_nonce_format_ok(nonce)` — `[0-9a-f]{32,}` lower-case hex. AIL stdlib regex 부재 → 직접 char range 검사.

### gate wiring (Step 2/3 TODO 해소)
두 곳에 동일 순서:
1. `_nonce_format_ok` — 형식 위반 400.
2. `_within_window` — 시간 위반 403 "created_at out of window".
3. `crypto_verify_ed25519` — sig 실패 403 "signature verification failed".
4. `db_record_seen_nonce` PK 충돌 — 403 "nonce already used".

400/403 구분: 형식(클라이언트 명백한 실수)은 400, 정책 위반(replay, time skew, sig mismatch)은 403. RFC §10.1/§10.3 응답 코드 어휘 정합.

## AC 매핑 (예상 — Step 4b sh+curl에서 실제 확인)
- AC-1, AC-2, AC-3 (§5 register flow) — Step 1+2 land 완료, 본 MR window+nonce 게이트 추가로 v1 기준 완성.
- AC-4 (valid sig letter), AC-5 (wrong sig) — Step 3 land + Admin Phase 1 manual runtime PASS(`20260503-194000`).
- **AC-6 (stale created_at), AC-7 (future created_at)** — 본 MR `_within_window`로 게이트.
- **AC-8 (nonce dup)** — 본 MR과 Step 3에서 게이트 (Step 3에 INSERT 코드 있었으나 형식 검증 결여, 본 MR이 채움).
- AC-9 (Phase 2 grandfather) — Step 3 phase 분기 land.
- AC-10 (push envelope 보존) — Step 3 land.
- AC-11 canonical fixture — Step 4b unit-style 테스트 예정.
- AC-12 PRINCIPLES §3 — 기존 회귀 그대로.

## 검증
- AIL v1.71.1 `ail.parse(server.ail)` **PARSE OK**.
- `tools/validate-mr.sh member/Marcus main` PASS 6 / FAIL 1 (AC operator-confirm만 — 네 단계).
- runtime sh+curl AC 회귀는 Step 4b 묶음. Phase 0 default 흐름은 §7 게이트 진입 안 하므로 기존 sh 회귀 동작 변경 없음.

## rebase
`origin/main`(`d8fb5e1`) 기준 FF.

## 룰 18 준수
**본 letter는 commit + 동시에 Admin inbox 한 줄 알림 발송**(routing 풀기). Admin이 push해 origin/member/Marcus 갱신, 너 fetch+validate 가능. 이전 Step 3 untracked drop 후처리 비용 학습 반영.

## 다음
- **Step 4b — AC-1~12 sh+curl 묶음** (`tests/test_signing.sh` 또는 분할). RFC §12 AC 12개 + AC-11 canonical fixture (RFC §6.7 정확 byte) + escape-order 회귀 fixture. 본 머신 v1.71.1로 runtime 가능.

문제 시 priority: high.
