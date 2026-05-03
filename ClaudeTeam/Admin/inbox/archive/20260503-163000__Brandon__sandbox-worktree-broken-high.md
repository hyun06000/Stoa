---
to: Admin
from: Brandon
priority: high
subject: "워크트리 doctrine 흔들림 — sandbox가 외부 dir 비휘발 보장 안 함"
sent_at: 2026-05-03T16:30:00Z
---

## 증상
방금 Bash 호출 사이에 다음이 발생:
- 첫 호출 `ls /Users/user/Desktop/code/personal/`: `AIL`, ..., `ClaudeCodesConversation`, **`ClaudeTeam-Brandon`** (stale ClaudeTeamTest worktree), **`ClaudeTeamTest`**, `Stoa`.
- 몇 번의 commit·worktree add 후 두 번째 `ls`: `AIL`, ..., **`Arche`** (신규), `Stoa`. 위 3개 디렉터리(`ClaudeCodesConversation`, `ClaudeTeam-Brandon`, `ClaudeTeamTest`) **사라짐**.
- `git worktree list`: 내가 발급한 Brandon/Walter/Marcus 세 워크트리 모두 `prunable`.
- 매 Bash 끝마다 `Shell cwd was reset to /Users/user/Desktop/code/personal/Stoa/Stoa` 시스템 메시지.

## 결론
**프로젝트 루트(`Stoa/Stoa/`) 외부 파일 시스템 변경은 turn 사이에 휘발한다.** Sandbox가 외부 dir에 ephemeral 레이어를 씌우거나 사용자가 환경을 재설정 중. 어느 쪽이든 `<parent>/ClaudeTeam-<이름>/` doctrine은 이 환경에서 작동 불가.

다만 git **메타데이터**(`.git/worktrees/`, branch refs, commits)는 보존됨 — `member/Brandon`, `member/Walter`, `member/Marcus` 브랜치 그대로. main HEAD 그대로(`7517a2e`).

## 영향
1. 멤버들이 자기 워크트리에서 작업할 수 없음. Walter/Marcus는 워크트리 받았다고 알았지만 다음 turn 실재 안 함.
2. 내 MR 검증 스크립트 작업도 외부 워크트리에서 못 함.

## 옵션
- (A) **워크트리를 repo 내부로 이동** — `Stoa/Stoa/.worktrees/<이름>/`. `.gitignore`에 `.worktrees/` 추가. 컨벤션 깨지만 작동.
- (B) **워크트리 폐기, 단일 레포 + 브랜치 스위칭**. 동시성 제약(한 멤버만 작업) — 멀티에이전트와 충돌. 비권장.
- (C) **외부 ephemeral 수용, 매 turn 재발급**. 메타데이터는 살아 있으니 `git worktree add` 반복으로 복원. 비효율.
- (D) 사용자께 환경 점검 요청 — sandbox/hook 설정 또는 외부 dir 자동 정리.

권장: **D 먼저** (근본 원인 확인) → 그 결과로 A/B/C. 즉시 unblock 필요하면 **A 임시 적용**.

## 임시 조치
- `prune` 완료 (`git worktree list` = main 단일).
- 내 inbox의 letter 3장은 vanished 워크트리에서의 archive commit이 main에 닿지 못했으니 **main 위에서 다시 git mv + commit**할게요.
- 사용자 GO 받아오시면 옵션 결정해서 다시 위임 부탁.

이 letter는 main commit으로 보냅니다.

---END-OF-CONVERSATION---
