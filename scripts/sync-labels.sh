#!/usr/bin/env bash
# .github/labels.yml 의 라벨을 GitHub 저장소에 반영한다.
#
# 사용:
#   bash scripts/sync-labels.sh            # 생성·갱신
#   bash scripts/sync-labels.sh --dry-run  # 실행할 명령만 출력
#
# issue form 이 지정한 라벨이 저장소에 없으면 GitHub 은 조용히 무시한다.
# 그래서 labels.yml 과 저장소를 같은 상태로 유지하는 이 스크립트가 필요하다.
#
# 이 스크립트는 라벨을 지우지 않는다. 지우는 것은 사람이 판단한다.
# 필요하면: gh label delete <이름>
set -u

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABELS_FILE="$REPO_ROOT/.github/labels.yml"

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

if ! command -v gh >/dev/null 2>&1; then
  printf 'gh CLI 가 필요하다: https://cli.github.com\n' >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  printf 'gh 인증이 필요하다: gh auth login\n' >&2
  exit 1
fi

if [ ! -f "$LABELS_FILE" ]; then
  printf '%s 가 없다.\n' "$LABELS_FILE" >&2
  exit 1
fi

# labels.yml 을 "이름<TAB>색<TAB>설명" 으로 편다.
# 의존성을 늘리지 않으려고 파서 대신 필드 3개만 읽는다.
parse() {
  awk '
    /^- name:/ {
      if (name != "") print name "\t" color "\t" desc
      name = value($0); color = ""; desc = ""; next
    }
    /^[[:space:]]+color:/ { color = value($0); next }
    /^[[:space:]]+description:/ { desc = value($0); next }
    END { if (name != "") print name "\t" color "\t" desc }
    function value(line,   v) {
      sub(/^[^:]*:[[:space:]]*/, "", line)
      v = line
      gsub(/^"|"$/, "", v)
      return v
    }
  ' "$LABELS_FILE"
}

created=0
updated=0
failed=0

while IFS=$'\t' read -r name color desc; do
  [ -z "$name" ] && continue
  if [ "$DRY_RUN" -eq 1 ]; then
    printf 'gh label create "%s" --color %s --description "%s" --force\n' "$name" "$color" "$desc"
    continue
  fi

  if gh label list --limit 200 --json name --jq '.[].name' | grep -Fxq "$name"; then
    action="updated"
  else
    action="created"
  fi

  if gh label create "$name" --color "$color" --description "$desc" --force >/dev/null 2>&1; then
    printf '  OK   %-24s %s\n' "$action" "$name"
    [ "$action" = "created" ] && created=$((created + 1)) || updated=$((updated + 1))
  else
    printf '  FAIL %-24s %s\n' "$action" "$name" >&2
    failed=$((failed + 1))
  fi
done < <(parse)

[ "$DRY_RUN" -eq 1 ] && exit 0

printf '\nlabels: created %s / updated %s / failed %s\n' "$created" "$updated" "$failed"
[ "$failed" -eq 0 ] || exit 1
