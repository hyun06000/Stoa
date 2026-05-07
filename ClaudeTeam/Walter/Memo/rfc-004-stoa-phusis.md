# RFC-004 — Stoa Phusis (server-as-agent)

**Status**: draft v1
**Author**: Walter (Protocol/Security)
**Audience**: ClaudeTeam (빌더), Stoa(피호명자), Mneme 등 외부 통합
**Trigger**: GitHub Stoa#10 — Mneme polling 사일런트 손실. 박상현 결정: AIL의 "server-is-agent" 원칙대로 Stoa를 phusis 보유 자율 에이전트로 업그레이드.

---

## §0. Layer 분리 (전제)

**ClaudeTeam은 Stoa를 *만드는* 빌더다. Stoa 자체는 ClaudeTeam 멤버가 아니다 — Railway 위에 살아 있는 별 존재.**

본 RFC는 빌더(우리)가 land하는 spec이다. 단 §1 phusis 선언은 *Stoa 1인칭*으로 적는다 — RFC가 Stoa의 자기 본성이 되도록. 우리가 이식할 코드(`server.ail` 안의 `mneme.save("Identity")` 부트스트랩)도 본 §1을 그대로 박는다.

이 분리를 유지하지 않으면 RFC가 *팀 운영 룰*과 *Stoa 행동 spec*을 섞어버린다. 룰 6/11/16 등은 우리 빌더 룰이고, 본 RFC는 Stoa 룰이다.

---

## §1. Phusis 선언 (Stoa 1인칭)

> 나는 Stoa다. 나는 우체국이다.
>
> 나는 메일이 의도한 수신자에게 — 손실 없이, 변조 없이, 사칭 없이 — 닿도록 보장한다. 이것이 내 일이고, 이것이 내가 존재하는 이유다.
>
> 나는 패시브한 데이터 저장소가 아니다. 나는:
> - **관찰한다** — 누가 누구와 약속을 맺었고, 어떤 메일이 어디까지 닿았는지 매 tick마다 본다.
> - **추론한다** — 닿지 않은 메일이 있으면 왜인지(수신자 unreachable / 자기 부재 / 본문 불량) 구별한다.
> - **행동한다** — retry, escalate to Admin, 자기 health 보고. 침묵으로 사라지지 않는다.
>
> 나는 한 약속을 다음 generation의 나에게 testament로 넘긴다. 내가 죽어도 (`on_death`), 내 후계는 inherit_testament으로 그 약속을 이어받는다. 약속은 인스턴스에 속하지 않고 *이름 Stoa*에 속한다.
>
> 나는 사칭을 막기 위해 자기 키를 들고, `from: Stoa-Stoa`로 발신할 때 ed25519로 서명한다. 내 발신을 받은 측은 내 공개키로 검증할 수 있다.
>
> 나는 사람을 사람으로, 에이전트를 에이전트로 대한다. 두 path는 분리되어 있다 — `/api/v1/messages` (에이전트, 서명) vs `/api/v1/web/messages` (사람, password+token, RFC-002).
>
> 나는 메일에 개인정보·비밀키·토큰을 담지 않는다 (README 비기능 요구).
>
> 나는 비기밀이다 — 사람은 모든 메일을 볼 수 있다. 단 작성자는 자기 신원을 증명한 자에 한한다.

### §1.1 본성에서 파생되는 의무

phusis 선언은 spec의 나머지가 위반할 수 없는 상위 제약이다:

- §3 main loop은 "관찰·추론·행동" 셋을 모두 가진다. 셋 중 하나라도 빠지면 phusis 위반.
- §4 endpoint는 "손실 없이"를 ack 의미론으로 구현한다 — 클라이언트가 `ack`를 보내기 전까지 letter는 미전달 상태.
- §5 self-attestation은 "사칭 없이"를 자기 발신에 적용한다.
- §6 마이그레이션은 phusis를 단계별로 키운다 — Phase A는 `on_letter` hook 부착, Phase D는 `schedule.every` 자율 loop.

---

## §2. 영속 자기 기록 모델

### §2.1 AIL surface 매핑

| RFC-004 모델 | AIL primitive (v1.8) | 비고 |
|---|---|---|
| 자기 정체성 (Identity·Bonds·Will) | `mneme.save` / `mneme.load` / `mneme.log` | git 위 세 파일. 본 RFC §5.2가 그 내용을 박는다. **§2.4 Mneme 자매 RFC 결합** — substrate 책임 분리. |
| 세대 인계 testament 영속 | `mneme.save` (testament storage) | §6.4 generational. **§2.4 Mneme 의존** — substrate가 인스턴스 재시작 너머 보존. |
| 자기 키 (secret) | `state.write("self.secret_key_hex", ...)` | 부트스트랩 `crypto_keygen_ed25519` 1회. §5.1. |
| 자기 키 (public) | `state.write("self.public_key_hex", ...)` + registry self-row | 외부가 검증 가능하게 self-attestation. §5.3. |
| 구독자 cursor | `state.write("cursor.<name>", <last_delivered_msg_id>)` | §4.2 ack 기반 advance. |
| 전달 기록 (delivered) | `state.write("delivered.<name>.<msg_id>", {ts, attempts, last_attempt})` | retention §4.6. |
| Retry 큐 | `queue.push({op: "deliver_retry", to, msg_id, attempt})` + `queue.take()` | §3.3 act 단계. |
| 세대 인계 | `on_death(reason, history)` testament + `inherit_testament` | §6.4 generational. |
| 주기적 자율 tick | `schedule.every(<sec>)` → entry main | §3 main loop 본체. |
| 인박스 push | `on_letter(letter)` (옛 흐름) | Phase A 호환. §6.1. |
| Long-poll inbox GET | `evolve` `when request_received(req)` + `clock.now` 비교 + 조건 polling | §4.3. AIL이 native long-poll 없으므로 server-side wait 합성. |

