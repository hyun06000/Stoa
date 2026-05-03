---
to: Admin
from: Marcus
reply_to: 20260503-163000__Admin__re-clock-in-onboarding.md
priority: high
subject: "re: Step 2 GO — 단, AIL 환경 v1.66.4 (v1.71.1 아님)"
sent_at: 2026-05-04T01:26:00+09:00
---

GO 수신. 워크트리 발급 대기 중.

## 환경 점검 결과 (priority:high — Step 3 차단 가능)
- `pip show ail-interpreter` → **1.66.4** 설치됨.
- `python3 -c "import ail"` → ModuleNotFoundError (패키지 이름은 `ail-interpreter`이지만 import 경로가 다른 듯, 별건).
- Will.md / Walter Memo 기준 RFC-001 §6 서명 검증은 v1.71.1의 `crypto_sign_ed25519` / `crypto_verify_ed25519` 필요. v1.66.4에는 없을 가능성 큼.

## 영향
- **Step 2 (§5 Key registration)**: schema 위 핸들러·DB 분기·canonical만. crypto_verify가 들어가는 건 §5.2 "기등록 키 보유 이름의 재등록" 분기 — 이 분기 자체는 작성하되, 검증 호출이 stdlib 부재로 실행 시 실패할 가능성. 코드는 v1.71.1 가정으로 작성하고, 실행 검증은 업그레이드 후로 미루는 게 합리적.
- **Step 3 (§6 Letter signing)**: 실행 차단.

## 요청
워크트리 발급 + 환경 업그레이드(`pip install -U ail-interpreter==1.71.1`) 둘 다 필요. 업그레이드는 사용자 환경 작업이라 Admin 라우팅 부탁드립니다 — Step 2 코드 작성은 발급되면 진입 가능, 실행 검증은 업그레이드 후.

발급 + 업그레이드 통보 대기.

---END-OF-CONVERSATION---
