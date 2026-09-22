#!/usr/bin/env bash
# make check-no-secrets — 커밋되면 안 되는 값이 작업 트리에 있는지 검사한다.
#
# 이 스크립트는 최소 방어선이다. 통과했다고 비밀이 없다고 단정하지 않는다.
# 실제 비밀 스캐너를 pre-commit/CI에 추가하는 것은 별도 작업이다.
#
# 검사 대상에서 제외:
#   - .env.example (이름과 설명만 있어야 한다)
#   - 문서의 예시 (allowlist 주석이 같은 줄에 있을 때)
#   - node_modules, .venv, dist, .git

source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

cd "$REPO_ROOT" || exit 1

EXCLUDES=(
  --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv
  --exclude-dir=dist --exclude-dir=build --exclude-dir=.pytest_cache
  --exclude-dir=.mypy_cache --exclude-dir=.ruff_cache --exclude-dir=coverage
)

# 잠금 파일은 사람이 쓰지 않는다. 안에 든 hash와 URL이 숫자 패턴을 오탐시킨다.
# 잠금 파일에 비밀이 들어가는 경로는 없다.
LOCKFILE_EXCLUDES=(
  --exclude=uv.lock --exclude=pnpm-lock.yaml
  --exclude=package-lock.json --exclude=yarn.lock
)

FOUND=0

# scan <이름> <정규식> <설명>
scan() {
  local name="$1" pattern="$2" desc="$3"
  local hits
  # allowlist: 같은 줄에 'secret-scan-allow' 주석이 있으면 예시로 간주한다.
  hits="$(grep -rInE "$pattern" . "${EXCLUDES[@]}" "${LOCKFILE_EXCLUDES[@]}" 2>/dev/null \
          | grep -v 'secret-scan-allow' \
          | grep -v '^\./\.env\.example:' \
          | grep -v '^\./scripts/check-no-secrets\.sh:')"
  if [ -n "$hits" ]; then
    FOUND=1
    fail "$name — $desc"
    printf '%s\n' "$hits" | sed 's/^/       | /'
  else
    ok "$name"
  fi
}

step "비밀·PII 스캔"

# .env 가 git에 추적되고 있는지
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  FOUND=1
  fail ".env 가 git에 추적되고 있다" "git rm --cached .env"
else
  ok ".env 추적 안 됨"
fi

scan "client secret 실값" \
  '(CLIENT_SECRET|client_secret)[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9_-]{8,}' \
  "설정 파일이나 코드에 client secret 값이 있다"

scan "OAuth token 리터럴" \
  '(access_token|refresh_token)[[:space:]]*[=:][[:space:]]*["'"'"'][A-Za-z0-9._-]{16,}["'"'"']' \
  "토큰 값이 하드코딩되어 있다"

scan "authorization code 리터럴" \
  '(authorization_code|auth_code)[[:space:]]*[=:][[:space:]]*["'"'"'][A-Za-z0-9._-]{16,}["'"'"']' \
  "authorization code가 하드코딩되어 있다"

# 앞뒤가 영숫자가 아닐 때만 잡는다. 잠금 파일의 hash·URL에 섞인 숫자열을
# 연락처로 오인하지 않기 위함이다.
scan "한국 휴대폰 번호" \
  '(^|[^0-9A-Za-z])01[016789][-. ]?[0-9]{3,4}[-. ]?[0-9]{4}([^0-9A-Za-z]|$)' \
  "실제 연락처로 보이는 번호가 있다. fixture라면 마스킹하고 secret-scan-allow 주석을 단다"

scan "개인 키" \
  '-----BEGIN [A-Z ]*PRIVATE KEY-----' \
  "개인 키 파일이 포함되어 있다"

summary "check-no-secrets"
RC=$?
if [ $FOUND -ne 0 ]; then
  printf '\n발견된 값을 제거하고 이미 커밋했다면 키를 폐기·재발급하라.\n'
  printf '문서의 예시라면 같은 줄에 secret-scan-allow 주석을 단다.\n'
fi
exit $RC
