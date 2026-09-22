#!/usr/bin/env bash
# make doctor — 개발에 필요한 도구가 설치됐는지 점검하고, 없으면 설치 명령을 안내한다.
# 필수 도구가 없을 때만 종료 코드 1을 반환한다.

source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

MISSING_REQUIRED=0

# check_required <표시명> <명령> <버전 인자> <설치 안내>
check_required() {
  local label="$1" cmd="$2" vflag="$3" howto="$4"
  if have "$cmd"; then
    local v; v="$("$cmd" "$vflag" 2>&1 | head -1)"
    ok "$label — $v"
  else
    MISSING_REQUIRED=1
    fail "$label 없음 (필수)" "$howto"
  fi
}

check_optional() {
  local label="$1" cmd="$2" vflag="$3" howto="$4" note="$5"
  if have "$cmd"; then
    local v; v="$("$cmd" "$vflag" 2>&1 | head -1)"
    ok "$label — $v"
  else
    warn "$label 없음 (선택) — $note"
    info "설치: $howto"
  fi
}

step "필수 도구"
check_required "node"  node  --version "https://nodejs.org 또는 'winget install OpenJS.NodeJS.LTS'"
check_required "pnpm"  pnpm  --version "npm install -g pnpm"
check_required "uv"    uv    --version "winget install astral-sh.uv"
check_required "git"   git   --version "winget install Git.Git"

step "Node 버전 확인"
if have node; then
  NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "$NODE_MAJOR" -ge 20 ]; then
    ok "node major $NODE_MAJOR (>= 20)"
  else
    MISSING_REQUIRED=1
    fail "node $NODE_MAJOR 은 너무 낮다. Vite 7은 20.19+ 또는 22.12+ 가 필요하다." \
         "winget install OpenJS.NodeJS.LTS"
  fi
fi

step "Python 런타임 (uv 관리)"
# 시스템 python은 쓰지 않는다. Windows의 Microsoft Store 스텁이 python이라는 이름을
# 가로채는 경우가 있어, 런타임은 uv가 설치·관리하는 것만 신뢰한다.
if have uv; then
  if uv python find 3.12 >/dev/null 2>&1; then
    ok "uv가 관리하는 Python 3.12 사용 가능 — $(uv python find 3.12 2>/dev/null)"
  else
    warn "uv가 관리하는 Python 3.12 없음"
    info "설치: uv python install 3.12   (또는 make init)"
  fi
fi
if have python; then
  PY_SRC="$(command -v python)"
  case "$PY_SRC" in
    *WindowsApps*)
      info "참고: '$PY_SRC' 는 Microsoft Store 스텁이며 실제 Python이 아니다. 이 저장소는 uv의 Python만 사용한다." ;;
  esac
fi

step "선택 도구"
check_optional "make"   make   --version "choco install make" \
  "없어도 된다. PowerShell에서 './make.ps1 <타깃>' 을 쓴다."
check_optional "docker" docker --version "https://docs.docker.com/desktop/" \
  "현재 범위에서는 쓰지 않는다. TASK-0002의 PostgreSQL에서 필요하다."

step "저장소 상태"
[ -f "$REPO_ROOT/AGENTS.md" ]          && ok "AGENTS.md 있음"          || fail "AGENTS.md 없음" "저장소 루트에서 실행하라"
[ -f "$REPO_ROOT/feature-list.json" ]  && ok "feature-list.json 있음"  || fail "feature-list.json 없음" ""
[ -f "$REPO_ROOT/docs/product/requirements.md" ] && ok "requirements.md 있음" || fail "docs/product/requirements.md 없음" ""
if [ -f "$REPO_ROOT/.env" ]; then
  ok ".env 있음"
else
  warn ".env 없음 — 현재 골격에서는 필요하지 않다"
  info "필요해지면: cp .env.example .env"
fi

summary "doctor"
RC=$?
if [ $MISSING_REQUIRED -ne 0 ]; then
  printf '\n필수 도구가 빠져 있다. 위 설치 명령을 실행한 뒤 다시 확인하라.\n'
  exit 1
fi
exit $RC
