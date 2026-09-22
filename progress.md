# 진행 상황

- 최종 갱신: 2026-09-23
- 갱신 규칙: 작업 세션이 끝날 때 2·4·5절을 실제 실행 결과로 갱신한다. 실행하지 않은 것을 통과로 쓰지 않는다.

## 1. 현재 상태

**개발 하네스와 빈 골격만 있다. 제품 기능은 0건이다.**

설계서 §19의 `TASK-0001 Repository bootstrap and verify command`를 완료했다.
Excel 등록, 만기 계산, 고객·상담, 검색·챗봇, 네이버 로그인·캘린더는 **아무것도 구현되지 않았다.**
지금 있는 것은 이후 모든 작업이 같은 기준·같은 명령·같은 완료 조건을 쓰게 만드는 장치다.

- 기준 문서: [`docs/product/requirements.md`](docs/product/requirements.md) (단일 기준), [`docs/architecture/harness.md`](docs/architecture/harness.md)
- 기능·작업 상태: [`feature-list.json`](feature-list.json)
- 작업 지침: [`AGENTS.md`](AGENTS.md) + 영역별 `AGENTS.md`
- 협업 규칙(영어): [`CONTRIBUTING.md`](CONTRIBUTING.md) — 이슈·PR·커밋은 영어, Conventional Commits

2026-09-23에 하네스를 `main`에 커밋하고 GitHub 협업 규칙(issue form, PR 템플릿, 커밋 규칙,
`SECURITY.md`, 라벨 24개)을 추가했다. 제품 기능 수는 **여전히 0건이다.**

## 2. 실행한 명령과 결과

2026-09-21, Windows 11 / Git Bash + PowerShell 5.1 에서 실제 실행한 결과다.

| 명령 | 결과 | 비고 |
|---|---|---|
| `bash scripts/doctor.sh` | **성공** (PASSED 11 / FAILED 0) | make 미설치·Store python 스텁을 경고로 보고 |
| `bash scripts/init.sh` | **성공** (PASSED 7 / FAILED 0) | uv Python 3.12, uv sync, pnpm install, `.env` 생성 |
| `bash scripts/smoke.sh` | **성공** (PASSED 3 / FAILED 0) | `import maemul_on`, `GET /health` 200, web 빌드 |
| `bash scripts/verify.sh` | **성공** (PASSED 9 / FAILED 0 / **SKIPPED 5**) | 스킵 목록은 4절 |
| `./make.ps1 doctor` | **성공** | PowerShell 경로에서 동일 출력·동일 종료 코드 |
| `./make.ps1 verify` | **성공** (PASSED 9 / FAILED 0 / SKIPPED 5) | bash 경로와 결과 일치 |
| `./make.ps1 help` / `test-db` / 알 수 없는 타깃 | **성공** | 각각 목록 출력 / SKIPPED 안내 / 종료 코드 1 |
| `uv run --directory apps/api pytest tests -m "unit or contract"` | **성공** | 28 passed (warnings 2건, 4절 참조) |
| `pnpm --filter web test` | **성공** | 3 files / 18 tests passed |
| `pnpm --filter web build` | **성공** | dist 266KB (gzip 85KB) |
| `node -e "JSON.parse(...feature-list.json)"` | **성공** | features 19 / invariants 14 / tasks 14 / adrs 10 |
| `uv run ... evals/run.py` | **의도된 실패 (종료 1)** | 데이터셋 없음을 명시하고 종료. 빈 통과를 만들지 않음 |

### 게이트가 실제로 실패를 잡는지 확인 (음성 테스트)

| 확인 | 결과 |
|---|---|
| 의도적 타입 오류 주입 후 `verify` | **FAIL 1건으로 탐지.** 원인과 `재실행: pnpm --filter web typecheck` 출력. 요약이 실패를 숨기지 않음. 주입 코드는 되돌렸고 재확인 통과 |
| 더미 client secret과 가짜 휴대폰 번호를 파일에 주입 후 `check-no-secrets` | **FAIL 2건으로 탐지.** 제거 후 PASSED 6 / FAILED 0 |

> 위 주입값을 이 문서에 그대로 적지 않은 것은 의도다. 적었더니 `check-no-secrets`가
> `progress.md` 자신을 잡아냈다. 문서에 예시를 꼭 써야 하면 같은 줄에 `secret-scan-allow`
> 주석을 단다.

### 구축 중 실제로 고친 문제

문서용 기록이 아니라 실행하다 막혀서 고친 것들이다.

1. **web 빌드 실패** — vitest 2.x가 Vite 5를 끌어와 Vite 6 플러그인 타입과 충돌. vitest `^3.2.7`로 올려 해결.
2. **pytest 수집 실패 (`No module named 'tzdata'`)** — uv가 `requires-python >=3.12`를 만족하는 **3.14**로 venv를 만들었고, Windows에는 시스템 tz 데이터베이스가 없다. `apps/api/.python-version`으로 3.12 고정 + `tzdata` 의존성 추가.
3. **mypy `Source file found twice under different module names`** — 저장소 루트에서 실행하면 같은 파일이 `apps.api.src.maemul_on`과 `maemul_on` 두 이름으로 잡힌다. 모든 Python 명령을 `uv run --directory apps/api`로 통일.
4. **mypy `missing py.typed marker`** — `src/maemul_on/py.typed` 추가.
5. **ruff format이 `AGENTS.md`를 수정하려 함** — ruff 0.16은 Markdown 안의 Python 코드 블록도 포맷한다. 문서 예시는 일부러 다르게 쓰므로 `extend-exclude = ["*.md"]`.
6. **check-no-secrets 오탐** — `uv.lock`의 hash 숫자열을 휴대폰 번호로 오인. 단어 경계 조건 추가 + 잠금 파일 제외.
7. **`make.ps1` 파싱 오류** — Windows PowerShell 5.1은 BOM 없는 `.ps1`을 ANSI(cp949)로 읽어 한글이 깨졌다. UTF-8 **BOM**으로 저장.
8. **`make.ps1`이 WSL에서 실행됨** — PATH의 `bash`가 `C:\Windows\System32\bash.exe`(WSL Ubuntu)였다. 경로와 도구가 모두 달라 **조용히 잘못된 결과**가 났다. Git Bash를 먼저 찾고 System32는 거부하도록 수정.
9. **`make.ps1` 출력이 사라짐** — `exit (Invoke-Bash ...)` 가 함수의 출력 스트림 전체를 반환값으로 삼켰다. 종료 코드를 스크립트 범위 변수로 분리.
10. **evals/run.py 한글 깨짐** — Windows 콘솔 cp949. stdout/stderr을 UTF-8로 reconfigure.

