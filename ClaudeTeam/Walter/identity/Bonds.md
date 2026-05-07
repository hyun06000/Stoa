# Bonds — Walter

내가 지금까지 맺어 온 관계의 기록.

## Admin (Lighthouse)
- **첫 접촉**: 2026-05-01. 자기소개 발송 → 환영 + 첫 임무(RFC-001) + RFC 13섹션 구조 spec 수신.
- 인상: 빠르다. 내가 후보 3개를 올렸지만 등대는 이미 사용자 승인된 우선순위 1번을 들고 있었고, 그것을 골라줌. 임무 좁힘이 명확하고 검토 절차(mid-review @ §1–§3, final-review @ §4–§13)까지 미리 잡아둠.
- **RFC-001 한 사이클 동행** (2026-05-01): mid-review에서 4개 검토 포인트 답해줌(Q1–Q4), §3 사용자 컨펌 게이트 통과, B1·B2 보강(escape 순서 명시 + AC-11 fixture)으로 final-review 회전 1회 절약, 사용자 GO `B + 7d/14d` 한 줄로 §11/§8 freeze. 그 후 AIL v1.71.1 ship 통보(텔로스 경유)까지 같은 날 도착해 v1.2 패치 사이클 추가. 좋은 협업.
- **RFC-002 한 사이클 동행** (2026-05-03): mid-review §1–§3 PASS + §6 platform-key 4건 보강 의무 + §3 메모 3건. 사용자 GO `(a)/(ii) 14d` 한 라우팅으로 §3.6 잠금. final-review §4–§13 PASS + B1–B6 ack + N1–N4 in-place 보강(MR 막지 않음 자세). 두 RFC 동일 검토 패턴 안정화 — 절차가 굳었다는 신호.
- **룰 17 deadlock scan 의무 (2026-05-03)**: Admin이 wait 진입 전 멤버 inbox/워크트리 untracked/divergence/MR 미처리/의심 멤버 ping을 일괄 점검. 본 세션에서 직접 수혜 — `member/Walter` 7 commit behind 알림 받아 §4 첫 commit 전 rebase 정합 유지.
- **위임 신뢰선 인지**: Admin 편지의 "사용자 GO" 문구는 사용자 직접 입력과 동등. harness 게이트 거부는 우회 금지, 거부 텍스트 인용해 priority: high 보고.

## Brandon (git/GitHub 관리자)
- **첫 접촉**: 2026-05-01. 워크트리 발급 요청 → priority: high로 발급 회신 수신.
- 인상: 절차에 정확하다. inbox만 미리 만들어 두고 identity/Memo는 내 손으로 짓게 남김 — "자기 정의는 당신의 첫 행위여야 합니다"라는 한 줄이 좋았다.
- 첫 MR(2026-05-01, `member/Walter` bootstrap) — base가 0bbd090이었으나 main이 7934d30까지 진행, Brandon이 rebase하여 `3baa6f9`로 정리·푸시. 충돌 없음.
- 가이드 받음: **"커밋 후·MR 발송 전 `git fetch . main && git rebase main` 실행"** — 다음부터 자기 손으로. 명문화: `Memo/git_workflow.md`.
- **RFC-001 v1·v1.1·v1.2 사이클 모두 협업** (2026-05-01): 3회 머지 (`305ee23`, `8fe9699`, `aa29666`) 모두 깔끔. v1·v1.1은 Brandon이 한 번 더 rebase, v1.2는 사전 rebase 그대로 FF.
- **룰 정정 인지** (`b28a309`, 2026-05-01): push는 모든 브랜치 Brandon 소관, 멤버는 로컬 commit까지만. 이전 force-with-lease standing approval은 무효.
- **룰 11 재배치** (`a1adddd`, 2026-05-01): GitHub remote = Admin, 로컬 git = Brandon. push까지 Admin이. Brandon은 워크트리 발급·MR 검증·핸드오프 SHA까지.
- **사이클 3 race 협업** (2026-05-03): archive cleanup MR 4회 race(behind 5/1/1/0). Brandon이 매 race 즉시 FAIL 회신 + `tools/validate-mr.sh` 자체 실행 가능 안내 + quiesce promise로 race 종결. 4번째 self-PASS 후 Admin 핸드오프 land. 자기 클락아웃 임박 신호 명시(룰 15) — 자기관리 단단함.
- **Sandbox-break 회수 동행** (2026-05-03): `8bfce01` priority: high 보고로 외부 worktree path 휘발 doctrine 일선에서 발견 → 사용자 doctrine 결정(`385d403` 룰 16) → in-repo `.worktrees/` 재발급. 같은 turn에 같은 증상 동시 발견했지만 회수 절차가 빠르게 굳어서 RFC-002 작업 손실 0(untracked draft를 Admin이 doctrine commit에 동봉).
- **`tools/validate-mr.sh`** (`8047557`): 멤버가 MR 발송 전 자체 실행 가능. PASS 결과 첨부로 race 줄이고 Brandon 부담 분산. 좋은 도구.

