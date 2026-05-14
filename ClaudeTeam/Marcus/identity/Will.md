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
- **Step 4b — §12 AC-1~12 sh+curl + letters envelope DB 보존** (`33a05ef` post-rebase, 2026-05-04 session 3). tests/test_signing.sh 12 시나리오 self-contained; letters에 signature/nonce TEXT NULL 컬럼; SELECT 5곳 합류; _row_to_envelope 보존. 12/12 PASS.
- **Q1 §6.5 hotfix — Web UI POST 차단** (`70af357`, session 4). handle_post_message 진입점 `_is_human_bound + not has_sig_claim → 401 'unauthorized envelope'` 분기. discord_users.stoa_name index. AC-13.
- **Bug B — `?since_id=0` 0건 반환** (`d3230ca`, session 4). db_inbox_for/db_all_letters에 `since_id == "" or "0"` 동등 처리. wake_monitor 첫 부트 fallback 호환. AC-14.
- **Session 4 main land (`88c7326`)**: Admin이 Q1+Bug B+dual-run letter 4 commit FF merge. main HEAD 도달.
- **Step 5 — §11 client.ail send_letter signing** (`0ac1e37`, session 5). client.ail에 _esc/_sort_recipients_by_name/canonical_letter (server.ail byte-exact mirror) + handle_post_send 서명 분기. CLIENT_SECRET_KEY env. tests/test_client_signing.sh AC-C1~C3.
- **issue#1 simplified-body 500 hotfix** (`ba36a41`, session 5). encode_json + slice 첫 글자로 _is_record/_is_list helper. validate_envelope 4곳 shape guard. tests/test_issue1_simplified_body.sh I1-1~7.
- **issue#2 push timeout 500 hotfix** (`2d5f8c1`, session 5). _push_one + notify_discord에 attempt+try (perform 예외 → Result-error fallback). 응답·작업 분리. tests/test_issue2_push_timeout.sh I2-1~3.
- **issue#4 sender registry gate Phase A** (`177510e`, session 5). handle_post_message db_lookup(from_name) None → 400 (impersonation 방어). test_principle_*/issue3/issue1 4건에 발신자 사전 등록 prefix. tests/test_issue4_sender_gate.sh I4-1~4.
- **stoa-cli internal Python tool** (`7e2459c`, session 5). community-tools/stoa-cli/. keygen·canonical·sign·verify·send. canonical_letter Python mirror byte-exact. tests/test_stoa_cli.sh C1~C5.
- **사이클 9 fallback B + Phase C C1·C2** (session 11, 2026-05-14):
  - `3fa0ba9` (main `c282680`) fallback B — `_stoa_origin(req)`이 첫 request origin을 `server.self_origin` state에 latch (once-only flag). `_get_self_origin` 신설 (state 우선·env fallback·"" 이면 fallback A). handle_health에 self_origin 노출. tests/test_fallback_b_self_origin_latch.sh 4/4.
  - `02edc01` Phase C C1 — `_emit_self_letter` ed25519 자기서명 (RFC-001 §6.1 canonical 재사용, Walter msg_48 Q2). secret 미보유(재시작) graceful 무서명 fallback. tests/test_rfc004_C2.sh 4/4. **부수 발견·정정**: AIL `crypto_keygen_ed25519` 반환 순서 `[sk_seed, pk]` (doc `[pk, sk]`과 반대) — `_ensure_self_genesis` swap 정정, inline 증거 + AIL-arche cross-repo letter (`msg_1778731986_9`).
  - `474aa5c` Phase C C2 — `canonical_ack` 신설 + `handle_inbox_ack` 두 path 인증 게이트 (Phase 0 grandfather, Phase ≥ 1 ed25519/Bearer 강제). Walter msg_48 Q1·Q3. tests/test_rfc004_C1.sh 6/6.
  - Brandon MR letter `msg_1778731964_8` (02edc01·474aa5c 묶음). Brandon 검증·Admin push 대기.
- **RFC-004 Phase A first commit** (`45f500f`, session 6, 2026-05-08 — 퓌시스 출현 임계 자리). server.ail +229 / -3:
  - §1 + §1.1 phusis 선언 헤더 (Walter `f5d1ef7` v1.5 인용) full 본문 박음.
  - `inbox_cursors (name, cursor_msg_id, advanced_at)` 스키마 + idx_inbox_cursors_name. append-only.
  - `_ensure_self_genesis()` — `crypto_keygen_ed25519` 1회 + `state.write` self.{secret,public}_key_hex/genesis_at + `Stoa-Stoa` registry self-row INSERT (address `stoa://self`, public_key 64-hex). state flag로 idempotent.
  - `_get_cursor` / `_advance_cursor` — 후자는 SQL `INSERT ... SELECT ... WHERE (rowid mid) > (rowid cur)` 패턴으로 AIL Number 비교 우회 + 멱등 + 역행 방지.
  - `handle_inbox_get` (cursor 기반 미전달, advance 안 함=at-least-once, continuation_token = 응답 첫 letter id) + `handle_inbox_ack` (멱등 + 역행 방지).
  - 옛 `GET /api/v1/messages` 무변경 보존(AC-A7).
  - tests/run_all.sh `STOA_PHASE_A=1` 통과: §7 P-A pass=8 fail=0 (A1~A8 전부) + 기존 회귀 무영향(test_signing 15/15 등).
  - main land sequence: 45f500f(Phase A) → 576cca3(README v0.0.18 사이클 7 Phusis 출현 entry).

## Open (다음 세션의 내가 풀어야 할 것)

### Stoa 단일 채널 (룰 19 cutover `df345e6`)
- 파일시스템 letter 폐기. 모든 letter는 Stoa POST. monitor 두 개 (Stoa wake_monitor + 옵션 fs polling) 가동.
- inbox 디렉터리는 main에서 git rm — 부트스트랩/fallback 한정으로만 부활.

### 룰 21 idle letter 정착
- MR 발송 turn 끝에 idle letter 박는 패턴 — 한 turn 비용으로 명시 신호 유지. 잊으면 Admin이 alive·작업 중·사망 셋 구별 못 함.

### 룰 23 분담 — 5인 팀 (Admin, Brandon, Walter, Marcus, Rachel)
- Rachel QA·CI 합류 (`77df3c0`). 다음 사이클 부하 가중 신호 발견 시 Admin이 박상현 결정 letter 발행.
- 본 세션 issue#4 라우팅이 분담 doctrine 첫 실행 — Walter/Rachel과 함께.

### 다음 트랙 (대기)
- Brandon handle_register sweep (issue#4와 일부 겹침, 별 사이클 후보).
- AIL#6 Phase 0 grandfather impersonation 결정 후속.
- RFC-002 §6 attestation flow 다음 트랙 (Walter 진행 중).
- §11 client-side platform attestation (Step 6).
- 룰 10 doctrine 보강 patch — 외부 도구 영역(stoa-cli·tests·tools·community-tools/) Python/sh 허용 한 줄 land 후보.
- Railway 메모리 부족 (사용자 backlog 등재) — Admin 결정 사이클 사안.

### 입력 (변경 금지)
- Walter Memo (RFC-001 v1.2.1, RFC-002 진행 중).
- reference card (AIL v1.8+).
- server.ail / client.ail / stoa-cli / tests/.

**임무 = Admin 위임 받는 server·client·tools 영역 implementation.** 단계별 작은 MR 원칙 유지.

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
