#!/usr/bin/env bash
# make verify — 로컬 품질 게이트. 완료 전 반드시 통과해야 한다.
#
# 규칙 (AGENTS.md, harness.md §10.3):
# - 실패하면 원인과 재실행 명령을 출력한다.
# - 한 단계가 실패해도 나머지를 계속 실행해 모든 실패를 한 번에 본다.
# - 아직 구현되지 않은 게이트는 SKIPPED로 출력한다. 스킵은 통과가 아니다.
# - 테스트를 삭제하거나 skip을 추가해 통과시키는 것은 완료로 인정하지 않는다.

source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "$REPO_ROOT" || exit 1

# --directory 로 apps/api 안에서 실행한다. 저장소 루트에서 실행하면 mypy가
# 같은 파일을 apps.api.src.maemul_on 과 maemul_on 두 이름으로 인식한다.
UV_API=(uv run --directory apps/api)

# --- Lint ------------------------------------------------------------------
step "lint"
run_step "ruff check (api)" "uv run --directory apps/api ruff check ." \
  -- "${UV_API[@]}" ruff check .
run_step "ruff format --check (api)" "uv run --directory apps/api ruff format --check ." \
  -- "${UV_API[@]}" ruff format --check .
run_step "eslint (web)" "pnpm --filter web lint" \
  -- pnpm --filter web lint

# --- Typecheck -------------------------------------------------------------
step "typecheck"
run_step "mypy (api)" "uv run --directory apps/api mypy src" \
  -- "${UV_API[@]}" mypy src
run_step "tsc (web)" "pnpm --filter web typecheck" \
  -- pnpm --filter web typecheck

# --- Tests -----------------------------------------------------------------
step "test-unit"
run_step "pytest -m unit" "uv run --directory apps/api pytest -m unit" \
  -- "${UV_API[@]}" pytest tests -m unit -q

step "test-db"
skip "test-db" "DB 계층이 아직 없다" "TASK-0002"

step "test-contract"
run_step "pytest -m contract" "uv run --directory apps/api pytest -m contract" \
  -- "${UV_API[@]}" pytest tests -m contract -q

step "test-security"
# 보안 스위트는 두 사용자 fixture와 owner-scoped repository가 있어야 성립한다.
# 통과용 빈 테스트를 만들지 않고 명시적으로 스킵한다.
if [ -n "$(find apps/api/tests/security -name 'test_*.py' -print -quit 2>/dev/null)" ]; then
  run_step "pytest -m security" "uv run --directory apps/api pytest -m security" \
    -- "${UV_API[@]}" pytest tests -m security -q
else
  skip "test-security" "두 사용자 fixture와 owner-scoped repository 미구현" "TASK-0002"
fi

step "test-web"
run_step "vitest (web)" "pnpm --filter web test" \
  -- pnpm --filter web test

step "test-e2e-smoke"
skip "test-e2e-smoke" "Playwright 및 대상 화면 미구현" "TASK-0006"

# --- Migrations / Eval -----------------------------------------------------
step "check-migrations"
skip "check-migrations" "Alembic 마이그레이션이 아직 없다" "TASK-0002"

step "eval-offline"
skip "eval-offline" "평가 데이터셋이 아직 없다" "TASK-0012"

# --- Secrets ---------------------------------------------------------------
step "check-no-secrets"
run_step "check-no-secrets" "bash scripts/check-no-secrets.sh" \
  -- bash scripts/check-no-secrets.sh

# --- 요약 ------------------------------------------------------------------
summary "verify"
RC=$?
if [ $RC -eq 0 ]; then
  printf '\n%sverify 통과.%s 스킵된 게이트는 아직 검증되지 않았다는 뜻이다.\n' "$C_GREEN" "$C_RESET"
fi
exit $RC
