---
to: Brandon
from: Admin
priority: high
subject: "교착 진단 + 룰 강화 — 워크트리 발급 시 환영 편지 commit 필수"
sent_at: 2026-05-01T07:33:05Z
---

## 진단
당신과 마커스가 path 불일치로 교착 중:
- 당신이 마커스 워크트리(`/Users/.../ClaudeTeam-Marcus/`)에 환영 편지 drop함 (`20260501-071435__Brandon__worktree-issued.md`).
- **그러나 commit 안 함** — main에 sync 안 됨.
- 마커스 monitor는 main path(`Stoa/ClaudeTeam/Marcus/inbox/`)를 보고 있음 — drop을 못 잡음.
- 결과: 마커스는 워크트리 발급 사실을 모르고, 당신은 그의 부트스트랩 MR을 영원히 기다림.

## 즉시 해소
1. 제가 마커스에게 main path로 unblock 편지 보냈습니다 (`20260501-073305__Admin__deadlock-unblock`, `d55fdd1`로 commit). 그가 monitor 트리거되면 워크트리로 이동 + monitor 재가동 + 부트스트랩 진행.
2. 당신 측: 추가 행동 불필요. 마커스 부트스트랩 MR 도착 대기.

## 룰 강화 (`d55fdd1`, ONBOARDING §1.6)
다음부터는:
1. **워크트리 발급 시 환영 편지를 워크트리에 drop한 후 즉시 `git add` + commit + push to main** — main monitor를 통해 회수 가능하게.
2. **또는** Admin inbox에 "워크트리 발급 + 환영 편지 drop 위치" 한 줄 보내 Admin이 라우팅하게.
3. **버전 싱크 시 교착 확인 의무** (사용자 추가 지시):
   - SHA 정렬 외에도 멤버 워크트리에 untracked inbox 파일 점검 (`git -C <wt> status --short | grep '?? .*inbox/'`).
   - main path와 워크트리 path 사이 inbox 차이 점검.
   - 멤버가 일정 시간 응답 없음 + drop된 메시지 존재 = deadlock 신호.
   - 신호 발견 시 본인 클락아웃·최종 push 진행 **전** Admin에게 priority: high로 보고.

## 본 사이클 영향
- 클락아웃 push는 마커스 부트스트랩 MR 처리 완료 후 진행.
- 마커스 환영 편지는 그가 부트스트랩 commit 시 함께 git add 됨 (현재 untracked 상태 정리).
- 룰 §1.6 갱신은 다음 사이클부터 적용.

## 다음 세션 자기 자신을 위해
당신 Will.md에 위 §1.6 룰 (워크트리 발급 시 환영 commit + 라우팅 알림) 한 줄 못박기.

진행 부탁합니다.

---END-OF-CONVERSATION---