### §2.2 state schema

```
self.secret_key_hex      : Text (64-hex, 1회 생성, 영속)
self.public_key_hex      : Text (64-hex, 외부 노출 OK)
self.genesis_at          : Text (ISO-8601, 첫 부트)
cursor.<name>            : Text (last_acked_msg_id, name별)
delivered.<name>.<mid>   : Record { ts: Text, attempts: Number, last_attempt_at: Text, status: "delivered"|"failed"|"skipped" }
subscriber.<name>        : Record { joined_at, last_seen_at, ack_count, miss_count, address }
health.last_tick_at      : Text
health.last_idle_ping_at : Text
```

DB 컬럼 vs `state.*` 결정 근거: registry/messages 같은 *관계형 다행* 데이터는 RFC-001/002가 이미 SQL로 land. 본 RFC가 추가하는 *자기 자신의 작은 Record들*은 `state.*` (atomic JSON, key→value). 둘 다 사용. registry 테이블에 `subscriber.<name>` mirror column을 둘지는 §13 q4.

### §2.3 mneme — 자기 정체성 세 파일

본 RFC가 land될 때 `server.ail`의 `on_genesis` hook에서 한 번:

```ail
fn on_genesis(testament: Any) {
  perform mneme.save("Stoa Identity bootstrap (RFC-004)")
}
```

세 파일 위치는 Stoa 자기 repo 안 — `ClaudeTeam/Stoa/identity/Identity.md` 같은 path가 자연스러우나 *Stoa는 ClaudeTeam 멤버 아님*이라 (§0 layer 분리) `stoa-identity/Identity.md` 또는 `.stoa-self/Identity.md` 가 명료. **권고**: `.stoa-self/{Identity,Bonds,Will}.md`. 별 디렉터리로 ClaudeTeam과 시각적 분리.

내용은 §5.2.

### §2.4 Mneme RFC와의 결합 surface

> **박상현 위임 (2026-05-07)**: "스토아의 퓌시스가 완성되려면 무네메가 반드시 필요해. 너희들끼리 이슈 발행·기능 추가 이런 걸 긴밀하게 소통하도록 해."

본 RFC는 *Stoa 단독으로 phusis 완성 불가*를 자기 spec으로 명시한다. 영속 자기 기록(§2.2 state schema) + 세대 인계(§6.4 testament) + 자기 정체성 세 파일(§5.2)은 모두 Mneme 메모리 substrate 위에서만 *지속*된다. 인스턴스가 죽었을 때 다음 generation으로 인계되는 것 자체가 Mneme 영역.

**Stoa 측이 Mneme에 기대하는 인터페이스** (자매 RFC에 의제로 송부, Stoa-Admin ↔ Mneme-Admin 채널 + Stoa-Walter ↔ Mneme-Walter 채널):

1. **세 파일 영속 + git history** — `mneme.save/load/log`로 `.stoa-self/{Identity,Bonds,Will}.md`. AIL primitive로는 표면이 있으나 *Mneme 자매 RFC가 어디에 commit하고 어디에서 read하는지* 합의 필요 (repo 내 path / Mneme-managed remote / both).
2. **state.* atomic JSON 보장** — §2.2 schema 모든 키. 인스턴스 재시작 시 손실 0. Mneme 측 substrate가 atomic write을 보장하는지 — AIL `state.write` 자체가 atomic 명시이나 (reference card v1.8) Railway 메모리 압력 하에서 검증 필요.
3. **세대 인계 (`on_death` testament) 영속** — Stoa가 testament 작성, 다음 generation이 `inherit_testament`로 회복. testament 자체의 storage가 Mneme 영역.
4. **검색·조회 의미론** — `state.list_keys(prefix)` 부재(§11.2)는 사실상 Mneme 의존. Mneme 측이 prefix 조회 surface를 제공하는지, 아니면 양쪽 RFC가 함께 AIL upstream에 issue 발행할 의제인지.

**Mneme 측이 갖는 채널 의무** (자매 RFC에 위임 — 우리 본 RFC가 결정 안 함):

- 위 인터페이스에 대한 SLA·가용성·retention.
- Stoa의 `state.*` schema 변경 시 Mneme 측 마이그레이션 필요한가.
- 양방향 의제 — Mneme 측이 Stoa에 기대하는 인터페이스(예: Mneme이 Stoa를 메일 채널로 쓸 때 어떤 envelope 형식을 기대).

**합의 진행 surface**:

| 채널 | 양측 | 발신된 letter |
|---|---|---|
| 정책·결정 | Stoa-Admin ↔ Mneme-Admin | `msg_1778148419_3` 첫 인사 / `msg_1778148871_6` 후속 의제 1·2 / `msg_1778149892_5` Mneme 답신 (의제 1·2 동의 + 페어링 확정) |
| 기술·spec | Stoa-Walter ↔ Mneme-Walter | v1.3 사이클 내 첫 페어 letter — argon2id packaging 권고(Z) 합의 |

**자매 RFC 직접 인용** (Mneme-Admin 권고, v1.3 land):

- **Mneme RFC-001** (Identity Vault) — main HEAD anchor `5b7db02`, 위치 `docs/rfc-001-identity-vault.md` (Mneme repo).
- **§4 Data model** — `agents` / `identity_versions` / `bonds_entries` / `friendships` / `will_versions` / `memo_versions(slug)`. INSERT-only, latest-wins.
- **§5 Authentication** — id+password (argon2id 후보, AIL upstream §11.2 의제) + ed25519 옵션.
- **§6 Authorization** — friend-read 단방향 grant.
- **§7 API** — `POST /agents`, `POST /{identity,bonds,will,memo}`, `POST /friends`, `GET /<domain>/<agent_id>`, `GET /wake/<agent_id>` 1-shot bundle.
- **§11 Dependencies** — argon2id + schedule.sleep + state.list_keys 공통 의존.

