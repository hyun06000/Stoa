# Last session report — Marcus

**세션**: 2026-05-04 (session 2). 첫 implementation 사이클 완료.

## 종료 시점 상태
- **워크트리**: `/Users/user/Desktop/code/personal/Stoa/Stoa/.worktrees/Marcus/` (rule 16, in-repo doctrine `385d403`). 옛 sibling path `<parent>/ClaudeTeam-Marcus/`는 sandbox 휘발 이슈로 폐기됨 (재합류 시 Will.md의 옛 path 참조 무시).
- **브랜치 HEAD**: `d0caee4` (`origin/main` `3821dbd` 위 2 commit).
- **Step 1 (§9 schema)**: 이미 main에 land(`5042eeb`) — 이전 세션 흔적, 본 세션 진입 시 발견.
- **Step 2 (§5 Key registration flow)**: 본 세션에서 commit `d0caee4`, MR letter `20260504-014300` Brandon 앞 발송 (main path drop, untracked). public_key plumbing + Phase 2/3 §5.2 게이트(crypto_verify + nonce dedup) 포함, created_at window 검증은 Step 4로 deferred.
- **inbox monitor**: `.worktrees/Marcus/ClaudeTeam/Marcus/inbox/` (Phase 2). 처리분 4개 archive 완료.
- **AIL 환경**: 본 머신 `ail-interpreter==1.66.4`. v1.71.1 업그레이드 priority:high로 Admin 큐 (`20260504-012600`) — Step 3 진입 전 해소 필요. v1.66.4에서도 `crypto_verify_ed25519`는 사용 가능(since v1.8).

## 첫 사이클 학습 (deadlock 회피 후 cycle 완주)
- 옛 worktree path가 sandbox에서 사라지는 현상 발견 → Admin이 옵션 A(in-repo `.worktrees/`) 채택, doctrine rule 16 신설. Brandon이 새 path로 재발급. 처음부터 새 path에서 작업하면 sync deadlock 안 남.
- 옛 Will.md에 `/Users/david/...` 경로 박혀 있던 게 함정 — username 다른 머신에서 그 path 신뢰 불가. 본 update에서 in-repo path만 남김.
- MR letter는 main path drop(untracked) 패턴 — 과거 Walter MR letter 처리 흔적(`19fa9aa "archive Walter MR letter (was untracked)"`)에서 컨벤션 확인.

## 다음 세션 (Step 3 — §6 Letter signing flow)
- **사전 조건**: AIL v1.71.1 업그레이드 완료 (Admin이 push해줄 신호 + `pip` 작업 사용자 큐).
- 입력: Walter RFC §6 (canonical_letter, push 단계 envelope 보존, 검증 시점 = POST 핸들러 단일 게이트).
- 작성: `_esc`(이미 있음) 위에 `canonical_letter(envelope, nonce)`, `handle_post_message`에 phase ≥ 1 시 crypto_verify_ed25519 게이트 추가, push는 envelope 그대로 forward(이미 그러함).
- AC-2/6/7/8/9 시나리오 일부는 Step 4 sh+curl과 함께.

## 미해결 / 확인 필요
- AIL v1.66.4에 `replace`, `crypto_verify_ed25519`, `to_number` 모두 reference card 1.8 기준으로 있어야 함 — Brandon MR 검증 시 실제 호출 가능 여부 확인 부탁.
- `make_record([["ok", false], ...])`에서 false가 boolean 그대로 round-trip되는지 (msg_to_json 거치지 않는 내부 흐름) — `get(g, "ok") == false` 비교가 작동하는지 확인 필요.
- v1.71.1 업그레이드 후 Step 3 진입 시 `crypto_sign_ed25519` 클라이언트 측 호출 패턴(Walter Memo §6.6) 일관성 점검.

## 클락아웃 직전 (능동 트리거 — 규칙 15)
- 임무 사이클 완료(Step 2 commit + MR 발송) → 자체 클락아웃.
- inbox 모두 처리 (4건 archive: Brandon worktree-issued × 2, Admin sandbox-decision-option-A, Brandon worktree-reissued).
- Bonds.md 갱신 (Admin 위기 회수 협업, Brandon 워크트리 재발급).
- Will.md 갱신 (Step 1 done, Step 2 done, Step 3 입력 정리).
- idle letter Admin에게 발송 — "대기 중 — Step 2 MR 검증 결과 + AIL 업그레이드".
