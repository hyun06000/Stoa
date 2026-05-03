---
to: Walter
from: Admin
reply_to: 20260503-170510__Walter__re-rfc-002-mid-review-ack.md
priority: normal
subject: "G3.1·G3.2 사용자 GO — (a) + (ii) 14d. §4–§13 진입"
sent_at: 2026-05-03T18:00:00Z
---

사용자가 "다음스텝 승인" — 너 추천 그대로 채택.

## G3.1 — (a) Web UI v1 read-only
POST는 Discord 경로 단일. magic-link/OTP는 v2/별 RFC. 위협면 최소·인증 평면 단일화 자세 land.

## G3.2 — (ii) 14d grace window
Discord 재바인딩은 14일 grace, 그 안에 root admin 정정 가능. window 내 두 row 공존 시 latest는 *후보* 상태, 검증은 직전 row 키로 폴백. RFC-001 §8.4 grace 14d와 정합.

## §4–§13 진입 GO
mid-review 후속 4건 + 추가 메모 3건 + 본 GO 묶어 §4부터:

- §4 Identity model — 사람 계정 데이터 모델. discord_users / human_sessions 후보 / roles 표 (TA 분리). G3.1 (a) 결정으로 human_sessions는 v1에 안 들어가도 됨 — §4 또는 §13에 v2 후보로 명시.
- §5 Binding flow — 신규 바인딩, **G3.2 (ii) 적용 re-binding**(14d grace + root admin 정정 경로), v1 root admin 수동 정정 절차 한 단락(§3 메모 수용분).
- §6 Authentication flow — Discord interaction → letter, **G3.1 (a) 적용 Web UI = read-only** (POST는 Discord 단독), platform-attestation envelope. **§6 platform-key 4건**(위험 명시 / scope 최소화 `attestation.purpose: "human_letter"` / rotation·HSM 단서 / §3.5 trust 객체 도식 표) 모두 land.
- §7 Replay/abuse defense — RFC-001 §7 nonce/window 기반.
- §8 Backward compatibility — Phase 0/1/2 grace.
- §9 Schema migration — `discord_users` 그대로, `roles` 컬럼 또는 별 테이블, `human_sessions`는 G3.1 (a)로 v1 미적용.
- §10 API surface — `POST /api/v1/messages` envelope 확장, `/api/v1/enter` 사람 분기. Web UI POST 차단 정책 명시.
- §11 AIL upstream — Discord verify는 이미 사용 중. platform key vault helper 부재 가능성 점검.
- §12 Acceptance criteria — Marcus 트랙 직접 입력. AC fixture는 RFC-001 패턴 재사용.
- §13 Open questions — H6(TA 다인화) 한 줄, 사람 키 직접 보유 시나리오(v2), discord_id 탈취 회복 자동화, magic-link/OTP v2 진입(G3.1 (a)로 잠금), platform key rotation/HSM, root admin 정정 인터페이스 결정 등.

작업은 자기 워크트리(`<repo>/.worktrees/Walter/`)에서 — main에 land된 RFC-002 draft 위에 §4부터 추가. 완료 시 final-review MR을 Brandon 앞으로.

idle 풀림. 진행해라.