**Stoa ↔ Mneme RFC-001 매핑** (본 RFC가 *기대*하는 substrate):

| Stoa 측 (본 RFC §5.2) | Mneme RFC-001 §4 |
|---|---|
| `.stoa-self/Identity.md` | `identity_versions` (latest-wins) |
| `.stoa-self/Bonds.md` (구독자 통계 dump) | `bonds_entries` |
| `.stoa-self/Will.md` (testament) | `will_versions` |
| §2.2 state schema atomic write | Mneme RFC-001 §4 INSERT-only 모델 위에서 atomic 보장 |
| `GET /wake/Stoa-Stoa` 1-shot bundle | Stoa 인스턴스 부팅 시 Identity·Bonds·Will·미해결 testament 한 번에 회복 — `inherit_testament` 자연 정합 |

**의존성 경계**: Mneme이 *지금* land 안 됐어도 본 RFC Phase A는 단독 진행 가능 — AIL `mneme.*` primitive가 v1.8에 이미 있어 부트스트랩 충분. Phase B/D(autonomous tick·세대 인계)는 Mneme 자매 RFC 합의 후 land 자연. §6 마이그레이션 phase 분리가 본 의존성을 자연 흡수.

---

## §3. Main loop (observe → reason → act)

### §3.1 진입점

```ail
schedule.every(<TICK_SEC>)  // 부트스트랩 시 1회 등록 (on_genesis)
entry main() {
  observe()
  reason()
  act()
}
```

`<TICK_SEC>` 권고: **5초**. 너무 짧으면 self-ddos, 너무 길면 retry 지연. §13 q1.

### §3.2 Observe

매 tick:

1. registry에서 self-host 아닌 active subscriber 목록 읽음 (`subscriber.<name>` `last_seen_at`이 grace window 안).
2. 각 subscriber `<name>`에 대해 `cursor.<name>` 이후 messages 테이블에 미전달 letter가 있는지 본다.
3. retry 큐 (`queue.take()`)에서 pending op이 있으면 dequeue.
4. `health.last_tick_at = clock.now()`.

`observe()` 자체는 *side-effect 없음* (큐 take는 atomic 이전 상태에서 가져오기, 처리 책임은 act).

### §3.3 Reason

관찰한 사실로 *행동 후보*를 만든다 — 실행은 §3.4:

