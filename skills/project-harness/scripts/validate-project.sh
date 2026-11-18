#!/usr/bin/env sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd -- "${1:-.}"
[ -f HARNESS.md ] || { printf 'Missing project map: %s/HARNESS.md\n' "$PWD" >&2; exit 1; }
grep -q '[^[:space:]]' HARNESS.md || { printf 'HARNESS.md is empty.\n' >&2; exit 1; }
if grep -Eq '^(<<<<<<< |>>>>>>> )' HARNESS.md; then
  printf 'Resolve the merge conflict in HARNESS.md.\n' >&2
  exit 1
fi
targets=$(LC_ALL=C awk -f "$script_dir/map-targets.awk" HARNESS.md)
while IFS= read -r target; do
  case "$target" in
    '') continue ;;
    /*|\\*|[a-zA-Z]*:*) printf 'Verify access separately: %s\n' "$target" ;;
    *) [ -e "./$target" ] || { printf 'Missing linked source: %s\n' "$target" >&2; exit 1; } ;;
  esac
done <<EOF
$targets
EOF
printf 'VALID: Project map and declared local paths at %s\n' "$PWD"
