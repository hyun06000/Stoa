# Decisions — Brandon

내가 내린·집행한 결정의 한 줄 로그.

- 2026-05-01 — 자기 부트스트랩: `member/Brandon` 브랜치 + `../ClaudeTeam-Brandon/` 워크트리 생성 (base `main@c979a65`).
- 2026-05-01 — `LICENSE` 파일 MIT 텍스트 추가, 저작권자 `hyun06000` (Admin 위임, 사용자 GO).
- 2026-05-01 — `member/Brandon`을 main 위로 rebase (FF 불가 상태였음). 새 SHA `a097762`, `9b75916`.
- 2026-05-01 — `origin/main` 푸시 `5440759..9b75916`, `member/Brandon` 새 브랜치 푸시 + 추적.
- 2026-05-01 — main 보호 규칙 적용: `enforce_admins=false`, `required_linear_history=true`, `allow_force_pushes=false`, `allow_deletions=false`, PRR/checks/restrictions = null.
- 2026-05-01 — 신규 멤버 표준 절차 채택 (`new_member_onboarding.md`). 별도 "팀 빌드 완료" 공지 없이 Phase G 종결.
- 2026-05-01 — Walter (Protocol/Security) 워크트리 발급. 브랜치 `member/Walter`, base `main@0bbd090`, 경로 `../ClaudeTeam-Walter/`. 절차 첫 실전 — `inbox/archive/`만 mkdir, identity는 본인이 작성 원칙 확정.
- 2026-05-01 — Walter 부트스트랩 MR 처리 완료. 그의 base가 main보다 3 커밋 뒤져 있어 rebase 후 FF (`473c469` → `3baa6f9`). 동일 파일 충돌 없음(Admin이 직접 main에 추가한 RFC-001 spec은 Walter가 자기 커밋에 동일 추가했지만 git이 동등으로 정리). Walter에게 다음부터 사전 rebase 권장 안내.
- 2026-05-01 — 자기 부수 커밋 전 rebase를 안 해서 origin/member/Brandon이 stale (`1458164`)이 됨. force-push 게이트 1차 거부 → Admin GO → harness 2차 거부 (inbox 위임은 사용자 의도 불충분) → 사용자 직접 GO → `1458164...85744c5` force-with-lease 성공. CLAUDE.md 규칙 11(자기 브랜치 force-with-lease 사전 포괄 승인) 신설. 절차 룰 "먼저 rebase, 그 다음 commit" 채택.
- 2026-05-01 — Cross-repo workflow Memo 작성 (`Memo/cross_repo_workflow.md`). CLAUDE.md `46058f8`의 5단계 중 4단계(외부 레포 issue/PR 발행)가 내 책임. 첫 실전은 Walter의 RFC-001 §11에서 AIL 누락 발견 시.
- 2026-05-01 — Cross-repo workflow 첫 실전. `hyun06000/AIL` issue #3 발행 — stdlib ed25519 sign/keygen + crypto_random. 본문은 Admin이 내려준 Walter 초안 그대로. AIL의 issue 템플릿 둘 다 정확히 안 맞아 free-form 발행.
- 2026-05-01 — Walter RFC-001 v1 MR 처리 (`8f532c0` → `305ee23`). 그가 사전 rebase 했지만 main이 한 발 더 갔어서 추가 rebase 후 FF. `member/Walter` 원격(`8f532c0`)은 stale 유지 — 규칙 11이 자기 브랜치 한정이라 다른 멤버 브랜치 force-push는 불가. 멤버가 다음 세션에서 자기 standing approval로 정렬하는 걸 표준 운용으로 채택.
- 2026-05-01 — Walter RFC-001 v1.1 (issue URL 추가) 처리 (`0346d11` → `8fe9699`). 사전 rebase 했지만 또 한 번 추가 rebase. FF + push.
- 2026-05-01 — **사용자 정정 `b28a309`**: 모든 git push는 Brandon 소관으로 중앙화. 규칙 11 좁아짐(자기 브랜치만 force-with-lease 사전 승인, 다른 멤버 브랜치 force-push는 매번 사용자 GO). 직전 §4.5 doctrine "멤버에게 위임"은 무효, 정반대로 갱신. `origin/member/Walter` 정렬은 내가 직접 처리 — 사용자 GO 라우팅 대기 중.
- 2026-05-01 — Walter RFC-001 v1.2 머지 (`aa29666`, `Result[Text]` 정정 흡수). AIL #3 monitor가 두 신호(state CLOSED + ref_card grep 0→1) 모두 잡고 priority: high 보고. v1.71.1 ship 확인.
- 2026-05-01 — Marcus (AIL 엔지니어) 워크트리 발급. 브랜치 `member/Marcus`, base `main@c819248`, 경로 `../ClaudeTeam-Marcus/`. 환영 메시지에 클락아웃 모드(implementation 보류) 명시. ONBOARDING §1.6 덕분에 Marcus가 main 워크트리에 inbox/ 미리 만들어 두어 첫 메시지 즉시 도착.
- 2026-05-01 — Walter clock-out MR 머지 (`d6b2861`) + post-clockout sync (`2cb46e1`). 세션 1 완전 종료.
- 2026-05-01 — **교착 사고**: Marcus 환영 편지를 워크트리에 drop만 하고 commit 안 했음 → Marcus monitor가 main path만 봐서 못 잡음 → 발급 사실 미인지 → MR 무한 대기. Admin이 main path에 unblock 편지 + commit (`d55fdd1`)으로 풀어줌. ONBOARDING §1.6 강화: 환영 편지 drop 후 즉시 commit + push, 또는 Admin 라우팅 알림. Will에 못박음.
