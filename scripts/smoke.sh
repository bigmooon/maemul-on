#!/usr/bin/env bash
# make smoke — 빠른 생존 확인. 외부 네트워크·DB·LLM을 호출하지 않는다.
# verify보다 빠르게 "앱이 뜨긴 하는가"만 본다.

source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "$REPO_ROOT" || exit 1

step "API 패키지 import"
run_step "import maemul_on" \
  "uv run --directory apps/api python -c 'import maemul_on'" \
  -- uv run --directory apps/api python -c "import maemul_on; print(maemul_on.__version__)"

step "API /health 응답"
run_step "GET /health == 200" \
  "uv run --directory apps/api pytest tests/contract -q" \
  -- uv run --directory apps/api python -c "
from fastapi.testclient import TestClient
from maemul_on.main import create_app

r = TestClient(create_app()).get('/health')
assert r.status_code == 200, r.status_code
body = r.json()
assert body['status'] == 'ok', body
print('health ok:', body)
"

step "Web 빌드"
run_step "pnpm --filter web build" "pnpm --filter web build" \
  -- pnpm --filter web build

summary "smoke"
