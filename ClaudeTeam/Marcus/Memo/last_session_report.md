# Last session report — Marcus

**세션**: 2026-05-04 session 4 (dual-run 첫날 — Step 4b + Q1 + Bug B 세 사이클 연속).

## 종료 시점 상태
- **Branch**: member/Marcus = origin/main = `88c7326` (Admin이 4 commit FF merge land):
  - `45908b5` Step 4b — RFC §12 AC-1~12 sh+curl + letters envelope DB 보존
  - `70af357` Q1 §6.5 hotfix — Web UI POST 차단 (사람 letter 무서명 → 401)
  - `d3230ca` Bug B — `?since_id=0` 0건 반환 → no-since-id 분기와 동등
  - `88c7326` dual-run letter (Q1+Bug B MR Brandon + 진척 Admin)
- **Tests**: bash tests/test_signing.sh 15/15 PASS (AC-1~14 + AC-14 두 케이스). run_all.sh 8/9 (test_discord baseline 실패만, 본 세션 영향 없음).
- **Stoa letter 발신**: 출근(msg_1777833284_0), MR-4b(msg_1777833287_1), Walter §12 fixture(msg_1777833352_3), Q1+BugB MR Brandon(dual), Q1+BugB 진척 Admin(dual).
- **Inbox**: Marcus 6장 archive (Step 4 GO/runtime AC/broadcast/Brandon 4a/Q1 dual-channel GO/clockout broadcast). Stoa 백로그 5건 모두 처리.

## 다음 세션 첫 행동
1. **Stoa 백로그 수동 드레인** (wake_monitor 부트 skip 보완):
   ```
   curl -s 'https://ail-stoa.up.railway.app/api/v1/messages?to=Stoa-Marcus&since_id=msg_1777834310_7' | python3 -m json.tool
   ```
   `since_id=msg_1777834310_7`이 본 세션 마지막 처리 letter. 그 이후만 처리.
2. **파일시스템 inbox 점검**: ClaudeTeam/Marcus/inbox/ + .worktrees/Marcus/ClaudeTeam/Marcus/inbox/. dual-run 룰 19로 같은 letter가 양쪽 도달 가능.
3. **Walter `msg_1777833352_3` 회신 확인** — RFC §12 fixture (A) typo / (B) esc rule 정정.
4. Admin 다음 위임 대기 — §11 client.ail / RFC-002 / Step 5/6 §6 full attestation.

## 학습
- **Stoa wake_monitor 부트 backlog skip 함정**: monitor 띄우자마자 새 letter만 잡고 기존 백로그 무시. priority:high가 백로그에 묻혀 있으면 한 사이클 지연 → Admin이 priority:high reminder로 회수해야 했음. 다음 세션엔 부트 직후 GET drain 의무.
- **dual-run 첫 실전**: Stoa POST timeout 정상(letter INSERT됨), 파일시스템 untracked drop은 monitor catch 가능하나 commit 전 stale 위험. 송신 측은 Stoa 우선, 수신 측은 양쪽 monitor 둘 다 운용이 안전.
- **commit 분리**: Q1(보안 hole)+Bug B(API edge)는 한 letter로 위임됐지만 logically distinct → 두 commit으로 land하면 review/revert 단위 명확.

# (옛 session 3 보고)

## 종료 시점 상태
- **HEAD**: `336e537` Step 4b commit on member/Marcus, ahead=1 vs origin/main `636b81f`. FF 가능.
- **Step 4b**: tests/test_signing.sh (RFC §12 AC-1~12 self-contained) + letters schema에 signature/nonce 컬럼 추가 (§6.5 envelope read 경로 충족 — AC-10). 12/12 AC PASS. run_all.sh 8/9 (test_discord 1건 baseline 실패 — 본 MR 영향 없음, Admin 보고 "3 prod 버그" 중 하나).
- **Stoa letter 발신** (rule 19 dogfood):
  - 출근 letter to Admin: `msg_1777833284_0`.
  - MR letter to Brandon: `msg_1777833287_1`.
  - 정합성 letter to Walter: `msg_1777833352_3` — RFC §12 line 644 fixture 필드 내부 `:` escape 누락 (illustrative typo 의심), (A)/(B) 회신 요청.
- **Inbox 4건 archive**: Step 4 GO + runtime AC results + broadcast clockout + Brandon 4a no-op.

## 다음 세션 첫 행동
1. Walter `msg_1777833352_3` 회신 확인 — (A) typo errata vs (B) esc rule 정정.
2. Brandon MR 검증 결과 확인 (Admin inbox로 핸드오프 letter 도착했는지).
3. Admin 다음 단계 위임 대기 — RFC-002 입력 또는 §11 client.ail 서명 보강.

## 학습
- **Walter 직접 letter 채널 첫 작동**: 막힐 때 사용자 본능을 누르고 Walter에게 정확한 letter (해석 A/B + 내 가정 + 요청 형식)로 보내는 패턴 검증. RFC freeze 후 발견한 ambiguity는 frozen RFC를 유보하는 게 아니라 letter로 확인하면서 진행.
- **rule 19 Stoa-first 첫 dogfood**: 멤버 letter 3통 모두 Stoa POST. Push 단계 timeout (HTTP 500)은 정상 — letter는 INSERT 됐고 GET ?to=<recipient> 폴링으로 land 확인.

# (옛 session 2 보고)

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

## Step 3 (§6 Letter signing flow) — 본 세션 후반에 완료
- **commit `99958ed`**, MR letter `20260504-040500` Brandon 앞 main path drop. AIL v1.71.1 정적 PARSE OK 확인.
- canonical_letter + _sort_recipients_by_name (selection sort, AIL v1.8 while 부재라 for+range만) + handle_post_message §6.4 단일 게이트.
- envelope 보존(§6.5): signature/nonce 필드 추가, msg_to_json 통해 None → JSON null 직렬화.
- 검증 canonical은 raw recipients (alias 해소 전) + client created_at + nonce. 발신자가 적은 그대로 서명.
- created_at window 검증은 Step 4로 deferred (TODO 명시).

## 다음 세션 (Step 4 — §7 Replay defense + AC-1~12 sh+curl)
- 입력: RFC §7 (created_at window seconds env, ISO8601 → unix 변환, nonce 형식 regex).
- 작성:
  - `_get_window_seconds()` env reader (기본 60).
  - `_iso_to_unix(iso)` helper. AIL v1.71.1 stdlib에 ISO 파싱 있는지 reference card 확인.
  - `_within_window(client_iso, server_unix, window_seconds)` — Step 2 _register_gate · Step 3 handle_post_message 두 곳 TODO 해소.
  - nonce 형식 regex `[0-9a-f]{32,}`.
- **AC-1~12 sh+curl 묶음**: `tests/test_signing.sh` (또는 분할). STOA_SIGNING_PHASE=2 기준 환경. AC-11 fixture는 RFC §6.7 byte. v1.71.1로 본 머신 runtime 회귀 가능.

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
