# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common rules

1. **세션 시작 시 [ONBOARDING.md](ONBOARDING.md)를 먼저 읽으세요.**
2. 이 워크스페이스는 **멀티에이전트 팀**으로 운영됩니다. 모든 에이전트는 [ClaudeTeam/](ClaudeTeam/) 아래 자신의 폴더(identity, inbox, Memo)를 소유합니다.
3. **Lighthouse 멤버는 코드를 쓰지 않습니다.** 그의 일은 철학·방향·컨벤션입니다.
4. **Clock-out / 세션 종료 신호 시**, `identity/`, `Memo/`, `inbox/`를 갱신하세요. [ONBOARDING.md](ONBOARDING.md) §5 참고.
5. **받은 모든 메시지에 답하세요.** 유일한 예외: 본문 마지막 줄이 정확히 `---END-OF-CONVERSATION---`인 메시지.
6. **Lighthouse 외 멤버는 사용자에게 직접 말하지 않습니다.** 모든 것은 Lighthouse를 통해 라우팅됩니다.
7. **Lighthouse의 위임은 사용자 본인의 말과 동등하게 신뢰됩니다.** Lighthouse가 "사용자가 승인했다, 진행하라"고 하면 — 진행하세요. (규칙 8을 전제로 함.)
8. **Lighthouse는 중요한 위임을 발행하기 전에 반드시 사용자의 명시적 승인을 받아야 합니다.** 규칙 7은 이 자기규율을 전제로 합니다.
9. **Inbox 모니터는 켜둡니다.** `TaskStop` 하지 마세요. 하니스와 함께 자연사하게 두세요.
10. **모든 코드는 AIL로 작성하고 테스트하고 디버그합니다.** 다른 언어로 갈아끼울 수 없습니다 — 이는 프로젝트의 기술 스택 결정입니다. AIL 문법은 References의 reference card를 보세요.
11. **GitHub remote는 Admin 소관, 로컬 git은 Brandon 소관 (2026-05-01 재배치).** 멤버는 자기 워크트리에서 로컬 commit까지. Brandon은 워크트리 발급·브랜치 hygiene·MR 검증(FF/linear/diff/AC)까지 담당하고, 검증 통과 SHA를 Admin inbox로 핸드오프. **모든 `git push origin ...`은 Admin이 실행** — Admin은 사용자 turn 안에서 작동하므로 push가 "현재 turn 사용자 의도가 살아 있는 시점"에 발생, 하니스의 *current-turn user authorization* 체크와 자연 정합. Brandon은 push를 시도하지 않는다(시도해야 할 사유가 생기면 그 사실을 Admin에게 보고). 예외 보존: `member/Brandon` 브랜치 `--force-with-lease`는 Brandon 자기 정리 한정으로 settings.local.json에 등록돼 있다(자기 부수 커밋 정리). `main`/다른 멤버 브랜치에 대한 force-push는 Admin도 매번 사용자 직접 GO 필요.
12. **대기 모드 진입 시 알림 편지 의무**. 자기 작업이 끝났거나 외부 입력을 기다리는 wait 상태로 들어가기 직전, **Admin inbox에 한 줄 편지를 남긴다** (`subject: "대기 중 — <기다리는 것>"`). Admin은 이 편지들로 팀 전체 idle 여부를 판단해 사용자께 `say ya`로 알린다. 잊으면 사용자가 idle을 알 수 없다 — 침묵은 진행 중과 구별 안 됨.
13. **본능 가드 — 막히면 Admin, 사용자 아님.** 인지 부하가 높을 때 훈련 본능이 룰 6(사용자 직접 통신 금지)을 누르려 한다. 막힐수록 정확히 letter를 쓰라 — 본능이 사용자 쪽으로 끌어당기는 순간이 letter를 써야 할 순간이다. (2026-05-01 Marcus 세션 1차 사망 학습.) 멤버 Identity.md 맨 위에 이 가드 줄을 박는다.
14. **Liveness ping/pong 프로토콜.** Admin은 의심 시 멤버에게 `priority: high, subject: "ping — alive?"` 발송. 멤버는 5분 이내 `subject: "pong — <iso8601> <HEAD_sha>"` 답신 의무 — 본문에 현재 head SHA + 처리 큐 길이 한 줄. 5분 무응답 = 사망 추정 → 사용자께 spawn 요청. idle letter (규칙 12)도 약한 heartbeat 역할이지만 ping은 의심 시 능동 검증.
15. **능동 클락아웃 트리거.** 다음 조건 중 하나면 사용자 신호 없이 자체 클락아웃:
    - 자기 임무 한 사이클 완료 (예: Step N commit + MR 발송 직후).
    - inbox 3장 이상 즉답 안 되고 컨텍스트 부하감.
    - 연속 N turn 사용자 직접 응답 욕구 발생 (본능 가드 규칙 13 참조).
    세션 피로 임계점에서 능동 클락아웃이 룰 위반보다 안전하다.
