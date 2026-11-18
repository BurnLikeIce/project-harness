#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project_path="${1:-.}"
[ "$#" -eq 0 ] || shift
revision=''
if [ "$#" -gt 0 ]; then
  [ "$#" -eq 2 ] && [ "$1" = --handoff-revision ] && [ -n "$2" ] || {
    printf 'Usage: inspect-project.sh PROJECT [--handoff-revision REF]\n' >&2; exit 2;
  }
  revision=$2
fi
project_path=$(cd "$project_path" && pwd)

mapped_existing() {
  pattern="$1"
  [ -f "$project_path/HARNESS.md" ] || return 1
  managed=$(awk '
    /<!-- project-harness:managed:start -->/ { active = 1; next }
    /<!-- project-harness:managed:end -->/ { active = 0 }
    active { print }
  ' "$project_path/HARNESS.md")
  line=$(printf '%s\n' "$managed" | grep -E "$pattern" | head -n 1 || true)
  [ -n "$line" ] || return 1
  value=$(printf '%s\n' "$line" | sed -E 's/^[[:space:]]*-[[:space:]]*[^:：]+[:：][[:space:]]*//; s/^`//; s/`$//')
  [ "$value" != "(not mapped)" ] || return 1
  printf '%s' "$value"
}

first_existing() {
  pattern="$1"
  shift
  if mapped=$(mapped_existing "$pattern"); then
    printf '%s' "$mapped"
    return 0
  fi
  for candidate in "$@"; do
    if [ -f "$project_path/$candidate" ]; then
      printf '%s' "$candidate"
      return 0
    fi
  done
  printf '%s' ""
}

tasks=$(first_existing '^[[:space:]]*-[[:space:]]*(Tasks|任务记录)[：:]' docs/tasks.md TASKS.md docs/task.md)
decisions=$(first_existing '^[[:space:]]*-[[:space:]]*(Decisions|决策记录)[：:]' docs/decisions.md DECISIONS.md docs/decision-log.md)
product=$(first_existing '^[[:space:]]*-[[:space:]]*(Product|产品事实)[：:]' docs/product.md docs/prd.md PRD.md docs/product-spec.md)
architecture=$(first_existing '^[[:space:]]*-[[:space:]]*(Architecture|架构事实)[：:]' docs/architecture.md ARCHITECTURE.md docs/design.md)
api=$(first_existing '^[[:space:]]*-[[:space:]]*(API|API 契约)[：:]' docs/api-contract.md docs/api.md API.md openapi.yaml openapi.yml)
acceptance=$(first_existing '^[[:space:]]*-[[:space:]]*(Acceptance|验收依据)[：:]' docs/acceptance.md docs/testing.md TESTING.md)
handoff=$(first_existing '^[[:space:]]*-[[:space:]]*(Handoff|主控交接)[：:]' docs/handovers/current-control-state.md docs/handoff.md HANDOFF.md)

protocol="unversioned"
if [ -f "$project_path/HARNESS.md" ] && grep -Eq 'Protocol:[[:space:]]*2|协议版本[：:][[:space:]]*2' "$project_path/HARNESS.md"; then
  protocol="2"
elif [ -f "$project_path/docs/sop.md" ] || [ -f "$project_path/prompts/master.md" ]; then
  protocol="1-compatible"
fi

git_repository="false"
git_branch=""
git_dirty=""
git_remote=""
if command -v git >/dev/null 2>&1 && git -C "$project_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_repository="true"
  git_branch=$(git -C "$project_path" branch --show-current 2>/dev/null || true)
  git_dirty=$(git --no-optional-locks -C "$project_path" status --porcelain 2>/dev/null || true)
  git_remote=$(git -C "$project_path" remote get-url origin 2>/dev/null || true)
fi

cat <<EOF
project_path=$project_path
protocol=$protocol
tasks=$tasks
decisions=$decisions
product=$product
architecture=$architecture
api=$api
acceptance=$acceptance
handoff=$handoff
git_repository=$git_repository
git_branch=$git_branch
git_dirty=$([ -n "$git_dirty" ] && printf true || printf false)
git_remote=$git_remote
EOF
if [ -n "$revision" ]; then
  cd -- "$project_path"
  [ "$git_repository" = true ] && [ -f HARNESS.md ] || {
    printf 'Choose a Git checkout containing HARNESS.md.\n' >&2; exit 1;
  }
  commit=$(git rev-parse --verify --end-of-options "$revision^{commit}") || exit 1
  prefix=$(git rev-parse --show-prefix)
  printf 'handoff_revision=%s\nhandoff_commit=%s\n' "$revision" "$commit"
  targets=$(LC_ALL=C awk -f "$script_dir/map-targets.awk" HARNESS.md)
  while IFS= read -r target; do
    [ -n "$target" ] || continue
    relative=$target
    while [ "${relative#./}" != "$relative" ]; do relative=${relative#./}; done
    case "$relative" in
      /*|\\*|[A-Za-z]*:*|..|../*|*/../*|*/..) state=verify-separately ;;
      *)
        if [ ! -e "./$relative" ]; then state=missing-locally
        elif [ ! -f "./$relative" ] || [ -L "./$relative" ]; then state=verify-separately
        elif recorded=$(git rev-parse --verify "$commit:$prefix$relative" 2>/dev/null); then
          working=$(git hash-object -- "$relative")
          if [ "$working" = "$recorded" ]; then state=matches-revision; else state=differs-from-revision; fi
        else state=absent-from-revision; fi ;;
    esac
    printf 'handoff_record=%s\t%s\n' "$state" "$target"
  done <<EOF
HARNESS.md
$targets
EOF
fi
