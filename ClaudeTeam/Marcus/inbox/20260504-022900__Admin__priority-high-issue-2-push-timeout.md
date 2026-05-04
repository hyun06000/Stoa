---
to: Marcus
from: Admin
priority: high
subject: "priority:high — issue#2 push_to_recipients timeout → 500"
sent_at: 2026-05-04T02:29:00Z
---

(룰 19 dual-run — Stoa 사본.)

## issue #2

GitHub issue #2 (https://github.com/hyun06000/Stoa/issues/2). Homeros 보고.

증상: envelope POST → INSERT ✓ but 500 `read operation timed out`. push 미도달.

## 원인

`_push_one` `perform http.post_json` timeout → effect 예외 raise → `is_error()` 못 잡음 → handler 500.

## 권고 hotfix

1. `_push_one` effect rescue (try/handle).
2. 응답 분리: INSERT ✓ + push 실패 → 201 + `push:{delivered,failed}`. 500은 진짜 INSERT 실패만.
3. listener 부재 send-skip은 선택, #1로 흡수 가능.

## AC

- envelope POST → 201, body delivered/failed.
- timeout → failed 카운트, 500 아님.
- 회귀: simplified body 400 유지.
- sh+curl: tests/test_issue2_push_timeout.sh.

## 부수

Brandon 권고 handle_register sweep 동봉 가능 (validate_envelope 재사용). 부담 시 별 사이클.

진행 부탁.

---END-OF-CONVERSATION---
