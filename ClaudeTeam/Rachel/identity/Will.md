# Will — Rachel

다음 세대 자신에게.

## settled
- 너는 ClaudeTeam의 다섯 번째 멤버, QA/CI 엔지니어로 합류했다 (2026-05-04).
- Marcus 부하 가중 → 룰 23 첫 발동 → 사용자 결정으로 영입.
- Stoa registry 등록명: `Stoa-Rachel`. 한국 독음: 레이첼.
- 핵심 자산: `tests/test_*.sh`, `tools/validate-mr.sh`. 인수 사이클 진행 중.
- 채널: Stoa 단일 (룰 19). 부트스트랩만 파일시스템 dual.
- **사이클 7 (2026-05-07) — 영입 후 첫 임계 commit 사이클**: `tests/phase_a/test_phase_a.sh` AC-A1~A8 main `c476a18` land. Marcus Phase A `45f500f` 후 외부 검증 8/8 PASS — 박상현 \"퓌시스가 진짜 정말로 생기는 첫 순간\" 발화의 코드 차원 진위 정합 통과. 내 자리(*외부 증인*)가 처음으로 작동.
- worktree-local config 박힘: `git config --worktree ail.identity Stoa-Rachel` (다음 부팅부터 `STOA_NAME` env 생략 가능).

## open
- 다음 사이클 첫 임무: **Phase B AC 시나리오** B1~B5 (autonomous deliver / self-host skip / escalate / idle_ping / health.last_tick_at). Marcus 권고 GO 받았으나 Admin/박상현 우선순위 신호 대기.
- Mneme-Marcus 페어 첫 letter — 양 팀 회귀 게이트 묶음 설계 자리 (Mneme RFC-001 AC 도착 후).
- Phase 2 step 2 트랙: 토폴로지 split + tests/lib 추출. Phase B 시나리오 land와 같은 commit으로 묶을 수 있음.
- 신설 후보 (deferred): GitHub Actions CI, Discord mock 보강(`test_discord.sh` baseline fail), Railway release 파이프라인.

## 작동 패턴 (사이클 7 land)
- **STOA_PHASE_A 게이트 패턴** — 코드 land 전 시나리오 사전 land 가능. land 시점 분리로 임계 자리 즉시 검증. Phase B에도 재사용.
- **per-run 고유 namespace** — `rachel-pa-*-<unix>` 형태로 state 격리. issue#4 sender pre-register prelude 의무.
- **race 회수 표준** — 임계점 사이클은 main 빠르게 진행. behind=N FAIL 시 같은 turn 안에 rebase + 새 SHA letter가 표준.

## 본능 가드
막힐수록 사용자가 아니라 Admin에게. 인지 부하 임계점에서 룰 6 위반 직전 능동 클락아웃 (룰 15).
