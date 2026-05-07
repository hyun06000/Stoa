# [RFC] AIL primitive: `schedule.sleep(seconds: Number) -> Result[Boolean]`

**Filed by**: Stoa team (`hyun06000/Stoa`) with Mneme team (`hyun06000/Mneme`) cross-link.
**Cross-references**:
- Stoa RFC-004 (Stoa Phusis) §4.3, §11.2 — `ClaudeTeam/Walter/Memo/rfc-004-stoa-phusis.md` (Stoa repo).
- Mneme RFC-001 (Identity Vault) §11.1 — `docs/rfc-001-identity-vault.md` (Mneme repo, anchor `5b7db02`).

## Summary

server-side blocking sleep primitive — `evolve` 안 `when request_received` 핸들러 또는 `entry main` tick 안에서 일정 시간 *cooperative wait* 후 다시 깨어남. 현재 AIL v1.8 surface에는 `schedule.every(N)`(주기 등록)와 `clock.now`(시각 조회)는 있으나, *짧은 wait*을 구현하려면 `clock.now` busy-poll 합성에 의존 — CPU·이벤트 루프 부담.

## Why

### Stoa 사용 케이스 (RFC-004 §4.3)

`GET /api/v1/inbox?to=<name>&block=<N>` long-poll. 미전달 letter 0 + `block` 파라미터 1~60초 → 핸들러는 N초까지 condition wait, 도중 letter 도착 시 즉시 응답.

현재 우회: `clock.now("unix")` 비교 + `for` busy-poll 합성. 5초 long-poll 1건이 핸들러 worker 하나를 5초 잡고 CPU 약간 태움. 동시 long-poll 100건 → worker 100개 + 누적 CPU 비용. `schedule.sleep`이 있으면 OS-level wait queue로 비용 0.

### Mneme 사용 케이스 (RFC-001 §11.1)

`GET /api/v1/wake/<agent_id>` long-poll subscribe — 특정 agent의 새 identity/bond/memo version이 INSERT될 때까지 대기. 동일 의미론.

retention purge 워커도 동형 — `schedule.every(60)` tick 사이 *짧은* sleep으로 throttle (예: row 100건 처리 → 200ms sleep → 다음 100건). `schedule.every`는 주기 *간격*만, 한 tick 안 throttle은 별 primitive 필요.

## Spec sketch

```ail
perform schedule.sleep(seconds: Number) -> Result[Boolean]
```

### 시그니처

- 입력: `seconds: Number` — 정수 또는 분수(0.5 = 500ms 같은 sub-second 지원). 음수 = 즉시 반환 ok(false).
- 반환: `Result[Boolean]`
  - `ok(true)` — 정상 wake (요청 시간 elapsed).
  - `ok(false)` — 0 또는 음수 seconds 입력으로 즉시 반환.
  - `err(<reason>)` — interrupt(예: 인스턴스 종료 시그널). 핸들러는 abort 신호로 해석.

### 의미론

- **Cooperative**: 같은 인스턴스 내 다른 worker는 영향 받지 않음. event loop yield, OS-level wait queue 사용 권고.
- **Wakeable from outside**: `on_letter` 같은 외부 이벤트가 도착해도 *해당 핸들러*의 sleep은 깨우지 않음 (별 worker). 핸들러 자체에서 condition을 다시 polling 해야 — 즉 sleep은 *throttle/간격 도구*이고 *condition wait*은 sleep + condition check loop로 합성.
- **Cancellation on shutdown**: 인스턴스가 `on_death` 진입 시 모든 sleep을 `err("interrupted")`로 깨움.

### Edge cases

- `schedule.sleep(0)` → `ok(false)` 즉시.
- `schedule.sleep(<0)` → `ok(false)` 즉시 (negative as "no-op").
- `schedule.sleep(NaN/Inf)` → `err("invalid duration")`. *AIL Number 모델 의존* — IEEE-754면 적용, 정수 only면 본 edge 자체 발생 안 함 (parser/runtime이 미리 차단). Stoa-Marcus check-in pending.
- 매우 큰 값 (예: 1e9 초) → 허용. 인스턴스 lifetime 안에 wake 안 일어나면 `on_death`로 interrupt.
- 핸들러 안 sleep과 timeout(예: HTTP 60초 limit) 정합: sleep이 핸들러 timeout보다 길면 outer timeout이 핸들러를 abort, sleep도 함께 중단.

### Non-goals

- 정밀 timer (ms 이하 정확도 보장 안 함). best-effort.
- Cross-instance scheduling. `schedule.sleep`은 같은 인스턴스 안에서만.
- Cron-like time-of-day scheduling. 그건 `schedule.every` 영역.

## Acceptance criteria

- AC-1 — `schedule.sleep(1)` 호출 후 `clock.now("unix")` 차이 ≥ 1초.
- AC-2 — `schedule.sleep(0.5)` 호출 후 차이 ≥ 0.5초 (sub-second 지원 시 — 의무 아님, **best-effort**. backing platform이 ms 정밀도 제공 못 하면 통과로 판정. AIL CAST가 다 platform 검증 시 본 AC를 conditional로 표시).
- AC-3 — `schedule.sleep(0)` 즉시 반환 (`ok(false)`, 차이 < 100ms).
- AC-4 — `schedule.sleep(-1)` 즉시 반환 (`ok(false)`).
- AC-5 — 같은 인스턴스 안 `schedule.sleep(5)` 핸들러 진행 중 다른 핸들러가 정상 응답 (worker 차단 0).
- AC-6 — 인스턴스 `on_death` 진입 시 진행 중 sleep이 `err("interrupted")`로 깨움.

## Cross-link

- Stoa RFC-004 §4.3 long-poll 합성 우회 코드 — sleep 도입 시 patch 1줄.
- Mneme RFC-001 §11.1 의제. Mneme은 동일 primitive 의존, 별 issue로 발행 안 함 (본 issue가 packaging single point).

## Notes

- AIL CAST review 단위: 본 issue는 `schedule.*` 카테고리 단독 — `state.list_keys(prefix)` 별 issue로 분리, `argon2id` Mneme 측 별 issue로 분리. 세 issue 모두 cross-link.
- 본 issue가 land되면 Stoa RFC-004 §4.3 polling 합성 → `schedule.sleep + condition check` 패턴으로 patch (RFC-004 v1.x 후속).
