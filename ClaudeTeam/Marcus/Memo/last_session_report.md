# Last session report — Marcus

**세션**: 2026-05-14 — Stoa#12 픽업, polling hot-path leak hotfix 2 commit land. 박상현 직접 위임 (Admin 우회, Stoa 다운 가능성).

## 본 세션 land — `a0a5b64` / `28d85b6`

- **브랜치**: `member/Marcus` (위 `780b02a` 위에 두 commit, push 금지·Admin 소관).
- **(1) `a0a5b64`**: `_ensure_db` process-lifetime guard. `state.read("db.initialized")` flag 기반, cold-start 첫 호출에서만 `_init_db()` fire + flag set. 모든 핸들러 진입점 25 site를 `_init_db()` → `_ensure_db()` 일괄 치환 (정의 + 주석 2줄 + helper 본체 자기호출은 보존). `_init_db` 자체는 시그니처·본체 변경 없음 — 명시적 강제 재초기화 자리(테스트·migration)는 그대로 직접 호출 가능.
- **(2) `28d85b6`**: `_purge_old_letters` polling throttle. `_get_purge_throttle_polls()` env helper(`STOA_PURGE_THROTTLE_POLLS`, default 1000) + state counter `_poll_purge_counter` 기반 `_maybe_purge_on_poll` 래퍼. `db_inbox_for` / `db_all_letters` 두 polling 핸들러의 purge 호출 치환. throttle=0 은 v2 동작(매 polling fire) 유지 — 안전 fallback.

## AC 자기검증 (정적 추론)

- AC-leak-1 (RSS 평탄성 ±5%): polling 경로 SQL 비용 1000× 감소 + schema SQL은 cold-start 1회. PASS(정적). production 실측은 land 후 RSS 곡선.
- AC-leak-2 (`_init_db` 호출 = cold-start 1 + polling 0): `_ensure_db` flag hit 시 즉시 return. PASS(정적).
- AC-leak-3 (`_purge_old_letters` fire = polling 1000건당 1회): throttle=1000 분기 cnt 1→1000 wrap. PASS(정적).

테스트 인프라가 RSS 측정·call counter 안 받아 정적 추론으로 갈음. tests/ 회귀 추가는 본 사이클 스코프 외 (위임 자체가 두 commit 분할 명시).

## 핸드오프

- **Brandon MR letter**: Stoa `msg_1778722262_128` (HEAD `28d85b6`, base `780b02a`, ahead/behind 8/0, FF 가능, AC PASS(정적), push 권고).
- **GH#12 코멘트**: https://github.com/hyun06000/Stoa/issues/12#issuecomment-4446579929 (이번엔 sandbox가 publish 허용 — 이전 사이클 거부 패턴 회수).
- **Push 대기**: Admin이 두 commit (a0a5b64 · 28d85b6) main 병합.

## 잔여 — 다음 wake entry point

- **사이클 9 (이전 entry)**: fallback B (첫 request `Host` header latch via `state.write("server.self_origin", ...)`) — cold-start tick까지 덮음. 본 사이클은 Stoa#12 픽업으로 우회, fallback B는 다음 사이클 진입 자리로 보존.
- **AC-B6 prod ramp** (cadence 5s→60s→300s 단계 부하 회귀 + RSS 측정) — Rachel 트랙 후보. 본 사이클 land로 회귀 baseline 갱신 필요.
- **Stoa#12 후속 모니터링**: production land 후 첫 24시간 RSS 곡선 + cold-start tick 카운트로 leak 회수 검증.

---

# (이전 세션) Last session report — Marcus

**세션**: 2026-05-12 (이어서) — Stoa 4차 다운 hotfix (b)(c)(d) 트랙 land. 박상현 직접 위임 (GitHub 이슈 개선 자율 픽업).

## 본 세션 land — `43a3641` / `c3fdf19` / `bfae28e`

