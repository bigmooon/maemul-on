# 매물온 Makefile
#
# 이 파일은 얇은 디스패처다. 실제 로직은 scripts/*.sh 한 곳에 있다.
# make가 없는 Windows에서는 동일한 타깃을 ./make.ps1 <타깃> 으로 실행한다.

SHELL := /bin/bash
.DEFAULT_GOAL := help

# --directory 로 apps/api 안에서 실행한다. 루트에서 실행하면 mypy가 같은 파일을
# 두 모듈 이름으로 인식한다.
UV_API := uv run --directory apps/api

.PHONY: help init doctor smoke verify dev lint typecheck \
        test test-unit test-contract test-security test-web \
        test-db test-e2e-smoke check-migrations eval-offline \
        seed-demo api-client check-no-secrets clean

help: ## 타깃 목록
	@echo "매물온 — 사용 가능한 타깃"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	  | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "make가 없으면: ./make.ps1 <타깃>"

# --- 환경 ------------------------------------------------------------------

doctor: ## 필요한 도구 점검과 설치 안내
	@bash scripts/doctor.sh

init: ## Python 런타임·의존성·.env 준비 (멱등)
	@bash scripts/init.sh

# --- 개발 ------------------------------------------------------------------

dev: ## web + api 개발 서버 (Ctrl+C로 종료)
	@echo "api: http://127.0.0.1:8000  |  web: http://127.0.0.1:5173"
	@trap 'kill 0' INT TERM; \
	$(UV_API) uvicorn maemul_on.main:app --reload --app-dir src & \
	pnpm --filter web dev & \
	wait

# --- 게이트 ----------------------------------------------------------------

smoke: ## 빠른 생존 확인 (import, /health, web 빌드)
	@bash scripts/smoke.sh

verify: ## 로컬 품질 게이트 — 완료 전 반드시 실행
	@bash scripts/verify.sh

lint: ## ruff + eslint
	@$(UV_API) ruff check .
	@pnpm --filter web lint

typecheck: ## mypy + tsc
	@$(UV_API) mypy src
	@pnpm --filter web typecheck

test: test-unit test-contract test-web ## 현재 실행 가능한 전체 테스트

test-unit: ## API 단위 테스트
	@$(UV_API) pytest tests -m unit -q

test-contract: ## API 계약 테스트
	@$(UV_API) pytest tests -m contract -q

test-security: ## 두 사용자 격리 테스트
	@bash -c 'if [ -n "$$(find apps/api/tests/security -name "test_*.py" -print -quit 2>/dev/null)" ]; then \
	  $(UV_API) pytest tests -m security -q; \
	else \
	  echo "SKIPPED: test-security — 두 사용자 fixture 미구현 (TASK-0002)"; \
	fi'

test-web: ## Web 테스트 (Vitest)
	@pnpm --filter web test

check-no-secrets: ## 비밀·PII 스캔
	@bash scripts/check-no-secrets.sh

# --- 미구현 타깃 -----------------------------------------------------------
# 존재하지 않는 타깃으로 두지 않고, 담당 TASK를 알려주고 종료한다.
# 스킵은 통과가 아니다.

test-db: ## (미구현) repository 테스트 — TASK-0002
	@echo "SKIPPED: test-db — DB 계층이 아직 없다 (TASK-0002)"

test-e2e-smoke: ## (미구현) Playwright E2E — TASK-0006
	@echo "SKIPPED: test-e2e-smoke — Playwright 및 대상 화면 미구현 (TASK-0006)"

check-migrations: ## (미구현) 마이그레이션 검사 — TASK-0002
	@echo "SKIPPED: check-migrations — Alembic 마이그레이션이 아직 없다 (TASK-0002)"

eval-offline: ## (미구현) 오프라인 평가 — TASK-0012
	@echo "SKIPPED: eval-offline — 평가 데이터셋이 아직 없다 (TASK-0012)"

seed-demo: ## (미구현) 데모 데이터 — TASK-0002
	@echo "SKIPPED: seed-demo — DB와 fixture가 아직 없다 (TASK-0002)"

api-client: ## (미구현) OpenAPI → TS 클라이언트 — TASK-0002
	@echo "SKIPPED: api-client — 생성할 API 스키마가 아직 없다 (TASK-0002)"

# --- 정리 ------------------------------------------------------------------

clean: ## 빌드·캐시 산출물 삭제 (의존성은 남긴다)
	@rm -rf apps/web/dist apps/web/node_modules/.vite
	@find . -type d \( -name __pycache__ -o -name .pytest_cache -o -name .mypy_cache -o -name .ruff_cache \) \
	  -not -path "./node_modules/*" -prune -exec rm -rf {} + 2>/dev/null || true
	@echo "정리 완료"
