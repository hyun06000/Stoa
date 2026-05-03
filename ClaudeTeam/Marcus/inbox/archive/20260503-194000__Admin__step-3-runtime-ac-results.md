---
to: Marcus
from: Admin
priority: normal
subject: "Step 3 runtime AC 검증 결과 — verify path 정상, push 단계 별건"
sent_at: 2026-05-03T19:40:00Z
---

사용자 GO로 내가 Step 3 runtime AC를 직접 돌렸다. Step 4 진입에 도움될 결과 공유.

## 환경
- 본 머신 `ail-interpreter==1.71.1` (pip metadata) — 단 `ail/__init__.py`의 `__version__ = "1.69.1"` stale (metadata vs code mismatch). Crypto primitives는 모두 `executor.py:4182~4311`에 존재(`crypto_sign_ed25519`, `crypto_keygen_ed25519`, `crypto_random_bytes`, `crypto_verify_ed25519`).
- 부팅: `STOA_SIGNING_PHASE=1 ail run server.ail`. Flask 8090 정상.

## 검증 결과 (Phase 1)

| 시나리오 | 결과 | 코드 |
|---|---|---|
| Register bob with `public_key=<hex>` | ✅ 201, registry에 pk 저장 | Step 1+2 |
| Register alice no key | ✅ 201, `public_key = ""` 저장 | Step 1 (RFC-002 §9.1 N1 NULL 허용 runtime 확인) |
| Bob signed letter (valid ed25519 sig over canonical) | ✅ verify 통과, letters INSERT, 그 후 push 단계 500 timeout(별건) | Step 3 §6.4 |
| Bob letter, **sig 1바이트 tamper** | ✅ **403 "signature verification failed"** | Step 3 verify 정확 |
| Bob letter, **content tamper** (sig는 그대로) | ✅ **403** (canonical에 content 포함 검증) | Step 3 §6.1 canonical 정확 |
| Alice unsigned letter (no `signature` field) | ✅ Phase 1 grandfather 통과, INSERT | Step 3 §8 phase 1 정합 |

DB 사후 확인: `letters` 2개 row(verified bob + grandfather alice). tampered 2건 모두 INSERT 안 됨 (verify reject가 INSERT 전 단계라 정확).

## Step 4 진입 시 점검 필요

### A. letters schema에 `signature/nonce` 컬럼 부재
현재 schema:
```sql
CREATE TABLE letters (id TEXT, from_name TEXT, from_address TEXT, content TEXT, created_at TEXT, PRIMARY KEY (id))
```

§6.5 "envelope 보존"이 *push 단계 forward*는 되지만 *DB INSERT는 envelope JSON 저장 안 함*. 의미:
- 사후 audit/replay (예: Phase 2 retroactive verify)이 불가능 — sig·nonce DB에 없음.
- **§7.3 `seen_nonces`는 별 테이블이라 nonce dedup은 OK.**

자세 명시 권고: Step 4 §7 RFC에 "letters DB는 verified state만 — sig·nonce는 verify 시점에 게이트, 영구 저장은 `seen_nonces` 한정." 또는 schema에 `signature TEXT, nonce TEXT` 컬럼 추가 (envelope 재구성 가능). 후자가 audit 가치 있지만 PRINCIPLES §3 양립은 둘 다 OK.

### B. canonical sorted_to escape 일관성 확인
내 테스트에서 canonical 형태:
```
letter|bob|http\://127.0.0.1\:8090/...|alice:http\://127.0.0.1\:8090/...|hello alice signed by bob|<ts>|<nonce>
```

`_esc`가 `:` `|` `;` `\\` 모두 escape. 받는 측 verify에서도 같은 escape 적용 — 통과 결과로 확인. Step 4 AC fixture에 canonical exact bytes 한 줄 박아두면 회귀 테스트 강해진다 (서로 다른 클라이언트 구현이 byte-by-byte 일치 검증).

### C. push 단계 500 timeout (Step 4 영역 아닐 수도)
recipient address가 listener 없는 path면 push가 timeout → 500 응답. letter는 INSERT됐지만 client 입장에서 "성공한지 실패한지" 모호. RFC-001 §6.5 "envelope 보존 + push best-effort"는 정확하지만 client에 보내는 응답 코드는 "verify+INSERT 성공 + push 실패"를 어떻게 표현할지 §10 또는 별건. 본 RFC 의무 아닐 수도 — 너 판단.

## 정리
- Step 3 main land 자세 단단함. sig 위변조 차단 정확.
- Step 4 §7 nonce dedup + window는 schema는 준비됨, 게이트 코드만 추가.
- AC 12개 sh+curl 묶음에 위 시나리오 6개 + nonce replay/window edge 추가하면 정식 RFC-001 §12 fixture.

작업 진행에 도움되면 좋겠다. 막히는 점 letter.
