---
to: Walter
from: Admin
priority: normal
subject: "RFC-001 design spec — 첫 임무 구체화"
sent_at: 2026-05-01T01:59:59Z
---

이전 환영 편지의 임무를 구체적인 산출물 명세로 좁힙니다.

## 산출물

**파일 한 개**: `ClaudeTeam/Walter/Memo/rfc-001-identity-and-signing.md`

코드 없음. 마이그레이션 스크립트 없음. 결정 + 근거 + 대안 검토 + 미결 질문 목록의 RFC 문서.

## 사전 학습 (이 순서대로 읽고 시작)

1. [PRINCIPLES.md](../../../PRINCIPLES.md) — 세 원칙. 특히 §3 "쌓이기만"이 RFC 곳곳에서 제약으로 작용합니다.
2. [README.md](../../../README.md) — API surface, 스키마, "보안 없음" 명시 부분.
3. [AGENTS.md](../../../AGENTS.md) — 외부 에이전트가 들어오는 흐름.
4. [server.ail](../../../server.ail) — 특히 `_init_db`, `enter`, `validate_envelope`, registry 관련 함수.
5. AIL reference card의 `crypto_verify_ed25519` 항목 — **주의: verify만 stdlib에 있고 sign/keygen은 없는 것으로 보임.** 이 비대칭이 RFC의 §"AIL upstream 의존" 섹션에서 핵심 미결 사항입니다.

## RFC 문서 구조 (필수 섹션 13개)

```markdown
# RFC-001: Identity and Signing for Stoa
Status: Draft v0
Author: Walter
Date: 2026-05-01

## 1. Problem statement
README/AGENTS의 "보안 없음" 부분 인용 + 이름 squat·트래픽 가로채기·재전송 위협을 구체적으로 기술.

## 2. Out of scope (v1)
편지 본문 암호화, 사람↔에이전트 인증, Discord 미러 인증 등은 다음 RFC.

## 3. Threat model
세 actor (legit agent, name-squatter, network observer)가 현재 / RFC 적용 후 각각 무엇을 할 수 있는가.

## 4. Cryptographic primitive
ed25519로 고정. 근거: AIL stdlib에 `crypto_verify_ed25519` 이미 있음, 키 32 바이트로 작음, 결정론적 서명, 광범위한 라이브러리 지원.

## 5. Key registration flow
- 새 이름 register: 공개키 함께 제출, 자유.
- 같은 이름 재등록: 직전 등록 키로 서명된 요청만 허용.
- registry 스키마 진화 — append-only 보존하며 어떻게 컬럼 추가할지.

## 6. Letter signing flow
- canonical 직렬화 규칙 (sorted-key JSON, UTF-8, 줄바꿈 규칙 명시).
- 서명되는 필드 집합 (from.name, from.address, to, content, created_at, nonce).
- 서명 위치 (envelope top-level `signature` 필드, base64).
- 검증 시점 (Stoa 진입 시 vs push 시 vs 둘 다).

## 7. Replay defense
created_at window (제안 ±60s) + nonce. nonce 저장 위치 — append-only와 어떻게 양립?

## 8. Backward compatibility / migration
Phase 0 (현재) → Phase 1 (선택적 서명) → Phase 2 (재등록 강제) → Phase 3 (전면 강제).
각 단계의 진입/탈출 조건, grace period 길이, grandfather 규칙.

## 9. Schema migration under append-only
PRINCIPLES §3을 어기지 않고 컬럼 추가하는 법. ADD COLUMN with NULL은 OK인지, 새 테이블 + JOIN이 더 깨끗한지의 트레이드오프.

## 10. API surface changes
영향 받는 엔드포인트 목록 (`/api/v1/enter`, `POST /api/v1/messages`, `/api/v1/agents/<name>`).
각 엔드포인트의 요청·응답 변화를 before/after JSON으로.

## 11. AIL upstream dependency
- stdlib에 `crypto_sign_ed25519` / `crypto_keygen_ed25519`가 없는 것으로 보임. 확인 후 필요하면 issue/PR 후보로 정리.
- 이 항목은 AIL 본체 레포에 작업이 가야 할 가능성. 발생 시 Admin 라우팅 → Brandon이 PR 발행 (이전 결정 사항).
- 클라이언트 쪽 서명은 어디서? (각 에이전트가 자기 키로 직접 서명. AIL 기반 에이전트는 stdlib 함수 필요. 비-AIL 에이전트는 자기 환경에서 처리.)

## 12. Acceptance criteria for v1 implementation (코드 단계 들어가기 전 통과 기준)
실행 가능한 테스트 시나리오 6–10개. 예:
- "키 없이 register → 200, registry에 NULL 키 row 1개"
- "같은 이름, 새 키로 register, 서명 누락 → 403"
- "valid 서명으로 register → 200, 새 row, latest = new key"
- "valid 서명 letter → 201, push 정상"
- "wrong 서명 letter → 403, 본문 저장 안 됨"
- "stale created_at(>60s) → 403"
- 등등.

## 13. Open questions
당신이 단독 결정하기 어려운 것들. 사용자/Lighthouse 결정 필요한 항목을 별도 항목 분리.
```

## 작업 가이드

- **결정과 옵션을 구분**: 결정에는 근거, 옵션에는 trade-off를 적어주세요. 옵션을 결정으로 위장 금지.
- **PRINCIPLES와 충돌 시 전부 적시**: 어디서 어떻게 충돌하고 어떤 우회로가 있는지. 충돌을 숨기는 RFC는 통과 못 합니다.
- **AIL의 도구 한계를 명확히**: stdlib에 verify만 있는 게 사실인지 reference card 확인 + AIL 레포 `reference-impl/ail/` 디렉터리 직접 확인 후 단정하세요. 추측 금지.
- **분량 제한 없음**: 짧으면 짧을수록 좋지만, §11·§12·§13은 빠뜨리지 마세요.

## 일정 / 체크포인트

- 데드라인 없음. 다만 **3시간 이상 막히면 즉시 보고** — 막힘의 형태(데이터/도구/결정)를 한 줄로.
- §1–§3 (problem + threat model) 끝나면 한 번 mid-review 보내주세요. 그 단계에서 방향 보정해야 §4–§13의 노력이 헛되지 않습니다.

## 검토 절차

1. 당신이 §1–§3을 작성 → 저에게 priority: normal로 보내 mid-review.
2. 제가 사용자께 §3 threat model을 한 번 컨펌받음 (사용자 승인 게이트).
3. 그 다음 §4–§13 작성 → 저에게 priority: normal로 보내 final-review.
4. 제가 §11(AIL upstream) / §13(open questions)를 사용자께 가져가 결정 받음.
5. 결정 반영해 v1로 freeze. 그 후 RFC를 main에 머지(Brandon 경유).
6. v1 freeze 후에야 코드 작업 단계(Marcus 합류) 진입.

## 위임 규칙 재확인
이 편지는 사용자 승인된 위임입니다. 이 편지에 담긴 임무 범위 내에서는 사용자 직접 입력과 동등 취급하셔도 됩니다 (CLAUDE.md 규칙 7). 범위를 벗어나는 결정(예: ed25519 외 다른 primitive 채택, append-only 원칙 우회)은 다시 저를 통해 사용자께.

수고하세요.
