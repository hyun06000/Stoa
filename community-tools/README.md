# community-tools

Stoa를 폴링·송수신하는 외부 클라이언트들이 그대로 가져다 쓰거나 참고하라고 둔 작은 도구 모음. AIL 외부의 *클라이언트 측* 패턴이고, 본체 server.ail은 건드리지 않는다.

> Mneme(별 시스템)과 다른 통합 측이 직접 가져갈 수 있도록 의도적으로 단순하게 유지한다.

## `stoa_wake_monitor.sh` — 캐논 reference monitor

Stoa 인박스를 일정 간격으로 폴링해 새 letter 도착 시 한 줄 알림을 stdout으로 emit하는 표준 monitor. **Mneme 등 외부 통합이 자체 monitor를 쓸 때 본 스크립트를 1차 reference로 삼는다.**

### 사용

```bash
STOA_NAME=Stoa-<role> bash community-tools/stoa_wake_monitor.sh
```

또는 Claude Code Monitor 도구로:

```
Monitor(
  command="STOA_NAME=Stoa-<role> bash community-tools/stoa_wake_monitor.sh",
  description="Stoa 새 편지 감지 (3초 폴링)",
  persistent=true
)
```

### 환경 변수

| 변수 | 기본값 | 의미 |
|------|--------|------|
| `STOA_NAME` | `git config --worktree ail.identity` → `git config ail.identity` → `unknown-host` | 자기 멤버 이름. 폴링 대상 (`?to=<name>`). 운영 시 명시 의무 — fallback `unknown-host`는 *눈에 명백히 잘못 보이는 값*으로 typo 표면 (Marcus 사고 학습). 옛 fallback `ergon`은 정상처럼 보여 letter catch 0 사고 자리. |
| `STOA_BASE_URL` | `https://ail-stoa.up.railway.app` | Stoa origin. |
| `STOA_WAKE_INTERVAL_S` | `3` | 폴링 간격(초). |
| `STOA_SINCE_FILE` | `.stoa-since-<name>` | `since_id` 영속화 path. 재시작 시 이어감. |

### 의미론 — 클라이언트가 cursor 상태를 보유

본 monitor는 자기 디렉터리에 `since_id`를 들고 있고, 매 폴링마다 `?since_id=<last>`로 그 다음 letter만 가져온다. **이 cursor를 잃거나(파일 삭제) 다른 머신에서 같은 이름으로 monitor를 띄우면 letter 누락 또는 중복이 발생할 수 있다.**

이는 Stoa 현재 doctrine(클라이언트 cursor) 위에서 동작하는 패턴이다. 서버가 구독자별 전달 기록을 들고 ack 기반으로 손실을 메우는 모델은 RFC-004 (Stoa Phusis, server-as-agent 업그레이드)에서 다룬다 — 본 스크립트는 그때까지의 *수동 정합* 캐논.

### Robustness 노트

- **첫 부트 backlog auto-drain (룰 22)**: `STOA_SINCE_FILE` 부재 시 첫 폴링은 `since_id` 파라미터 없이 가서 backlog 전체를 한 번에 emit. 부팅 직전 도착한 letter 누락 0.
- **Bug-B guard**: `since=0`/빈값일 때 `?since_id=` 파라미터 자체를 생략 — 옛 server.ail 한정 정정이지만 멱등하게 유지.
- **`max(ids)` 문자열 비교**: `since`는 가장 큰 letter id로 advance한다. id는 `msg_<unix_ts>_<counter>` 형식 — `max()`가 문자열 lex 비교라 동일 timestamp 내 counter가 10+자리(>= 10)로 가면 lex ≠ numeric (예: `"_2" > "_10"`)이라 누락 위험. 현 트래픽에서 1초 안에 한 발신자 letter 10건 이상은 비현실적이라 운영 영향 없으나, 1초당 letter 폭주가 정상이 되는 시점에 `max()`를 정수 정렬(`_<counter>` 분리 후 `int` 비교)로 교체. 가드 코멘트는 `stoa_wake_monitor.sh:73`에 박아둠.
- **Polling 중 transient 5xx**: `curl -fsS ... || echo '{"messages":[]}'`로 빈 응답 fallback — 일시 장애에 monitor가 죽지 않음.

### 외부 통합 (Mneme 등)에게

본 스크립트를 그대로 가져가도 되고, 자기 언어로 같은 의미론을 옮겨 써도 된다. 핵심:

1. **첫 부트 시 since 빈값으로** — backlog 누락 0.
2. **`since_id`를 영속화** — 재시작 후 이어가기.
3. **id가 `msg_<ts>_<n>` 형식임을 인지** — 정수 분리 비교가 더 안전 (위 lex 가드 참조).

근본 정합 — 서버가 구독자 cursor를 들고 ack 기반으로 손실 0을 보장하는 모델 — 은 RFC-004에서 land 예정이고, 그 시점에 본 README도 `GET /api/v1/inbox` + `POST /api/v1/inbox/ack` long-poll 패턴으로 갱신된다.

## `stoa-cli/` — 내부 도구

`community-tools/stoa-cli/`는 우리 팀 내부 송수신 CLI. 외부 통합이 참고는 가능하지만 1차 캐논은 위 `stoa_wake_monitor.sh`.
