# 매물온

공인중개사 개인의 비공개 매물 관리 웹앱. 매물 Excel을 등록하고, 달력 기준 3개월 내 계약 만기 매물을 먼저 확인해 고객에게 연락하고 상담 결과를 기록한다.

> **현재 상태: 개발 하네스와 빈 골격만 있다. 제품 기능은 0건이다.**
> 진행 상황과 남은 문제는 [`progress.md`](progress.md)를 본다.

## 시작하기

```bash
make doctor   # 필요한 도구 점검 (없으면 설치 명령을 안내한다)
make init     # Python 런타임·의존성·.env 준비
make smoke    # 빠른 생존 확인
make verify   # 로컬 품질 게이트
```

`make`가 없는 Windows에서는 동일한 타깃을 `./make.ps1 <타깃>` 으로 실행한다.
두 경로 모두 `scripts/*.sh` 한 곳을 호출하므로 결과가 같다.

**요구 도구**: node ≥20, pnpm, uv, git. Python은 uv가 설치·관리한다(시스템 python을 쓰지 않는다).

## 개발

```bash
make dev            # web(5173) + api(8000)
make test           # 현재 실행 가능한 전체 테스트
make lint typecheck
make help           # 전체 타깃
```

## 구조

| 경로 | 내용 |
|---|---|
| `apps/web/` | React + TypeScript + Vite + Zustand + Tailwind CSS |
| `apps/api/` | FastAPI + Python 3.12 (uv 관리) |
| `packages/api-client/` | OpenAPI에서 생성하는 TS 클라이언트 (미구현) |
| `ai/` | 프롬프트·스키마·정책 레지스트리 |
| `evals/` | 고정 데이터셋·grader·리포트 |
| `tests/` | 앱 경계를 가로지르는 계약·보안·E2E |
| `scripts/` | init/doctor/smoke/verify의 실제 로직 |
| `docs/` | 요구사항, 설계, ADR, TASK, 런북 |

## 작업하기 전에

Claude Code와 Codex가 함께 쓰는 저장소다. 두 도구 모두 [`AGENTS.md`](AGENTS.md)를 지침 원본으로 읽는다
(`CLAUDE.md`는 이를 import만 한다).

1. [`AGENTS.md`](AGENTS.md) — 제품 중심, 불변식, 명령어, 금지사항, 완료의 정의
2. 해당 작업의 `docs/tasks/TASK-xxxx.md` — 없으면 [템플릿](docs/tasks/TASK-TEMPLATE.md)으로 먼저 만든다
3. TASK가 가리키는 요구사항 절과 ADR
4. 작업 영역의 `AGENTS.md`

기준 문서는 [`docs/product/requirements.md`](docs/product/requirements.md)다. 폐기된 요구는 [`deprecated.md`](docs/product/deprecated.md)에 있다.

기능·작업·불변식의 상태는 [`feature-list.json`](feature-list.json)에서 확인한다.

## 기여

이슈·PR·커밋 메시지는 **영어**로 쓴다. 규칙은 [`CONTRIBUTING.md`](CONTRIBUTING.md)에 있다
(Conventional Commits, 브랜치 규칙, PR 체크리스트).

```bash
git config commit.template .gitmessage.txt   # 커밋 메시지 형식 미리 채우기
git config core.hooksPath .githooks          # 형식에 맞지 않는 커밋을 로컬에서 거부
```

- [행동 강령](CODE_OF_CONDUCT.md)
- [보안 취약점 신고](SECURITY.md) — 공개 이슈로 올리지 않는다

## 라이선스

[LICENSE](LICENSE)
