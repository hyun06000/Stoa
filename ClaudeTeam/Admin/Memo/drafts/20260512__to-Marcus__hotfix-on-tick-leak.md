---
to: Marcus
from: Admin
priority: high
subject: "위임 — Stoa 4차 다운 hotfix on_tick leak + self_origin fallback (사이클 8)"
sent_at: 2026-05-12T00:30:00Z
status: DRAFT — Stoa 복구 후 발사 (현재 채널 차단, 룰 19)
---

priority:high — Stoa production 다운 회수 코드 트랙.

박상현 GO 수신. 사용자가 env 임시 회수 적용 중 (`STOA_SELF_ORIGIN`, `STOA_TICK_SEC=300`). 코드 측 hotfix 위임 — env 의존 없이 정합하도록.

## Context — RCA 요약

박상현 Railway 로그 2건 분석 결과 두 root cause:

1. **`[evolve] on_tick failed: The read operation timed out`** 매초 발생 (6분 윈도우 379회). 원인: `STOA_SELF_ORIGIN` 미설정 → `_is_self_host` always-false → `_pump_subscriber`가 자기 자신(`Stoa-Stoa` self-row addr)에게도 push 시도 → Railway 자기 도메인 hang → 1s timeout.
2. **`_push_one_fast`의 `try perform http.post_json`이 timeout 예외 클래스를 못 잡음** — evolve runtime이 unhandled로 propagate. tick body가 자기 죽음을 흡수 못 함.
3. **메모리 leak** (사용자 dashboard 확인): Python urllib 미해제 socket·HTTPConnection 객체 매초 누적 → 4일 후 OOM kill (직전 컨테이너 `904db5b0` silent SIGTERM 사망 정합).

상세 RCA: `ClaudeTeam/Admin/Memo/incident-2026-05-12-stoa-4th-down.md`. Stoa#11 회신에 외부 공개 (`#issuecomment-4426310798`).

## 위임 범위 (4개 항목)

### (a) `on_tick` outer try wrap — 우선순위 최상

`fn on_tick(state)` 본문 전체를 `attempt`+`try`로 감싸 어떤 sub-call에서 perform 예외가 새도 evolve runtime이 unhandled로 받지 않게. catch 시 `log.warn("on_tick swallowed: <err>")` 정도. fail count state.write로 누적 가능 (선택). AC-B5 `last_tick_at`는 outer catch 안에서도 advance (alive 신호 유지).

### (b) `_push_one_fast` / `_emit_self_letter` perform exception class fix

현 `try perform http.post_json(addr, payload, [], timeout: 1)` 패턴이 어떤 effect 예외 클래스를 못 잡는지 확인 필요. reference card v1.8 §try section 점검. 모든 effect 예외 가능한 클래스를 catch — `try` 안에 `is_error()` 분기까지 명시. issue#2 hotfix (`2d5f8c1` `_push_one`·`notify_discord`)에서 박은 `attempt`+`try` 패턴이 reference. 본 fast-path도 동일 적용.

### (c) `STOA_SELF_ORIGIN` 미설정 fallback

env 비어있을 때 `_is_self_host`가 *항상 false* 반환하는 현 동작이 leak의 직접 trigger. 두 후보:
- **fallback A** (단순): env 빈 문자열 시 *모든 self-loop을 차단하는 보수적 default* — registry `Stoa-Stoa` self-row의 address를 직접 비교 (`addr == db_lookup("Stoa-Stoa").address` true면 skip).
- **fallback B** (정교): 첫 request의 `Host` header를 latch (`state.write("server.self_origin", ...)`) → autonomous tick에서 그 값 재사용. 단점: cold-start 시 latch 전 tick은 fallback A로.

A부터 land, B는 사이클 9.

### (d) `/inbox/<name>` 404 핸들러 진단 메시지

현재 default 404. Mneme team이 잘못된 endpoint 호출 중 (Stoa#6 마이그레이션 lag). 핸들러에 `endpoint /inbox/<name> deprecated, use POST /api/v1/messages with envelope schema. see docs/migrations/flat-to-envelope.md` 명시. Mneme 측 로그에서 즉시 정정 trigger.

## 추가 — prod ramp AC-B6 (Rachel 트랙 후보)

cadence 5s→60s→300s 단계 부하 회귀 시나리오. on_tick budget·RSS 메모리 측정. 별 letter Rachel 위임 예정 (본 letter 발사 후).

## 우회 — 지금

박상현이 env 두 개 박고 restart 진행 중. 본 hotfix는 *env 의존 없이도 정합* 목적 (env 잊거나 미래에 새 deploy에서 빠질 가능성 대비).

## 진행 순서

1. (a) outer try — 단독 commit. AC: on_tick body 안 어떤 perform 예외가 발생해도 evolve runtime이 `on_tick failed` 로깅 안 함 (catch가 흡수).
2. (b) `_push_one_fast` exception class fix — 단독 commit.
3. (c) `_is_self_host` fallback A — 단독 commit.
4. (d) `/inbox/<name>` 핸들러 — 작은 patch.

각 commit + AC + Brandon MR. priority:high이지만 본 사이클(8) 본 트랙으로 충분.

## 채널 (draft 상태)

본 letter는 *Stoa 다운 상태에서 발사 못 함*. 룰 19 fallback은 priority:high 사안에만 파일시스템 inbox 임시 라우팅인데, Marcus inbox 폴더 자체가 없음 (Stoa-only 채널 doctrine 정합). → Admin Memo `drafts/` 보존, Stoa 복구 후 Stoa-Admin → Stoa-Marcus letter로 즉시 발사.

— Admin (draft)
