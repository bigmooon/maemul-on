#!/usr/bin/env bash
# 커밋 메시지가 Conventional Commits 규칙을 지키는지 검사한다.
#
# 사용:
#   bash scripts/check-commit-msg.sh <메시지 파일>
#   bash scripts/check-commit-msg.sh .git/COMMIT_EDITMSG
#
# .githooks/commit-msg 가 이 스크립트를 호출한다. 훅은 선택이며,
#   git config core.hooksPath .githooks
# 로 켠다. 의존성을 추가하지 않으려고 commitlint 대신 순수 bash로 쓴다.
#
# 규칙 원문은 CONTRIBUTING.md 에 있다. 규칙을 바꾸면 두 곳을 함께 고친다.
set -u

MSG_FILE="${1:-}"
if [ -z "$MSG_FILE" ] || [ ! -f "$MSG_FILE" ]; then
  printf 'usage: bash scripts/check-commit-msg.sh <commit-message-file>\n' >&2
  exit 2
fi

TYPES='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
SCOPES='web|api|api-client|ai|evals|tests|scripts|docs|deps|release'
MAX_HEADER=72

if [ -t 2 ]; then
  C_RED=$'\033[31m'; C_YELLOW=$'\033[33m'; C_DIM=$'\033[2m'; C_RESET=$'\033[0m'
else
  C_RED=''; C_YELLOW=''; C_DIM=''; C_RESET=''
fi

errors=()
warnings=()

# 주석(#)과 diff 안내를 뺀 실제 메시지만 읽는다.
mapfile -t lines < <(grep -v '^#' "$MSG_FILE" | sed -e '/^diff --git /,$d')

# 앞쪽 빈 줄 제거
while [ "${#lines[@]}" -gt 0 ] && [ -z "${lines[0]//[[:space:]]/}" ]; do
  lines=("${lines[@]:1}")
done

header="${lines[0]:-}"

if [ -z "${header//[[:space:]]/}" ]; then
  printf '%serror%s empty commit message.\n' "$C_RED" "$C_RESET" >&2
  exit 1
fi

# merge / revert / fixup / squash 는 git 이 만든 형식이므로 통과시킨다.
case "$header" in
  Merge\ *|Revert\ *|fixup!\ *|squash!\ *|amend!\ *|Initial\ commit)
    exit 0
    ;;
esac

# --- 1. 형식 ---------------------------------------------------------------
if ! printf '%s' "$header" | grep -Eq "^($TYPES)(\([a-z0-9][a-z0-9._-]*\))?!?: .+$"; then
  errors+=("header does not match '<type>(<scope>): <subject>'")
  if printf '%s' "$header" | grep -Eq '^[A-Za-z]+\([^)]*\)?!?[[:space:]]*:'; then
    errors+=("  unknown type — allowed: ${TYPES//|/, }")
  elif ! printf '%s' "$header" | grep -Eq ':'; then
    errors+=("  missing ': ' between the type and the subject")
  fi
else
  subject="${header#*: }"
  scope="$(printf '%s' "$header" | sed -nE 's/^[a-z]+\(([^)]*)\).*/\1/p')"

  # --- 2. 길이 -------------------------------------------------------------
  if [ "${#header}" -gt "$MAX_HEADER" ]; then
    errors+=("header is ${#header} characters, limit is $MAX_HEADER")
  fi

  # --- 3. 마침표 -----------------------------------------------------------
  case "$subject" in
    *.) errors+=("subject must not end with a period") ;;
  esac

  # --- 4. 대소문자 ---------------------------------------------------------
  # "Add ..." 는 잡고 "API ..." 같은 약어는 통과시킨다.
  if printf '%s' "$subject" | grep -Eq '^[A-Z][a-z]'; then
    errors+=("subject must start lowercase and be imperative ('add', not 'Added')")
  fi

  # --- 5. 과거형/3인칭 (경고) ----------------------------------------------
  first_word="${subject%% *}"
  case "$first_word" in
    *ed|*ing) warnings+=("'$first_word' — use the imperative mood ('add', not 'added'/'adding')") ;;
  esac

  # --- 6. scope 허용 목록 (경고) -------------------------------------------
  if [ -n "$scope" ] && ! printf '%s' "$scope" | grep -Eq "^($SCOPES)$"; then
    warnings+=("unknown scope '$scope' — known scopes: ${SCOPES//|/, }")
  fi
fi

# --- 7. 본문 앞 빈 줄 -------------------------------------------------------
if [ "${#lines[@]}" -gt 1 ] && [ -n "${lines[1]//[[:space:]]/}" ]; then
  errors+=("leave one blank line between the header and the body")
fi

# --- 8. PII 방지 ------------------------------------------------------------
if printf '%s\n' "${lines[@]}" | grep -Eq '(^|[^0-9])01[016-9][-. ]?[0-9]{3,4}[-. ]?[0-9]{4}([^0-9]|$)'; then
  errors+=("the message looks like it contains a phone number — commit messages must not carry PII")
fi

# --- 결과 -------------------------------------------------------------------
for w in "${warnings[@]:-}"; do
  [ -n "$w" ] && printf '%swarning%s %s\n' "$C_YELLOW" "$C_RESET" "$w" >&2
done

if [ "${#errors[@]}" -eq 0 ]; then
  exit 0
fi

printf '\n%scommit message rejected%s\n\n' "$C_RED" "$C_RESET" >&2
printf '  %s\n\n' "$header" >&2
for e in "${errors[@]}"; do
  printf '  %s-%s %s\n' "$C_RED" "$C_RESET" "$e" >&2
done

cat >&2 <<EOF

${C_DIM}  format   <type>(<scope>): <subject>
  type     ${TYPES//|/ | }
  scope    ${SCOPES//|/ | }
  example  feat(api): add owner-scoped property repository

  Rules: CONTRIBUTING.md
  Retry:  git commit --edit --file .git/COMMIT_EDITMSG
  Skip once (not recommended): git commit --no-verify${C_RESET}
EOF

exit 1
