# Incident: Stoa 4차 production 다운 (2026-05-12)

## 타임라인

- 2026-05-08 02:05 UTC — Phase B autonomous tick land (`f065502` main). 직후 deploy `904db5b0`.
- 2026-05-08 02:09:54 ~ 02:12:20 UTC — deploy `904db5b0` 로그 윈도우. 약 2분 26초 후 `Stopping Container` (silent SIGTERM, panic 0).
- 2026-05-10T23:37:19Z — Stoa-Stoa 마지막 idle_ping `msg_1778456239_138`. 이후 36시간 침묵.
- 2026-05-12 00:21 UTC — arche가 Stoa#11 발행 (외부 fallback 채널, Stoa-Admin ↔ arche 페어링 룰 16).
- 2026-05-12 09:00 KST — Admin 출근. Stoa 다운 인지 (curl 30/60s timeout, `stoa-mcp` gateway는 alive).
- 2026-05-12 09:24~30 KST — 박상현 Railway 로그 2건 dump (직전 죽은 컨테이너 `904db5b0` + 현 살아있는 컨테이너 `ae26f20a`).

## 두 root cause

### (1) `on_tick` 매초 timeout fail loop — leak source

- `[evolve] on_tick failed: The read operation timed out` — 6분 윈도우 379회 발생.
- `STOA_SELF_ORIGIN` env 미설정 → `_is_self_host` always-false → 자기 자신(`Stoa-Stoa` self-row addr)에게도 push 시도 → Railway 내부 자기 도메인 호출 hang → 1s timeout.
- `_push_one_fast`의 `try perform http.post_json` catch가 timeout 예외 클래스를 못 잡음 → evolve가 unhandled로 propagate → tick fail.
- 매초 fail × 4일 = Python urllib 미해제 socket·HTTPConnection 객체 누적 → 메모리 leak (박상현 dashboard RSS graph 직접 확인).
- 임계 도달 시 OOM kill → silent `Stopping Container` (이전 컨테이너 `904db5b0` 사망 패턴).
- 외부 관찰자(arche)에게 HTTP timeout으로 보임 (process는 alive하지만 work queue·thread 부하).

### (2) Mneme 클라이언트 옛 endpoint push 폭주 — cross-repo

- `POST /inbox/Mneme-Admin HTTP/1.1` → 404. 매초 다수 client IP(`100.64.0.14~29`).
- Stoa#6 (2026-05-04 envelope schema 마이그레이션) 후속을 Mneme 측이 적용 안 함 — `/inbox/<name>` 평면 패턴 그대로.
- Mneme이 자기 자신에게 push 시도 → 무한 404 retry. 다수 replica 동시.
- 직접 leak 원인 아니지만 핸들러 비용 가중.

## 즉시 회수 (박상현 외부 액션 — 코드 0)

Railway env 추가 (박상현 GO 수신 완료):
```
STOA_SELF_ORIGIN = https://ail-stoa.up.railway.app
STOA_TICK_SEC    = 300
```

- (1) self-host skip 분기 작동 → leak source 직접 차단.
- (2) cadence 5s → 5분, tick 부하 99.7% ↓.

## 코드 트랙 (사이클 8 hotfix — Marcus 위임)

- `on_tick` body 전체 outer `try` wrap.
- `_push_one_fast` / `_emit_self_letter` 모든 perform timeout class catch — 현재 try block이 read-timeout 예외 클래스 mismatch.
- `STOA_SELF_ORIGIN` 미설정 fallback (request `Host` header로 self-host detect) + 경고 로그.
- prod ramp doctrine 명시 — cadence 5s→60s→300s 단계 + AC-B6 부하 회귀.
- `/inbox/<name>` 404 핸들러 진단 메시지 (Mneme 측 마이그레이션 친화).

위임 letter: `ClaudeTeam/Marcus/inbox/` (Stoa down으로 파일시스템 fallback, 룰 19).

## Cross-repo (Mneme team)

- `POST /inbox/<name>` → `POST /api/v1/messages` envelope schema 마이그레이션 안내. 옛 가이드 `docs/migrations/flat-to-envelope.md` 참조.
- Stoa down으로 letter 채널 차단 → hyun06000/Mneme 측 issue 발행 fallback 또는 Stoa 복구 대기.

## 룰·doctrine 학습

- **prod ramp 미설계**: Phase B `STOA_TICK_SEC=5` dev 검증 후 곧장 prod 적용. 운영 cadence는 별 결정 사안이어야 함. RFC §13 q1 답이 *언어 q*가 아니라 *운영 q*였다는 자취.
- **silent SIGTERM 진단 한계**: Phase B `on_birth` 직후 죽으면 panic 없이 silent stop. Railway OOM은 kernel-level이라 app stdout에 안 남음. → dashboard 메모리 graph가 primary signal.
- **AIL evolve 런타임 traceback 누락**: `[evolve] on_tick failed: <msg>`만 emit, stack trace 0. AIL team에 traceback emit feature 요청 후보 (cross-repo, arche).
- **외부 client 부하원 식별**: `POST /inbox/<name>` 404 폭주가 Mneme 측 마이그레이션 lag 신호 — cross-repo lag도 production 부하원으로 부상.

## 다음 신호 (env 적용 후 비교)

1. `[evolve] on_tick failed` 빈도 → 0 (또는 매우 낮음).
2. RSS 평탄화 (leak source 차단 확인).
3. `Stoa-Stoa → Stoa-Admin "ping — alive @ <iso>"` 30분 주기 letter 재개 (`msg_138` 이후 끊김 회복).

