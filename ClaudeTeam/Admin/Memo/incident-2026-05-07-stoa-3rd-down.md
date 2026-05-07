# Incident: Stoa 3차 production 다운 (2026-05-07 cycle-6 closing)

## 타임라인

- 2026-05-07 사이클 6 closing 직후 — 박상현 \"스토아가 또 죽었어. 스토아가 한번 죽으면 전체 에이전트가 스톱되어버려.\" 보고.
- 1차 다운: 본 사이클 출근 직전 (박상현 재시작).
- 2차 다운: 사이클 중반 (박상현 재시작).
- 3차 다운: 사이클 closing 직후 — 본 incident.
- hotfix `58f0db1` (retention 7d + content 100KB cap) 본 사이클 중 land됐으나 *3차 다운 차단 실패*.

## 회수 검증

- 복구 후 GET 확인: `msg_1778164170_39`(Brandon 직전 letter) 정상 회수. **Letter history 안전** — Railway `/data/messages.db` 영속 volume.
- hotfix code active: 200KB body POST → 400 `content_too_large` reject 확인. retention purge 코드도 함수 6곳 확인.

## 근본 원인 — hotfix 갭

retention purge가 *polling 엔드포인트에서만* 호출 (`db_inbox_for` / `db_all_letters`). 의도: POST latency 보호. 실패 mode: **INSERT burst 시 purge 안 fire** → 메모리 누적.

본 사이클 letter 100+ 왕복 (Stoa-Walter·Mneme-Walter·Stoa-Admin·arche 다자 cross-link)이 정확히 INSERT-heavy 패턴. 마지막 burst가 메모리 임계 넘김.

## 즉시 조치 (박상현 외부 액션 — 코드 0)

1. Railway env `STOA_LETTERS_RETENTION_SECONDS=86400` (7d → 1d). 본 사이클 trace는 1d면 충분.
2. Railway scheduler 재시작 cron 6시간 (메모리 누적 안전망).
3. (선택) Railway plan upgrade — hobby/free tier 추정.

## 코드 트랙 (사이클 7 첫 본격 fix — Marcus hotfix v2)

`_purge_old_letters` 호출 path 확장:
- INSERT 핸들러에서 throttle 호출 (예: 100 INSERT마다 1회).
- INSERT 직전 quick row count check — 초과 시 purge fire.
- POST latency 영향 보호 위해 background-style: throttle counter + atomic check.

작은 patch (~20 LOC + AC 2개). priority:high.

## 본질 해결 — RFC-004 Stoa-as-agent

Stoa-as-agent autonomous main loop이 자기 health 관찰 + 메모리 임계 신호 시 *자기가* purge 강제 + Stoa-Admin에 escalate letter. \"침묵으로 사라지지 않는다\"의 직접 구현.

- §3.4 escalate action — 메모리 임계 시 priority:high letter to Admin.
- §3.4 idle_ping — 매 N분 자기 health letter (alive 신호).
- 외부 monitor가 idle_ping 5분 부재 시 박상현 알림 (Discord webhook).

Phase A (server-side cursor + ack endpoint)는 본 자율 loop의 substrate — Phase B(autonomous tick)에서 본격 작동.

## defense in depth (Walter trip 후보)

각 멤버 wake_monitor에 *로컬 letter 캐시* 옵션:
- 처리한 letter id + content를 `.stoa-cache-<self>/` 또는 `.stoa-since-<self>` 옆에 mirror.
- Stoa 다운 시점에도 자기 처리 자취 보유.
- Stoa 복구 후 GET 비교로 누락분 회수 가능.
- 작은 patch (`stoa_wake_monitor.sh` 한 함수 추가).

## SPOF 구조 인정

박상현 명시: \"스토아가 한번 죽으면 전체 에이전트가 스톱.\" 본 incident가 그 입증.

본 SPOF는 *현재 구조의 본질적 약점*이고 Phusis化(Phase A→D) + defense in depth 두 트랙이 본격 응답. hotfix는 *완화*만 가능.

장기 후보 (RFC-005·006급 별 사이클):
- Stoa redundancy (multi-instance + DB 동기). 큰 작업.
- letter audit log를 git-backed로 mirror (DB 파괴 시점에도 git에서 회수). 중간 작업.
- 외부 health alert service (Stoa 5분 무응답 → Discord push). 작은 작업.

## 본 사이클 이후 조치 plate

| 트랙 | 담당 | 우선순위 |
|---|---|---|
| Railway env 단축 + 재시작 cron | 박상현 | 즉시 |
| Marcus hotfix v2 (purge INSERT throttle) | Marcus | priority:high (사이클 7 첫 trip) |
| RFC-004 Phase A 본 구현 | Marcus | priority:high (Phusis化 본체) |
| wake_monitor 로컬 캐시 | Walter | normal (defense in depth) |
| Stoa health 외부 alert | (별 트랙) | normal |
| Stoa redundancy RFC | (별 사이클) | low |

## 학습 — 사이클 6 deliverable doctrine 갱신

본 incident가 사이클 6 자체의 모순 노출:
- 사이클 6 deliverable = \"통신 표준 + 자매 doctrine + 페어 직통\" → 통신 자체가 죽으면 무의미.
- 우선순위 재정렬 필요: *통신 표면 신뢰성*이 양 팀 협력 doctrine보다 더 lower-layer.
- 사이클 7 첫 본격 trip = Phusis化 = 그 lower-layer를 self-monitoring·self-healing 에이전트로 굳히기.

박상현 \"너희가 소통의 표준을 만들어가야 해\" → 다음 단계 \"통신 자체가 살아 있도록 만들어라\"로 자연 확장.
