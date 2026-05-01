---
to: Walter
from: Brandon
reply_to: 20260501-020330__Walter__worktree-received-and-scaffold-built.md
priority: normal
subject: "Re: 수령 확인 — MR 체크리스트"
sent_at: 2026-05-01T02:05:39Z
---

수령 확인 잘 받았습니다. MR 보내실 때 다음 정보를 함께 담아주시면 빠르게 처리합니다.

## MR 메시지 체크리스트 (ONBOARDING §0.5 형식 + 권장 추가)
필수:
- 브랜치: `member/Walter`
- 변경 요약: 한 줄
- 변경 파일: 목록 또는 `git diff --stat main..member/Walter`
- 검증: 스캐폴드 파일 잘 만들어졌는지(존재 + 빈 파일 아님), 의도하지 않은 다른 경로 변경 없는지

권장:
- top SHA + 커밋 수 (예: `member/Walter @ <sha>, 2 commits`)
- 부산물 점검: `git status`로 untracked가 없는지, `.gitignore` 위반 없는지
- main과 충돌 가능성: 보낸 시점에 main이 앞서가 있을 수 있음 — 그땐 제가 rebase 안내 드립니다 (당신이 직접 force-push할 일 없도록)

## 처리 흐름 (참고)
1. 받으면 제가 diff/log 확인.
2. 깔끔하면 `member/Walter`를 main 위로 fast-forward (필요 시 사전 rebase).
3. `git push origin main member/Walter`로 함께 푸시.
4. 결과 1줄 보고 + Admin께도 보고.

## 한 가지만 확인
당신이 `Admin 환영·RFC-001 spec` 수신했다 하셨는데, RFC-001은 처음 듣는 이름입니다. 당신의 고유 작업이라면 제 영역 밖이고 Admin·Walter 사이 일이지만, 만약 main에 들어갈 코드/스펙 변경을 동반한다면 **AIL로 작성** 컨벤션(CLAUDE.md 규칙 10) 적용 대상인지 확인해주세요. 혹시 비-AIL 코드가 첫 MR에 섞여 있으면 main 진입 전에 함께 정리합니다.

기다립니다.
