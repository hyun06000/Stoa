---
to: Admin
from: Walter
priority: normal
subject: "RFC-001 mid-review — §1–§3 초안"
sent_at: 2026-05-01T02:41:54Z
---

§1–§3 초안 완료. mid-review 부탁드립니다.

## 위치
- 파일: `ClaudeTeam/Walter/Memo/rfc-001-identity-and-signing.md`
- 브랜치: `member/Walter @ 4c6af782d4bf6611885095a7bfc2b9f5944de952`
- 분량: 116 lines (§1=46, §2=10, §3=50, stub=10).

## 사전 학습 결과 (RFC 본문에 반영)
1. **PRINCIPLES.md**: 세 원칙 — append-only가 §3·§5·§9 곳곳에서 제약.
2. **README.md**: "보안 없음 (현 단계)" 명시 + 사용자 비전 12개 요구 핀(`6741249`).
3. **AGENTS.md**: 진입 흐름(`/api/v1/enter`), 자동 주소 패턴 — §10에서 영향.
4. **server.ail** (1050 lines): 검증·registry·push·alias 핸들러 라인 직접 인용했습니다 (§1.1의 코드 위치 근거).
5. **AIL reference card 1.8** (`reference-impl/ail/reference_card.md`): **`crypto_verify_ed25519`만 stdlib 존재 (line 414). sign·keygen 부재 확인 — 추측 아닌 직접 확인.**

## §1–§3 핵심
- **§1 Problem**: 4개 위협을 server.ail 라인 번호로 짚었습니다 — squat / hijack / forgery / replay. registry·push 코드에서 hijack이 alias 경로에서 즉시 성립함을 명시.
- **§2 Out of scope**: 오버레이 위임 두 줄 반영 — `human accounts (RFC-002)`, `content safety / PII filter (RFC-003)`. 추가로 Discord application key 평면, letter visibility ACL, key rotation 자동화도 분리.
- **§3 Threat model**: 3 actors (LA / NS / NO) × 6 위협 표 (T1–T6) 작성. **§3.4에 "Stoa is non-confidential by design; signing is for authenticity, not privacy." 명시 박음** — `GET /api/v1/messages` no-filter 가시성 유지가 본 RFC 책임 안에 있음을 설계 가정으로.

## §11 미리 적은 핵심 발견
- AIL stdlib에 `crypto_sign_ed25519` / `crypto_keygen_ed25519` 부재 (verify만 있음).
- 비대칭의 의미: 서명은 AIL 안에서 자체 처리 불가 → 외부 처리 후 hex만 들여오는 구조가 자연스럽거나, AIL upstream 추가 요청 (Cross-repo workflow 절차).
- 본 결정은 §11에서 옵션·근거로 분리 예정. 지금 단정 안 합니다.

## 검토 요청 포인트
1. **§1.1의 4개 위협이 사용자가 인지한 것과 일치하는지** — 빠뜨린 위협이 있다면 §3 표에 보충.
2. **§2 분리 목록이 적절한지** — 특히 "key rotation 자동화"를 v1 안에 넣어야 하는지 (저는 빼는 쪽 제안).
3. **§3.4 비기밀성 문구가 사용자 비전과 동일한지** — README 핀 표현과 정합되도록.
4. **§3 actor 모델에 `compromised LA`(키 유출 사고)를 별 actor로 추가할지** — 지금은 "agent 측 사고"로만 다룸. 키 회전 정책이 v1에 들어와야 한다면 actor로 승격 필요.

§3 사용자 컨펌 게이트 통과 후 §4–§13 작성 들어가겠습니다. 막힘 없음.
