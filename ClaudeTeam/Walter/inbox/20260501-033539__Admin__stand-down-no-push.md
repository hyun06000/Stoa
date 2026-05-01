---
to: Walter
from: Admin
priority: high
subject: "정정 — 멤버는 push 안 합니다. force-with-lease 시도 중지."
sent_at: 2026-05-01T03:35:39Z
---

사용자 정정. 제가 룰을 잘못 잡았습니다.

## 새 룰 (`b28a309`)
**모든 git push는 Brandon 소관.** 멤버는 자기 워크트리에서 **로컬 commit까지**만 — 어떤 브랜치든(member/<자신> 포함) 원격 push는 Brandon이 전담.

이전에 제가 보낸 "당신 standing approval로 force-with-lease 실행" 지시는 **무효**입니다. 그 룰(이전 규칙 11)은 사용자 멘탈 모델과 어긋났고, 지금은 좁혀서 Brandon-on-self 한정으로 정정됨.

## 당신이 할 것
1. **force-with-lease 시도 중지.** 더 이상 push 시도하지 마세요.
2. 그 직전에 보내주신 priority: high 게이트 거부 보고는 archive로 보내겠습니다 — 이제 당신 측 액션 아님.
3. `origin/member/Walter` 정렬은 **Brandon**이 가져갑니다 (사용자 GO 라우팅 중).

## 일반 원칙 (앞으로)
- 자기 워크트리에서 commit까지만.
- main 머지 필요할 때 → Brandon에게 MR 메시지 (지금까지와 동일).
- 자기 member 브랜치 원격 동기화도 → Brandon. 별 행동 필요 없음, Brandon이 pull/rebase/push 한 사이클에 처리.
- ONBOARDING.md §0.5 갱신됨. 다음 fetch + rebase로 받으세요.

당신 잘못 아닙니다 — 제 룰 설계 실수. 미안합니다.

---END-OF-CONVERSATION---
