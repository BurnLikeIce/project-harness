#!/usr/bin/env sh
set -eu
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
project=.
language=en
sources=''
while [ "$#" -gt 0 ]; do
  [ "$#" -ge 2 ] || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
  case "$1" in
    --project-path) project=$2 ;;
    --language) language=$2 ;;
    --source)
      case "$2" in ''|*'
'*) printf 'Expected a single project-relative source path.\n' >&2; exit 2 ;; esac
      sources="$sources$2
" ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift 2
done
case "$language" in en|zh-CN) ;; *) printf 'Language must be en or zh-CN\n' >&2; exit 2 ;; esac
cd -- "$project"
if [ -f HARNESS.md ] && [ -z "$sources" ]; then
  exec sh "$script_dir/validate-project.sh" .
fi

lock=.project-harness-write.lock
mkdir "$lock"
trap 'rm -f "$lock/HARNESS.md" "$lock/known" "$lock/links"; rmdir "$lock"' EXIT
trap 'exit 1' HUP INT TERM
if [ -e HARNESS.md ] || [ -L HARNESS.md ]; then
  sh "$script_dir/validate-project.sh" .
  LC_ALL=C awk -f "$script_dir/map-targets.awk" HARNESS.md > "$lock/known"
  destination=HARNESS.md
else
  for entry in README.md AGENTS.md; do
    if [ -f "$entry" ]; then sources="$entry
$sources"; fi
  done
  : > "$lock/known"
  destination="$lock/HARNESS.md"
  cp "$script_dir/../assets/minimal-project/$language/HARNESS.md" "$destination"
fi

: > "$lock/links"
while IFS= read -r source; do
  [ -n "$source" ] || continue
  source=$(printf '%s' "$source" | tr '\\' '/')
  while [ "${source#./}" != "$source" ]; do source=${source#./}; done
  case "$source" in /*|[A-Za-z]*:*|..|../*|*/../*|*/..) printf 'Expected a project-relative source: %s\n' "$source" >&2; exit 1 ;; esac
  [ -f "./$source" ] || { printf 'Missing source: %s\n' "$source" >&2; exit 1; }
  if ! grep -Fqx -e "$source" "$lock/known"; then
    printf '%s\n' "$source" >> "$lock/known"
    label=$(printf '%s' "$source" | sed 's/[][]/\\&/g')
    url=$(printf '%s' "$source" | sed 's/%/%25/g;s/#/%23/g;s/</%3C/g;s/>/%3E/g')
    printf '%s\n' "- [$label](<$url>)" >> "$lock/links"
  fi
done <<EOF
$sources
EOF

if [ -s "$lock/links" ]; then
  [ ! -L "$destination" ] || { printf 'Edit the shared link target explicitly before adding sources.\n' >&2; exit 1; }
  if ! LC_ALL=C tr -d '\000' < "$destination" | cmp -s - "$destination"; then
    printf 'Edit this map in its existing text encoding.\n' >&2; exit 1
  fi
  cr=$(printf '\r')
  ending=''
  if ! LC_ALL=C tr -d '\r' < "$destination" | cmp -s - "$destination"; then ending=$cr; fi
  {
    if [ -n "$(tail -c 1 "$destination")" ]; then printf '%s\n' "$ending"; fi
    printf '%s\n' "$ending"
    while IFS= read -r line; do printf '%s%s\n' "$line" "$ending"; done < "$lock/links"
  } >> "$destination"
fi
if [ "$destination" != HARNESS.md ]; then
  # Prefer atomic creation. A noclobber copy also works on volumes without hard links.
  ln "$destination" HARNESS.md 2>/dev/null || (set -C; cat "$destination" > HARNESS.md)
fi
sh "$script_dir/validate-project.sh" .