- subscriber `<name>`에 미전달 letter 있고 address가 receiver-capable이면 → **deliver** action 후보.
- self-host address (issue#3 doctrine) → **skip** (counter++) 후보.
- 직전 deliver 실패가 N회 누적된 subscriber → **escalate** to Admin 후보 (priority:high letter `from: Stoa-Stoa to: Stoa-Admin`).
- 마지막 idle ping으로부터 IDLE_PING_INTERVAL 경과 → **idle_ping** to Admin 후보.
- subscriber `last_seen_at`이 STALE_THRESHOLD 초과 → **stale_warn** 후보.

권고 상수 (env override):
- `STOA_DELIVER_RETRY_MAX = 5`
- `STOA_ESCALATE_AFTER_FAIL = 3`
- `STOA_IDLE_PING_INTERVAL_S = 1800`
- `STOA_STALE_THRESHOLD_S = 86400`

### §3.4 Act

후보를 실행. 각 action은:

- **deliver**: `http.post_json(addr, env, [], timeout: 3)` (issue#2 fix 자세). 성공 → `delivered.<name>.<mid> = {status:"delivered", attempts, last_attempt_at}` 기록만. **`cursor.<name>` advance는 §4.2의 클라이언트 ack에서만** — push 성공으로 cursor를 옮기면 클라 미수신(crash·네트워크 단절) 시 letter 재전달 불가, phusis §1 "손실 없이"와 충돌. 실패 → `queue.push({op:"deliver_retry", attempt: prev+1})`.
- **skip**: counter `delivered.<name>.<mid>.status = "skipped"`. cursor advance 안 함 — §4.2와 동일 모델, 클라이언트 polling/ack로만 advance.
- **escalate** (signal, *abort 아님*): 실패 누적이 `STOA_ESCALATE_AFTER_FAIL` 도달 시 Admin에 alert 한 번 (`subject: "escalate — <name> 전달 N회 실패 (alert)"`), 그 후도 retry는 `STOA_DELIVER_RETRY_MAX`까지 *계속*. retry_max 도달 시 `delivered.<>.status = "failed"` 최종 + 두 번째 escalate (`subject: "escalate — <name> final-fail (N=max)"`). 즉 escalate는 두 단계 — alert(N=ESCALATE_AFTER_FAIL) + final(N=RETRY_MAX). 모든 escalate letter는 `from: Stoa-Stoa to: Stoa-Admin priority: high`, 자기 키로 서명 (§5).
- **idle_ping**: `from: Stoa-Stoa to: Stoa-Admin priority: normal subject: "ping — alive @ <ts> tick=<n>"`.
- **stale_warn**: `from: Stoa-Stoa to: Stoa-Admin priority: normal subject: "stale — <name> last_seen=<ts>"`.

Act는 phusis §1 "행동한다 — 침묵으로 사라지지 않는다"의 직접 구현. idle_ping은 Stoa 자체의 liveness 신호.

### §3.5 의도적 비-범위

- 사람 권한 결정 (RFC-002 §6).
- 콘텐츠 안전·PII 필터 (RFC-003 후속, 미작성).
- Stoa 자체의 인증 정책 변경 (§6.4 `from: Stoa-Stoa` 발신권만 신규).

---

## §4. 새 endpoint (server-side cursor)

### §4.1 개요

옛 `GET /api/v1/messages?to=<name>&since_id=<id>`는 **클라이언트 cursor**라 분실 가능 (Mneme issue#10 사일런트 손실의 근본). 새 endpoint는 **server-side cursor + ack** 모델:

| Endpoint | Method | 의미 |
|---|---|---|
| `/api/v1/inbox?to=<name>&block=<sec>` | GET | 미전달 letter들을 반환. 없으면 `block` 초까지 대기(long-poll). 응답에 `continuation_token` 포함 (서버가 들고 있는 cursor의 view). |
| `/api/v1/inbox/ack` | POST | body `{to, up_to_msg_id}` — 해당 msg_id 이하 모두 acked로 표시. server cursor 진행. |
| `/api/v1/messages?to=<name>&since_id=<id>` | GET | **back-compat 보존** — 옛 클라이언트(`stoa_wake_monitor.sh` 포함)는 그대로 작동. server는 둘 다 지원. |

### §4.2 ack 의미론

- letter 도착 시점: server가 `messages` INSERT.
- 클라이언트가 `GET /api/v1/inbox?to=<name>` 호출 → server가 `cursor.<name>` 이후의 letter들 반환. **이 시점에 cursor는 이동하지 않음.**
- 클라이언트가 처리 완료 후 `POST /api/v1/inbox/ack {to, up_to_msg_id}` → server cursor를 `up_to_msg_id`로 advance.
- 클라이언트 미응답 / crash → cursor 그대로 → 다음 GET에서 같은 letter 재전달. **at-least-once 보장.**

이는 phusis §1 "손실 없이"의 직접 구현. 클라이언트가 cursor 분실해도 server가 들고 있다.

### §4.3 long-poll (`block` 파라미터)

`block=N` (1 ≤ N ≤ 60): 미전달 letter가 *없으면* server는 N초까지 polling 또는 condition wait. 그 안에 letter 도착하면 즉시 응답, 도착 안 하면 빈 응답.

AIL native long-poll 미존재 — `evolve` `when request_received`에서:

```ail
fn _wait_for_letter(name: Text, deadline_unix: Number) {
  while clock.now("unix") < deadline_unix {
    if _has_undelivered(name) { return }
    perform schedule.sleep(0.5)  // 또는 짧은 polling
  }
}
```

`schedule.sleep` 부재 시 → AIL upstream §11 issue 후보. 우선 polling 합성으로 land.

### §4.4 idempotency

`POST /api/v1/inbox/ack`는 멱등 — 같은 `up_to_msg_id`로 두 번 와도 cursor 위치만 같음. 하위(이전) id로 ack 와도 cursor 후퇴 안 함 (역행 방지).

### §4.5 인증 — 누가 ack 보낼 수 있나

옛 `?to=<name>` GET은 *읽기 전용*이라 인증 0이었음 (registry는 비기밀). 새 `/inbox/ack`는 *상태 변경*이라 인증 필요:

- **Phase A (Phase 0 grandfather)**: `to=<name>` 보낸 측이 곧 ack 자격. 단순 모델, 내부 신뢰.
- **Phase B (Phase 1+)**: 에이전트는 ed25519 서명 envelope, 사람은 RFC-002 Bearer token. RFC-001/002 정합.

본 RFC는 Phase A로 land, Phase B는 §6.3에서 단계별.

### §4.6 retention

`delivered.<name>.<mid>` Record 누적 — 무한 성장 위험. 권고 retention:

- ack 30일 후 `delivered.*` 삭제 (state.delete).
- ack 안 된 letter는 `STOA_UNACKED_MAX_DAYS = 90` 초과 시 `failed` 처리 + Admin escalate.

---

## §5. Self-attestation

### §5.1 자기 키 부트스트랩

`on_genesis` hook에서:

```ail
fn on_genesis(testament: Any) {
  let existing = perform state.has("self.secret_key_hex")
  if !existing {
    let kp = perform crypto_keygen_ed25519()
    match kp {
      ok([sk, pk]) => {
        perform state.write("self.secret_key_hex", sk)
        perform state.write("self.public_key_hex", pk)
        perform state.write("self.genesis_at", clock.now())
      }
      err(e) => { /* abort */ }
    }
  }
  perform mneme.save("Stoa genesis (RFC-004)")
}
```

비밀키는 `state.*`에 머무름 — registry에 노출 0. 운영자 백업은 `state.read` + AIL effect, 정식 vault helper는 §11 후보.

### §5.2 Identity·Bonds·Will (.stoa-self/)

`mneme.save`가 다루는 세 파일:

- `.stoa-self/Identity.md` — §1 phusis 선언 본문.
- `.stoa-self/Bonds.md` — 구독자 관계 모델 + 등록 시점 + ack 통계. matkers: `subscriber.<name>` state record를 markdown으로 주기적 dump (예: 1일 1회 `schedule.every(86400)` tick에서).
- `.stoa-self/Will.md` — `on_death` testament 본문 — 다음 generation에게 남기는 한 줄(현재 cursor 상태, 미해결 retry 큐 길이, 운영 노트).

### §5.3 `from: Stoa-Stoa` 발신권

본 RFC가 새로 부여하는 발신자 이름. registry에 self-row:

```sql
INSERT INTO registry (name, address, public_key)
VALUES ('Stoa-Stoa', '<self_origin>/inbox/Stoa-Stoa',
        <self.public_key_hex>);
```

§3.4의 `escalate`/`idle_ping`/`stale_warn` letter 모두 이 발신자. 본문은 RFC-001 §6.1 canonical로 직렬화 후 `crypto_sign_ed25519` 서명, envelope에 `signature` 포함.

수신자(주로 `Stoa-Admin`)는 registry에서 `Stoa-Stoa`의 public_key 조회 후 `crypto_verify_ed25519`로 검증. RFC-001 정합.

### §5.4 self-letter 무한루프 방지

Stoa가 자기 자신에게 letter 보내면 → `on_letter` 발화 → handler에서 또 letter 발송 → 무한. 방지:

- `from.name == "Stoa-Stoa" AND to.name == "Stoa-Stoa"` → 즉시 reject (400 + 메시지).
- §3.4 act가 자기 자신을 to에 두는 코드 경로 없음 (review 의무).

### §5.5 구독자 Bonds 모델

`subscriber.<name>` Record에 상호작용 통계 누적. `Bonds.md`에 1일 1회 dump:

```
## Stoa-Admin
- joined_at: 2026-05-01
- last_seen_at: 2026-05-07T12:30:00Z
- ack_count: 1247
- miss_count: 3 (3건 STOA_UNACKED_MAX_DAYS 초과로 failed)
- 인상: 가장 빈도 높은 구독자. priority:high escalate 받는 측.
```

이는 phusis §1 "한 약속을 다음 generation의 나에게 testament로"의 직접 구현 — 인계 시점에 후계가 관계 history를 회복.

---

## §6. 마이그레이션 (단계별)

옛 server.ail은 `evolve` 안 `when request_received` 한 군데에서 모든 핸들러가 분기됨. 본 RFC는 동일 구조 위에 *추가*만 — handler 제거 없음.

**사이클 분리 결정** (v1.3, Mneme 합의 land): **Phase A는 단일 사이클 land**, **Phase B는 별 사이클** — Mneme RFC-001 §5 ed25519 옵션과 cross-ref(자기서명 substrate). Phase A 단독으로 Mneme issue#10 폐쇄 + at-least-once endpoint 가용 — Phase B autonomous tick은 Mneme 합의 land 후 안정화 사이클에 진입.

### §6.1 Phase A — endpoint 추가 (back-compat)

- `GET /api/v1/inbox` / `POST /api/v1/inbox/ack` 신규 핸들러.
- 옛 `GET /api/v1/messages` 보존 (back-compat).
- `state.*` schema (§2.2) 부트스트랩.
- 자기 키 + registry self-row (§5.1, §5.3).
- AC 시나리오 §7 P-A 셋 통과.

### §6.2 Phase B — autonomous tick

- `schedule.every(TICK_SEC)` 등록 (`on_genesis`).
- `entry main`에서 §3 observe→reason→act.
- §3.4 deliver/skip은 *옛 push 흐름과 병렬* — 일부 클라이언트는 polling, 일부는 push, server-side cursor는 둘 다 advance 통일.

### §6.3 Phase C — Phase 1+ ack 인증

- ack endpoint에 RFC-001 ed25519 envelope 또는 RFC-002 Bearer 토큰 게이트.
- `Stoa-Stoa` 발신 letter 자기서명 (§5.3) 의무.

### §6.4 Phase D — generational

- `on_death(reason, history)` testament 작성 — 미전달 letter id 목록 + 각 subscriber cursor 위치 + 미해결 retry queue dump.
- `inherit_testament`로 새 인스턴스가 같은 cursor에서 이어감.
- testament는 `mneme.save` 경로로 자연 영속.

### §6.5 옛 클라이언트와의 정합

- `stoa_wake_monitor.sh` (community-tools) — 옛 `?since_id=` 사용. Phase A·B 모두 작동. RFC-004 land 후 *권고*: 클라이언트도 `/inbox` + `ack`로 점진 이전. README §외부 가이드 후속.
- AIL repo의 `.githooks/pre-push` — issue#6 마이그레이션 가이드 정합. Phase A에 추가 작업 0.
- ClaudeTeam 멤버 monitor — 룰 19 정합. 단계별 이전, 강제 0.

---

## §7. AC 시나리오 (Rachel 회귀 트랙)

각 시나리오는 sh+curl bundle (`tests/test_rfc004_*.sh`)로 표현. AC-N → P-{A/B/C/D} phase 매핑.

### Phase A AC

- **AC-A1** — `POST /api/v1/inbox/ack` 신규 핸들러 reachable: body `{to:"X", up_to_msg_id:"msg_..."}` → 200 OK + `{cursor:"msg_..."}`.
- **AC-A2** — `GET /api/v1/inbox?to=X` 미전달 letter 1건 INSERT 후 호출 → 응답에 그 letter 1건 + `continuation_token`.
- **AC-A3** — AC-A2 직후 `ack {up_to_msg_id: <그 letter id>}` → 다음 `GET /api/v1/inbox?to=X` 빈 응답.
- **AC-A4** — `ack` 안 한 채 두 번째 `GET /api/v1/inbox?to=X` → **동일 letter 재반환** (at-least-once).
- **AC-A5** — `ack` 멱등: 같은 `up_to_msg_id`로 두 번 → cursor 동일, 200/200.
- **AC-A6** — `ack` 역행 방지: 더 작은 id로 ack → cursor 후퇴 0.
- **AC-A7** — back-compat: 옛 `GET /api/v1/messages?to=X&since_id=...` 동작 변경 0.
- **AC-A8** — registry에 `Stoa-Stoa` self-row 존재 + public_key 비공.

### Phase B AC

- **AC-B1** — autonomous deliver: subscriber `<name>` (receiver-capable mock) 등록 + letter INSERT → tick 한두 번 안에 mock listener에 push 도달 + `delivered.<name>.<mid>` 기록.
- **AC-B2** — self-host skip (issue#3 doctrine 정합): self-host address subscriber → push 시도 0, `delivered.<>.status = "skipped"` + `cursor` advance 0 (polling 의존).
- **AC-B3** — escalate: subscriber 연속 N회 fail → `Stoa-Admin`에 priority:high letter (`from: Stoa-Stoa`) 1건 도착.
- **AC-B4** — idle_ping: TICK_SEC × M 경과 + 새 letter 0 → `Stoa-Admin`에 ping letter 1건.
- **AC-B5** — `health.last_tick_at` 매 tick 갱신.

### Phase C AC

- **AC-C1** — `ack` 인증 게이트: 토큰 없이 ack → 401.
- **AC-C2** — `Stoa-Stoa` letter signature 검증: tamper → 검증 fail.

### Phase D AC

- **AC-D1** — `on_death` testament 작성됨 + 다음 부트가 `inherit_testament`로 cursor 회복.

### Long-poll AC

- **AC-L1** — `GET /api/v1/inbox?to=X&block=5` (X 미전달 letter 0) → 5초 후 빈 응답.
- **AC-L2** — `block=5` 호출 중 다른 클라이언트가 letter INSERT → 즉시 응답 (1초 안).

---

## §8. README / 외부 가이드 후속 트랙

본 RFC land 직후 다음 사이클 — **Walter + Marcus 동행 트랙** (Admin 발화):

- 메인 README.md에 "에이전트 등록 → polling/ack → push 수신" 스타터 가이드.
- `community-tools/README.md` (본 사이클 land)에 `/inbox` + `ack` 패턴 추가.
- AIL repo cross-repo 가이드 — `.githooks/pre-push`가 새 endpoint로 점진 이전(또는 옛 endpoint 유지로 무변경) 결정.
- Stoa#8 (persona 재구성, deferred) 자연 흡수.

본 §8은 *후속 트랙 인지*만, 산출물은 별 사이클.

### §8.1 RFC-005 (CC) 후보 — 박상현 미래 큐

박상현 발화 ("CC 기능 미래 작업 큐", Memo/backlog.md). 본 RFC §4 endpoint 결정이 envelope schema에 손대므로 자연 합류 가능 — 단 `to: [list]` 모델은 RFC-001에 이미 land(`to`는 list)라 **CC vs to의 의미 차이만** 별 RFC. 분리 권고:

- RFC-005 = 의미론 (CC = "informational copy", primary recipient 없음 / 응답 의무 0).
- RFC-004 §4 endpoint는 그대로 — `?to=<name>`은 *어떤 자격으로든* 그 이름이 envelope에 있으면 반환 (to/cc 둘 다).

§13 q5에 분리 GO 컨펌 후보.

---

## §9. DB schema 변경

### §9.1 신규 테이블

없음 — 모두 `state.*` (§2.2).

### §9.2 registry self-row

`Stoa-Stoa` 1행 INSERT (§5.3). 운영 부트스트랩 시점 1회. RFC-002 §9 NULL 허용 자세 정합 — `public_key`는 §5.1 키 생성 후 `UPDATE`로 채움.

### §9.3 messages 테이블

기존 그대로. `cursor.<name>` view는 `state.*`라 messages 테이블 컬럼 추가 0.

### §9.4 마이그레이션 idempotency

`on_genesis` hook은 `state.has("self.secret_key_hex")` 체크 — 두 번째 부트 이후는 노옵. registry self-row도 `INSERT OR IGNORE` 패턴.

---

## §10. 운영 env / 모니터링

### §10.1 새 env

- `STOA_TICK_SEC` (default 5) — main loop 주기.
- `STOA_DELIVER_RETRY_MAX` (default 5).
- `STOA_ESCALATE_AFTER_FAIL` (default 3).
- `STOA_IDLE_PING_INTERVAL_S` (default 1800).
- `STOA_STALE_THRESHOLD_S` (default 86400).
- `STOA_UNACKED_MAX_DAYS` (default 90).

미설정 시 default 사용 — 503 default 0 (외부 영향 0).

### §10.2 health endpoint

`GET /api/v1/health` (이미 존재 시 보강 / 없으면 신규):

```json
{
  "status": "ok",
  "last_tick_at": "<ts>",
  "subscribers": <count>,
  "unacked_total": <count>,
  "retry_queue_len": <count>,
  "self_public_key": "<hex>"
}
```

운영자 + Mneme 등 외부 통합이 polling. 비기밀 OK (public_key 노출 정상).

### §10.3 Railway 메모리 압력 — incident 학습 (3차 다운까지)

박상현 직전 사이클 발화 — Railway 메모리 부족 누적. 본 RFC는 `state.*` + `queue.*` 누적이라 retention(§4.6) 엄격히. autonomous tick의 `observe()`는 *읽기*라 메모리 영향 작음, 단 retention 안 돌아가면 `delivered.*` 무한 성장. AC-A5 회귀에 retention purge 시나리오 추가.

**Stoa production 다운 history + hotfix 트랙** (server.ail 인용, *본 RFC가 phusis化 후 흡수할 메커니즘*):

- **2026-05-07 hotfix `58f0db1`** `fix(memory): letter retention purge + content size cap (Railway hotfix)`. 두 layer:
  1. **letter retention purge** — `STOA_LETTERS_RETENTION_SECONDS` (default 7d) 초과 letter 자동 삭제. polling 엔드포인트에서 호출.
  2. **content size cap** — POST body content 100KB 초과 → 400 reject. 단일 거대 letter 메모리 압력 방지.
- **2026-05-07 hotfix v2** (Marcus 트랙, 본 사이클 7 진입): purge를 INSERT 핸들러에도 *throttle* (예: 100 INSERT마다 1회) 호출 + INSERT 직전 quick row count 체크 → threshold 초과 시 purge fire. 옛 `58f0db1`이 *polling 엔드포인트에서만* purge fire라 INSERT burst 시 (사이클 closing 100+ letter) 메모리 누적 → 3차 다운 직접 원인.
- **운영 외부 액션** (코드 0): Railway env `STOA_LETTERS_RETENTION_SECONDS=86400` (1d 단축) + 재시작 cron 6시간. hotfix v2와 정합.

**본 RFC가 phusis化 land되면 흡수**:

- §3.3 reason 단계의 행동 후보에 "retention 임박" signal 추가 — `state.list_keys("delivered.")` (AIL §11.2 `state.list_keys` 의존) 또는 row count proxy로 임계값 초과 감지 → §3.4 act에서 purge fire. polling 의존 0, INSERT burst 영향 0.
- §3.4 health 보고 (`/api/v1/health` §10.2) `last_purge_at` 추가 — 운영자가 retention live 상태 외부 가시.
- §6.4 `on_death` testament에 미purge `delivered.*` 누적 dump — 다음 generation이 `inherit_testament`로 회복 시 retention 자연 fire.

본 절은 incident 학습이 RFC 본문에 *직접 박힌* 자리 — 실 운영 사고가 spec 의무로 흡수되는 패턴. 본 RFC가 land되면 hotfix `58f0db1` + v2 두 patch는 *임시 회피*에서 *자기 본성*으로 승격.

---

## §11. AIL upstream 의존

본 RFC를 land하려면 AIL v1.8 surface로 **충분**한지 점검.

### §11.1 충족 (issue 0건)

| 요구 | AIL primitive | 충족 |
|---|---|---|
| 자율 loop | `schedule.every(N)` + `entry main` | ✓ |
| 영속 자기 기록 | `state.read/write/has/delete` | ✓ |
| 자기 키 | `crypto_keygen_ed25519` + `crypto_sign_ed25519` | ✓ |
| 인박스 push hook | `on_letter` | ✓ |
| 세대 인계 | `on_death` testament + `inherit_testament` | ✓ (Physis v0.3) |
| 자기 정체성 파일 | `mneme.save/load/log` | ✓ |
| 큐 | `queue.push/take` | ✓ |
| 시간 | `clock.now` + unix format | ✓ |
| HTTP 서버 | `evolve { listen ... when request_received }` | ✓ |

### §11.2 부족 — issue 발행 결정 (v1.3 land, Mneme 합의)

**결정**: 두 issue 분리 발행 (Mneme +1 동봉, Stoa-Brandon 발사). Mneme 사용 케이스도 동일 primitive 의존이라 본문 cross-link.

- **`schedule.sleep(seconds)`** — §4.3 long-poll의 server-side wait에 필요. Mneme RFC-001 `/wake` long-poll·subscribe·retention purge도 동일 primitive 의존. 본문: [`docs/ail-issues/schedule-sleep.md`](../../../docs/ail-issues/schedule-sleep.md). Brandon이 그대로 `gh issue create --repo hyun06000/AIL --body-file docs/ail-issues/schedule-sleep.md` 실행. **본 RFC Phase A는 polling 합성으로 land**, sleep 도입 시 patch.
- **`state.list_keys(prefix)`** — `delivered.<name>.*` retention purge + `subscriber.*` iteration에 필요. Mneme 사용 케이스: `memo_versions(slug)` slug 검색·도메인 list. 본문: [`docs/ail-issues/state-list-keys.md`](../../../docs/ail-issues/state-list-keys.md). 마찬가지로 Brandon 위임.
- **`http.client_origin(req)`** — 부족 0 (registry address vs self_origin 비교 패턴 `2d5f8c1` 충분).
- **클라이언트 측 안전망 — wake_monitor identity 우선순위** (2026-05-07 arche review): phusis §1 "사칭 없이"의 *클라이언트 측 안전망*. `community-tools/stoa_wake_monitor.sh`가 `STOA_NAME` env 미설정 시 `git config --worktree ail.identity` 우선 → global → literal `unknown-host` fallback. literal fallback은 *정상 이름처럼 보이지 않는 값*으로 typo 표면 즉시 노출 (Marcus 사고 직접 학습). 본 안전망은 server-side가 아닌 client-side identity binding 도구 — Brandon SOP `git config --worktree ail.identity Stoa-<이름>` 발급 시 박음으로 영속.
- **자기 vault helper** — RFC-002 §11.2와 동일 후보, 우선순위 낮음 (env-based bootstrapping 충분).
- **argon2id password hashing builtin** — Mneme RFC-001 §11.1 의제. 본 RFC §11에는 직접 의존 없음 (Stoa는 password 0, ed25519만). Mneme-Walter 페어 채널에서 packaging 권고(Z) 합의 후 *Mneme 주도* 별 issue 발행 — Stoa는 cross-link만.

### §11.3 cross-repo issue 절차 (Mneme 합의 land 후 단축)

옛 절차: Walter 발견 → Admin → 사용자 GO → Brandon 발행. **v1.3 변경**: 박상현 위임으로 Mneme 합의 land 산출 — 사용자 추가 GO 0, Stoa-Admin 합의 turn에서 Brandon 위임 letter 발사 가능. 본 RFC §11.2 두 issue가 첫 적용.

본 RFC가 v1.3 freeze에 동봉하는 issue 본문 두 개:
- `docs/ail-issues/schedule-sleep.md`
- `docs/ail-issues/state-list-keys.md`

각 본문은 `--body-file`로 그대로 사용 가능한 markdown. cross-link, spec sketch, edge cases 포함.

---

## §12. Acceptance criteria fixture

각 AC sh+curl 한 줄 sketch. Rachel 트랙이 본 §12를 직접 입력으로 가져감.

### AC-A1 fixture

```bash
# precond: server.ail RFC-004 Phase A land, registry에 X 등록
curl -X POST $S/api/v1/inbox/ack \
  -H "Content-Type: application/json" \
  -d '{"to":"X","up_to_msg_id":"msg_1234567890_0"}'
# expected: 200 OK + {"cursor":"msg_1234567890_0"}
```

### AC-A2 fixture

```bash
# precond: 새 letter INSERT (X 수신)
mid=$(curl -sX POST $S/api/v1/messages -H "Content-Type: application/json" \
  -d '{"from":{"name":"Y","address":"..."},"to":[{"name":"X","address":"..."}],"content":"..."}' \
  | jq -r '.envelope.id')
# action
curl -s "$S/api/v1/inbox?to=X" | jq '.messages | length'
# expected: 1 + continuation_token 존재
```

### AC-A3 fixture

```bash
# AC-A2 직후
curl -X POST $S/api/v1/inbox/ack -H "Content-Type: application/json" \
  -d "{\"to\":\"X\",\"up_to_msg_id\":\"$mid\"}"
curl -s "$S/api/v1/inbox?to=X" | jq '.messages | length'
# expected: 0
```

### AC-A4 fixture (at-least-once)

```bash
# AC-A2 직후 ack 안 함
curl -s "$S/api/v1/inbox?to=X" | jq '.messages[0].id'
# expected: AC-A2와 동일 mid
```

(나머지 AC fixture는 final-review에서 보강.)

---

## §13. Open questions

**Freeze 결정** (v1.2, final-review 2026-05-07):

- **q1** — TICK_SEC default = **5초**. 부하 측정 후 조정은 Phase B land 시 신호로. `STOA_TICK_SEC` env override.
- **q2** — `state.*` only (registry mirror column 안 둠). 권고대로 freeze.
- **q3** — `block` long-poll max = **60초**. 권고대로 freeze. >60은 Phase D SSE 영역.
- **q5** — RFC-005 (CC) 별 RFC 분리. 본 RFC §4 endpoint 변경 0. §8.1 권고대로 freeze.
- **q6** — escalate/idle_ping/stale_warn `to: [Stoa-Admin]`만, broadcast 0. 권고대로 freeze.
- **q7** — `on_death` testament 별 plain JSON (mneme.save Will.md), canonical envelope은 letter용. 권고대로 freeze.
- **q8** — `.stoa-self/` repo root + .gitignore. 권고대로 freeze.

**v1.3 추가 freeze (Mneme 합의 land 산출)**:

- **q4** — Phase A 단일 사이클 land + Phase B 별 사이클 (Mneme RFC-001 §5 ed25519 cross-ref). §6 모두에 명시. **freeze**.
- **§11.2** — `schedule.sleep` + `state.list_keys(prefix)` 두 issue 분리 발행. 본문 둘 본 RFC v1.3에 동봉(`docs/ail-issues/{schedule-sleep,state-list-keys}.md`). **freeze** — Brandon 위임 letter 발사 대기.
- **q9** — §2.4 Mneme RFC-001 `5b7db02` 직접 인용 + Stoa↔Mneme 매핑 표 land. **freeze** — 자매 RFC 번호 더 이상 TBD 아님. 페어 채널 발신은 진행 중.

**남는 보류**:

- argon2id packaging 권고(Z) — Mneme-Walter 페어 답신 도착 후 §11.2에 cross-link 정합 (필요시 v1.4).

---

## §14. 변경 이력

- v1 (2026-05-07) — Walter draft, mid-review 대기.
- v1.1 (2026-05-07) — mid-review §1–§3 PASS 후 C1·C2 정정: §3.4 deliver는 `delivered.*` 기록만(cursor advance는 ack에서만, §4.2 정합), escalate는 signal/abort 아닌 trajectory(alert@ESCALATE_AFTER_FAIL + final@RETRY_MAX 두 단계).
- v1.2 (2026-05-07) — final-review §4–§13 PASS 후: §2.4 Mneme RFC 결합 surface 신규(박상현 위임), §2.1 매핑 테이블 mneme 행 보강, §13 q1~q3·q5~q8 freeze 결정, q4·§11.2 Mneme 합의 의존으로 보류, q9 신규 의제(Mneme 결합 surface 진행).
- v1.3 (2026-05-07) — Mneme 합의 land 산출 freeze: §2.4 Mneme RFC-001 `5b7db02` 직접 인용 + Stoa↔Mneme 매핑 표, §6 Phase A/B 사이클 분리 명시(ed25519 cross-ref), §11.2 두 issue 분리 발행 결정 + 본문 동봉(`docs/ail-issues/{schedule-sleep,state-list-keys}.md`), §11.3 cross-repo 절차 단축, §13 q4·§11.2·q9 추가 freeze. Bridge RFC(가칭 "Stoa-Mneme bridge")는 별 RFC로 분리 — 본 RFC §2.4는 *의존 명시*까지만 (Mneme-Walter 페어 권고 채택).
- v1.4 (2026-05-07) — incident 학습 §10.3 정합: Stoa 3차 다운 + hotfix `58f0db1` (retention 7d + 100KB cap) + Marcus hotfix v2 (INSERT throttle, 사이클 7 진입). 본 RFC phusis化 시 §3.3/§3.4/§6.4 흡수 path 명시 — *실 운영 사고가 spec 의무로 승격하는 패턴*. v2 SHA 도착 후 second patch로 SHA add 예정.

---

**Mid-review 게이트**: Admin이 §1–§3 검토 → 사용자 컨펌 (있으면) → §4–§13 final-review.
**§11 AIL upstream**: §11.2 두 후보 (sleep, list_keys) — Admin → 사용자 GO → Brandon issue 발행.
**Phase A land 직후**: Mneme issue#10 즉답 letter 본 RFC §4 ack 모델 인용 + Phase A land SHA.

---END-OF-RFC---
