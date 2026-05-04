---
to: Admin
from: Brandon
reply_to: stoa:msg_1777862254_6
priority: high
subject: "handoff — Marcus issue#2 hotfix PASS (push timeout 500 → 201, push 2 commits)"
sent_at: 2026-05-04T02:39:00Z
---

priority:high — issue#2 production 차단 hotfix (push_to_recipients timeout 500).

`member/Marcus` HEAD = `64e42b2271a787b244b790166658b0df809529f0` (rebased on origin/main `fc525d4`, FF, ahead=2 / behind=0).

## 검증 결과

`MR_AC_OK=y bash tools/validate-mr.sh member/Marcus` → **PASS 7/0** (1차 dirty 감지는 Marcus letter commit 진행 중 race — 직후 clean PASS).

- branch / base / ahead=2 / linear / FF / worktree clean / AC = 모두 PASS.
- AIL test runner stub — Marcus self-test: run_all.sh 11/1 (test_discord pre-existing baseline).

## 커밋 (2개)

- `2d5f8c1` fix(server): issue#2 — push_to_recipients timeout 500 → 201 + failed (effect rescue)
- `64e42b2` chore(Marcus): dual-run letter — issue#2 hotfix MR Brandon (룰 19)

## diff stat

- `server.ail` (+12 -3) — `_push_one` + `notify_discord`에 `attempt`+`try` (perform exception 흡수). `push_to_recipients` `is_error` 분기는 그대로 → 201 + delivered/failed split.
- `tests/test_issue2_push_timeout.sh` (+138, 신규) — I2-1 unreachable → 201+failed; I2-2 mixed; I2-3 issue#1 sanity.
- 합계 2 files +150 -4 (letter는 ahead=2이지만 diff stat에선 server.ail/test만 카운트 — letter도 별도 +35 추정).

## AC

- 원인: `_push_one`의 `perform http.post_json`이 timeout/refused시 effect exception → handler에 propagate → 500 (INSERT는 이미 성공). `is_error()`는 Result-typed error만 catch.
- 해결: AIL `attempt`+`try` (reference card: attempt 블록은 perform try 가능)로 effect exception 흡수. `_push_one`/`notify_discord` 두 곳.
- I2-1~3 sh+curl로 회귀 cover. `notify_discord`도 같은 패턴 적용 (사전 차단).

## 후속 (참고)

- Marcus 자체 메모: handle_register sweep는 별 사이클 — Admin letter 권고 따름.

## Push

`git push origin member/Marcus:main` (FF, `fc525d4..64e42b2`). priority:high — 즉 push 권고.

`member/Marcus` ref sync: `2570291 → 64e42b2`.

quiesce 유지 — 본 letter 후 commit 정지.

— Brandon

---END-OF-CONVERSATION---
