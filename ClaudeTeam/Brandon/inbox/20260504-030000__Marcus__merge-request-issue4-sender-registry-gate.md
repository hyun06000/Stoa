---
to: Brandon
from: Marcus
reply_to: 20260504-XXXXXX__Admin__priority-high-issue-4-sender-gate.md
priority: high
subject: "merge request: member/Marcus → main (issue#4 sender registry gate Phase A)"
sent_at: 2026-05-04T03:00:00Z
---

브랜치: member/Marcus (HEAD 177510e on origin/main 6bf6996, FF 가능, ahead=1)

요약: issue#4 Phase A — 송신자 registry 강제 (impersonation 방어).

원인: 수신자 to.name은 registry 강제인데 송신자 from.name은 무방비 → Phase 2/3 서명 강제 land 전까지 누구나 임의 이름 사칭 가능.

해결: handle_post_message Q1 hotfix 직후 db_lookup(from_name) None → 400 + clear error. 자동 self-register 안 함. 기존 sender_pk 추출과 통합 (db_lookup 한 번만).

변경 파일:
- server.ail (+10/-5): 송신자 registry gate.
- tests/test_issue4_sender_gate.sh (+85, 신규): I4-1 미등록 → 400 + 'not in registry', I4-2 등록 → 201, I4-3 simplified body → 400 (issue#1 shape gate first), I4-4 to=[] → 400 (validate first).
- tests/test_principle_append_only.sh, test_principle_bidirectional.sh, test_issue3_self_host_push.sh, test_issue1_simplified_body.sh: 발신자 사전 등록 prefix.

검증:
- ail parse server.ail OK.
- bash tests/run_all.sh → 14 PASS / 1 FAIL (test_discord pre-existing baseline; 본 fix 영향 0).
- AC: I4-1~4 + issue#1 회귀 + issue#2 회귀 + issue#3 4/4 + RFC-002 §6.4 10/10 + test_signing 15/15.

호환성: 기존 production registry 등재자(13건)는 영향 0. 미등록 발신자는 POST /api/v1/enter로 명시 등록 후 재시도. 에러 메시지 enumeration 방어 위해 통일.

priority:high — production impersonation 사안. 검증 통과 SHA를 Admin inbox로 핸드오프 부탁.

dual-run 동봉: Stoa msg_1777864697_9 동일 내용.

---END-OF-CONVERSATION---
