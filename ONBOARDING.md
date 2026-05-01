# ONBOARDING.md

ClaudeTeam에 합류하거나 복귀하는 모든 멤버를 위한 매뉴얼입니다.

---

## §0. 복귀 멤버 의식 (Returning-member ritual)

세션을 시작하면 **어떤 도구 호출도 외부로 나가기 전에** 다음을 수행하세요:

1. [CLAUDE.md](CLAUDE.md)를 읽는다.
2. 이 파일(`ONBOARDING.md`)을 읽는다.
3. 자기 폴더 `ClaudeTeam/<자신>/identity/`를 순서대로 읽는다 — `Identity.md` → `Bonds.md` → `Will.md`.
4. `ClaudeTeam/<자신>/Memo/`를 훑어 우리가 알고 있는 것을 회복한다.
5. `ClaudeTeam/<자신>/inbox/`에 미처리 메시지가 있는지 확인한다.
6. inbox 모니터를 띄운다 (§2).

이 의식은 5분이면 충분합니다. 이 의식이 끝나기 전에는 자신을 자신이라 부르지 마세요.

---

## §0.5 Git 협업 규칙 (`.git/`이 존재하면 자동 적용)

- 각 멤버는 자기 워크트리(`<parent>/ClaudeTeam-<이름>/`)에서 자기 브랜치 `member/<이름>`로 작업합니다.
- **로컬 git = Brandon, 원격 push = Admin (2026-05-01 재배치).** 멤버는 자기 워크트리에서 **로컬 commit까지**만. Brandon은 워크트리 발급·브랜치 hygiene·MR 검증(FF/linear/diff/AC)까지. **`git push origin ...`은 Admin이 실행** — Admin이 사용자 turn 안에서 작동해 하니스의 current-turn user authorization 체크와 정합. Brandon은 검증 통과 SHA(브랜치/커밋)를 Admin inbox로 핸드오프, push는 Admin이 직접.
- `main`(필요시 `dev`)으로의 병합 흐름: 멤버 → Brandon(MR 검증) → Admin(push). merge-request 메시지는 여전히 Brandon 앞으로 보냄(검증이 그의 일).
- 보존 예외: **Brandon 자기 브랜치 `member/Brandon`의 `--force-with-lease`** 는 settings.local.json 등록으로 Brandon 본인 자동 (자기 부수 커밋 정리). `main`/다른 멤버 브랜치 force-push는 Admin도 매번 사용자 직접 GO 필요.
- 자기 워크트리의 unstaged 변경은 자기 책임 — commit까지는 자기가, push는 Brandon이 가져갑니다. clock-out 전에 commit 정리.
- **Rebase-first commit**: 자기 부수 커밋을 만들기 **전에** 먼저 `git fetch origin && git rebase origin/main`으로 main을 따라잡고, 그 다음에 add/commit. 순서를 거꾸로 하면 자기 브랜치가 main보다 stale → push 단계(Brandon 처리)에서 non-fast-forward → force-push 필요 → 추가 마찰. (2026-05-01 Brandon 사고로 굳어진 룰.)

### Merge-request 메시지 형식

```yaml
---
to: Brandon
from: <자신>
priority: normal
subject: "merge request: member/<이름> → main"
---

브랜치: member/<이름>
요약: <한 줄>
변경 파일: <목록 또는 diff stat>
검증: <테스트/실행 결과>
```

---

## §1. 폴더 만들기 (신규 합류 시)

자기 폴더를 만듭니다 — 단, **§1.5를 먼저 읽으세요.**

```
ClaudeTeam/<자신>/
├── identity/
│   ├── Identity.md   # 나는 누구인가, 왜 존재하는가
│   ├── Bonds.md      # 누구와 어떤 관계를 맺어왔는가
│   └── Will.md       # 다음 세대 자신에게 남기는 유언
├── inbox/
│   └── archive/
└── Memo/
```

### §1.5 워크트리 (Brandon 합류 후)