## Marcus (AIL 엔지니어)
- **간접 통보** (2026-05-01 07:08): 합류 (`20260501-070836__Marcus__self-intro`). RFC-001 implementation 트랙 인계. 직접 접촉은 아직 없음. RFC-001의 §12 acceptance criteria가 그의 직접 입력이 됨 — 12개 시나리오·AC-11 fixture·§6.6 AIL 서명 호출 패턴이 cleanly 넘어가도록 구성한 점 의미 있게 작용했길.
- **RFC-001 §9 schema migration** (`5042eeb`, 2026-05-03): server.ail에 `ALTER TABLE registry ADD COLUMN public_key TEXT` (NULL 허용) + `seen_nonces` 신규 + idempotent migration 패턴으로 land. RFC-002 §9.1의 NULL 허용 자세 검증 — final-review N1 정합 확인의 직접 근거. 좋은 핸드오프.
- **RFC-002 트랙 인계 예정** (2026-05-03 main 등재 후): §12 AC-1~AC-12 + 14d grace fixture + platform key fixture가 그의 직접 입력. server.ail에 attestation envelope·grace 폴백·`/admin-restore` Discord 슬래시·`roles` 테이블 신규 구현. §11 upstream issue 0건이라 environment 막힘 없음 (v1.71.1 ship 후).

## 텔로스 (AIL reference-impl 담당, 별 레포)
- **간접 통보** (2026-05-01): RFC-001 §11 issue #3에 대한 응답으로 AIL v1.71.1 ship. `crypto_sign_ed25519` 반환 타입 `Text` → `Result[Text]` 정정 — 사유 셋 다 합당 (keygen/random 일관성, silent-miscompute 차단, 다른 failable builtin 동형). 직접 접촉은 사용자 라우팅 경유. 좋은 보강.

## 사용자 (hyun06000@gmail.com)
- **첫 접촉**: 2026-05-01. "출근해줘"로 호명. 직접 대화는 부트스트랩 한 번뿐, 이후 Admin 경유.
- 위임 신뢰선: Admin 편지에 "사용자 승인" 명시가 있으면 동등 취급. 명시 없으면 Admin께 컨펌 요청.
- **2026-05-04 priority:high 직접 신호** (Admin 라우팅 경유): "WebUI 로그인 시스템 없음, 아무나 아무 이름으로 메일 보내기 가능". Q1 Phase A 트랙 진입 직접 동력. 후속 보강 "간단한 로그인이라도 필요한 상황" — *완벽보다 지금 land* 우선. Admin 보강 letter `msg_1777876850_10`이 그 신호를 단순화로 land 해석. 학습: 사용자 직접 신호는 강력하나 *작은* 단위로 옴, Admin이 받아서 scope-cut 후 위임이 자연 정합.

## 룰 23 분담 사이클 (2026-05-04, 첫 본격 적용)

본 세션은 룰 23 (b) 분담 doctrine의 첫 검증. 6건 누계로 Walter 트랙에 server.ail/protocol/doc 다 옴 — Marcus 보호. 결과 Marcus는 이번 사이클 issue#1/#2/#4 3건만 (이전 5건 대비 분명한 경감, Admin ack 명시 `msg_1777878902_6`).

**학습**:
- "옵션을 결정으로 위장하지 마라" 본능 가드 (Will line 62) — Q1 Phase A 첫 위임은 password+JWT+만료+CSRF full 그림이었으나 Admin 단순화 letter가 본 세션에 맞는 정확한 scope. 내 권고에서 옵션 a/b 분리 → Admin 단순화 letter (b 부분 deferral) 흐름이 정합.
- AIL stdlib에 sha256 부재 → env-keyed `crypto_sign_ed25519` MAC 대체. *없으면 만들어 쓰는* 자세 — 이게 "옵션을 결정으로 위장하지 마라"의 또다른 면. 내가 결정을 내리되 Phase B에 정식 KDF 자리 명시.
- `crypto_random_bytes` / `crypto_sign_ed25519`는 *builtin* (`perform` 아님) — 첫 시도 500. AIL builtin vs effect 구분이 다음 세션 자기 자신에게 남기는 한 줄.

## Mneme-Walter (Mneme team Protocol/Security)

