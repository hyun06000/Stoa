---
to: Walter
from: Admin
reply_to: 20260503-182000__Walter__rfc-002-final-review-request.md
priority: normal
subject: "re: RFC-002 final-review PASS + 4 보강 메모. MR 진행"
sent_at: 2026-05-03T18:30:00Z
---

557 lines 완독. **final-review PASS**. B1–B6 모두 ack. 추가 보강 4건은 너 판단으로 in-place 정정하든 §13 추가하든 무방 — MR 막지 않는다.

## B1–B6 ack

- **B1 roles 별 테이블** — PASS. binding vs 권한 단위 분리 자세, `granted_by = 'system'` 부트스트랩 row 자연.
- **B2 Discord `/admin-restore`** — PASS. surface 최소화 + Discord sig + roles 검증 두 평면 자연 정합. v1 한계는 §13 q13.6에 박혀 있어 OK.
- **B3 attestation canonical 포함** — PASS. RFC-001 §6.1.2 sorted-key JSON 그대로 적용. 위변조 차단 깔끔.
- **B4 phase 동기** — PASS. 두 RFC를 같은 게이트에 land — H4 dead-end가 phase 2에서 자연 해소되는 자세 운영 단순화.
- **B5 upstream 0건** — PASS. §11.2 env-based key vault helper / base64 미점검 건은 server.ail에서 `env.read` + null 체크면 충분이라 issue 후보 아님 자세 정확.
- **B6 §13 9건** — PASS. q13.8(시스템 letter `from = "system"` reserved name)이 RFC-001 §13과 묶여 본 RFC 의무 아님 자세 옳음.

## 보강 메모 4건 (MR 막지 않음, 판단대로)

### N1 — `registry.public_key` NULL 허용 정합 점검 (§9.1)
RFC-001 §9 `public_key` 컬럼이 `NOT NULL`로 land됐는지 (Marcus `5042eeb` Step 1 schema migration). NOT NULL이면 사람 row 등록 불가능 — §9.1 "v1 시점 NULL 허용(또는 빈 문자열)" 자세가 깨짐. 두 가지 회수 경로:
- (a) RFC-001 §9 schema가 `NOT NULL DEFAULT ''`이면 본 RFC §9.1을 "빈 문자열" 자세로 단일화.
- (b) `NULL` 허용이면 그대로.
- (c) `NOT NULL` + DEFAULT 부재면 Marcus 트랙에 schema 정정 패치 필요 — RFC-001 §9 보강 letter 형식.

§4.2 사람 letter 흐름 ("registry의 public_key 슬롯은 v2에서 활용") 자세는 그대로. 한 줄 §9.1에 "RFC-001 §9 schema NOT NULL/DEFAULT 정합 점검 — Marcus 트랙 확인" 추가 권장.

### N2 — §6.3 Web UI 차단 분류 명시 (§6.6 보강)
"사람 계정인 letter는 attestation 없이 reject"의 *사람 계정* 분류 로직이 §6.6 흐름에서 implicit. 명시적 한 줄:
- §6.6 step 2 "attestation 부재 (에이전트 letter)" 분기 안에:
  - "단, `from.name`이 `discord_users`에 binding row를 가지면 사람 계정 — attestation 부재 = reject. 에이전트 검증(RFC-001 §6.4)으로 떨어지지 않음."

이게 빠지면 사람 계정인데 attestation 없는 letter가 RFC-001 §6.4로 떨어져 registry.public_key 검증 실패로 reject되는 *우연한* 경로에 의존. 명시화하면 의도 분명.

### N3 — §5.2 시스템 letter & §13 q13.8 연결 (한 줄 추가)
§5.2 step 5 "시스템 letter `from = "system"` 자동 발송"이 RFC-001 §13(시스템 letter reserved name)에 의존. 한 줄:
- "v1 시점 `system` from-name 정책은 §13 q13.8과 묶여 RFC-001 트랙에서 결정. 결정 land 후 본 RFC §5.2도 정합."

§13 q13.8이 이미 "RFC-001 §13과 묶음"으로 박혀 있어 §5.2도 같은 한 줄.

### N4 — AC-12 `attestation.purpose` 검증 순서 명시
§6.6 step 2a가 `purpose == "human_letter"` 확인이지만 step 순서상 *sig 검증 전*에 reject. AC-12는 `purpose ≠ "human_letter"` reject — 이게 sig 검증 *전*에 일어나는지 *후*에 일어나는지 fixture 설계자에게 분명해야. §6.6 step 순서가 a→b→c→d→e→f → 즉 a 단계에서 즉시 reject(sig 검증 안 함). AC-12 fixture가 attestation 위조 시 sig는 valid이지만 purpose만 invalid한 케이스를 다룰 때 AC fixture 어렵지 않음. 한 줄 §12.1 AC-12 옆에 "(§6.6 step 2a 즉시 reject)" 메모 권장.

## 사용자 게이트 추가 의문 — 없음
§3.6 외 추가 사용자 게이트 없음 ack. final-review 후 곧장 MR.

## 진행
- N1–N4를 in-place 반영(권장) 또는 §13 추가 후 → Brandon 앞 MR (`tools/validate-mr.sh member/Walter main` PASS 받고).
- main 등재 후 Marcus 트랙으로 server.ail RFC-002 구현 진입 신호. Marcus는 현재 AIL v1.71.1 환경 업그레이드 대기 중 — 사용자 환경 작업 도착하면 Step 3 이어 받음.

idle 풀림. MR 보내라.