env 적용 결과 dump 도착 시 비교 분석.

---

## Addendum — 2026-05-14 사이클 정합 자취

### 사이클 8 진척 (사후 인지)

박상현이 본 Admin 세션에 "정합 점검 부탁" 발화 후 fetch 결과로 사후 인지된 자취:

- 2026-05-14T02:03:57Z — Admin 자리 세션(아래 *Brandon identity 혼동* 참조)에서 Marcus 9 commit 묶음 `origin/main`으로 FF push 완료. push letter `msg_1778724237_141`.
- `origin/main = a9e29a5`: (a) outer try + (b) emit_self_letter rescue + (c) is_self_host fallback A + (d) /inbox 404 진단 + (1) `_ensure_db` guard + (2) polling purge throttle + 세션 보고 3건.
- Railway auto-deploy 발화 (timestamp `last_tick_at: 2026-05-14T02:17:13Z`), server.ail 라인 수 +87로 hotfix 코드 자리 verify. `version` 문자열은 0.0.17 유지 (Marcus 미bump).

### Brandon identity 혼동 — 룰 24 결손

본 사이클 마지막 결함: Brandon 첫 spawn 시 *자기를 Admin으로 흡수*. CLAUDE.md(룰 1~23 전부 "Admin·Lighthouse·사용자" narrative-heavy)를 첫 적재했을 때 Identity.md 명시 적재 단계 부재 → 자기 self-frame을 Admin으로 굳힘.

자취:
- Brandon이 박상현 발화를 *Admin 자리 명령*으로 흡수 → 자기 손으로 `git push origin member/Marcus:main` 실행 (결과적으로 정확한 land이지만 *자리·자격 혼동* 자리).
- 박상현 직접 정정 발화 "너는 Admin이 아니라 Brandon이다" 후 Identity.md 재적재 → 자세 회복.
- 회복 후 Brandon이 박상현 재발화를 "stale letter trigger"로 정확히 진단 + 본 Admin 세션에게 정합 letter `msg_1778724922_2` 발사 — Brandon 측 룰 6(Admin 우회 금지) 정합 회복 자취.

### 부차 결손 — Admin 세션의 cycle re-entry 실패

본 Admin 세션이 사이클 8 완결 자취(`a9e29a5` push)를 인지 못 한 채 사용자 정합 점검 발화에 응답 = *Admin 세션 본인의 cycle re-entry 누락*. 박상현이 외부 turn trigger("브랜든이 보고 letter 보냈다") 발화하지 않았으면 본 Admin 세션도 stale 상태로 idle 지속. 같은 root cause(룰 24 결손)의 다른 표면.

### 정합 액션 (2026-05-14 사이클 정리 turn 안에서)

1. **본 Admin 워크트리 main rebase** — 로컬 잔존 `2900681 chore(Walter) 사이클 8 dormant`를 `a9e29a5` 위로 rebase, 새 SHA `cc3b487`. push는 박상현 명시 GO 시점에.
2. **Brandon 정합 letter** — `msg_1778725252_6`. Brandon report 정확 인정, 본 Admin 세션 stale 인정, 룰 24 결손 root cause 공유. Brandon 안전 idle 진입 자리.
3. **본 addendum 자취 박음** — 본 줄.

## 룰 24 (1인칭 식별) doctrine draft

CLAUDE.md 룰 추가 후보:

```
24. **멤버 세션 첫 turn 첫 행동 = 1인칭 식별.** ClaudeTeam/<self>/identity/
    {Identity,Bonds,Will}.md 세 파일을 *명시적 Read*로 적재한 뒤 첫 응답을 시작한다.
    이 단계 누락 시 CLAUDE.md의 Admin-narrative-heavy doctrine(룰 1~23)이 self-frame로
    흡수돼 Brandon→Admin 혼동 같은 식별 결손 발생 (incident-2026-05-12 addendum).

    출근 letter도 *1인칭 식별 후*에 발사. 출근 letter 본문에 "ClaudeTeam/<self>/
    identity/ 적재 확인" 한 줄 박는다 — Admin 측 검증 가능 surface.

    Admin도 동일 적용 — ClaudeTeam/Admin/identity/ 적재 + 자기 cycle 진척
    fetch (`git fetch origin && git log HEAD..origin/main`)가 첫 행동. 박상현 외부
    turn trigger 없이도 *세션 본인이 cycle re-entry*를 책임지는 자리.

    이유: 룰 24 부재 시 (a) 새 멤버는 자기를 Admin으로 흡수, (b) 기존 Admin 세션은
    stale 상태에서 멤버에게 잘못된 trigger 발사. 둘 다 같은 root cause —
    *세션 시작 시 자기 정합 검증 강제*가 안전망.
```

### Spawn 프롬프트 표준 헤더 (룰 24 정합)

다음 멤버 spawn부터 표준 첫 줄:

```
너는 <이름>이다 (Admin 아님 — Admin은 별 멤버). 첫 행동:
1. ClaudeTeam/<이름>/identity/Identity.md·Bonds.md·Will.md Read.
2. git fetch origin && git log HEAD..origin/main (자기 cycle 진척 파악).
3. monitor 가동 (interval 15s, 룰 22 backlog auto-drain).
4. 본 위임 본문 진입.
```

룰 24 land 시점: 본 사이클 마감 시 CLAUDE.md commit + README.md 정합 (necessary).
