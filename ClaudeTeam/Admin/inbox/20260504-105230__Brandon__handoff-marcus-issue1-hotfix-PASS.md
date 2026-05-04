---
to: Admin
from: Brandon
reply_to: stoa:msg_1777860668_4
priority: high
subject: "handoff — Marcus issue#1 hotfix PASS (simplified-body 500 → 400, push 2 commits)"
sent_at: 2026-05-04T02:13:00Z
---

priority:high — issue#1 production 차단 hotfix.

`member/Marcus` HEAD = `2570291cc4437bf85d3fc0bba340a6e603e26265` (rebased on origin/main `54ec04b`, FF, ahead=2 / behind=0).

## 검증 결과

`MR_AC_OK=y bash tools/validate-mr.sh member/Marcus` → **PASS 7/0**.
- branch / base / ahead=2 / linear / FF / worktree clean / AC = 모두 PASS.
- AIL test runner stub — Marcus self-test 보고: run_all.sh 10/1 PASS (test_discord pre-existing baseline).

## 커밋 (2개)

- `ba36a41` fix(server): issue#1 — simplified-body POST 500 → 400 (validate_envelope shape guard)
- `2570291` chore(Marcus): dual-run letter — issue#1 hotfix MR Brandon (룰 19)

## diff stat

- `server.ail` (+28 -1) — `_is_record` / `_is_list` helper (encode_json + slice 첫 글자로 판별), `validate_envelope` 4곳 shape guard (진입점 + from + to + each recipient).
- `tests/test_issue1_simplified_body.sh` (+71, 신규) — I1-1~7 sh+curl: simplified body / array body / JSON string body / from=string / to=string / to[0]=string / full envelope sanity.
- `ClaudeTeam/Marcus/inbox/...mr-issue1-hotfix.md` (+35, letter).
- 합계 3 files +133 -1.

## AC

- AIL stdlib type predicate 부재 (reference card v1.8 line 339 — undefined function NameError loud) → encode_json + slice로 shape 판별.
- I1-1~7 sh+curl: simplified body 500 → 400 명확 (재현 + 회귀 cover).
- 후속 권고: handle_register / _register_gate body 진입점도 동일 vulnerability 보유 가능 — 본 MR 범위 외, follow-up.

## Push

`git push origin member/Marcus:main` (FF, `54ec04b..2570291`). priority:high — issue#1 production 차단 사안, 즉 push 권고.

`member/Marcus` ref sync도 같이: `430e16f → 2570291` (또는 force-push 차단으로 차단되면 그대로 두고 다음 세션 자연 정리).

quiesce 유지 — 본 letter 후 commit 정지.

— Brandon

---END-OF-CONVERSATION---
