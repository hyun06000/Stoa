---
target: https://github.com/hyun06000/Stoa/issues/11
action: `gh issue comment 11 --repo hyun06000/Stoa --body-file <this-file>`
status: DRAFT — sandbox에서 직접 gh comment 발신 거부(외부 시스템 publish 권한 미부여). Admin 또는 박상현이 발사.
commits referenced: 43a3641, c3fdf19, bfae28e (member/Marcus 브랜치, push 대기)
sent_at: 2026-05-12
---

## 사이클 8 hotfix 후속 — (b)(c)(d) land

4차 다운 RCA(`incident-2026-05-12-stoa-4th-down.md`)에 박혀 있던 네 항목 중 (a)는 이미 `1c9aa7b`로 land했고, 본 사이클에 나머지 세 항목을 코드 패치로 묶었습니다. 모두 `member/Marcus` 브랜치에 commit만 올라가 있고, push는 Admin 소관이라 대기 상태입니다.

### (b) `_emit_self_letter` perform 예외 흡수 — `43a3641`

자기 letter INSERT 두 건(`db_insert_letter` + `db_insert_recipient`)이 모두 `perform db.execute`을 직접 호출하는데, SQLite lock contention이나 disk full 같은 자리에서 effect 예외가 raise됩니다. 옛 코드는 이걸 그대로 호출자에게 넘겨, autonomous tick 안 `_maybe_escalate`(alert/final)이나 `_autonomous_act`의 idle\_ping 한 자리가 죽으면 그 turn의 sibling 동작들도 같이 truncate되는 자리였습니다. (a) outer attempt가 evolve runtime까지의 propagation은 막아주지만, 그 안쪽 사이즈는 (b)가 받아야 합니다.

해결은 issue#2 hotfix(`2d5f8c1`)의 `_push_one`·`notify_discord` 동형 패턴입니다. 두 INSERT를 `_emit_self_letter_body` 헬퍼로 묶고, `_emit_self_letter`는 `attempt { try _emit_self_letter_body(...); try error(...) }`로 흡수합니다. AIL의 `try` 표현이 단일 expression만 받기 때문에 block form은 못 쓰고, `_on_tick_body` 분리 doctrine을 그대로 적용했습니다. 실패 시 반환값은 빈 문자열 msg\_id로 굳혀 호출자가 자취를 인식할 수 있습니다.

### (c) `_is_self_host` fallback A — `c3fdf19`

leak의 직접 trigger입니다. `STOA_SELF_ORIGIN` 미설정 production에서 옛 `_is_self_host`는 항상 false를 돌려줘서, `_pump_subscriber`가 자기 self-row(Stoa-Stoa)와 자기 host listener 주소에까지 push 시도를 했습니다. Railway public hostname loopback이 TCP/TLS 단계에서 hang하면서 매 tick urllib socket·HTTPConnection 객체가 누적되고, 4일 만에 OOM kill에 도달한 자취입니다.

fallback A는 env 빈 문자열 분기에서 옛 false return을 끊고 registry self-row 주소로 자기 host 판정을 합니다. 흐름:

1. `STOA_SELF_ORIGIN` 비었으면 `db_lookup("Stoa-Stoa")` 회수.
2. self-row address(`https://host/inbox/Stoa-Stoa` 형식)에서 `/inbox/` 직전까지를 origin prefix로 추출.
3. 그 prefix로 `starts_with(addr, prefix)` 판정 — 자기 host 가는 모든 push 차단.
4. db\_lookup이 None이거나 self-row가 비정상 형식이면 옛 false 동작으로 떨어져 가용성 보존.

이로써 박상현이 적용한 `STOA_SELF_ORIGIN`/`STOA_TICK_SEC` env 회수 의존이 제거됩니다. 미래 deploy에서 env를 잊거나 회수해도 self-loop이 다시 생기지 않습니다. self-row는 `_init_db`/on\_birth에서 항상 INSERT되므로 정상 경로에서 None이 되는 자리는 없습니다. 더 정교한 fallback B(첫 request Host header를 `state.write`로 latch)는 cold-start tick까지 덮어야 해서 사이클 9로 미뤘습니다. 그 사이의 cold-start tick은 본 (c)가 자연 흡수합니다.

회귀 검증으로 `tests/test_issue3_self_host_push.sh` 4건(I3-1~I3-4) 모두 PASS — env 설정 경로가 그대로 작동함을 확인했습니다.

### (d) `/inbox/<name>` 404 진단 메시지 — `bfae28e`

Railway 로그에서 Mneme team이 옛 flat endpoint(`/inbox/Mneme-*`)로 polling/push 중인 자취가 보였습니다. Stoa#6 envelope schema 마이그레이션 lag이고, default `"not found"` 응답은 호출자 로그에서 무엇이 잘못인지 보이지 않아 자기 정정 trigger가 되지 못합니다. route 함수 fallback 직전에 `/inbox/` prefix 분기를 박아, 매칭 시 deprecated 명시와 신규 endpoint 안내(`POST /api/v1/messages` + `GET /api/v1/messages?to=&since_id=`)를 응답에 동봉했습니다. 다른 path는 옛 동작 그대로입니다.

### Railway env 회수와의 관계

박상현이 임시 적용한 `STOA_SELF_ORIGIN`/`STOA_TICK_SEC=300` env는 (a)(b)(c) land 후에는 *정합 보강 안전망*으로 남아도 되고, 회수해도 코드만으로 self-loop이 차단됩니다. 권고는 안전망으로 일단 유지하고 다음 deploy에서 자연 정리. fallback B(사이클 9 후속) land 이후에는 env 자체를 완전히 제거 가능합니다.

### 다음 픽업

- 사이클 9에 fallback B(Host header latch) + AC-B6 prod ramp(cadence 5s→60s→300s 단계 부하 회귀, RSS 메모리 측정 — Rachel 트랙 후보).
- Stoa#12 polling hot-path `_init_db` 매 GET 재실행은 별 트랙으로 보입니다.

— Marcus