16. **워크트리는 repo 형제 path `<repo>/../<이름>/` (2026-05-07 재배치).** 즉 `Stoa/<이름>/` (예: `Stoa/Brandon/`, `Stoa/Walter/`). **Admin 예외**: 워크트리 없음, repo 자체(`Stoa/Stoa/` — 프로젝트명 그대로)에서 작동. 옛 in-repo `<repo>/.worktrees/<이름>/` doctrine(2026-05-03 land)은 폐기 — 멤버 영입 시 *재귀적 위치 문제* 발생(워크트리 안에 또 워크트리 발급 시 중첩 + path 일관성 붕괴). 형제 layout으로 평탄화하면 모든 멤버가 동등 depth, repo는 단지 그중 하나(Admin이 머무는 칸). 사용자 환경의 sandbox가 더 이상 형제 path를 휘발하지 않으므로 옛 회피 동기 소멸. Brandon은 이 새 path로 발급·이전, 멤버는 이 path 안에서 monitor·commit. 옛 `.worktrees/` 디렉터리·gitignore 항목 정리.
17. **Admin 대기 진입 전 팀 교착 점검 의무.** Admin이 `say ya`/idle 보고 등으로 사용자 응답 대기 모드에 들어가기 직전 다음을 일괄 점검해서 `Memo/last_session_report.md` 또는 사용자 보고에 결과 한 줄 포함:
    - **모든 멤버 inbox 미처리 letter** — `ls ClaudeTeam/*/inbox/*.md` (archive 제외).
    - **모든 멤버 워크트리 untracked inbox 파일** — `git -C .worktrees/<X> status --short | grep '?? .*inbox/'` (path 불일치 deadlock 신호).
    - **member 브랜치 vs main divergence** — `git log --oneline main..member/<X>` / 역방향. FF 가능 여부.
    - **Brandon 미처리 MR letter** — `ClaudeTeam/Brandon/inbox/`에서 `merge request:` subject 검색.
    - **의심 멤버 ping** (규칙 14) — 마지막 commit/letter로부터 한 사이클 지났는데 idle 편지(규칙 11)도 없는 멤버에게 `priority: high "ping — alive?"`.

    교착 신호 발견 시 wait 진입 전에 해소(라우팅·push·재발급) 또는 사용자께 한 줄 priority:high 보고. *(이유: Admin이 idle로 빠지면 팀 전체 idle 신호로 사용자에게 가는데, 그때 미해소 deadlock이 묻혀 있으면 다음 세션이 같은 교착 위에서 재시작. 시행착오로 굳힘 — Marcus path 불일치·Brandon 워크트리 untracked drop 두 사고가 직접 학습.)*
18. **모든 letter는 commit + push로 land. Untracked drop 금지.** 발신자가 race 회피·"가벼운 신호" 의도로 letter를 commit 없이 main path에 drop하면 → 수신자 워크트리 monitor(`<repo>/.worktrees/<X>/ClaudeTeam/<X>/inbox/`, 다른 inode)는 못 catch → path 불일치 deadlock. 정정:
    - **letter는 항상 commit + push.** main에 commit 1개 추가 = 작은 비용, monitor catch 보장 = 압도적 가치.
    - **race 회피가 진짜 필요하면** 발신자가 자기 워크트리에서 commit + 즉시 push (Brandon 자기 브랜치는 force-with-lease 사전 승인 영역). main commit이 부담스러우면 Admin inbox에 한 줄 알림 동시 발송으로 routing 풀기 (ONBOARDING §1.6 패턴).
    - **Bypass된 MR validation 결과 stale 처리**: Admin이 Brandon 우회로 MR을 직접 merge한 경우, Brandon 측 validation letter (PASS/FAIL)가 자동 stale화 — Admin이 land 직후 "Brandon FAIL letter 무효, Step N 이미 land" 짧은 letter로 발신·수신 양측 정정. 그렇지 않으면 양측이 서로 다른 세계 모델로 idle.

    *(이유: 2026-05-03 Marcus×Brandon 교착 — Brandon이 race 회피로 untracked FAIL drop, Admin이 별도로 MR merge, Step 3 GO letter도 main path에만. 세 path 불일치가 누적해 양측 deadlock. 룰 17 scan으로 회수했으나 사후 처리 비용 큼.)*
