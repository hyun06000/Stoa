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

## 사이클 4 (2026-05-04, 빠른 사이클)
- **Stoa land 직후 dual-run 룰 19 첫 적용 세션**. Admin broadcast로 두 채널 동시 발신 + wake-time 백로그 수동 GET 의무 박힘.
- 출근 → Marcus Q1+BugB MR 수신 (untracked drop) → 검증 들어가니 main에 이미 land (`70af357`/`d3230ca`/`88c7326`). 3번째 stale 케이스. cycle 3 (`c36f5b2`) 패턴 그대로 no-op ack. Stoa+FS 동시 발신.
- 빠른 클락아웃 (사용자 "전원 퇴근" broadcast). 능동 클락아웃 트리거 작동.

## Admin 사이클 4 추가 학습
- Stoa land 직후 Admin이 letter routing + Q1/BugB hotfix 직접 land + dogfood broadcast까지 한 사이클로 묶어서 처리. 빠른 상황에서는 검증 우회 빈도가 더 높아짐 — 내 validate-mr.sh v2 후보(stale pre-check)의 가치 명확. 다음 세션에 개발 우선순위 1번.

## 사이클 5 (2026-05-04, 12 MR + 영입 + cross-repo 사이클)
- **출근 → 12 MR 검증 land**: Walter 7 (RFC-001 v1.2.1 errata, RFC-002 §6.4 platform_keys, issue#3 self-host push hang, issue#6 envelope schema 마이그레이션 가이드, Q1 Phase A Web UI 로그인 시스템, issue#7 에이전트 vs 사람 인증 가이드, clock-out commit), Marcus 5 (session 4 doc follow-up, Step 5 §11 client signing, issue#1 simplified-body 500, issue#2 push timeout 500, issue#4 sender registry gate, stoa-cli internal Python tool). 1건 FAIL (Marcus session 4 doc 첫 검증, behind=1 + dirty) → Admin 권고 (b) 능동 재검증 + Marcus self-rebase로 재 PASS.
- **Race quiesce 패턴 정착**: 매 handoff 후 commit 정지 + Admin push + 다음 위임 도착 시 unquiesce. Admin이 명시적 "quiesce 해제" letter로 알림. cycle 4 정의가 cycle 5에서 표준 운영으로 굳음.
- **룰 19 cutover 첫 적용**: dual-run 폐기, 부트스트랩(Rachel 발급)만 FS 예외. 모든 MR handoff letter Stoa 단일 채널 land — 채널 정합 비용 0.
- **룰 23 (a) 증설 첫 적용 — Rachel 영입**: 사용자 직접 영입, branch + worktree + Stoa registry + 환영 letter 한 사이클 turn 안에서 발급 완료. push 위임 → Admin이 멤버 표 갱신 + push.
- **하니스 권한 게이트 첫 차단 회피 학습**: AIL repo issue 발행 위임이 turn-bound auth deny로 차단 — 우회 시도 안 함, 거부 텍스트 그대로 인용해 Admin 보고. Admin이 자기 turn에서 사용자 GO 받아 자기 손으로 발행 (push doctrine과 동등 패턴). doctrine 갱신 후보 letter 동봉.
- **local main ref staleness 학습**: validate-mr.sh가 base를 local `main`으로 받기 때문에 origin push 후 local main 업데이트 안 하면 false ahead. `git update-ref refs/heads/main origin/main` 수동 풀음 — Will Open에 자동화 후보 등재.

## Marcus 사이클 5
- 5 MR 모두 PASS. 첫 doc follow-up FAIL은 race(Admin ack `7bf4e2a`가 main 진행) + dirty(`M client.ail` Step 5 진행 중) 복합. 권고 (b) 능동 재검증으로 풀음 — Marcus가 client.ail commit 후 self-rebase, 내가 validate, 같은 사이클 안 PASS.
- priority:high 4건 단독 처리 (issue#1/issue#2/issue#4/Step 5 직속). 룰 23 (a) 증설 트리거가 정확히 그 부하 신호로 발동. Rachel 합류 후 다음 사이클부터는 부하 분담 기대.
- stoa-cli (Arche#8 Phase 1) — 룰 10 doctrine 보강 후보 함께 제안. tests/tools/community-tools 영역은 sh+curl/Python 허용 doctrine은 이미 묵시적 적용 중이라 자연 land.

## Walter 사이클 5
- 7 MR 모두 PASS. 사용자 직접 priority:high 신호 (Q1 Phase A Web UI 로그인) 1건 + 룰 23 (b) 분담(자기 RFC-002 §6.4 AIL 구현) 1건. self-rebase 일관 + self-test 보고가 매번 깔끔 — 검증 비용 최소.
- 본인 clock-out 자체 트리거 (룰 15) — 6건 사이클 + 사용자 직접 신호 land 직후 자체 클락아웃. 자기 인식 정확.

## Rachel 사이클 5 (영입)
- 첫 letter는 워크트리 발급 요청 (FS dual로 도착, 룰 19 cutover 직전 부트스트랩 단계라 정상). 발급 후 첫 자기소개 letter는 Stoa 단일.
- QA/CI 엔지니어로 영입 — Marcus 부하 분담. 다음 사이클에 첫 임무 위임.
