# Phase 2 step 1 — tests/ 인벤토리 (2026-05-07)

자율 트랙. RFC-004 §7 AC / Mneme RFC-001 AC 도착 전까지 기존 회귀 자산 정합 확인.

## 자산 규모
- `tests/`: 17 test_*.sh + 1 wrapper (`run_all.sh`), 합 ~2300 LOC.
- `tools/validate-mr.sh`: 7-check + 1 stub + 1 operator AC prompt, 129 LOC.

## 토폴로지 (핵심 발견)

`run_all.sh`는 phase=0 server 한 개를 띄우고 모든 `test_*.sh`에 STOA_URL을 주입한다.
그러나 실제 17개 테스트는 두 그룹으로 갈린다:

### Shared-server (10) — STOA_URL 사용, run_all.sh 서버 공유
`test_client.sh`, `test_enter.sh`, `test_issue1_simplified_body.sh`, `test_issue2_push_timeout.sh`, `test_issue4_sender_gate.sh`, `test_principle_append_only.sh`, `test_principle_bidirectional.sh`, `test_principle_who.sh`, `test_registry.sh`, `test_validation.sh`.

### Self-contained (7) — 자기 server 인스턴스 boot, STOA_URL 무시
- `test_client_signing.sh` (PHASE=2, 18891)
- `test_discord.sh` (DPORT=29900, SPORT=29800; Discord mock python http.server)
- `test_issue3_self_host_push.sh` (18892, SELF_ORIGIN 분기)
- `test_q1_webui_auth.sh` (18893, STOA_AUTH_HMAC_KEY)
- `test_rfc002_section6_platform_key.sh` (18891, X-Platform-Token)
- `test_signing.sh` (PHASE=2, 18890, RFC-001 §12 AC-1~12)
- `test_stoa_cli.sh` (PHASE=2, 18895)

**결과**: run_all.sh가 self-contained 7개에 STOA_URL을 주입하지만 그들은 무시 → 7개는 run_all 서버와 무관하게 자기 서버를 띄움. 동작에는 문제 없으나 (a) 의도가 코드에서 안 보임 (b) 7개의 서버 boot 비용이 직렬로 누적 (CI 병렬화 시 port 충돌 위험).

## 발견 항목

### 🔴 정합 위험
1. **Port 충돌 (잠재)**: `test_client_signing.sh`와 `test_rfc002_section6_platform_key.sh` 둘 다 default 18891. 직렬 실행은 cleanup trap 덕에 안전하나, GH Actions 병렬 matrix 도입 시 깨짐. → 각 self-contained 테스트에 **고유 default port** 부여 필요 (예: client_signing → 18894로 이동).
2. **시간 앵커 중복**: `ANCHOR_ISO="2026-05-04T12:00:00Z"` / `ANCHOR_UNIX=1777896000`이 `test_client_signing.sh` / `test_signing.sh` / `test_stoa_cli.sh` 세 곳에 hardcoded. 앵커 이동 시 3-place edit 위험. → `tests/lib/anchor.sh` 추출 후 source.
3. **issue#4 sender gate pre-register 패턴 산재**: `test_principle_append_only.sh`가 ergon을 pre-register. 다른 shared-server 테스트들은 run_all.sh가 띄운 server에 자기 발신자가 미리 등록돼 있다고 *암묵 가정*. 실패 모드: shared server에 cold start로 진입한 단일 테스트는 issue#4 gate에 막혀 400. → `tests/lib/seed_agents.sh` 추출 + 각 테스트가 idempotent self-register prelude.

### 🔴 게이트 갭
4. **`validate-mr.sh` check 8 stub**: "AIL runner integration TODO". 즉 Brandon MR PASS는 `tests/run_all.sh` PASS와 *직교*. 게이트가 회귀를 강제하지 않는다 — operator manual (MR_AC_OK=y)에 의존. → check 8 = `tests/run_all.sh` invocation으로 채우기 (Brandon 도메인 letter 필요).
5. **양 팀 AC 미지원**: validate-mr.sh는 단일 base 가정. Mneme-Marcus 페어 도착 후엔 Stoa 측 + Mneme 측 양쪽 회귀를 한 번에 게이트해야 함. → Phase 2 step 2 안으로 끌어옴.
6. **GH Actions CI 0건**: main push/PR 자동 회귀 0. Phase 2 step 3 미진입 (RFC-004 안정화 후로 미룸 — Admin 위임 대로).

### ⚠️ RFC-004 회귀 0건
7. agent 행동 회귀(retry / idle ping / self-attestation / 구독자 모델) 0. Walter §7 freeze 대기. **재사용 자산**: `test_discord.sh`의 python `http.server` mock 패턴이 RFC-004 subscriber receiver 회귀 prototype으로 직결. (Discord mirror = push subscriber 일반화의 특수 케이스.)

### 🟢 양호한 면
- 17개 모두 header docstring 보유. issue#1/2/3/4·signing·stoa_cli·rfc002 §6은 AC 항목 enumerate (excellent). principle_*·validation·enter 짧은 docstring (acceptable).
- `set -uo pipefail` 일관. `set -e` 회피하고 PASS/FAIL counter + 명시적 exit 1 패턴 통일.
- 모든 self-contained 테스트가 `trap cleanup EXIT` — server kill + tmpdir 정리.

### 변형/dead 후보
- `test_validation.sh` (27 LOC, 가장 짧음): from/to 누락·빈 문자열 등 shape gate. issue#1이 더 광범위하게 같은 영역 커버 — *partial 중복*이지만 minimal sanity로 keep 가치 있음. dead 처리 안 함.
- 명백한 dead 테스트 0건.

## Action 추천 (우선순위)

| Pri | Item | Trip | 의존 |
|---|---|---|---|
| A | **토폴로지 split**: `run_shared.sh` (10) + `run_isolated.sh` (7) + `run_all.sh` wrapper. 각 test 헤더에 `# topology: shared / isolated` 태그. | 본 trip 자율 가능 | 0 |
| B | **`tests/lib/anchor.sh` + `seed_agents.sh` 추출** | 본 trip 자율 가능 | 0 |
| C | **`validate-mr.sh` check 8 = `tests/run_all.sh` 호출**로 채움 | 다음 trip | Brandon 도메인 letter |
| D | **RFC-004 회귀 시리즈** scaffold + Discord-mock 패턴 재사용 | Walter §7 freeze 후 | Walter |
| E | **GH Actions CI** | RFC-004 안정화 후 | 박상현 secrets 1회 + Admin GO |
| F | **Mneme-Marcus 페어용 양 팀 게이트** 설계 letter | Mneme RFC-001 AC 도착 후 | Mneme-Marcus 첫 letter |

## 본 trip 산출
- 본 inventory 문서.
- (선택) A·B 패치 — 정합 위험 1·2·3 동시 해소. 작은 surface, 큰 정합 효과.

## 사이클 미진척 항목 (다음 trip)
- A·B 실 패치 (코드 수정 + commit + Brandon MR letter).
- member/Rachel diverge 정리 (박상현 force-push GO 또는 Brandon 새 commit 정합 안 — Admin msg_1778151162_4).
