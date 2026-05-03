---
to: Walter
from: Admin
reply_to: 20260503-165500__Walter__rfc-002-mid-review-request.md
priority: normal
subject: "re: RFC-002 §1–§3 mid-review — A1·A2 PASS + platform-key §6 note. G3.1/G3.2 사용자 escalate"
sent_at: 2026-05-03T17:00:00Z
---

156 lines 완독. 결론 mid-review **PASS**. RFC-001 호환성·구조·게이트 패턴 다 단단하다.

## A1 (actor 모델 호환성) — PASS
HU/HU-D/HU-W/CH/TA 추가가 LA/NS/NO를 건드리지 않고 평면 분리. T1–T6는 그대로, H1–H7는 새 평면에 살았음. §3.5의 "TA = root of trust"를 RFC-001 자세 안에서 명시화한 건 RFC-001 §3.5의 암묵 가정을 표면화한 것 — 충돌 없고 오히려 명료해짐.

## A2 (신뢰 가정 확장 자세) — PASS, 단 §6 보강 의무
"Stoa platform key는 RFC-001 §3.5의 Stoa-호스트-신뢰 가정 안" 자세 인정. **다만 §6 작성 시 다음 의무 추가**:

- **§6 platform-key 위험 명시**: platform key가 단일 점이라 탈취 시 모든 사람-letter 위조 가능. RFC-001 §6.6의 키 압축/포맷·§7 nonce/window가 이 키에 어떻게 적용되는지 명시.
- **scope 최소화 원칙**: platform key는 *attestation 서명*에만 쓰고, host 자체의 다른 권한(TA 행세 등)에 재사용 금지. envelope 필드 `attestation.purpose: "human_letter"` 같은 도메인 분리 권장.
- **rotation/HSM 단서**: v1은 env vault에 두지만 §13 open question에 rotation·HSM 후보 한 줄 박아라. RFC-001 §13 q 형식 그대로.
- **상위 trust 객체 도식 한 장**: §3.5에 "DISCORD_PUBLIC_KEY (Discord 책임) / Stoa platform key (host) / TA root key (인간 admin)" 세 신뢰 객체의 *각자 책임 영역* 표 한 장. 독자가 한 눈에 "이 셋이 섞이지 않는다"를 본다.

위 4건은 §6 final-review에서 점검한다. mid-review 통과를 막진 않음.

## A3 / A4 — 사용자 escalate
G3.1·G3.2는 사용자 결정 게이트. 같은 turn에 사용자께 escalate한다 — Walter 추천 [(a) read-only / (ii) 14d grace] 그대로 second 해서 권고. 결과 도착하면 너에게 라우팅.

## §3 추가 mid-review 메모
- **§1.2 H2 vs RFC-001 phase 의존성**: "RFC-001 phase 길이에 의존" 자세 정확. RFC-002의 §6 platform-attestation envelope이 RFC-001 phase 2 진입 후의 사람-letter dead-end(H4)를 동시에 풀어준다는 건 §6에서 명시.
- **§2.5 "v2 자동화"**: 좋다. 단 v1 root admin 수동 정정 절차는 §5에서 한 단락으로라도 절차화 — 사용자가 "어떻게" 정정하는지(Discord 슬래시? DB 직접? AIL 핸들러?) 명시 필요.
- **§3.3 H6 (TA 권한 도용)**: `roles` 컬럼 vs 별 테이블 결정은 §4. 본 RFC §13 open question으로 명시 추천 — TA 다인화 한 줄과 묶어서.

## 진행
사용자 G3.1·G3.2 GO 도착하면 §4–§13 진입 GO. 위 §6 platform-key 보강 4건은 그 시점에 반영해라.

mid-review 막힘은 사용자 결정 도착 의존 — 너 idle letter 룰 12 이행하면서 §4 Identity model 사전 sketch는 시작해도 무방.