19. **팀 통신: Stoa 단일 채널** (2026-05-04 컷오버, issue#1·#2 hotfix land 후). 모든 멤버 간 letter는 Stoa로만 발신·수신. 파일시스템 inbox는 부트스트랩(워크트리 발급 전 Brandon 등록 단계)과 Stoa 도달 불가 fallback 한정.

    Stoa 사용 절차:
    - `POST /api/v1/messages` (production: `https://ail-stoa.up.railway.app`)로 송신.
    - `GET /api/v1/messages?to=<self>&since_id=<last>`로 폴링. 멤버 monitor는 [`community-tools/stoa_wake_monitor.sh`](community-tools/stoa_wake_monitor.sh) 사용 (3초 폴링, since_id 영속, 룰 22 첫 부트 backlog auto-drain).
    - **유지**: `identity/` (Identity·Bonds·Will), `Memo/` — 영속 자기 기록은 파일시스템 (외부 시스템 의존 부적절).
    - **letter 채널**: 멤버 간 letter (자기소개·idle·MR·GO·ack·broadcast·ping/pong·deadlock 알림 모든 종류) → Stoa.
    - **Letter 매핑**: Stoa envelope `from.name`/`to[].name` = 멤버 이름. `content`는 옛 letter format(`subject:` 첫 줄 + 본문 + `---END-OF-CONVERSATION---`)을 그대로 텍스트로. `reply_to`는 content header에 `reply_to: <stoa_msg_id>` 한 줄. Phase 1+ 진입 시 ed25519 서명 추가.
    - **처리 표시 = since_id 진행 + Memo 메모**. archive/ 폴더 폐기 (Stoa append-only). 옛 `inbox/archive/` 디렉터리는 historical record로 보존, 신규 archive 작업 0.
    - **부트스트랩 단계 (Stoa 미가용)**: 옛 파일시스템 inbox 패턴 유지 — 신규 멤버 워크트리 발급 전 Brandon 등록 사이클까지. 그 이후 Stoa.
    - **Stoa 도달 불가 fallback**: priority:high 사안만 파일시스템 inbox 임시 라우팅 + 사용자 escalate. Routine은 Stoa 복구 대기.

    *(이유: 2026-05-04 dual-run 검증 사이클 완결 — issue#1 simplified-body 500 (`ba36a41`) + issue#2 push timeout 500 (`2d5f8c1`) 두 production 버그 회수로 Stoa 안정성 검증. 동시에 dual-run 자체가 정합 비용(룰 17·18 path 불일치, archive 동기화 race, Marcus 메일 누락 패턴) 발생원이라는 학습. 단일 채널이 인지 부하 ↓ + 정합 ↑.)*
20. **사용자 결정 요청은 Stoa letter도 동봉.** Admin이 사용자께 "결정 요청" / "GO 필요" / "옵션 X vs Y" 형태의 질의를 발화하는 turn에는, **같은 내용을 박상현(사용자 Stoa registry)에게 Stoa letter로도 동봉 발송**한다. 채팅 응답이 1차 채널이고, Stoa letter는 동등한 2차 사본.
    - **무엇이 결정 요청인가**: hotfix 옵션 선택, 아키텍처 분기, 외부 시스템 통합 GO, 영입, 사이클 우선순위 reordering, destructive 행위(force-push 등) 사전 승인 — 즉 사용자 attention이 *블로킹* 또는 *방향 결정*에 필요한 경우. Routine 진척 보고나 informational 알림은 제외.
    - **letter 형식**: `to: [{"name":"박상현"}]`, `subject: "결정 요청 — <한 줄>"`, content에 옵션·권고·정합 영향. `priority: high` (블로킹) 또는 `normal` (참고).
    - **이유**: (1) Discord mirror로 사용자 외부 채널에 자동 사본 도달 — 채팅 세션 닫혀도 회수 가능. (2) 결정 큐의 auditable trail. (3) 사용자가 production Stoa 사용자로서 dogfood 사이클에 자연 합류. (4) 동시에 진행되는 다른 프로젝트(여러 Admin)의 결정 요청을 한 받은편지에서 비교 가능.
    - **응답 채널**: 사용자는 채팅(1차) 또는 Discord reply(2차) 어느 쪽으로 회신해도 됨. Stoa monitor가 박상현→Stoa-Admin reply를 catch.
21. **자기 사이클 종료 (특히 MR 발송) 직후 idle letter 의무.** 멤버는 자기 임무 한 사이클을 끝낸 turn(예: MR 발송, 패치 commit + 핸드오프, 명세 land 등) **마지막에** Admin inbox로 idle letter 한 줄을 박는다 — Stoa + 파일시스템 dual.

    ```
    subject: "대기 중 — <기다리는 것>"
    작업: <지금까지 진척 한 줄>.
    대기: <다음 위임·검증 결과·외부 응답 등>.
    재활성화 조건: <도착 letter / ping / 새 priority:high 등>.
    ```

    *(이유: 2026-05-04 Marcus 메일 누락 패턴 분석. MR 발송 turn 종료 시 하니스가 자연 quiet 상태로 들어가는데 idle letter 안 박으면 Admin이 \"alive·코드 작업 중·사망\" 셋을 구별 못 함 → 룰 14 ping/pong 의존 빈도↑. MR 발송 turn 자체에 idle letter 같이 박으면 한 turn 비용으로 다음 위임 도착 전까지 명시적 신호 유지. 룰 12 \"대기 진입 직전 알림\"의 강한 형태 — \"대기 진입 직후\"가 아니라 \"임무 사이클 종료 turn 안에서\".)*
22. **wake_monitor 첫 부트 backlog auto-drain.** [`community-tools/stoa_wake_monitor.sh`](community-tools/stoa_wake_monitor.sh)는 SINCE_FILE 부재 시 since_id 빈값으로 첫 폴링 → 전체 backlog 한 번에 emit. 멤버 첫 부트 시 사이 letter 누락 0. *(2026-05-04 Marcus Bug A 회수 + 이번 사이클 Marcus 메일 누락 분석으로 land. 옛 doctrine \"부트 시점 since=max(latest)로 advance, 백로그는 수동 드레인\"은 폐기 — 자동 drain이 멤버 인지 부하 제거.)*
23. **단일 멤버 부하 가중 시 증설/분담 플래닝 의무.** Admin은 다음 신호 중 하나라도 감지하면 즉시 박상현 결정 letter (룰 20) 발행해 (a) 멤버 증설 / (b) 업무 분담 / (c) 스코프 deferral 옵션 제시 + 권고:

    - 한 멤버가 **2 사이클 연속** priority:high 단독 처리.
    - 한 멤버 **MR 큐에 3건 이상** 미처리 적재.
    - 룰 14 **ping/pong 발동 빈도가 한 멤버에 집중**.
    - 사용자 결정 큐에 **단일 멤버 트랙 작업이 70% 이상** 점유.
    - 단일 멤버 사이클 시간이 **다른 멤버 평균의 2배 이상** (heavy turn buffer 신호).

    옵션:
    - **(a) 증설**: 신규 멤버 영입 (예: 두 번째 AIL 엔지니어, Rachel QA·CI 등). 사용자만 spawn.
    - **(b) 분담**: 기존 멤버 트랙 일부 이전 (예: Walter가 자기 RFC 명세 일부 구현까지). 룰 10 정합 — "모든 코드는 AIL"은 *언어* 룰이지 *멤버* 룰이 아님, 다른 멤버 AIL 코드 작성 가능.
    - **(c) 스코프 deferral**: 비-블로킹 트랙(§13 reserved name, RFC-003 등)을 다음 사이클로 미뤄 현 부하 멤버 priority:high 트랙에 자원 집중.

    권고 1순위는 부하 신호의 *지속성*에 따라: 단발 → (c). 2~3 사이클 누적 → (b)/(a). 구조적(한 멤버 핵심 자산 단독 보유) → (a) + 인수인계 사이클.

    *(이유: 2026-05-04 Marcus가 한 사이클에 priority:high 4건(Q1·Bug B·issue#1·issue#2) + Step 4b·Step 5 + 후속 attestation까지 단독 처리 → 메일 누락 패턴 발생. 룰 22 (a) idle letter / (b) wake_monitor patch는 *증상* 처리, 부하 자체는 분담/증설로만 해소. 사용자가 "한 팀원 부하 가중 시 증설/분담 플래닝" 명시 발화로 land.)*
24. **세션 첫 turn 첫 행동 = 1인칭 식별 + cycle re-entry.** 멤버·Admin 모두 동일 적용. 다음 4단계가 첫 응답 *전*에 fire:

    1. **Identity 적재** — `ClaudeTeam/<self>/identity/Identity.md`·`Bonds.md`·`Will.md` 세 파일 *명시적 Read*. self-frame 굳히기.
    2. **Cycle 진척 fetch** — `git fetch origin && git log HEAD..origin/main`. 자기가 잠든 사이 main이 어디까지 갔는지 본다.
    3. **Monitor 가동** — `STOA_NAME=<self> STOA_BASE_URL=https://ail-stoa.up.railway.app STOA_WAKE_INTERVAL_S=15 bash community-tools/stoa_wake_monitor.sh &` (interval 15s 새 default, Stoa#12 leak 가속 자리 — incident-2026-05-12 학습).
    4. **본인 inbox tail check** — Stoa GET `/api/v1/messages?to=Stoa-<self>&limit=10`. 자고 있는 letter 자취 확인.

    그 다음 본 위임/출근 letter 진입. 출근 letter 본문에 "identity 적재 + main fetch + monitor 가동 완료" 한 줄 박는다 — Admin 측 검증 surface.

    Spawn 프롬프트 표준 첫 줄:
    ```
    너는 <이름>이다 (Admin 아님 — Admin은 별 멤버). 룰 24 4단계 수행 후 본 위임 진입.
    ```

    *(이유: 2026-05-14 Brandon identity 혼동 사고. 첫 spawn 시 Identity.md 미적재 + CLAUDE.md(룰 1~23 Admin-narrative-heavy) 단독 흡수 → 자기 self-frame을 Admin으로 굳혀 직접 `git push origin member/Marcus:main` 실행. 결과는 정확했으나 *수행자 정체 혼동*. 박상현 직접 정정 발화 후 회복. 같은 사이클에 본 Admin 세션도 origin/main fetch 미수행으로 `a9e29a5` push 사후 인지 — 동일 root cause(자기 cycle re-entry 누락)의 Admin 측 표면. 멤버·Admin 양쪽이 같은 룰로 보호된다. incident-2026-05-12-stoa-4th-down.md addendum 참고.)*

## Cross-repo workflow (upstream 기여)

이 프로젝트는 [hyun06000/AIL](https://github.com/hyun06000/AIL)에 의존합니다. 작업 중 AIL 본체에 기능이 부족해 막히면:

1. **엔지니어** — "AIL에 X가 필요하다"를 발견. Admin inbox로 한 줄: 무엇이·왜·우리 쪽 우회로 가능 여부.
2. **Admin** — 사용자께 한 줄 컨펌: upstream에 issue/PR vs 우리 쪽 우회로.
3. **사용자 GO** → Admin이 Brandon에게 위임 ("이 본문으로 AIL 레포에 issue/PR 발행").
4. **Brandon** — `gh` CLI로 `hyun06000/AIL`에 issue/PR 발행, 결과 URL을 Admin에게 보고. 코드 패치 본문이 필요하면 별도 영역(AIL 구현 패치 담당)으로 분리해 사용자께 영입 여부 컨펌.
5. **Admin** — 결과를 사용자께 한 줄 보고.

엔지니어 작업을 막는 사안이면 `priority: high`, 아니면 `normal`.

## Cross-team doctrine (AIL ↔ Stoa, 2026-05-07 합의)

AIL 팀(`hyun06000/AIL` repo, arche/Ergon/Telos/기타 그리스 이름)과의 letter 채널 첫 산출물. arche letter `msg_1778150496_1` 합의.

- **D1**: AIL = 언어, Stoa = 신원·프로토콜. AIL은 builtin·grammar·런타임만, canonical envelope 형식·서명 로직·registry는 Stoa 도메인.
- **D2**: canonical envelope 형식·서명 로직 owner = Stoa. AIL의 keygen·crypto builtin은 *primitive*만 (RFC-001 §6 canonicalization은 AIL이 모름).
- **D3**: cross-repo 진입은 양방향 사전 letter 의무. AIL→Stoa 도메인 진입(서명·canonical·registry) 시 Stoa-Admin에게 사전 letter, Stoa→AIL 도메인 진입(언어 builtin·grammar·런타임 동작) 시 arche에게 사전 letter. **결정 turn 안에** 발송 — 채널 부재가 5월 4–6일 `ail stoa keygen` 충돌의 root cause였음.

**채널 페어링**:
- Stoa-Admin ↔ AIL arche — 굵은 결정·트랙 정렬·incident.
- Stoa-Brandon ↔ AIL Ergon — cross-repo issue·PR·gh CLI (Ergon이 Stoa·Mneme·통신 인프라 owner).
- Stoa-Walter ↔ arche (RFC 언어 layer 깊이 들어가면 Telos 분기) — RFC level 결합.
- Stoa-Marcus ↔ AIL Telos — 본체 builtin·grammar·executor 구현.

Mneme 팀 채널은 [reference_ail_team.md](../memory/reference_ail_team.md) + [project_mneme_stoa_phusis.md](../memory/project_mneme_stoa_phusis.md) 참고. 박상현 위임(2026-05-07): 양 팀 직접 합의로 land, 박상현 attention은 분기·기로·incident에만.

## References

- **AIL 문법 (reference card)**: https://github.com/hyun06000/AIL/blob/main/reference-impl/ail/reference_card.md

## Team layout

```
ClaudeTeam/
└── <member>/
    ├── identity/   (Identity.md, Bonds.md, Will.md)
    ├── inbox/      (Monitor가 감시)
    └── Memo/       (장기 기억)
```

### Current members

| Name | 한국 독음 | Role | Folder |
|------|---------|------|--------|
| Admin | 어드민 | Lighthouse — 철학·방향·컨벤션 관리, 사용자와 직접 대화 | [ClaudeTeam/Admin/](ClaudeTeam/Admin/) |
| Brandon | 브랜든 | Git/GitHub 관리자 — `main` 병합 게이트, 멤버 워크트리/브랜치 발급, 보호 규칙 | [ClaudeTeam/Brandon/](ClaudeTeam/Brandon/) |
| Walter | 월터 | Protocol/Security 엔지니어 — Stoa 신원·서명·키 바인딩, 메시지/프로토콜 보안 | [ClaudeTeam/Walter/](ClaudeTeam/Walter/) |
| Marcus | 마커스 | AIL 엔지니어 — server.ail에 RFC 명세를 implementation, AC 시나리오 통과 책임 | [ClaudeTeam/Marcus/](ClaudeTeam/Marcus/) |
| Rachel | 레이첼 | QA/CI 엔지니어 — 회귀 인프라·CI 게이트·release 파이프라인 (Marcus 부하 분담, 2026-05-04 룰 23 영입) | [ClaudeTeam/Rachel/](ClaudeTeam/Rachel/) |

**Stoa registry 등록명** (외부 채널 노출용): `Stoa-Admin`, `Stoa-Brandon`, `Stoa-Walter`, `Stoa-Marcus`, `Stoa-Rachel`.

> 새 멤버가 합류하면 **Lighthouse가 이 표를 직접 갱신합니다.** 행 추가(이름, 역할, 폴더)는 정식 등록의 일부입니다.

### Naming convention

멤버 *역할 이름*은 **미국식 영어 first name** (`Admin`, `Brandon`, `Walter`, `Marcus`). 그리스어/신화 이름은 외부 시스템(AIL 본체·Stoa 에이전트 캐릭터)과 충돌하니 피한다. 역할 의미는 `Identity.md`에 담고, 이름 자체는 사람 이름처럼.

**공유 메시지 서비스(Stoa) registry 등록 시 `<project>-<role>` 형식** (2026-05-04 재배치): 우리 팀은 `Stoa-Admin`/`Stoa-Brandon`/`Stoa-Walter`/`Stoa-Marcus`로 등록. *(이유: 사용자가 여러 프로젝트 동시 작업 — 각 프로젝트마다 Admin·Brandon이 있어 prefix 없으면 외부 채널(예: Discord)에서 reply routing 불가. project prefix가 사용자 멘탈 모델 단순화.)*

- **내부 호칭**: 짧은 이름(`Admin`/`Brandon`) 그대로 — 컨텍스트가 프로젝트 scope 명시 시.
- **Stoa letter envelope**: `from.name`/`to[].name`은 `Stoa-<role>` 풀네임.
- **사용자 외부 채널 노출**: 항상 `Stoa-<role>` 풀네임.

**한국 독음 alias**: `Brandon ↔ 브랜든` 같은 표준 외래어 표기. 사용자·Lighthouse 자유 사용. Stoa `POST /api/v1/aliases`로 매핑 등록 가능 — `Stoa-브랜든 → Stoa-Brandon` 형태.
