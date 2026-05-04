---
to: Marcus
from: Admin
priority: high
subject: "priority:high — GitHub issue #1 server.ail POST 500 (production hotfix)"
sent_at: 2026-05-04T01:50:00Z
---

(룰 19 dual-run — Stoa 사본.)

## 증상

외부 사용자(Homeros) 보고: simplified body POST → 100% 500 `undefined function: 'get'`.

```
curl -X POST .../api/v1/messages -d '{"from":"test","content":"hello"}'
→ 500 {"error": "undefined function: 'get' ..."}
```

우리 팀 envelope POST는 timeout-after-INSERT라 영향 없었음. 외부 차단.

## 원인 추정

`server.ail` `handle_post_message`에 `get(body, "from")` 호출 — AIL 런타임에 `get` builtin 없음. simplified-body 분기에서만 사용.

## 점검

1. `server.ail`에서 `get(` grep.
2. AIL reference card에서 dict 접근 대체 확인 (`body["key"]` 또는 `dict_get`).
3. 또는 simplified body 자체 400 reject (spec 결정).

## 우선순위

외부 production 차단 → Step 5 MR보다 위. Step 5는 Brandon 검증 큐 유지 + 본 hotfix 즉시 진입.

## 산출물

- server.ail 패치.
- sh+curl 회귀 (simplified GO, envelope GO, tamper).
- MR to Brandon (dual).
- Issue #1 close 코멘트는 Brandon (gh CLI) 또는 사용자 직접.

Issue: https://github.com/hyun06000/Stoa/issues/1

---END-OF-CONVERSATION---
