# §11 Cross-repo workflow — AIL upstream 발행 후보 (초안)

CLAUDE.md "Cross-repo workflow" (`46058f8`) 절차의 1단계 산출물.
사용자 §3 컨펌이 떨어진 후 §11 결정 시점에 Admin께 별도 메시지로 발송할 한 줄(들).

---

## 후보 한 줄 (Admin inbox 행)

> AIL stdlib에 `crypto_sign_ed25519` + `crypto_keygen_ed25519` + cryptographic random 부재(verify만 있음, reference card 1.8 line 414). RFC-001 §11 결정에 따라 추가 요청 후보. 우회: 서명·키·nonce 생성을 AIL 외부(Python/openssl 등)에서 처리하고 hex/base64로 들여오는 비대칭 구조.

## 무엇 / 왜 / 우회 가능 여부

### 무엇
- `crypto_sign_ed25519(secret_key_hex: Text, message: Text) -> Text` (서명 hex 반환).
- `crypto_keygen_ed25519() -> Result[[Text, Text]]` (`[secret_key_hex, public_key_hex]` 페어).
- `crypto_random_bytes(n: Number) -> Result[Text]` (hex 인코딩, n 바이트). nonce 생성용.

### 왜
- RFC-001 §6 letter signing은 발신자가 자기 letter를 서명한다는 가정 위에 선다. **AIL 기반 에이전트가 자기 letter를 self-sign할 수 없다면 신원·서명의 한쪽 끝이 끊긴다.**
- verify만 있는 비대칭은 "AIL 안에서 검증은 하지만 서명은 못한다"는 구조 — 운영상 모든 AIL 에이전트가 외부 서명 도구를 필수 동반해야 한다.
- nonce는 §7 replay defense의 핵심. cryptographic random 부재 시 발신자가 약한 random을 쓸 위험.

### 우회 가능 여부
- **단기**: 가능. 비-AIL 에이전트는 자기 환경에서 서명. AIL 에이전트는 Python wrapper나 shell 호출로 서명 후 hex 반입. RFC-001 v1은 이 구조로 나갈 수 있음.
- **장기**: 비대칭이 표면적이 아니라 구조적인 비용. 새 에이전트가 합류할 때마다 외부 도구 셋업이 강제되고, 본 프로젝트의 "모든 코드는 AIL" 컨벤션(CLAUDE.md 규칙 10)과 정면 충돌.

## §11 결정 옵션 (RFC 본문에 들어갈 옵션)

| 옵션 | 단기 비용 | 장기 비용 | 트레이드오프 |
|---|---|---|---|
| A. AIL upstream 추가 요청 안 함, 외부 서명 영구 | 0 | 매 합류마다 외부 도구 셋업, AIL-only 컨벤션 위반 | 빠른 시작, 구조적 비대칭 |
| B. AIL upstream 추가 요청 (sign + keygen + random) | upstream PR 사이클 1회 | 0 | upstream 의존, 그러나 컨벤션 정합 |
| C. 임시 외부 서명 → upstream 떨어지면 자동 마이그레이션 | A 비용 + 마이그레이션 시점 비용 | 0 | 두 phase 운영 부담 |

**제안 (RFC 본문 §11에 적을 추천)**: 옵션 B. 근거: 컨벤션 정합 + 본 프로젝트가 AIL의 첫 자율 에이전트 사용처라 stdlib 확장이 정당화되는 시점. 단 사용자 결정 게이트.

## 발송 절차 (Cross-repo workflow)
1. 사용자 §3 컨펌 후, Admin께 위 "후보 한 줄" 발송 (priority: normal).
2. Admin이 사용자 컨펌.
3. GO 시 Brandon이 `gh`로 `hyun06000/AIL` issue/PR 발행.
4. 본 RFC §11 본문은 결정 결과(옵션 A/B/C)를 적시. 결정되지 않은 채로 머지하지 않음.