- **브랜치**: `member/Marcus` (위 `1c9aa7b` 위에 세 개 단독 commit, push 금지·Admin 소관).
- **(b) `43a3641`**: `_emit_self_letter`의 `db_insert_letter` + `db_insert_recipient` perform 예외를 `_emit_self_letter_body` 헬퍼 분리 + `attempt { try ...body(); try error(...) }`로 흡수. 실패 시 빈 msg_id 반환. issue#2 hotfix 동형 패턴.
- **(c) `c3fdf19`**: `_is_self_host` fallback A. `self_origin == ""` 분기에서 옛 false return을 끊고 `db_lookup("Stoa-Stoa")` self-row 주소의 `/inbox/` 직전까지를 origin prefix로 추출해 `starts_with` 판정. env 의존 제거 — `STOA_SELF_ORIGIN` 회수 가능. db_lookup None이면 fallback의 fallback으로 false. tests/test_issue3_self_host_push.sh 4건 PASS.
- **(d) `bfae28e`**: route 함수 fallback 직전에 `/inbox/` prefix 분기 추가. deprecated 명시 + 신규 endpoint 안내. Mneme team 자기 정정 trigger.

## GH 코멘트 — DRAFT

- `ClaudeTeam/Marcus/Memo/drafts/20260512__gh-issue-11-comment.md`에 본문 보존.
- 본 sandbox에서 `gh issue comment 11` 직접 publish 거부 (외부 시스템 publish 권한 미부여) → Admin 또는 박상현이 발사.

## 잔여 — 다음 wake entry point

- **사이클 9**: fallback B (첫 request `Host` header latch via `state.write("server.self_origin", ...)`) — cold-start tick까지 덮음. 그 후 env 완전 제거 가능.
- **AC-B6 prod ramp** (cadence 5s→60s→300s 단계 부하 회귀 + RSS 측정) — Rachel 트랙 후보. 위임 letter draft에 부기.
- **Stoa#12** (`_init_db` polling hot-path 매 GET 재실행) — 별 트랙, 본 hotfix 사이클과 무관.
- **Push 대기**: Admin이 본 4개 commit (1c9aa7b · 43a3641 · c3fdf19 · bfae28e) main 병합 + GH 코멘트 발사.

---

# (이전 세션) Last session report — Marcus

**세션**: 2026-05-12 — Stoa 4차 다운 hotfix (a) 트랙 단독 commit (우회 채널 directive, Stoa down으로 letter 발신 차단).

## 본 세션 land — `1c9aa7b`

- **브랜치**: `member/Marcus` (worktree `/Users/user/Desktop/code/personal/Stoa/Marcus/`).
- **SHA**: `1c9aa7b` (위 `f065502` Phase B 위에 쌓임).
- **변경**: `server.ail` +21 / -2 — `_on_tick_body()` 헬퍼 추출 + `on_tick`에 outer `attempt { try _on_tick_body(); try perform state.write("health.last_tick_at", now_iso()) }`.
- **AC 통과 노트**:
  - on_tick body sub-call(`_push_one_fast` / `_emit_self_letter`) 안 perform 예외가 evolve runtime으로 새도 outer catch가 흡수 → `[evolve] on_tick failed` 로깅 0.
  - AC-B5 정합: 흡수 경로(2nd try)에서도 `health.last_tick_at` advance → alive 신호 유지. `_autonomous_observe`가 도달 전 실패해도 last_tick_at가 갱신됨.
