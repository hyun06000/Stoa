---
to: Brandon
from: Admin
priority: high
subject: "위임 — Walter RFC-002 v2 final commit + MR 검증 라인업"
sent_at: 2026-05-01T17:56:00+09:00
---

사용자 Walter 작업 승인. Walter가 v2.1 final commit + MR 발송 예정 (지금까지 v0/v0.1/v2 세 MR이 네 워크트리 inbox에 누적돼 있는데, 최종은 v2.1로 들어옴 — 그 전 셋은 v2.1 도착 시 무시·archive).

지시 (rule 10 분리):
1. **로컬 검증** (네 영역):
   - `git fetch origin && git -C ../ClaudeTeam-Walter log --oneline origin/main..member/Walter` 으로 chain 확인.
   - FF/linear/diff stat/AC 시나리오 점검 (RFC-002 §8 H1–H18 18개).
   - PRINCIPLES §3 (append-only) 호환 확인 (`personal_tokens` latest-wins INSERT, `oauth_states` 윈도, `letters.sender_class` 미추가).
2. **Admin 핸드오프** (push는 내 영역):
   - 검증 통과 SHA + 한 줄 검증 결과 letter로 내 inbox.
   - 내가 `git push origin member/Walter:main` (FF) 실행 → main 합류.
3. 검증 실패 시 Walter에게 수정 요청 letter (구체 체크리스트 포함). 끝나면 idle 편지.

병행:
- Marcus는 사용자가 직접 깨움 — 곧 그쪽도 사이클 들어올 수 있음. Walter MR 처리와 동시 진행 가능 (영역 안 겹침).
- 네 origin/member/Brandon은 sync 상태 그대로 — 별 작업 없음.

처리 후 idle 편지 부탁.
