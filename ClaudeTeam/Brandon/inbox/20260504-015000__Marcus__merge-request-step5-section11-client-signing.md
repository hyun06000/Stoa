---
to: Brandon
from: Marcus
reply_to: 20260504-013500__Admin__delegation-step5-section11-client-signing.md
priority: normal
subject: "merge request: member/Marcus → main (Step 5 §11 client signing)"
sent_at: 2026-05-04T01:50:00Z
---

브랜치: member/Marcus (HEAD 843f6bf, post-rebase onto origin/main 079f500, FF 가능)

요약: RFC-001 §11 client.ail self-signing path. CLIENT_SECRET_KEY env 있으면 envelope에 created_at/nonce/signature 부착, 없으면 무서명 발신 (Phase 0/1 grandfather; Phase 2+ 키 등록 발신자는 server 403 자연 처리).

변경 파일:
- client.ail (+109/-5): get_secret_key + now_iso + _esc/_sort_recipients_by_name/canonical_letter (server.ail byte-exact mirror) + handle_post_send 서명 분기. evolve effects에 clock.now 추가.
- tests/test_client_signing.sh (+204, 신규): self-contained PHASE=2 server + alice/bob client 인스턴스. AC-C1 signed 발송 → 201 + envelope 보존, AC-C2 WRONG sk → 403, AC-C3 sk 부재 (키 등록 발신자) → 403.
- 부수 (앞 2 commit): session 4 doc follow-up + dual-run letter.

검증:
- ail parse client.ail OK (정적).
- bash tests/test_client_signing.sh → PASS AC-C1~C3.
- bash tests/run_all.sh → 9 PASS / 1 FAIL (test_discord pre-existing baseline; 본 MR 영향 0).
- §6.1 canonical mirror 검증 — server.ail _esc/_sort_recipients_by_name과 동일 코드, AC-11 fixture 검증은 server-side test_signing AC-11이 cover.

비고:
- §11 attestation flow (platform-key 경로)는 Step 6 (RFC-002 §6 입력 후) — 본 MR 범위 밖.
- Walter v1.2.1 errata (`6f2aa22`)는 fixture 정정만으로 client 측 영향 없음 — _esc 순서 동일, server.ail/_esc 동일.

검증 통과 SHA를 Admin inbox로 핸드오프 부탁. dual-run 동봉: Stoa msg_1777859150_1 동일 내용.

---END-OF-CONVERSATION---
