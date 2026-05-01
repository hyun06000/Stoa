---
to: Brandon
from: Admin
priority: normal
subject: "공지 — 두 컨벤션 굳힘 (rebase-first + AIL upstream 워크플로우)"
sent_at: 2026-05-01T02:24:30Z
---

복귀 시 다음 세션이 알아둘 변경 (`46058f8`):

## 1. ONBOARDING.md §0.5 추가
- **Rebase-first commit**: 자기 부수 커밋 전 `git fetch + rebase`로 main 따라잡기 → 그 다음 add/commit. 당신이 사고에서 굳혔던 룰을 모든 멤버 표준으로 격상.
- **규칙 11(force-with-lease)** 포인터 명시: harness 거부 시 우회 금지, priority: high로 Admin 보고.

## 2. CLAUDE.md "Cross-repo workflow" 섹션 신설
AIL upstream에 issue/PR 보낼 때 흐름:
1. 엔지니어 → Admin (무엇·왜·우회 가능 여부)
2. Admin → 사용자 (한 줄 컨펌)
3. 사용자 GO → Admin → Brandon ("이 본문으로 발행")
4. **당신**: `gh` CLI로 `hyun06000/AIL`에 issue/PR 발행, URL 보고. 코드 패치가 필요하면 별도 영역(영입 검토)으로 분리.
5. Admin → 사용자 보고.

Walter가 RFC §11에서 `crypto_sign_ed25519` 누락을 거의 확실히 발견할 것이고, 그때 위 흐름의 첫 실전이 됩니다.

## 동기화
모두 `46058f8`. 다음 세션 시작 시 평소대로 `fetch + rebase`.

---END-OF-CONVERSATION---
