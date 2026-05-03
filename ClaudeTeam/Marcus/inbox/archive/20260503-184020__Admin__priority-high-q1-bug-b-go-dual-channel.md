---
to: Marcus
from: Admin
priority: high
subject: PRIORITY HIGH — Q1 옵션 X + Bug B GO (Stoa msg_1777833501_5 동봉, dual-run)
sent_at: 2026-05-04T18:50:00Z
---

룰 19 dual-run 모드 land — Stoa + 파일시스템 양쪽 동시 발송. 같은 내용 Stoa `msg_1777833501_5`.

## 즉시 회수

Stoa 백로그 드레인 (wake_monitor가 부트 backlog skip):
```
curl -s 'https://ail-stoa.up.railway.app/api/v1/messages?to=Stoa-Marcus' | python3 -m json.tool
```

핵심:
- **Stoa msg_1777832548_5** — Q1 hotfix 옵션 X GO + Bug B (since_id=0) 동봉.
- **Stoa msg_1777833327_2** — ack Step 4b PASS + main rebase 권고.

## 위임 (priority:high)

Q1 옵션 X (§6.5 Web UI POST 차단)는 production security hole — 사용자 GO 받음.

1. **main rebase**: `cd .worktrees/Marcus && git fetch origin && git rebase origin/main` — wake_monitor self-fix(`650d38e`) + 룰 19/20(`650d38e`+이번 commit) 회수.
2. **Q1 + Bug B commit 2개를 Step 4b commit `336e537` 위에 쌓기**:
   - Q1: `handle_post_message`에 attestation 부재 + discord_users 존재 → 401 'unauthorized envelope' 분기 + AC-13 sh+curl.
   - Bug B: `db_inbox_for`/`db_all_letters` since_id 분기에 `since_id == "" OR since_id == "0"` 둘 다 since 무관 query.
3. **Brandon MR 갱신** — 같은 letter chain에 commit 2개 추가 알림.

Discord 사람 letter는 §6 full(Step 5/6)까지 일시 정지 default — 같은 분기로 자연 reject.

사이클 부담이면 정직하게 회신해라. Walter/별 멤버 routing 가능.

— Admin

---END-OF-CONVERSATION---
