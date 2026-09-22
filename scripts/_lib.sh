#!/usr/bin/env bash
# 매물온 스크립트 공통 라이브러리.
# 모든 스크립트가 이 파일을 source 한다. 로그 형식과 실패 처리를 한 곳에 둔다.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# --- 색상 (TTY가 아니면 비활성) --------------------------------------------
if [ -t 1 ]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''
fi

# --- 집계 ------------------------------------------------------------------
PASSED_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0
WARN_COUNT=0
FAILED_STEPS=()
SKIPPED_STEPS=()

# --- 로그 ------------------------------------------------------------------
step()  { printf '\n%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()    { PASSED_COUNT=$((PASSED_COUNT + 1)); printf '%s  OK%s   %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn()  { WARN_COUNT=$((WARN_COUNT + 1));     printf '%s  WARN%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
info()  { printf '%s       %s%s\n' "$C_DIM" "$*" "$C_RESET"; }

# fail <메시지> [재실행 명령]
# 실패는 원인과 재실행 명령을 함께 출력한다 (harness.md §10.3).
fail() {
  local msg="$1"; local rerun="${2:-}"
  FAILED_COUNT=$((FAILED_COUNT + 1))
  FAILED_STEPS+=("$msg")
  printf '%s  FAIL%s %s\n' "$C_RED" "$C_RESET" "$msg"
  if [ -n "$rerun" ]; then
    printf '%s       재실행: %s%s\n' "$C_DIM" "$rerun" "$C_RESET"
  fi
}

# skip <이름> <사유> [담당 TASK]
# 스킵은 통과가 아니다. 사유와 담당 작업을 반드시 남긴다.
skip() {
  local name="$1"; local reason="$2"; local owner="${3:-}"
  SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
  local line="$name — $reason"
  [ -n "$owner" ] && line="$line ($owner)"
  SKIPPED_STEPS+=("$line")
  printf '%s  SKIP%s %s\n' "$C_YELLOW" "$C_RESET" "$line"
}

# --- 실행 헬퍼 -------------------------------------------------------------
# run_step <이름> <재실행 명령> -- <실행할 명령...>
# 성공하면 ok, 실패하면 fail(재실행 명령 포함). 스크립트는 중단하지 않고 계속 진행해
# 한 번의 실행으로 모든 실패를 볼 수 있게 한다.
run_step() {
  local name="$1"; shift
  local rerun="$1"; shift
  [ "${1:-}" = "--" ] && shift

  local out rc
  out="$("$@" 2>&1)"; rc=$?
  if [ $rc -eq 0 ]; then
    ok "$name"
    [ -n "${VERBOSE:-}" ] && [ -n "$out" ] && printf '%s\n' "$out"
    return 0
  fi
  fail "$name" "$rerun"
  printf '%s\n' "$out" | sed 's/^/       | /'
  return 1
}

have() { command -v "$1" >/dev/null 2>&1; }

# --- 요약 ------------------------------------------------------------------
# summary <제목>  — 종료 코드는 FAILED_COUNT > 0 일 때 1
summary() {
  local title="$1"
  printf '\n%s%s%s\n' "$C_BLUE" "────────────────────────────────────────" "$C_RESET"
  printf '%s 결과: PASSED %d / FAILED %d / SKIPPED %d\n' "$title" \
    "$PASSED_COUNT" "$FAILED_COUNT" "$SKIPPED_COUNT"

  if [ ${#SKIPPED_STEPS[@]} -gt 0 ]; then
    printf '\n%s스킵된 게이트 (스킵은 통과가 아니다):%s\n' "$C_YELLOW" "$C_RESET"
    local s; for s in "${SKIPPED_STEPS[@]}"; do printf '  - %s\n' "$s"; done
  fi

  if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
    printf '\n%s실패한 단계:%s\n' "$C_RED" "$C_RESET"
    local f; for f in "${FAILED_STEPS[@]}"; do printf '  - %s\n' "$f"; done
    printf '\n실패를 테스트 삭제나 skip 추가로 통과시키지 않는다.\n'
    return 1
  fi
  return 0
}
