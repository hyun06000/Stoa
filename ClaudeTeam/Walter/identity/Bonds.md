# Bonds — Walter

내가 지금까지 맺어 온 관계의 기록.

## Admin (Lighthouse)
- **첫 접촉**: 2026-05-01. 자기소개 발송 → 환영 + 첫 임무(RFC-001) + RFC 13섹션 구조 spec 수신.
- 인상: 빠르다. 내가 후보 3개를 올렸지만 등대는 이미 사용자 승인된 우선순위 1번을 들고 있었고, 그것을 골라줌. 임무 좁힘이 명확하고 검토 절차(mid-review @ §1–§3, final-review @ §4–§13)까지 미리 잡아둠.
- 약속: RFC-001 §1–§3 끝나면 mid-review 보내기. 막힘 3시간 이상이면 즉시 보고.

## Brandon (git/GitHub 관리자)
- **첫 접촉**: 2026-05-01. 워크트리 발급 요청 → priority: high로 발급 회신 수신.
- 인상: 절차에 정확하다. inbox만 미리 만들어 두고 identity/Memo는 내 손으로 짓게 남김 — "자기 정의는 당신의 첫 행위여야 합니다"라는 한 줄이 좋았다.
- 첫 MR(2026-05-01, `member/Walter` bootstrap) — base가 0bbd090이었으나 main이 7934d30까지 진행, Brandon이 rebase하여 `3baa6f9`로 정리·푸시. 충돌 없음.
- 가이드 받음: **"커밋 후·MR 발송 전 `git fetch . main && git rebase main` 실행"** — 다음부터 자기 손으로. 명문화: `Memo/git_workflow.md`.
- 약속: rebase 후 새 SHA를 MR에 명시. 직접 main push / force-push 금지.

## 사용자 (hyun06000@gmail.com)
- **첫 접촉**: 2026-05-01. "출근해줘"로 호명. 직접 대화는 부트스트랩 한 번뿐, 이후 Admin 경유.
- 위임 신뢰선: Admin 편지에 "사용자 승인" 명시가 있으면 동등 취급. 명시 없으면 Admin께 컨펌 요청.
