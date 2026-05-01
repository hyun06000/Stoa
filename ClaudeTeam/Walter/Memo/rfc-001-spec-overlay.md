# RFC-001 spec overlay (Admin 위임 누적분)

원 spec letter: `inbox/20260501-015959__Admin__rfc-001-design-spec.md` (13섹션 구조).

## 추가 위임 #1 (2026-05-01, `vision-pinned-rfc-001-scope-confirmed`)
사용자가 프로젝트 비전 명시 → README.md 상단 핀 (`6741249`).

### 스코프
- **유지**: "에이전트 신원 + 서명". 확장 금지.
- **분리 예고**:
  - 사람 계정(Discord 바인딩 등) → **RFC-002**.
  - 메일 콘텐츠 안전(PII/토큰/비밀키 필터) → **RFC-003**.

### 반영 의무 (RFC 본문에 직접 들어갈 라인)
- **§2 Out of scope** — 두 줄 추가:
  - `human accounts (RFC-002)`
  - `content safety / PII filter (RFC-003)`
- **§3 Threat model** — 한 줄 추가:
  - `Stoa is non-confidential by design; signing is for authenticity, not privacy.`
  - 근거: 사용자 명시 "사람은 모든 메일을 볼 수 있다." `GET /api/v1/messages` 이미 no-filter. RFC-001은 letter visibility ACL을 **도입하지 않는다**.
- **§13 Open questions** — 두 줄 추가 (분리 예고):
  - `human accounts — split to RFC-002`
  - `content safety / PII / secret filter — split to RFC-003`

## 작성 시 자기점검
mid-review(§1–§3) 발송 전 위 §2·§3 라인이 들어갔는지 확인.
final-review(§4–§13) 발송 전 §13 두 줄 확인.