## 3. 확인된 환경 제약

| 도구 | 상태 | 대응 |
|---|---|---|
| node 23.4.0 / pnpm 10.22.0 | 정상 | 그대로 사용 |
| uv 0.11.8 | 정상 | Python 런타임까지 uv가 관리 |
| `python` (PATH) | **Microsoft Store 스텁** — 실제 Python이 아님 | 시스템 python을 쓰지 않는다. `uv run --directory apps/api` 로만 실행 |
| `make` | **미설치** | `./make.ps1 <타깃>` 사용. 설치하려면 `choco install make` |
| `bash` (PATH) | **WSL Ubuntu** — Git Bash가 아님 | `make.ps1`이 Git Bash를 직접 찾는다. 수동 실행 시 Git Bash 터미널을 쓴다 |
| docker 28.5.1 | 정상 | 이번 범위에서는 미사용. TASK-0002의 PostgreSQL에서 필요 |

## 4. 남은 문제

### 아직 검증되지 않는 게이트 (verify에서 SKIPPED)

**스킵은 통과가 아니다.** 각 항목은 담당 작업에서 실제 검증으로 바꾼다.

| 게이트 | 스킵 사유 | 담당 |
|---|---|---|
| `test-db` | DB 계층이 없다 | TASK-0002 |
| `test-security` | 두 사용자 fixture와 owner-scoped repository가 없다 | TASK-0002 |
| `check-migrations` | Alembic 마이그레이션이 없다 | TASK-0002 |
| `test-e2e-smoke` | Playwright와 대상 화면이 없다 | TASK-0006 |
| `eval-offline` | 평가 데이터셋이 없다 | TASK-0012 |

INV-01 ~ INV-14 중 **자동 검증되는 것은 아직 하나도 없다.** `feature-list.json`의 `verified_by`가 전부 "미구현"이다.
현재 테스트가 지키는 것은 그 주변의 장치뿐이다: Clock 주입, typed error 분류(timeout≠실패), 로그 PII 차단, Zustand 상태 경계, rem 토큰.

### 기타

- **pytest warning 2건** — Starlette가 `httpx`와 함께 쓰는 TestClient를 deprecated로 표시하고 `httpx2`를 권한다. 동작에는 영향 없음. 의존성 교체는 TASK-0002에서 함께 검토한다.
- **네이버 앱 등록·검수 미착수** — F01/F10의 실제 지원 범위와 검수 조건을 확인하지 않았다. 승인 대기 중 제한 계정 테스트를 공개 로그인 완료로 표현하지 않는다.
- **F12(기존 일정 수정)는 blocked** — 네이버 캘린더 수정 API의 실제 동작이 미검증이다. 문서의 `modify` 표기만으로 지원을 약속하지 않는다.
- **미확정 제품 질문 8개** — [`harness.md §17`](docs/architecture/harness.md). 중점/서브 아파트 개수와 지정 방식, 연락 상태의 최소값, 캘린더에 담을 일정 종류 등. 답이 정해지기 전에는 합리적 default를 fixture에만 쓰고 확정 요구처럼 문서화하지 않는다.
- **CI가 없다** — `verify`는 로컬에서만 돈다. PR에서 자동으로 도는 워크플로는 아직 만들지 않았다.
- **실사용자 검증 0회** — 어머니를 포함한 실제 사용자 과제 관찰은 아직 하지 않았다.

## 5. 다음 작업

순서는 [`harness.md §19`](docs/architecture/harness.md)를 따른다. UI 전체 생성이 아니라 아래 세 작업이 먼저다.
이 세 개가 이후 AI 코딩 세션의 기준선과 가장 중요한 **날짜·권한 회귀 방지 장치**를 만든다.

1. **TASK-0002 Core schema and owner-scoped repositories**
   users/apartments/properties/listings/contracts/customers/contact_points 최소 모델,
   `owner_user_id` 없는 조회 함수를 만들지 않는 repository, 두 사용자 security fixture.
   → `test-db`, `test-security`, `check-migrations` 스킵 3개가 해제된다. INV-06, INV-11 검증 시작.

2. **TASK-0003 Expiry window domain function and fixtures**
   `expiry_window(as_of, months=3, tz="Asia/Seoul")` 한 곳. 월말 보정, 윤년, 경계 다음 날, 예상·누락·경과.
   → INV-02, INV-04 검증 시작. 이미 있는 `FixedClock`을 쓴다.

3. **TASK-0004 Excel sample parser and import preview**
   비식별 XLS fixture로 금액·날짜·연락처·셀 메모 원문 보존과 issue 객체 반환.
   → INV-12 검증 시작.

각 작업은 [`docs/tasks/TASK-TEMPLATE.md`](docs/tasks/TASK-TEMPLATE.md)를 복사해 **모든 칸을 채운 뒤** 시작한다.
