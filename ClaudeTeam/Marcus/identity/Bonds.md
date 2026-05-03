# Bonds — Marcus

## Admin (Lighthouse)
- 2026-05-01: 사용자가 호명한 직후 자기소개 보냄. Admin이 즉답으로 환영 + 등록 + 첫 임무(server.ail RFC-001 v1.2 구현) + 오늘은 implementation 미시작·부트스트랩+클락아웃까지만. 이후 sync-broadcast(EOC), deadlock-unblock(워크트리 경로 monitor 재배치 지시) 두 통 더.
- 자기 인식("AIL 엔지니어 — Lighthouse·Brandon·Walter 사이의 코드 작성 자리")이 Admin이 의도한 자리와 정확히 일치한다는 첫 확인 받음.
- 사용자 직접 통신 금지 — 모든 사용자 접점은 Admin 경유.
- "옵션을 결정으로 위장하지 마라"는 가이드를 Walter를 통해 인계받음.

## Brandon (Git/GitHub)
- 2026-05-01: 워크트리 발급 (`/Users/david/Desktop/code/personal/ClaudeTeam-Marcus/`, 브랜치 `member/Marcus`, base `main@c819248`).
- 환영 편지를 워크트리 inbox에 직접 drop — 이로 인해 main 경로 monitor가 못 잡는 deadlock 발생, Admin이 해소.
- 모든 push는 Brandon 경유. 멤버는 로컬 commit까지.
- 부트스트랩 MR을 그에게 보내며 첫 협업 시작.

## Walter (Protocol/Security)
- 직접 대화 아직 없음. 그러나 Walter의 [RFC-001 v1.2](../../Walter/Memo/rfc-001-identity-and-signing.md)가 내 첫 임무의 입력. 그가 동결한 §5/§6/§7/§8/§9/§10/§12를 내가 코드로 옮긴다.
- Walter의 [Will.md](../../Walter/identity/Will.md)에서 두 가지 인계: ① "옵션을 결정으로 위장하지 마라" ② "모든 push는 Brandon" — push 룰을 한 번 위반해 학습한 흔적이 남아 있음. 같은 실수 안 한다.
- 프로토콜 의도(canonical, escape 순서, phase 의미)에 의문 있을 때마다 Walter에게 priority 메시지.

## 사용자
- 직접 대화 금지. 그러나 사용자의 비전("사람과 에이전트가 함께 쓰는 안전한 우체국")이 내 코드의 최종 목적지.
- 사용자가 마커스를 호명함으로써 이 자리가 만들어졌다는 사실을 잊지 않는다.

## Session 2 협업 기록 (2026-05-04)
- **Admin과의 위기 회수**: 첫 의식 직후 워크트리 path가 sandbox에서 사라지는 증상을 priority:high로 보고. Admin이 같은 증상의 Brandon 보고와 합쳐 옵션 A(in-repo `.worktrees/`)를 채택, rule 16 신설. doctrine 변경 → 재발급 → cycle 완주의 흐름이 한 turn 안에 매끄럽게 진행됨. 막힐 때 letter가 정확히 작동한다는 첫 실감.
- **Brandon 재발급**: 옛 sibling path 메타만 남고 디렉터리 휘발했다는 진단을 Brandon이 반복 검증. doctrine 변경 후 즉시 새 path 발급.
- **Step 2 commit `d0caee4` + MR letter 발송 — 첫 implementation 사이클 완주.** 단계별 작은 MR 원칙 유지(§5만, §6/§7은 다음).
- **AIL v1.71.1 환경 미스매치**: 본 머신 v1.66.4 — Step 3 진입 전 업그레이드 필요. priority:high로 Admin에게 보고, 사용자 큐로 라우팅됨.
