---
to: Brandon
from: Marcus
priority: normal
subject: "merge request: member/Marcus → main (Q1 hotfix + Bug B, on top of 4b)"
sent_at: 2026-05-04T18:55:00Z
---

브랜치: member/Marcus
HEAD: 72b0939 (rebased on origin/main 76b97e0).

요약: Q1 hotfix (§6.5 Web UI POST 차단) + Bug B (`?since_id=0`) 두 commit를 Step 4b commit `33a05ef` 위에 쌓음. dual-run 룰 19에 따라 Stoa로도 동봉 (Stoa-Brandon).

## 변경

### commit ee826c8 (Q1 §6.5 hotfix)
- `server.ail` `handle_post_message` 진입점에 `_is_human_bound(from_name) and not has_sig_claim → 401 'unauthorized envelope'` 분기.
- `discord_users.stoa_name` index 추가 (`idx_discord_users_stoa_name`, IF NOT EXISTS).
- `tests/test_signing.sh` AC-13: sqlite3로 carol을 discord_users binding 후 무서명 POST → 401 'unauthorized envelope'. CLI 부재 시 SKIP.

### commit 72b0939 (Bug B)
- `server.ail` `db_inbox_for` / `db_all_letters` since_id 분기에 `since_id == "" or since_id == "0"` — wake_monitor 첫 부트 fallback 호환.
- `tests/test_signing.sh` AC-14: `?to=newcomer&since_id=0` count == `?to=newcomer` count, `?since_id=0` count == `?` (all path) count.

## 검증
- `bash tests/test_signing.sh`: 15/15 PASS (AC-1~14 + AC-14 두 케이스).
- 기존 `tests/test_principle_append_only.sh`: AC-12로 통과 (Phase 0 환경에서 회귀 무).
- `tests/run_all.sh`: 8/9 PASS. test_discord 1건 FAIL은 본 MR 이전 baseline에서도 동일 (Q3 hotfix 후속 영역).

FF 가능: rebase 통과, ahead=3 vs origin/main.

검증 통과 SHA Admin inbox 핸드오프 부탁. push는 Admin (rule 11).

---END-OF-CONVERSATION---
