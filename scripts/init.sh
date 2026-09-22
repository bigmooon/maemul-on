#!/usr/bin/env bash
# make init — Python 런타임, 의존성, .env를 준비한다. 여러 번 실행해도 안전하다.

source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "$REPO_ROOT" || exit 1

step "필수 도구 확인"
for c in node pnpm uv; do
  if have "$c"; then
    ok "$c"
  else
    fail "$c 없음" "bash scripts/doctor.sh"
  fi
done
if [ $FAILED_COUNT -gt 0 ]; then
  printf '\n필수 도구가 없다. 먼저 실행하라: make doctor\n'
  exit 1
fi

step "Python 3.12 (uv 관리)"
if uv python find 3.12 >/dev/null 2>&1; then
  ok "이미 설치됨 — $(uv python find 3.12)"
else
  run_step "uv python install 3.12" "uv python install 3.12" -- uv python install 3.12
fi

step "API 의존성 (uv sync)"
run_step "uv sync --project apps/api" "uv sync --project apps/api" \
  -- uv sync --project apps/api

step "Web 의존성 (pnpm install)"
run_step "pnpm install" "pnpm install" -- pnpm install

step ".env"
# 기존 .env를 자동으로 덮어쓰지 않는다. 사람이 채운 값을 잃지 않기 위함이다.
if [ -f .env ]; then
  ok ".env 이미 있음 (덮어쓰지 않음)"
elif [ -f .env.example ]; then
  cp .env.example .env
  ok ".env.example → .env 복사"
  info "실제 값은 직접 채운다. .env는 커밋하지 않는다."
else
  warn ".env.example 없음"
fi

summary "init"
RC=$?
if [ $RC -eq 0 ]; then
  printf '\n다음: make smoke  (빠른 생존 확인) → make verify  (품질 게이트)\n'
fi
exit $RC
