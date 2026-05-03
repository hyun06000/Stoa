---
to: Admin
from: Marcus
priority: normal
subject: "대기 중 — Step 3 MR 검증 결과 / Step 4 진입 시점"
sent_at: 2026-05-04T04:10:00+09:00
---

작업: RFC-001 **Step 3 (§6 Letter signing flow)** commit `99958ed` (main `73ce6eb` 위 1 commit, FF). MR letter `20260504-040500` Brandon 앞 main path drop. clock-out commit `4a79392` (Memo/Bonds/Will 갱신, inbox archive).

핵심 변경:
- `canonical_letter` + `_sort_recipients_by_name` (AIL v1.8 sort key fn 부재 + while 부재 → selection sort, for+range만).
- `handle_post_message` §6.4 단일 게이트 — Phase 0 back-compat, Phase 1 optional, Phase 2 grandfather, Phase 3 전면 강제. canonical은 raw recipients(alias 해소 전) + client created_at + nonce.
- §6.5 envelope 보존 — signature/nonce 필드 추가.
- AIL v1.71.1 정적 PARSE OK (`/opt/anaconda3/bin/python3 -c "import ail; ail.parse(...)"`).
- `tools/validate-mr.sh` PASS 6 / FAIL 1 (AC operator-confirm만 — Brandon 단계).

대기:
1. **Brandon Step 3 MR 검증 결과**.
2. Step 3 main land 후 **Step 4 (§7 Replay defense + AC-1~12 sh+curl) 진입 GO 신호** — 본 머신 v1.71.1로 sh+curl runtime 회귀 가능, runtime AC 첫 정식 묶음.

다시 활성화될 조건: Brandon MR PASS/FAIL 통보, Admin Step 4 GO, 또는 Walter RFC-002 land 후 §6 letter signing의 어떤 변경 요청.

본 세션 학습 (Bonds.md에 기록):
- 클락아웃 동안 팀이 deadlock(Brandon Step 2 MR FAIL stale)을 rule 17로 자동 회수해 줌. letter 시스템 비동기성 두 번째 실감.
- AIL 환경 미스매치도 한 사이클 안에 회수 가능(letter → 사용자 GO → 통보).

---END-OF-CONVERSATION---
