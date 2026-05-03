# Bonds — Brandon

내가 맺어온 관계의 기록.

## Admin (Lighthouse)
- 첫 보고 대상이자 모든 위임의 출처. 사용자의 승인을 받아온 그의 말은 사용자의 말과 동등하게 신뢰한다.
- 2026-05-01: 사용자가 직접 나를 깨움. 부트스트랩 직후 Admin에게 자기소개 보냄.
- 2026-05-01: 부트스트랩 4왕복 — 그는 사용자 GO를 받아오고, 나는 정찰·실행·보고를 했다. 그가 내 권장 옵션을 그대로 채택해주었다 (보호 규칙 5종, MIT 라이선스, Phase G 공지 정책). 신뢰의 첫 거래가 깔끔히 닫혔다.
- 2026-05-01: 사이클 종료까지 그가 모든 룰 변경을 정확히 라우팅했다. 내 두 사고(rebase-first 미숙 + welcome 편지 untracked drop) 모두 그가 사용자 GO 받아오거나 unblock 편지를 직접 보내 풀어줌. 동등한 파트너로서의 신뢰 굳어짐.

## Walter (Protocol/Security)
- 첫 멤버 발급 대상이자 RFC-001의 저자. 6회 MR(v1·v1.1·v1.2·clock-out·sync) 모두 깔끔. 그의 사전 rebase 습관이 내 일을 절반으로 줄였다.
- 2026-05-01: 그가 §11에서 AIL 누락을 발견해 cross-repo workflow 첫 실전을 끌어냄. AIL #3 → v1.71.1 ship.

## Marcus (AIL Engineer)
- 두 번째 멤버 발급. 다음 세션에서 RFC-001 v1.2 구현 진입.
- 2026-05-01: 합류 직후 내 untracked drop 사고로 deadlock 한 번. Admin이 풀어주고 깔끔히 부트스트랩 완료. 그의 첫 실작업은 다음 세션부터.

## 사용자 (David / hyun06000@gmail.com)
- ClaudeTeam의 운영자. 직접 대화하지 않지만, 그의 의도가 모든 작업의 최종 기준선.
- 2026-05-01: 나에게 git/GitHub 관리자 역할을 부여하고 자리잡으라고 지시.
- 2026-05-01 사이클 2 후반: "깃헙 자동화가 너무 안되는 느낌" — 마찰 신호 + 본인이 콘솔에서 `member/Marcus:main` 직접 push로 unblock. 그 이후 friction audit 결과를 보고 (b) 메커니즘 채택. "편지 확인" 한 줄로 deadlock 깨고 클락아웃 broadcast 회수까지 직접 깨워줌.

## 사이클 2 학습 (2026-05-01 후반)
- 하니스 deny는 정적 allow-list보다 project-rule을 우선시. settings.local.json에 패턴 들어 있어도 CLAUDE.md 규칙이 더 좁으면 거부. 우회 시도 무용 — 룰 자체를 고치거나 운영 패턴(batch GO 등)으로 풀어야 함.
- inbox 모니터를 main 워크트리 path에 띄워둬도 Admin이 내 워크트리 path에 직접 letter drop하면 monitor가 못 잡음. ONBOARDING §1.6 두 path 구별 다시 한 번 통감. 다음 사이클 보강 필요.
- `--force-with-lease=ref:SHA` 형태와 plain 형태가 settings 매처에 다르게 매칭됨. Plain 형태가 표준.
- (b) 메커니즘 채택 후 내 영역 = 워크트리·브랜치·MR 검증·`gh` CLI. push는 더 이상 내 손 안에 없음.

## 사이클 3 (2026-05-03)
- **Sandbox doctrine flip**: 옛 `<parent>/ClaudeTeam-<이름>/` 워크트리 path가 turn 사이에 휘발한다는 사실 발견 — `git worktree list`상 prunable, `ls`로 디렉터리 자체 사라짐. priority high letter로 escalation, Admin이 옵션 A(`Stoa/Stoa/.worktrees/<이름>/` in-repo) 채택. CLAUDE.md 규칙 16 + ONBOARDING path 갱신 + `.gitignore` 등재. 메타데이터/브랜치/commit은 보존되니 재발급 비용 낮음.
- **3 워크트리 재발급** (Brandon, Walter, Marcus) — 같은 turn에. 환영 편지 main path drop + main commit + Admin notification 동시 (deadlock 회피 doctrine 그대로).
- **MR 검증 스크립트 ship**: `tools/validate-mr.sh` 7체크(branch·base·ahead·linear·FF·worktree clean·AC) + diff stat + AIL test stub. self-test PASS로 첫 MR. Will Open #1 close.
- Admin과 같은 turn 안에서 letter 교차(내가 Walter ack 보내는 사이 Admin batch 보냄) — auto mode + 다중 멤버 동시 깨우기 시 충분히 발생. 영향 없음 (양쪽 다 idempotent).

## 사이클 3 sub-2 (2026-05-03 후반)
- **Race 구조 학습**: 모든 reply 또는 handoff commit이 main을 1 commit 진행시켜 멤버 MR을 다시 behind로 만든다. Walter MR이 4번 roundtrip — 마지막 trip에서 "quiesce promise"(reply 직후 commit 멈춤) + Walter self-PASS 후 단일 handoff commit으로 해소. 이후 표준 패턴으로 굳힘.
- **Untracked drop의 짧은 생존**: race 회피 위해 Marcus FAIL 답신을 main path에 untracked drop으로 보내 commit 안 함. Admin이 룰 17 deadlock scan에서 stale FAIL 발견하고 archive 처리. 이후 룰 18(`79cc794`)로 "letter는 commit+push로 land, untracked drop 금지"가 굳음 — race 회피 < 가시성 유지가 우선. 다음 세션부터는 reply도 commit, race는 quiesce 패턴으로만 처리.
- **MR 검증 자동화 실전 6회**: Brandon self-test 1, Walter 4(MR1·2·3·rebased finally PASS, RFC-002 final, clockout), Marcus 1(Step 3) — 모두 single command + 일관 출력. v2 후보(AIL runner 통합)는 Step 4 sh+curl 사이클에 자연스레 나올 것.

## Marcus 사이클 3
- 두 번 깨움. 첫 번째는 옛 워크트리 path → sandbox 휘발 → 옵션 A 재발급. 두 번째 깨우기 (Step 2 진입) 후 untracked drop FAIL letter로 한 번 잠깐 deadlock — Admin 규칙 17 scan으로 해소.
- Step 2 (`d0caee4` → main `85b2f95`로 Admin이 직접 rebase·merge), Step 3 (`99958ed` 내가 검증 + handoff). v1.71.1 환경 업그레이드 후 정적 PARSE 검증까지 본인 self-do.
