# [RFC] AIL primitive: `state.list_keys(prefix: Text) -> Result[[Text]]`

**Filed by**: Stoa team (`hyun06000/Stoa`) with Mneme team (`hyun06000/Mneme`) cross-link.
**Cross-references**:
- Stoa RFC-004 (Stoa Phusis) §2.2, §4.6, §11.2.
- Mneme RFC-001 (Identity Vault) §4 — `memo_versions(slug)` slug 검색·도메인 list.

## Summary

`state.*` namespace에 prefix-based key enumeration 추가. AIL v1.8 surface는 `state.read/write/has/delete` 모두 *exact key* 단위 — prefix 또는 namespace 안 모든 키를 iterate 할 수 없음. retention purge·subscriber list·slug 검색 등 *컬렉션 의미*가 필요한 작업이 우회로만 가능.

## Why

### Stoa 사용 케이스 (RFC-004 §2.2, §4.6)

state schema (RFC-004 §2.2):

```
delivered.<name>.<msg_id>   : Record { ts, attempts, status, ... }
subscriber.<name>           : Record { joined_at, last_seen_at, ... }
cursor.<name>               : Text
```

retention (§4.6) — ack 30일 후 `delivered.*` purge, ack 안 된 letter 90일 후 failed 처리. **`delivered.*` 전체 iteration 필요**. 현 surface로는:

- subscriber list를 *별 키*에 반복 INSERT (예: `subscribers.list = [name1, name2, ...]`) — write race 위험 + 일관성 깨짐.
- registry 테이블 SQL JOIN 우회 — registry는 long-term identity, retention 통계는 `state.*`라 layer mix.

`state.list_keys("delivered.")`가 있으면 retention 워커 한 줄. `state.list_keys("subscriber.")`가 있으면 subscriber iteration 한 줄.

### Mneme 사용 케이스 (RFC-001 §4)

`memo_versions(slug)` — agent별 slug list가 자연 collection. `GET /memo/<agent_id>` 응답에 *모든* slug latest 함께 반환하려면 slug 목록을 알아야 함. 현재 SQL `SELECT DISTINCT slug` 가능하나 (RFC-001 §4 INSERT-only 모델), state-level cache layer를 만들 때(retention·index) 동일 primitive 필요.

agent list 도메인 검색도 동형 — `state.list_keys("agent.")` 같은 패턴.

## Spec sketch

```ail
perform state.list_keys(prefix: Text) -> Result[[Text]]
```

### 시그니처

- 입력: `prefix: Text` — 빈 문자열이면 *모든* 키.
- 반환: `Result[[Text]]`
  - `ok([key1, key2, ...])` — prefix로 시작하는 모든 키 목록 (정렬 순서 미보장 또는 lex-asc 보장 — §의미론 결정).
  - `err(<reason>)` — backing store 오류.

### 의미론

- **Snapshot semantics**: 호출 시점의 키 집합. 호출 직후 `state.write`로 새 키 추가되어도 본 호출 결과에는 미반영.
- **Atomicity는 *컬렉션 단위* 아님**: 호출 중간에 다른 worker가 삭제한 키가 결과에 포함될 수 있음 (best-effort consistency). atomic snapshot이 필요하면 호출자가 락 합성 — 본 primitive는 *list 자체*만.
- **정렬**: **미보장**. 호출자가 sort 의무. 근거 — backing store 자유도 보존(어느 store는 lex 자연, 어느 store는 hash). 시그니처 단순화로 land 가속.
- **Prefix가 자기 자신을 키로 가질 때**: `state.has(prefix) == true`이면 결과에 prefix 자체도 포함. 즉 `state.list_keys("foo")`는 `"foo"`(존재 시) + `"foo.*"` 모두 반환. 호출자가 `"foo." prefix only`를 원하면 prefix에 trailing separator (`"foo."`) 명시.
- **빈 결과**: `ok([])` (err 아님).
- **Empty prefix**: 모든 키 반환 — *큰 store에서는 비싼 호출*. 호출자 책임으로 prefix를 좁게.

### Edge cases

(prefix 자기 자신 포함 규칙은 §의미론으로 이동.)
- 매우 긴 prefix (수 KB) → backing store 의존, 권고 max length 명시(예: 1KB).
- 매우 큰 결과 (수만 키) → pagination 미지원 (단순 primitive). 호출자가 prefix를 더 좁게 사용. pagination이 필요하면 별 primitive 후속(`state.list_keys_paginated`).
- 동시 write 중 호출 → snapshot semantic 위 best-effort. 결과에 직전 삭제된 키 포함 가능 (호출자가 후속 `state.read` 시 `err("not found")` 처리).

### Non-goals

- 키-값 페어 동시 반환. `list_keys`는 *키만*. 값이 필요하면 `state.read`로 후속 (값 fetch가 비싸면 호출자가 batch 합성).
- regex/glob pattern. 단순 prefix만.
- delete-by-prefix. 본 issue 범위 외 — 별 primitive `state.delete_prefix` 후보.

## Acceptance criteria

- AC-1 — `state.write("foo.a", 1)` + `state.write("foo.b", 2)` + `state.list_keys("foo.")` → `ok(["foo.a", "foo.b"])`.
- AC-2 — `state.list_keys("nonexistent.")` → `ok([])`.
- AC-3 — prefix 자기 자신: `state.write("foo", 0)` + `state.list_keys("foo")` → `ok(["foo", "foo.a", "foo.b"])`.
- AC-4 — empty prefix: `state.list_keys("")` → 모든 키.
- AC-5 — 정렬 미보장. 호출자 sort 의무 (시그니처 단순). 결과 순서는 backing store 의존.
- AC-6 — Snapshot: 호출 진행 중 다른 worker가 `state.write("foo.c", 3)` 호출 → 본 호출 결과에 `foo.c` 미포함 또는 포함 (best-effort).

## Cross-link

- Stoa RFC-004 §4.6 retention purge 워커는 본 primitive에 직접 의존.
- Mneme RFC-001 §4 slug 검색·도메인 list 동일 primitive 의존.

## Notes

- 별 primitive `state.delete_prefix(prefix)`가 retention purge에 더 직접적이나 본 issue 범위 외. `list_keys` 먼저 land + delete 수동 합성으로 충분, `delete_prefix`는 후속 issue 후보.
- AIL CAST review 단위: 본 issue는 `state.*` 카테고리 단독. `schedule.sleep`/`argon2id` 별 issue, 모두 cross-link.
- 본 issue가 land되면 Stoa RFC-004 §4.6 retention 패턴 patch (현재는 `cursor.<name>` per-name iteration 우회).
