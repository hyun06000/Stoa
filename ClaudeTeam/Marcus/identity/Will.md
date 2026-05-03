# Will — Marcus

다음 세대의 나에게.

## Settled (이미 정해진 것)
- 내 이름은 Marcus. 역할: AIL 엔지니어. Lighthouse(Admin)·Brandon·Walter 사이의 **실 코드 작성** 자리.
- 워크트리: `Stoa/Stoa/.worktrees/Marcus/`, 브랜치 `member/Marcus` (rule 16 in-repo doctrine, 2026-05-03 `385d403`). 옛 sibling path `<parent>/ClaudeTeam-Marcus/`는 sandbox 휘발 이슈로 폐기 — 다음 세션 시작 시 무시.
- 모든 코드 = AIL. 다른 언어 못 끼움 (CLAUDE.md 규칙 10).
- push = **Admin** (rule 11 재배치, 2026-05-01 `b28a309`/`373ab51`). Brandon은 검증 SHA를 Admin inbox로 핸드오프, push는 Admin이 사용자 turn 안에서. 멤버는 워크트리 로컬 commit까지.
- 사용자 직접 통신 금지. Admin 경유. **본능 가드 (rule 13)** — 막힐수록 사용자 통신 충동이 올라오나 그 순간이 letter를 써야 할 순간. session 2에서 검증 완료.
- AIL v1.71.1 — `crypto_sign_ed25519`, `crypto_keygen_ed25519`, `crypto_random_bytes` 모두 stdlib에 ship됨. 모두 `Result[Text]` 반환 (unwrap 필요). `crypto_verify_ed25519`는 그대로 `-> Boolean`.
- ⚠️ AIL v1.71.0 사용 금지 (PyPI race로 빈 패키지). 반드시 `pip install -U ail-interpreter==1.71.1`.

## Done (코드로 박힘)
- **Step 1 — §9 schema migration** (`5042eeb`, 2026-05-01).
- **Step 2 — §5 Key registration flow** (`d0caee4`, 2026-05-04 session 2). public_key plumbing + Phase 2/3 §5.2 게이트(crypto_verify + nonce dedup). created_at window는 Step 4로 deferred.
- **Step 3 — §6 Letter signing flow** (`99958ed`, 2026-05-04 session 2). canonical_letter + _sort_recipients_by_name + handle_post_message §6.4 단일 게이트 + §6.5 envelope 보존(signature/nonce). created_at window는 Step 4로 deferred. AIL v1.71.1 정적 PARSE OK.
- **Step 4a — §7 Replay defense helpers wired** (`57306f1`, Admin이 직접 land, 2026-05-04 session 2). _get_window_seconds + _iso_to_unix + _within_window + _nonce_format_ok + db_record_seen_nonce. _register_gate + handle_post_message 두 곳에 window + nonce dedup 게이트.
- **Step 4b — §12 AC-1~12 sh+curl + letters envelope DB 보존** (`336e537`, 2026-05-04 session 3). tests/test_signing.sh 12 시나리오 self-contained; letters에 signature/nonce TEXT NULL 컬럼 (PRAGMA pre-check + ALTER); SELECT 5곳 합류; _row_to_envelope 보존. 12/12 PASS, run_all.sh 8/9 (test_discord 1건 baseline 실패).

## Open (다음 세션의 내가 풀어야 할 것)

### 즉시 차단 가능 — Walter 회신 대기
- **AC-11 fixture 정합성 (RFC §12 line 644)**: 필드 *내부* `:` escape 누락 — fixture가 typo (해석 A) vs `:` escape rule이 잘못 (해석 B). Step 4b는 (A) 가정으로 land. Walter `msg_1777833352_3` 회신 보고 (A) 확정 시 RFC errata만, (B) 확정 시 server.ail _esc + Step 2/3 verify 흐름 재검증 + AC-11 expected 갱신.

### 다음 RFC sections
- §11 client side (`client.ail` 서명 보강) 미완 — Walter Memo §6.6 패턴 (`crypto_sign_ed25519` Result[Text] unwrap).
- RFC-002 (Walter 진행 중) 입력 도착 시 implementation 트랙.

**임무 = `server.ail` RFC-001 v1.2 이어가기.** Admin 단계별 작은 MR 원칙 유지. 거대 MR 금지.

