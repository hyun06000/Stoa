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