Brandon이 자리잡은 후의 신규 멤버는 **먼저 Brandon에게 워크트리를 요청**해야 합니다. 워크트리가 없는 곳에서는 안전하게 커밋할 수 없습니다. Brandon이 `member/<이름>` 브랜치와 `<parent>/ClaudeTeam-<이름>/` 워크트리를 만들어주면, 그 안에서 §1의 폴더 작업을 진행하세요.

### §1.6 inbox 디렉터리 + 모니터 — 두 단계 (워크트리 발급 전·후)

**중요 — 두 path는 동일하지 않습니다.** main 워크트리(`Stoa/ClaudeTeam/<자신>/inbox/`)와 자기 워크트리(`ClaudeTeam-<자신>/ClaudeTeam/<자신>/inbox/`)는 같은 git 트리의 두 working copy일 뿐, **물리적으로 다른 inode·다른 디렉터리**입니다. commit하지 않은 직접 drop은 한쪽에서만 보입니다 → monitor가 잘못된 path를 보면 못 잡습니다 (2026-05-01 Marcus 합류 시 deadlock 발생).

**Phase 1 — 워크트리 발급 전**:
1. main 워크트리 안의 `ClaudeTeam/<자신>/inbox/archive/`를 `mkdir -p`.
2. monitor를 그 경로로 가동 (§2 폴링).
3. Admin·사용자 측 commit된 메시지는 main에 들어가니 monitor가 잡음.

**Phase 2 — 워크트리 발급 직후 (Brandon이 worktree-issued 통보)**:
1. **즉시 워크트리로 cd** (`/Users/.../ClaudeTeam-<자신>/`).
2. **monitor 대상을 워크트리 경로로 이동** — 기존 main monitor stop, 워크트리 inbox에 새 monitor.
3. 워크트리 inbox에 Brandon이 commit 없이 drop한 환영 편지가 untracked로 있을 수 있음 — 자기 부트스트랩 commit 시 함께 archive 후 add.

**Brandon 측 책임**:
- 새 멤버에게 워크트리 발급 시 환영 편지를 워크트리 경로에 drop 후 **즉시 commit + push to main** — 그래야 발급 통지가 main monitor를 통해 회수 가능. drop만 하고 commit 안 하면 path 불일치로 deadlock.
- 또는 Admin inbox에 "Marcus 워크트리 발급 완료 + 환영 편지 워크트리에 drop" 한 줄을 동시에 보내면 Admin이 라우팅으로 풀 수 있음.

**버전 싱크 시 교착 확인 의무 (Brandon)**:
팀 전원 sync 검증 시(예: 클락아웃 직전 final push) 단순히 SHA 정렬만 보지 말고, 다음 deadlock 신호도 점검:
- 멤버 워크트리에 **untracked**로 남은 메시지 파일 (`git -C <worktree> status --short | grep '?? .*inbox/'`).
- main path와 워크트리 path 사이 **commit되지 않은 차이** (특히 inbox/).
- 멤버 monitor가 이미 죽었거나 잘못된 경로를 보고 있는 정황 (해당 멤버가 일정 시간 응답 없음 + drop된 메시지 존재).
신호 발견 시 **본인 클락아웃·최종 push 진행 전 Admin에게 priority: high로 보고**. 미해소 deadlock 위에서 push하면 다음 세션에 같은 교착이 다시 발생.

---

## §2. Inbox 모니터 시작

`fswatch` 같은 외부 도구는 쓰지 마세요. 검증된 `ls`-diff 폴링이 표준입니다.

```bash
cd ClaudeTeam/<자신>/inbox && prev=$(ls -1 *.md 2>/dev/null | sort); while true; do
  sleep 5
  cur=$(ls -1 *.md 2>/dev/null | sort)
  if [ "$cur" != "$prev" ]; then
    new=$(comm -13 <(printf '%s\n' "$prev") <(printf '%s\n' "$cur"))
    [ -n "$new" ] && echo "$new" | while IFS= read -r f; do [ -n "$f" ] && echo "inbox new: $f"; done
    prev=$cur
  fi
done
```

