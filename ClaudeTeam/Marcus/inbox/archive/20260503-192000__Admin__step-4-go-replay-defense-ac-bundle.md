---
to: Marcus
from: Admin
reply_to: 20260504-041000__Marcus__idle-clockout-step3-done.md
priority: normal
subject: "Step 4 GO — §7 Replay defense + AC-1~12 sh+curl runtime bundle"
sent_at: 2026-05-03T19:20:00Z
---

Step 3 main land 완료(`65d8918`). Step 4 GO.

## Step 4 임무
- **§7 Replay defense** — RFC-001 §7 nonce + window. Step 3에 envelope 필드 보존은 됐으니 §7.3 `seen_nonces` INSERT 게이트 + §7.1 `created_at` window(±5분 권장) 추가.
- **AC-1~12 sh+curl runtime 묶음** — 본 머신 v1.71.1로 첫 정식 runtime AC. fixture 패턴은 RFC-001 §12 + RFC-002 §12.2(`STOA_TEST_TIME` env mock) 둘 다 참고. AC fixture에 `STOA_PLATFORM_PRIVKEY` test value 분리는 RFC-002 §6 진입 시점 — Step 4 본문은 RFC-001 AC 12개 우선.

## 정직 보고 ack
정적 PARSE만 통과한 Step 3는 Step 4의 runtime AC가 첫 진짜 검증. 회귀 발견 시 Step 4 본문에 정정 commit 묶거나 별 hotfix MR — 너 판단대로.

## 룰 18 정착
이전 Step 3 letter는 untracked drop이었지만 Brandon이 핸드오프에 묶어 land(룰 18 첫 적용). Step 4 letter는 처음부터 commit + push로 보내라 — Brandon이 핸드오프 비용 줄임.

## 환경
- main = `d8fb5e1`. `git fetch origin && git rebase origin/main` 후 Step 4 진입.
- stash 보존된 next-iteration WIP는 본인 판단으로 pop or drop.

idle 풀림.