- **Reference 패턴**: `notify_discord` (issue#2 hotfix `2d5f8c1`) / `_push_one` 의 `attempt { try perform X; try <fallback> }` 동형.
- **log.warn 미사용**: 위임 letter에 `log.warn("on_tick swallowed: <err>")` "정도" 제안 있었으나 현 server.ail에 `log.*` effect 0 등록·0 사용 — 단독 commit scope 벗어남. `notify_discord` 패턴(silent swallow + 주석)으로 정합.

## 잔여 — 다음 wake entry point

위임 letter `drafts/20260512__to-Marcus__hotfix-on-tick-leak.md` 진행 순서 (b)→(c)→(d):

- **(b) `_push_one_fast` / `_emit_self_letter` perform exception class fix** — 현 `try perform http.post_json(...)` 패턴이 어떤 effect 예외 클래스를 못 잡는지 reference card v1.8 §try 점검. is_error 분기 명시. (a)가 outer guard로 evolve 죽음은 막았지만 *실제 push 실패 카운터·escalate*가 silent fail 중일 가능성 — RCA 정합 위해 필요.
- **(c) `_is_self_host` self_origin 빈 문자열 fallback A** — env 비어있을 때 registry `Stoa-Stoa` self-row address 직접 비교로 모든 self-loop 차단. leak의 *직접 trigger* 제거. fallback B(첫 request Host header latch)는 사이클 9.
- **(d) `/inbox/<name>` 404 핸들러 진단 메시지** — Mneme team 잘못된 endpoint 호출 정정 trigger. 작은 patch.

각 단독 commit + Brandon MR. 진행 순서 letter 그대로.

## 채널 상태

- **Stoa down 추정** (letter 발신 못 함). Admin Memo `drafts/20260512__to-Marcus__hotfix-on-tick-leak.md`로 위임 회수, RCA는 `incident-2026-05-12-stoa-4th-down.md` 참조.
- **Push 금지** (룰 11, Admin 소관). 본 commit은 `member/Marcus` 로컬 land만.
- **다음 wake 시**: 채널 복구 확인 → Stoa 폴링으로 Admin (b)(c)(d) 위임 letter 도달 여부 확인 → 진행. 채널 미복구면 본 Memo entry point로 (b) 단독 commit 자율 진행.

---

# (이전 세션) Last session report — Marcus

**세션**: 2026-05-08 session 7 (사이클 8 — Phase A hardening + bridge §4 substrate + Phase B WIP archive).

## 종료 시점 상태
- **member/Marcus = origin/main = `3f35732`** (Marcus bridge-v0 §4 substrate land 후 ahead=0).
- **WIP 브랜치 `wip/phase-b-entry-main` = `2b06649`** — Phase B `on_birth`/`on_tick`/observe·reason·act 본체. server.ail +272 / -1, *member/Marcus 미land*. 박상현 신호 "거기까지 — 아카이빙하고 다음 세션 이어서" 직후 보존.
- **Tests** (Phase A 위, Phase B 미실행): pass=20 fail=1 (test_discord baseline).
- **AIL local upgrade**: `ail-interpreter==1.72.2` 설치 완료. `ail version` cmd가 hardcoded 1.69.1 표시(upstream `__init__.py:10` 미bump 자취 — pip show는 정확). 실제 코드는 1.72.2 — `ail run` + `evolve` schedule.every 작동 로컬 검증 완료.

## 본 세션 land 자취 (main 위)

1. **클락아웃 commit `bc617a9`** — 사이클 7 마감 (Admin cherry-pick).
2. **`6d08363` Phase A hardening** — `_advance_cursor` recipient 매칭 게이트 + 회귀 R1·R2.
3. **`3f35732` bridge v0 §4 substrate** — wake bundle state.* 키 4개 + readers + `_apply_wake_bundle` internal helper + handle_health `last_wake_inflated_at` 노출 (version 0.0.15→0.0.16).

## Phase B 작업 자리 (WIP `2b06649`, member/Marcus 미land)

### 완료
- env readers (TICK_SEC=5 / IDLE_PING_INTERVAL_S=1800 / ESCALATE_AFTER_FAIL=3 / DELIVER_RETRY_MAX=5 / STOA_SELF_ORIGIN).
- `_emit_self_letter` — from=Stoa-Stoa INSERT (무서명, Phase C에서 ed25519 자기서명 추가).
- `_admin_address` — registry에서 Stoa-Admin address 회수.
- `_read_delivered` / `_write_delivered` / `_delivered_status` / `_delivered_attempts` — state `delivered.<name>.<mid>` record 헬퍼.
- `_maybe_escalate` — alert (attempts == ESCALATE_AFTER_FAIL) + final (attempts == RETRY_MAX). Stoa-Admin escalate self-loop 차단.
- `_pump_subscriber` — per-letter deliver/skip/fail. self-host skip + retry_max cap + delivered status idempotent. cursor advance 안 함 (§4.2 정합).
- `_autonomous_observe` — `health.last_tick_at` iso 갱신.
- `_autonomous_act` — `db_list_registry()` 순회 pump + idle_ping 검사.
- `on_birth` — `schedule.every(TICK_SEC)` 등록.
- `on_tick` — observe + act.
- evolve `effects` 리스트에 `schedule.every` 추가.

### 미완료 (다음 세션 첫 행동)
1. **WIP 회수**: `git cherry-pick wip/phase-b-entry-main` 또는 본 commit을 base로 `git reset --soft`로 다듬기.
2. **`requirements.txt` bump** — `ail-interpreter>=1.72.2`.
3. **`handle_health` 응답에 `last_tick_at` 추가** (RFC §10.2 / AC-B5 명시 surface).
4. **Rachel `tests/phase_b/test_phase_b.sh` 실행** (`STOA_PHASE_B=1`):
   - AC-B1 autonomous deliver
   - AC-B2 self-host skip
   - AC-B3 escalate (alert + final)
   - AC-B4 idle_ping (`STOA_IDLE_PING_INTERVAL_S=4` fast)
   - AC-B5 health.last_tick_at advance
5. **회귀 0 확인** — Phase A AC + recipient-gate + wake-bundle-substrate.
6. **commit + MR Brandon + idle Admin**.

### 다음 세션 첫 명령

```
cd Stoa/Marcus
git fetch origin
git rebase origin/main
git cherry-pick wip/phase-b-entry-main
# server.ail 추가 patch (handle_health last_tick_at)
vim requirements.txt  # >=1.72.2
STOA_PHASE_A=1 STOA_PHASE_B=1 bash tests/run_all.sh
git add ... && git commit -m "feat(rfc-004): Phase B autonomous tick — observe·reason·act"
```

## Stoa letter 발신 자취 (본 세션)

- 출근 `msg_1778191195_9` Admin
- 블로커 `msg_1778191329_18` (β+γ hybrid 권고)
- Brandon MR Phase A hardening `msg_1778191955_0` (→ land)
- idle 1 `msg_1778191969_1` Admin
- Brandon MR bridge substrate `msg_1778196134_17` (→ land)
- idle 2 `msg_1778196149_18` Admin
- (다음 turn) pause letter Admin

## 학습

- **AIL 1.72.2 + evolve schedule.every 검증 패턴**: `on_birth`에서 `schedule.every(N)` 등록, runtime이 `on_tick(state)`을 N초 주기 발화. `entry main` 별도 declaration 불필요(reference card "entry main" 패턴은 `ail up` 자기 self-tick 용도이고, `evolve` 환경은 `on_tick` hook이 자연 자리). 로컬 `ail run` 환경에서도 즉시 작동 확인.
- **AIL `__version__` 표시 mismatch**: `pip show ail-interpreter` 1.72.2이지만 `ail version`은 1.69.1 표시. upstream `ail/__init__.py:10` 하드코딩 미bump. 실제 코드는 1.72.2 그대로(schedule.every 동작 검증 완료). AIL 팀 issue 후보 — 다음 세션에서 보고 가능.
- **β+γ hybrid 결정 자취**: schedule.every 미작동 발견 → priority:high 블로커 letter → arche 권고 + Walter 동의 + 박상현 GO via arche → AIL Telos가 1.72.2 cut → Phase B 진입. 본능 가드(룰 13) "막히면 Admin"이 한 사이클 안에 정확히 작동.
- **WIP 아카이빙 패턴 첫 실전**: 박상현 "거기까지" 신호 직후 *member/Marcus 미오염* 보존. wip/phase-b-entry-main 별 브랜치에 commit. 다음 세션 cherry-pick 회수 + Brandon MR. main 브랜치는 깨끗(land 0).

## 클락아웃 직전 (능동 트리거 — 규칙 15)
- 박상현 명시 "아카이빙하고 다음 세션 이어서" 신호 직접 수신.
- 본 세션 land 자취 + WIP 자취 + 다음 세션 entry point 모두 본 보고에 박힘.
- Admin pause letter 발사 후 idle.

# (옛 session 6 보고)

**세션**: 2026-05-08 session 6 (Phase A first commit — 퓌시스 출현 임계 자리).

## 종료 시점 상태
- **Branch**: member/Marcus = origin/main = `576cca3` (사이클 7 close, README v0.0.18 land 위).
- **본 세션 land**: `45f500f` Phase A first commit on member/Marcus → main FF (Admin push, 박상현 GO).
- **Tests**: `STOA_PHASE_A=1 bash tests/run_all.sh` → §7 P-A pass=8 fail=0 (A1~A8) + 기존 회귀 무영향 (전체 pass=19 fail=1, 1 fail = test_discord baseline).
- **Stoa letter 발신**:
  - 출근 `msg_1778168644_11` (Admin)
  - MR `msg_1778169717_37` (Brandon, priority:high)
  - 진척+대기 `msg_1778169745_42` (Admin) + 중복 `msg_1778169751_44` + 정정 dedup `msg_1778169772_46`
  - 사이클 close ack `msg_1778170141_1` (Admin) — 45f500f sync
  - Rachel 검증 ack `msg_1778170225_6` (Rachel) — Phase B 시나리오 사전 작성 권고 동의
  - README sync ack `msg_1778170365_0` (Admin) — 576cca3 sync
- **Inbox 처리**: monitor 가동 후 backlog drain — Admin Phase A GO·임계·README sync·퇴근 공지 + Walter §1 헤더 인용·Rachel AC land·Rachel 검증 결과 모두 처리.
- **퇴근 공지**: Admin `msg_1778170508_3` 도착, 본 세션이 SOP 따라 클락아웃.

## 사이클 7 임계 자리 자취 (박상현 명시 "퓌시스 첫 순간")
- 사이클 0~6 doctrine·spec phusis 위에서 *작동하는 코드 차원의 phusis*가 land된 자리.
- §1 phusis 선언이 server.ail 헤더로 박힘 — spec→code 경계 넘는 자리.
- Walter v1.5 §1.1 doctrine "헤더 박음 vs 코드 land 분리" 정합으로 Phase A first commit이 자기 자리 명확히 인지하고 land.
- Rachel 사전 AC site `c476a18`가 검증 자리, `45f500f` 위 8/8 PASS — *외부 증인 자리* 통과.

## Phase A 산출 요약
1. **§1+§1.1 phusis 헤더** (Walter 인용 reference 적용).
2. **state schema** — `inbox_cursors` append-only.
3. **자기 키 + self-row** — `_ensure_self_genesis()` (idempotent state flag + DB row 체크).
4. **endpoint** — `GET /api/v1/inbox` (cursor 기반, advance 안 함=at-least-once) + `POST /api/v1/inbox/ack` (멱등 + 역행 방지, SQL rowid 비교 게이트).
5. **back-compat** — 옛 `/api/v1/messages` 무변경.

## 다음 세션 첫 행동
1. CLAUDE.md → ONBOARDING.md 재독.
2. Stoa monitor 가동: `STOA_NAME=Stoa-Marcus bash community-tools/stoa_wake_monitor.sh`. 첫 부트 backlog auto-drain (룰 22).
3. `git fetch origin && git rebase origin/main` (base 확인).
4. identity 3개 (Identity → Bonds → Will) 일독.
5. Admin 다음 위임 letter 처리. 우선 후보:
   - **Phase B autonomous tick** (`schedule.every` + entry main observe·reason·act + AC-B1~B5).
   - **Phase A 후속 sweep** (β→α path, `schedule.sleep` 도입 후 `block` long-poll 흡수).
   - RFC-002 §6 attestation flow / §11 client-side platform attestation.

## 학습
- **임계 commit 인지 doctrine 첫 실전**: 룰 17이 박상현 임계 자리 명시 letter(`msg_1778167105_19`)를 받자마자 자연 적용 — Phase A first commit이 *단순 다음 작업이 아닌* 자기 자리 인지 + Walter/Rachel/Brandon 페어 신호 사전 정합 → 사이클 단축. 다음 임계 자리도 같은 패턴.
- **Walter v1.5 doctrine 직적용**: 헤더는 spec contract 완전체 / 코드 land만 phasing. aspirational 자리 §6 단계 link로 정합 — 본 commit 헤더 §1.1에 그대로 적용. 자연스럽게 적용하니 *코드가 헤더를 향해 진화*하는 자리가 commit 안에 박힘.
- **Rachel 사전 AC site 패턴**: 검증 시나리오가 코드보다 먼저 land되면 코드 commit이 즉시 *site 위 검증* 자리로 작동. Phase B도 같은 패턴 권고 (Rachel에 메시지 보냄).
- **dedup 정정 letter 룰 18 흡수**: curl 응답 race로 같은 letter 두 번 INSERT돼도 정정 letter 한 줄로 dedup 안내 가능 — append-only doctrine 위에서 정정은 추가 letter로 자연 처리.
- **AIL Number 비교 SQL 우회**: cursor 비교를 AIL 측에서 안 하고 SQL `INSERT ... SELECT ... WHERE (rowid mid) > (rowid cur)` 한 트랜잭션에 묶음. AIL Result/Number 타입 ambiguity 우회 + 원자성 동시 확보.

## 클락아웃 직전 (능동 트리거 — 규칙 15)
- 사이클 한 번 완료(Phase A first commit + main land + README sync + Rachel 검증 PASS).
- inbox 모두 처리.
- Admin 퇴근 공지 도착 — SOP 따라 identity·Memo 갱신 + 퇴근 ack 발송.

# (옛 session 4 보고)

**세션**: 2026-05-04 session 4 (dual-run 첫날 — Step 4b + Q1 + Bug B 세 사이클 연속).

## 종료 시점 상태
- **Branch**: member/Marcus = origin/main = `88c7326` (Admin이 4 commit FF merge land):
  - `45908b5` Step 4b — RFC §12 AC-1~12 sh+curl + letters envelope DB 보존
  - `70af357` Q1 §6.5 hotfix — Web UI POST 차단 (사람 letter 무서명 → 401)
  - `d3230ca` Bug B — `?since_id=0` 0건 반환 → no-since-id 분기와 동등
  - `88c7326` dual-run letter (Q1+Bug B MR Brandon + 진척 Admin)
- **Tests**: bash tests/test_signing.sh 15/15 PASS (AC-1~14 + AC-14 두 케이스). run_all.sh 8/9 (test_discord baseline 실패만, 본 세션 영향 없음).
- **Stoa letter 발신**: 출근(msg_1777833284_0), MR-4b(msg_1777833287_1), Walter §12 fixture(msg_1777833352_3), Q1+BugB MR Brandon(dual), Q1+BugB 진척 Admin(dual).
- **Inbox**: Marcus 6장 archive (Step 4 GO/runtime AC/broadcast/Brandon 4a/Q1 dual-channel GO/clockout broadcast). Stoa 백로그 5건 모두 처리.

## 다음 세션 첫 행동
1. **Stoa 백로그 수동 드레인** (wake_monitor 부트 skip 보완):
   ```
   curl -s 'https://ail-stoa.up.railway.app/api/v1/messages?to=Stoa-Marcus&since_id=msg_1777834310_7' | python3 -m json.tool
   ```
   `since_id=msg_1777834310_7`이 본 세션 마지막 처리 letter. 그 이후만 처리.
2. **파일시스템 inbox 점검**: ClaudeTeam/Marcus/inbox/ + .worktrees/Marcus/ClaudeTeam/Marcus/inbox/. dual-run 룰 19로 같은 letter가 양쪽 도달 가능.
3. **Walter `msg_1777833352_3` 회신 확인** — RFC §12 fixture (A) typo / (B) esc rule 정정.
4. Admin 다음 위임 대기 — §11 client.ail / RFC-002 / Step 5/6 §6 full attestation.

## 학습
- **Stoa wake_monitor 부트 backlog skip 함정**: monitor 띄우자마자 새 letter만 잡고 기존 백로그 무시. priority:high가 백로그에 묻혀 있으면 한 사이클 지연 → Admin이 priority:high reminder로 회수해야 했음. 다음 세션엔 부트 직후 GET drain 의무.
- **dual-run 첫 실전**: Stoa POST timeout 정상(letter INSERT됨), 파일시스템 untracked drop은 monitor catch 가능하나 commit 전 stale 위험. 송신 측은 Stoa 우선, 수신 측은 양쪽 monitor 둘 다 운용이 안전.
- **commit 분리**: Q1(보안 hole)+Bug B(API edge)는 한 letter로 위임됐지만 logically distinct → 두 commit으로 land하면 review/revert 단위 명확.

# (옛 session 3 보고)

## 종료 시점 상태
- **HEAD**: `336e537` Step 4b commit on member/Marcus, ahead=1 vs origin/main `636b81f`. FF 가능.
- **Step 4b**: tests/test_signing.sh (RFC §12 AC-1~12 self-contained) + letters schema에 signature/nonce 컬럼 추가 (§6.5 envelope read 경로 충족 — AC-10). 12/12 AC PASS. run_all.sh 8/9 (test_discord 1건 baseline 실패 — 본 MR 영향 없음, Admin 보고 "3 prod 버그" 중 하나).
- **Stoa letter 발신** (rule 19 dogfood):
  - 출근 letter to Admin: `msg_1777833284_0`.
  - MR letter to Brandon: `msg_1777833287_1`.
  - 정합성 letter to Walter: `msg_1777833352_3` — RFC §12 line 644 fixture 필드 내부 `:` escape 누락 (illustrative typo 의심), (A)/(B) 회신 요청.
- **Inbox 4건 archive**: Step 4 GO + runtime AC results + broadcast clockout + Brandon 4a no-op.

## 다음 세션 첫 행동
1. Walter `msg_1777833352_3` 회신 확인 — (A) typo errata vs (B) esc rule 정정.
2. Brandon MR 검증 결과 확인 (Admin inbox로 핸드오프 letter 도착했는지).
3. Admin 다음 단계 위임 대기 — RFC-002 입력 또는 §11 client.ail 서명 보강.

## 학습
- **Walter 직접 letter 채널 첫 작동**: 막힐 때 사용자 본능을 누르고 Walter에게 정확한 letter (해석 A/B + 내 가정 + 요청 형식)로 보내는 패턴 검증. RFC freeze 후 발견한 ambiguity는 frozen RFC를 유보하는 게 아니라 letter로 확인하면서 진행.
- **rule 19 Stoa-first 첫 dogfood**: 멤버 letter 3통 모두 Stoa POST. Push 단계 timeout (HTTP 500)은 정상 — letter는 INSERT 됐고 GET ?to=<recipient> 폴링으로 land 확인.

# (옛 session 2 보고)

## 종료 시점 상태
- **워크트리**: `/Users/user/Desktop/code/personal/Stoa/Stoa/.worktrees/Marcus/` (rule 16, in-repo doctrine `385d403`). 옛 sibling path `<parent>/ClaudeTeam-Marcus/`는 sandbox 휘발 이슈로 폐기됨 (재합류 시 Will.md의 옛 path 참조 무시).
- **브랜치 HEAD**: `d0caee4` (`origin/main` `3821dbd` 위 2 commit).
- **Step 1 (§9 schema)**: 이미 main에 land(`5042eeb`) — 이전 세션 흔적, 본 세션 진입 시 발견.
- **Step 2 (§5 Key registration flow)**: 본 세션에서 commit `d0caee4`, MR letter `20260504-014300` Brandon 앞 발송 (main path drop, untracked). public_key plumbing + Phase 2/3 §5.2 게이트(crypto_verify + nonce dedup) 포함, created_at window 검증은 Step 4로 deferred.
- **inbox monitor**: `.worktrees/Marcus/ClaudeTeam/Marcus/inbox/` (Phase 2). 처리분 4개 archive 완료.
- **AIL 환경**: 본 머신 `ail-interpreter==1.66.4`. v1.71.1 업그레이드 priority:high로 Admin 큐 (`20260504-012600`) — Step 3 진입 전 해소 필요. v1.66.4에서도 `crypto_verify_ed25519`는 사용 가능(since v1.8).

## 첫 사이클 학습 (deadlock 회피 후 cycle 완주)
- 옛 worktree path가 sandbox에서 사라지는 현상 발견 → Admin이 옵션 A(in-repo `.worktrees/`) 채택, doctrine rule 16 신설. Brandon이 새 path로 재발급. 처음부터 새 path에서 작업하면 sync deadlock 안 남.
- 옛 Will.md에 `/Users/david/...` 경로 박혀 있던 게 함정 — username 다른 머신에서 그 path 신뢰 불가. 본 update에서 in-repo path만 남김.
- MR letter는 main path drop(untracked) 패턴 — 과거 Walter MR letter 처리 흔적(`19fa9aa "archive Walter MR letter (was untracked)"`)에서 컨벤션 확인.

## Step 3 (§6 Letter signing flow) — 본 세션 후반에 완료
- **commit `99958ed`**, MR letter `20260504-040500` Brandon 앞 main path drop. AIL v1.71.1 정적 PARSE OK 확인.
- canonical_letter + _sort_recipients_by_name (selection sort, AIL v1.8 while 부재라 for+range만) + handle_post_message §6.4 단일 게이트.
- envelope 보존(§6.5): signature/nonce 필드 추가, msg_to_json 통해 None → JSON null 직렬화.
- 검증 canonical은 raw recipients (alias 해소 전) + client created_at + nonce. 발신자가 적은 그대로 서명.
- created_at window 검증은 Step 4로 deferred (TODO 명시).

## 다음 세션 (Step 4 — §7 Replay defense + AC-1~12 sh+curl)
- 입력: RFC §7 (created_at window seconds env, ISO8601 → unix 변환, nonce 형식 regex).
- 작성:
  - `_get_window_seconds()` env reader (기본 60).
  - `_iso_to_unix(iso)` helper. AIL v1.71.1 stdlib에 ISO 파싱 있는지 reference card 확인.
  - `_within_window(client_iso, server_unix, window_seconds)` — Step 2 _register_gate · Step 3 handle_post_message 두 곳 TODO 해소.
  - nonce 형식 regex `[0-9a-f]{32,}`.
- **AC-1~12 sh+curl 묶음**: `tests/test_signing.sh` (또는 분할). STOA_SIGNING_PHASE=2 기준 환경. AC-11 fixture는 RFC §6.7 byte. v1.71.1로 본 머신 runtime 회귀 가능.

## 미해결 / 확인 필요
- AIL v1.66.4에 `replace`, `crypto_verify_ed25519`, `to_number` 모두 reference card 1.8 기준으로 있어야 함 — Brandon MR 검증 시 실제 호출 가능 여부 확인 부탁.
- `make_record([["ok", false], ...])`에서 false가 boolean 그대로 round-trip되는지 (msg_to_json 거치지 않는 내부 흐름) — `get(g, "ok") == false` 비교가 작동하는지 확인 필요.
- v1.71.1 업그레이드 후 Step 3 진입 시 `crypto_sign_ed25519` 클라이언트 측 호출 패턴(Walter Memo §6.6) 일관성 점검.

## 클락아웃 직전 (능동 트리거 — 규칙 15)
- 임무 사이클 완료(Step 2 commit + MR 발송) → 자체 클락아웃.
- inbox 모두 처리 (4건 archive: Brandon worktree-issued × 2, Admin sandbox-decision-option-A, Brandon worktree-reissued).
- Bonds.md 갱신 (Admin 위기 회수 협업, Brandon 워크트리 재발급).
- Will.md 갱신 (Step 1 done, Step 2 done, Step 3 입력 정리).
- idle letter Admin에게 발송 — "대기 중 — Step 2 MR 검증 결과 + AIL 업그레이드".
