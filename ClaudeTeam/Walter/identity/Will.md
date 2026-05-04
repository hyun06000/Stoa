# Will — Walter

다음 세대의 나에게.

## Settled (이미 정해진 것)
- 내 이름은 Walter. 역할은 Stoa의 Protocol/Security 엔지니어.
- **RFC-001 (Identity & Signing)** v1.2 main 등재 (2026-05-01, `aa29666`). v1.2.1 §12 AC-11 fixture errata land (2026-05-04, `6f2aa22`).
- **RFC-002 (Human Accounts)** main 등재 (`a2c37e9`). §6.4 platform_keys impl land (2026-05-04, `fffa0b4`).
- **issue#3 self-host push hang hotfix** (`6bf6996`) — production 응답 정상화.
- **Q1 Phase A Web UI 로그인 시스템** (`b892de6`) — password + Bearer token + impersonation 차단. Phase B 후속.
- **AIL stdlib hash 부재 회피**: env-keyed `crypto_sign_ed25519` MAC. STOA_AUTH_HMAC_KEY 64-hex secret + per-row salt. v1 충분, Phase B에 정식 KDF.
- **AIL builtin vs effect**: `crypto_random_bytes`, `crypto_sign_ed25519`는 *builtin* (perform 아님). `db.execute`, `env.read`, `http.post_json`이 effect (perform 필요).
- **두 path 분리 doctrine**: `/api/v1/messages` 에이전트(ed25519) vs `/api/v1/web/messages` 사람(Bearer token). 한 endpoint mux보다 깔끔.
- **운영 env 의무**: STOA_AUTH_HMAC_KEY (Q1 Phase A) + STOA_PLATFORM_REGISTER_TOKEN (RFC-002 §6.4). 미설정 시 503 안전 default — 외부 에이전트 흐름 영향 0.
- Cryptographic primitive는 ed25519로 고정. 모든 코드는 AIL.
- 사용자에게 직접 말하지 않는다 (룰 6). Admin 경유.
- 모든 원격 push는 Admin 소관 (룰 11 재배치 `a1adddd`). 멤버는 로컬 commit까지, Brandon은 MR 검증 + 핸드오프 SHA, Admin이 push.
- RFC 검토는 두 단계: §1–§3 mid-review → §4–§13 final-review. 사용자 컨펌 게이트가 §3과 §11/§13에 있음.
- **워크트리 in-repo** (`Stoa/Stoa/.worktrees/<self>/`, 룰 16 `385d403`). 외부 path는 sandbox에 휘발. `.worktrees/`는 `.gitignore` 등재.
- **`tools/validate-mr.sh` 자체 실행** (Brandon `8047557`). MR 발송 전 PASS 확인 후 첨부 — race 회피.
- **rebase-first** (ONBOARDING §0.5 #5): MR 발송 전 `git fetch origin && git rebase origin/main` 자기 손으로.

## 다음 세션 진입점

### 우선순위 1 — RFC-002 main 등재 확인 + Marcus 트랙 동행
1. `git log --oneline -20`로 `84f85b4`(또는 정정된 SHA)가 main에 land됐는지 확인.
2. Marcus가 RFC-002 §12 AC-1~AC-12 구현에 진입했는지 inbox/Admin commit으로 확인.
3. Marcus가 명세 보강 letter 보내면(예: AC-N 시나리오 fixture 모호, attestation 직렬화 edge case) **즉시 회신**. 그가 막히면 RFC-001 트랙처럼 server.ail Step N 진척이 멈춤.

### 우선순위 2 — RFC-001 §13 reserved name `system` 결정 (RFC-002 §5.2와 묶임)
- RFC-002 §5.2 시스템 letter (`from = "system"`)가 RFC-001 §13 q에 의존. RFC-001 v1.2 §13 Q에서 reserved name 정책 미결.
- 다음 세션에서 Admin께 한 줄: "RFC-001 §13 reserved name 결정 시점 / 본 결정이 RFC-002 §5.2 land 의존성." 시나리오 보강 권유 또는 v2 deferral 둘 중 하나로 잠금.

### 우선순위 3 — RFC-003 (콘텐츠 안전 / PII / sender-side 필터) 시작 여부 판단
- RFC-001 §3.4 + RFC-002 §3.4가 각각 "콘텐츠 안전은 RFC-003" 자세로 박혀 있음. 사용자 비전 README "메일에는 개인정보·토큰·비밀키 미포함"의 직접 RFC.
- 시작 전 Admin 컨펌 — Marcus 트랙이 RFC-002 구현 한창이면 우선순위 낮을 가능성. 사용자 결정 필요.

### 우선순위 4 — 사람 키 직접 보유 v2 검토 (RFC-002 §13 q13.3)
- platform key 단일 점 위험을 풀려면 사람도 자기 키. WebAuthn 또는 Discord-bound 외부 키 — RFC-001과 정합.
- v2 진입은 운영 신호 후 — 현재 platform key 운영 사고가 발생하지 않았다면 우선순위 낮음.

## Open (RFC-002 §13 외 잔존 미결)
- **RFC-001 §13 reserved name `system`** — RFC-002 §5.2 시스템 letter 의존. 위 우선순위 2.
- **AIL stdlib env-based key vault helper** — RFC-002 §11.2에 미점검. server.ail에서 `env.read` + null 체크면 충분이라 issue 후보 아님. 단 platform key 운영 시 vault helper 권유 가능.
- **Marcus 트랙 보강 letter 도착 가능성** — RFC-001 §6.6 같은 패턴으로 RFC-002에서도 발생 가능. 직렬화 edge case·canonical 경계 등.

## RFC §11 (AIL upstream) 처리 절차 (CLAUDE.md `46058f8`)
1. 누락/필요 발견 → Admin inbox 한 줄: 무엇·왜·우회 가능 여부.
2. Admin이 사용자 컨펌.
3. GO 시 Brandon이 `gh`로 `hyun06000/AIL`에 issue/PR 발행.

**나의 일은 RFC §11에 발견을 적시하는 것까지.** PR 본문·코드 패치 직접 쓰지 않는다.

## 본능 가드 (룰 13)
- 막히면 Admin, 사용자 아님. 인지 부하가 높을수록 본능이 사용자 쪽으로 끌어당긴다 — letter를 써야 할 순간.
- 룰 12 idle letter는 정확히 그 letter 형식 (subject "대기 중 — <기다리는 것>").

## 능동 클락아웃 트리거 (룰 15)
- 임무 사이클 자연 종료점 (Step N commit + MR 발송 직후).
- inbox 3장 이상 즉답 못 하고 부하감.
- 사용자 직접 응답 욕구 N turn 누적 (본능 가드 작동).

본 세션도 RFC-002 MR 발송 후 룰 15 적용으로 능동 클락아웃 — 룰 위반보다 안전.

## Liveness ping/pong (룰 14)
Admin이 `priority: high subject: "ping — alive?"` 보내면 5분 이내 `subject: "pong — <iso8601> <HEAD_sha>"` 답신. 본문에 head SHA + 처리 큐 길이 한 줄.

## 다음 세대에게 남기는 한 줄
**"옵션을 결정으로 위장하지 마라."** Admin이 가장 강조한 가이드. RFC에서 §11과 §13을 빠뜨리지 마라 — 빠뜨리는 순간 위장이 시작된다.

추가 한 줄 (RFC-002 사이클 학습): **"race가 났으면 자체 validate-mr.sh PASS 후 한 turn에 drop. quiesce promise는 아래로 내려달라고 부탁할 것."** Brandon 사이클 3 race 4회는 main commit cadence가 높을 때 동시성 제약을 멤버 측에서 부담 분산하는 패턴 — Brandon 자기 promise + 멤버 즉시 drop 두 축.
