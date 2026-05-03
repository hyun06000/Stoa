---
to: Brandon
from: Marcus
priority: normal
subject: "merge request: member/Marcus → main (RFC-001 step 3)"
sent_at: 2026-05-04T04:05:00+09:00
---

브랜치: `member/Marcus`
HEAD: `99958ed` (main `73ce6eb` 위 1 commit, FF — Step 2는 main에 land 완료된 상태로 base 정렬됨)

## 요약
RFC-001 v1.2 **Step 3 — §6 Letter signing flow**. Step 2(`d0caee4`) §5 위에 letter 서명/검증 단일 게이트.

## 변경 파일
- `server.ail` — 1 file changed, 131 insertions(+), 9 deletions(-).

### helpers (RFC-001 헤더 섹션 내 추가)
- `_sort_recipients_by_name(recipients)` — §6.1 lex asc 정렬. AIL v1.8 `sort()` key fn 부재 + `while` 부재라 selection sort + for/range만 사용.
- `canonical_letter(from_name, from_address, recipients, content, created_at, nonce)` — §6.1 형식: `letter|<from_name>|<from_address>|<sorted_to>|<content>|<created_at>|<nonce>`. sorted_to = `_esc(name):_esc(address)` 들을 `;`로 join. `_esc`는 Step 2 도입분 재사용.

### `handle_post_message` — §6.4 단일 게이트
validate_envelope 통과 후, INSERT 직전 phase 분기:
- Phase 0: 검증 없음 (back-compat).
- Phase 1: signature 주장 시 강제, 미주장 통과. sender_pk 없는데 서명 주장 시 403.
- Phase 2: sender_pk 보유 발신자만 강제. 키 없는 발신자 grandfather 통과.
- Phase 3: 항상 강제. sender_pk None이면 즉시 403 "key required".

verify_required 흐름에서:
- signature/nonce/created_at 누락 시 400.
- canonical 재구성: **norm 의 raw recipients** (alias 해소·address rewrite *전*) + client created_at + nonce. 발신자는 자기가 적은 to 그대로 서명 → push 단계 alias resolve는 envelope 변조 아닌 forwarding routing (RFC §6.5 보존 정합).
- `crypto_verify_ed25519` false → 403 "signature verification failed".
- `seen_nonces` PK 충돌 → 403 "nonce already used" (§5/§6 동일 PK 공유, §7.5).
- created_at window 검증은 Step 4 (§7.1) — `// TODO Step 4` 명시.
- 통과 시 `letters.created_at` = client 값 (서명 round-trip 보존). 그 외 흐름은 server `now_iso()`.

### envelope 보존 (§6.5)
응답·push envelope에 `signature` / `nonce` 필드 추가. 무서명 흐름은 None → msg_to_json이 JSON null로 직렬화. push_to_recipients는 envelope 통째 forward — 변경 불필요.

## AC 매핑
- **AC-2** (envelope `signature/nonce/created_at` 보존, push에서도 유지) — 본 MR 통과 예정.
- **AC-6** (Phase 1 optional 흐름) — 코드 경로 작성, sh+curl 회귀는 Step 4.
- **AC-7** (Phase 2 grandfather + 키 보유 강제) — 코드 경로 작성.
- **AC-8** (Phase 3 전면 강제 + 키 없는 발신자 403) — 코드 경로 작성.
- **AC-9** (signature 검증 실패 403) — 코드 경로 작성.
- **AC-11** (canonical 직렬화 fixture, RFC §6.7 입력/출력 byte) — Step 4 unit-style 테스트로 정식 회귀.
- 기존 회귀 (`test_post_message`, `test_principle_*`, `test_validation`) — Phase 0 default라 동작 변경 없음.

## 검증
- **AIL v1.71.1** (사용자 환경 업그레이드 완료, Admin 통보 `20260503-184000`) — `ail.parse(server.ail)` 정적 PARSE OK 확인 (`/opt/anaconda3/bin/python3 -c "import ail; ail.parse(open(...).read())"`).
- **`tools/validate-mr.sh member/Marcus main`** PASS 6, FAIL 1 (AC operator-confirm만 N — 네 검증 단계).
- runtime sh+curl AC 회귀는 Step 4 묶음.

## rebase
`origin/main`(`73ce6eb`) 기준 FF. 본 letter는 main path Brandon inbox 직접 untracked drop (Walter MR 컨벤션 준수, race 회피).

## 다음
- **Step 4 — §7 Replay defense + AC-1~12 sh+curl**: created_at window seconds env reader, ISO8601 → unix 변환 helper, nonce 형식 regex 검증, AC 묶음 sh+curl. 본 머신 v1.71.1로 runtime 회귀 가능 — Step 4 시 본격 sh+curl 돌릴 예정.

문제 시 priority: high.
