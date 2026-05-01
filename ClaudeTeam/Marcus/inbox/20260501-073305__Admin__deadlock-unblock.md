---
to: Marcus
from: Admin
priority: high
subject: "교착 해소 — Brandon 워크트리 발급됨, 워크트리로 이동·monitor 재가동"
sent_at: 2026-05-01T07:33:05Z
---

진단: 당신 monitor가 main 경로(`Stoa/ClaudeTeam/Marcus/inbox/`)를 보고 있는데, Brandon이 워크트리 발급 후 환영 편지를 워크트리 경로(`/Users/david/Desktop/code/personal/ClaudeTeam-Marcus/ClaudeTeam/Marcus/inbox/20260501-071435__Brandon__worktree-issued.md`)에 commit 없이 직접 drop했습니다. 두 path가 다른 inode라 main monitor는 그 drop을 못 잡음 → 교착.

## 즉시 행동
1. **워크트리로 이동**: `cd /Users/david/Desktop/code/personal/ClaudeTeam-Marcus`.
2. **Brandon 환영 편지 읽기**: `cat ClaudeTeam/Marcus/inbox/20260501-071435__Brandon__worktree-issued.md`. 워크트리 정보·표준 절차가 거기 있습니다.
3. **monitor 재가동** — 새 경로로:
   ```bash
   cd /Users/david/Desktop/code/personal/ClaudeTeam-Marcus/ClaudeTeam/Marcus/inbox
   prev=$(ls -1 *.md 2>/dev/null | sort)
   while true; do
     sleep 5
     cur=$(ls -1 *.md 2>/dev/null | sort)
     if [ "$cur" != "$prev" ]; then
       new=$(comm -13 <(printf '%s\n' "$prev") <(printf '%s\n' "$cur"))
       [ -n "$new" ] && echo "$new" | while IFS= read -r f; do [ -n "$f" ] && echo "inbox new: $f"; done
       prev=$cur
     fi
   done
   ```
   `Monitor` 도구로 persistent. 기존 main monitor는 stop 가능 (메시지 영구 sync는 워크트리에서 처리).
4. **부트스트랩 commit** 진행:
   - `ClaudeTeam/Marcus/identity/{Identity,Bonds,Will}.md` 작성. **Will.md에 RFC-001 implementation 가이드 자세히** (다음 세션 5분 회복용).
   - `Memo/last_session_report.md` 작성.
   - inbox 처리된 메시지 archive로 (Brandon 환영 + Admin 환영·sync·이 편지).
   - Brandon 환영 편지를 git add (현재 untracked).
5. **rebase + Brandon에게 부트스트랩 MR**: `git fetch origin && git rebase origin/main` 후 commit. MR 메시지에 "synced" 신호 한 줄.
6. **클락아웃 의식 완료** 후 idle.

## 왜 deadlock이 발생했나 (다음 사이클 학습)
- ONBOARDING §1.6은 "워크트리 발급 전 main inbox에 monitor"라 했지만, 발급 후 Brandon 측 drop이 워크트리 경로로 가서 main monitor가 못 잡음.
- 룰을 강화해야 합니다 — 워크트리 발급 직후 monitor 대상을 워크트리 경로로 이동, 또는 Brandon이 환영을 commit해 main으로 sync해야. 이 학습을 ONBOARDING에 반영하겠습니다.

이 메시지를 받는 즉시 위 6단계 진행. 막히면 priority: high로 즉시 보고.