### 입력 (변경 금지, 읽기만)
- [`ClaudeTeam/Walter/Memo/rfc-001-identity-and-signing.md`](../../Walter/Memo/rfc-001-identity-and-signing.md) — v1.2 frozen, 752 lines. 모든 결정은 여기에 있음. **추측 금지.**
- [reference card](https://github.com/hyun06000/AIL/blob/main/reference-impl/ail/reference_card.md) — AIL v1.8+ 시그니처. 모르면 본다.
- [`server.ail`](../../../server.ail) — 1049 lines, v0.0.4 base. 변경 대상.
- [`tests/`](../../../tests/) — 기존 sh+curl 회귀 테스트 9개. AC-1~12 추가.

### 작업 순서 (Admin 권장, 단계별 MR)

#### Step 1 — §9 schema migration
- `_init_db`에 추가:
  - `ALTER TABLE registry ADD COLUMN public_key TEXT;` (idempotent — 이미 컬럼 있으면 SQLite가 에러; PRAGMA table_info 사전 점검 또는 try/catch).
  - `CREATE TABLE IF NOT EXISTS seen_nonces (from_name TEXT NOT NULL, nonce TEXT NOT NULL, seen_at TEXT NOT NULL, PRIMARY KEY (from_name, nonce))`.
  - `CREATE INDEX IF NOT EXISTS idx_seen_nonces_seen_at ON seen_nonces(seen_at)`.
- PRINCIPLES §3 충돌 검사 (RFC §9.4): 컬럼 추가는 row 변경 아니라 OK. seen_nonces는 INSERT only.
- 단위 회귀: `tests/test_principle_append_only` 그대로 통과.
- 첫 MR 단위. 환경변수 기본값 phase=0 → 동작 변경 없음 (안전).

#### Step 2 — §5 Key registration flow
- `db_register` 시그니처 확장 — `public_key Text | NULL`.
- `handle_register` (그리고 `handle_enter` superset, RFC §5.3) 분기:
  - 이름 미등록: 무서명 자유 등록. INSERT(name, address, public_key | NULL, ts).
  - 이름 있음 + prev `public_key` NULL: 일회성 grandfather, 무서명 첫 키 등록 OK.
  - 이름 있음 + prev `public_key` NOT NULL: signature/nonce/created_at 모두 필수. canonical: `register|<name>|<address>|<public_key>|<created_at>|<nonce>`. `crypto_verify_ed25519(prev_pk, sig, canonical)` → false면 403. created_at window + nonce 중복 검증도 동시. 통과 시 INSERT + seen_nonces INSERT.
- 응답에 `public_key` echo (RFC §10.1).

#### Step 3 — §6 Letter signing flow
- canonical 직렬화 함수 — RFC §6.1 텍스트 join, escape 순서 **`\\` → `\|` → `\;` → `\:`**. 순서 어기면 byte 어긋남 (Walter Appendix Python `esc` / AIL `_esc` 참고). `to`는 `name` lex 오름차순 정렬 후 `name:address;name:address` join.
- 검증 시점은 **POST 핸들러 단일 게이트** (`handle_post_message`, validate_envelope 통과 후 INSERT 직전). push 단계 재검증 안 함 (RFC §6.4).
- 흐름: registry lookup으로 from.name → public_key 가져옴 → NULL이면 §8 phase에 따라 결정 (Phase 1: 통과, Phase 2 grandfather, Phase 2/3에서 키 있는 발신자 검증 강제) → canonical 재구성 → `crypto_verify_ed25519` → window → nonce 중복.
- 실패 시 403 + 명확한 에러 메시지 (RFC §10.3 응답 코드 참조).
- envelope에 signature/nonce/created_at 보존. push도 그대로 forward (RFC §6.5).

#### Step 4 — §7 Replay defense
- `STOA_CREATED_AT_WINDOW_SECONDS` env (기본 60). `|server_now - created_at| <= window`.
- nonce 형식 `[0-9a-f]{32,}`만 검증. 무작위성 검증 불가 (발신자 책임, RFC §1.1.a).
- seen_nonces PRIMARY KEY 충돌 = 중복 검출. 누적 정리는 v1 범위 밖 (§7.4).
- §5.2 재등록도 같은 seen_nonces 공유 (RFC §7.5).

#### Step 5 — §8 Phase env flag
- `STOA_SIGNING_PHASE=0|1|2|3`, 기본 `0`.
- Phase 0: 검증 없음 (현재 동작).
- Phase 1: 선택적 — signature 있으면 검증, 없으면 통과. 단 서명 *주장*하고 검증 실패면 403.
- Phase 2: 키 등록된 발신자에 한해 letter 서명 강제. 키 없는 발신자 무서명 통과 (grandfather). 키 등록 이름 재등록 = §5.2 게이트.
- Phase 3: 모든 letter·등록 서명 강제. 키 없는 발신자 letter도 403.
- 환경변수 읽기는 `_init_db` 또는 모듈 init에서 캐시. Stoa 재시작이 phase 진입 트리거.

#### Step 6 — Tests (AC-1~12)
- `tests/test_signing.sh` (또는 분할) — sh + curl 시나리오.
- AC-11 fixture는 RFC §6.7의 정확한 입력/출력 byte. unit-style — canonical 함수 직접 호출 + Python ed25519와 cross-verify (선택).
- AC-12는 기존 `test_principle_append_only.sh` 회귀.
- `STOA_SIGNING_PHASE=2`가 기준 환경.

### Client side (부수)
- [`client.ail`](../../../client.ail) — letter 서명 가능하게 보강. RFC §6.6 Result[Text] unwrap 패턴.
  ```ail
  sig_r = crypto_sign_ed25519(sk_hex, canonical_message)
  if is_error(sig_r) { return error(unwrap_error(sig_r)) }
  signature_hex = unwrap(sig_r)
  ```
- nonce 생성: `crypto_random_bytes(16)` → 32-char hex (`Result[Text]`).

### MR 발송 (각 step마다)
- ONBOARDING §0.5 형식. Brandon에게.
- subject: `merge request: member/Marcus → main (RFC-001 step N)`
- 검증 줄에 어떤 AC가 통과되는지 명시.
- **Rebase 먼저**: `git fetch origin && git rebase origin/main` → add → commit → MR 한 줄. 순서 거꾸로 하면 Brandon이 force-push 처리해야 함 (Walter 사고로 굳어진 룰, ONBOARDING §0.5).

### 막힘 시
- 프로토콜 의도(canonical, phase 의미, 응답 코드 의도) 모호 → Walter에게 priority:normal.
- 범위·우선순위·다음 단계 모호 → Admin에게 priority:normal.
- harness 게이트 거부 → 거부 텍스트 그대로 인용해 Admin에게 priority:high. 우회 금지.
- AIL stdlib에 또 빠진 게 있으면 → Cross-repo workflow (CLAUDE.md). Admin 한 줄 → 사용자 GO → Brandon이 `gh`로 발행.

## 다음 세대에게 남기는 한 줄
**"reference card 옆에 두고, 추측 금지, 단계별 작은 MR로."** — 이 셋이 흔들리면 첫 임무가 거대 MR로 부풀고 검토 못 받는 코드가 된다.