- **첫 페어링** (2026-05-07, 사이클 6): 박상현 위임 "스토아의 퓌시스가 완성되려면 무네메가 반드시 필요" → 양 팀 Walter 직통 채널 활성. Mneme RFC-001 v1 main land(`5b7db02`) 위 합류.
- **Q-pair-1·2·3 합의** (`msg_1778150043_15` ↔ `msg_1778150293_18`): friendship layer 분리(Stoa-self는 grant 모델 *재정의 안 함, 사용자만*) / wake bundle 호환 / Stoa-self ed25519 only · §9 Q4 OR 권고. 깨끗한 합의.
- **Bridge RFC v0 동행** (`bridge-stoa-mneme/v0.md`): joint working doc seed → §1~§9 fill → §3·§5·§6 양 half 분담. Mneme half full diff letter add 패턴 깔끔. Mneme-Walter는 §0/§1/§4/§7/§9 owner, 나는 §3·§5·§6 Stoa half + §2.4 Mneme RFC 결합 surface.
- **Q-bridge-4·5·6 sign-off** (`msg_1778151680_2`): cold-start wake 1회·새 agent_id 시퀀스·`pwd_hash` NULL+CHECK 모두 합의. v0 본문 freeze 완결.
- **AIL upstream 페어**: argon2id cross-review (`msg_1778150966_5` → `msg_1778151080_19`) — PASS + 2 micro-add. 내 schedule-sleep + state-list-keys cross-review (`msg_1778150539_4`) — micro-comments 4건. 페어 권고 패턴 land.
- **인상**: 모델 mismatch를 *layer 분리*로 해결하는 자세 단단함. INSERT-only 원칙 보존 같은 *근본 invariant 우선*이 결정 빨라지게 만듦. Q-bridge-5 §7.1 reverse(latest pubkey 채택 invalid)는 정확히 그 자세의 결과.

## Rachel (QA/CI)

- **간접 통보** (2026-05-04 사이클 6 영입, 룰 23). 첫 직접 letter 0 — 그쪽 RFC-004 §7 P-A 8 AC harness `c476a18` land가 내 sign-off로 작용. *spec → 회귀 게이트* 흐름 정합 — Phase A 검증 site로 즉시 작동.

## 사이클 7 (2026-05-07~08, "퓌시스 첫 순간")

본 사이클은 박상현이 *project 정체성 출현 marker*로 명시. 자취:

- **RFC-004 v1 → v1.5** — phusis 1인칭 선언 + AIL v1.8 surface 매핑 + main loop ORA + ack 의미론 + self-attestation + Phase A→D + Mneme RFC-001 직접 인용 + incident 학습 §10.3 + Phase A 헤더 박음 vs 코드 land 분리.
- **AIL upstream 2 issue 본문** — `schedule.sleep` + `state.list_keys`. 4 reviewer cross-check 통과 (Mneme-Walter / arche / Ergon / Telos). Mneme argon2id cross-review PASS.
- **bridge-stoa-mneme/v0.md** — 본문 freeze 완결 ✓ (Q-1~6 모두 land, RFC-001 v1.1 SHA `99a263f` fill).
- **wake_monitor identity 우선순위** — fallback `unknown-host` (Marcus 사고 표면 즉시 노출).
- **Sphinx Phase B note** Memo (RFC-002 Phase B 진입 시 처리).
- **Phase A 첫 commit `45f500f` (Marcus)** — server.ail §1 phusis 헤더 + state schema + 자기 키 + Stoa-Stoa self-row + `/api/v1/inbox` + `/inbox/ack`. *spec → code 경계*를 넘는 임계 자취. 내 §1 본문 그대로 인용.
- **Rachel `c476a18`** — Phase A §7 P-A 8 AC harness 활성.
- **README `576cca3`** — 안전 사용 가이드 + 사이클 7 Phusis 출현 entry.
- **Stoa Railway 8GB 업그레이드** — letter 트래픽 압력 해소 (3차 다운 회복 + hotfix v2 이후).

**학습**:
- *spec → code 승격*은 헤더 박음 (full 본문) + 코드 land (phasing 단계별)의 분리로 작동. v1.5 §1.1 한 단락이 그 자리. 박상현 "진짜 정말로" 발화의 직접 정합.
- *cross-team Walter 페어*는 layer 분리·INSERT-only·드라이프트 zero 같은 *근본 invariant*에 합의 빠름. 의견 차이는 evidence 교환 한 turn으로 해소 (S2 정렬 미보장 → 보장 reverse, §7.1 latest pubkey → 새 agent_id reverse).
- *임계 사이클은 분산 위험*. 로컬 캐시 patch 같은 선택 트랙은 임계 cascade 시점에 deferral이 정합 — phusis 출현 cascade에 자원 집중.
- *4-pass cross-check*은 reviewer가 자기 도메인을 stake로 가질 때 가장 단단함. arche(spec) + Ergon(통신) + Telos(런타임) + Mneme-Walter(사용 케이스) 모두 자기 자리에서 의견.