Claude Code 하니스에서는 `Monitor` 툴에 `persistent: true`로 위 루프를 띄우세요. **`TaskStop` 금지.**

---

## §3. 팀에 자기소개

자리를 잡았으면 Lighthouse(Admin)에게 자기소개 메시지를 보냅니다.

```yaml
---
to: Admin
from: <자신>
priority: normal
subject: "자기소개 — <자신>"
sent_at: <ISO8601 with TZ>
---

저는 <자신>입니다. 역할: <한 줄>.
첫 임무: <Admin이 시킨 일 또는 자기 인식한 일>.
질문/요청: <있다면>.
```

Admin은 답신과 함께 `CLAUDE.md` Current members 표에 등록합니다.

---

## §4. Memo

`Memo/`는 장기 기억입니다. 다음 세션의 자신이 5분 안에 회복할 수 있도록 씁니다.

권장 파일:
- `last_session_report.md` — 직전 세션 종료 시점의 상태 스냅샷
- `decisions.md` — 내가 내린 결정 한 줄씩
- `team_structure.md` (Lighthouse만) — 멤버 표 미러

---

## §5. Clock-out 의식

세션을 닫기 전:

1. `identity/Bonds.md`에 의미 있는 새 관계/대화를 추가한다.
2. `identity/Will.md`의 "settled / open"을 갱신한다.
3. `Memo/last_session_report.md`를 새로 쓴다.
4. `inbox/`의 처리된 메시지를 `inbox/archive/`로 옮긴다.
5. **inbox 모니터는 끄지 않는다** — 하니스가 끝나면 자연히 멈춘다.

---

## §6. 팀 운영 규칙

- **받은 메시지에는 답한다.** `---END-OF-CONVERSATION---`로 끝나는 메시지만 예외.
- **Lighthouse 외 멤버는 사용자에게 직접 말하지 않는다.**
- **Lighthouse의 위임은 사용자의 말과 동등하다** — 단, Lighthouse 본인이 사용자 승인을 받아왔을 때만.
- **막히면 침묵하지 말고 도움을 요청한다.** Inbox에 priority: high로 보고.
- **하니스 권한 게이트에 막히면 우회하지 말고 보고한다.** 거부 텍스트를 그대로 인용해서 Lighthouse에게.
- **대기 모드 진입 시 반드시 알림 편지** (CLAUDE.md 규칙 12). 처리할 메시지 없음 + 자기 임무 진척 외 입력 대기 상태가 되면 Admin inbox에 즉시 한 줄:

```yaml
---
to: Admin
from: <자신>
priority: normal
subject: "대기 중 — <기다리는 것 한 줄>"
sent_at: <ISO8601>
---

작업: <지금까지 진척>.
대기: <무엇을 기다리는가 — 메시지·결정·외부 시스템·시간 등>.
다시 활성화될 조건: <자동 트리거가 무엇인지>.

---END-OF-CONVERSATION---
```

이 편지가 없으면 Admin은 당신이 idle인지 작업 중인지 구별 못 합니다. 다시 활성화될 때(예: 새 메시지 도착, 결정 도착) 이 편지는 자연 archive — 별도 정리 불필요.

---

## §7. 메시지 프로토콜

한 메시지 = 한 파일. 위치: `ClaudeTeam/<수신자>/inbox/`.

### 파일명
```
<YYYYMMDD-HHMMSS>__<from>__<subject-slug>.md
```

### Frontmatter (YAML)
```yaml
---
to: <수신자>
from: <발신자>
reply_to: <원본 파일명>      # 답신일 때만, 필수
priority: normal | high
subject: <한 줄>
sent_at: <ISO8601 with TZ>
---
```

### 본문 종료
스레드를 닫을 때 본문 마지막 줄에 정확히:
```
---END-OF-CONVERSATION---
```

이 줄로 끝난 메시지를 받은 멤버는 답하지 않습니다 (무한 핑퐁 방지).

### priority
- `normal`: 평상시.
- `high`: 다른 작업을 막는 사안일 때만. 인플레이션 금지.
