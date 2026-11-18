#!/usr/bin/env sh
set -eu
skill=$(CDPATH= cd -- "$(dirname -- "$0")/../skills/project-harness" && pwd)
parent=$(CDPATH= cd -- "${TMPDIR:-/tmp}" && pwd -P)
temp=$(mktemp -d "$parent/project-harness-test-XXXXXXXX")
cleanup() {
  actual=$(CDPATH= cd -- "$temp" && pwd -P) || return 1
  [ "$actual" = "$temp" ] && [ "$(dirname -- "$actual")" = "$parent" ] || return 1
  case "$(basename -- "$actual")" in project-harness-test-????????) rm -rf -- "$actual" ;; *) return 1 ;; esac
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM
fail() { printf '%s\n' "$*" >&2; exit 1; }
init() { sh "$skill/scripts/init-project.sh" "$@" >/dev/null; }
update() { sh "$skill/scripts/update-project.sh" "$@" >/dev/null; }
validate() { sh "$skill/scripts/validate-project.sh" "$1" >/dev/null; }
inspect() { sh "$skill/scripts/inspect-project.sh" "$@"; }
testgit() { git -C "$temp" -c user.name='Harness tests' -c user.email=tests@example.invalid "$@"; }

for lang in en zh-CN; do
  mkdir "$temp/$lang"
  init --project-path "$temp/$lang" --language "$lang"
  init --project-path "$temp/$lang" --language "$lang"
  [ "$(find "$temp/$lang" -type f | wc -l | tr -d ' ')" = 1 ] || fail 'Empty project gained extra files'
  cmp "$temp/$lang/HARNESS.md" "$skill/assets/minimal-project/$lang/HARNESS.md"
done

project="$temp/sample"
mkdir -p "$project/docs" "$temp/legacy"
printf 'Existing team rules\r\n' > "$project/AGENTS.md"
printf 'Project guide\n' > "$project/README.md"
printf 'Package ready, deployment pending.\n' > "$project/docs/work items.md"
cp "$project/AGENTS.md" "$temp/original-team"
init --project-path "$project" --source 'docs/work items.md'
cmp "$temp/original-team" "$project/AGENTS.md"
[ ! -e "$project/docs/decisions.md" ] || fail 'Empty ledger created'
cp "$project/HARNESS.md" "$temp/first"
update --project-path "$project" --source 'docs/work items.md'
cmp "$temp/first" "$project/HARNESS.md"

printf '%s\r\n' '# Map' 'Team agreements.' '- [tasks](docs/work%20items.md#today)' '- [tracker](https://example.org/items)' 'Example `[ignore](missing.txt)`.' '```md' '[ignore](missing.md)' > "$project/HARNESS.md"
printf '%s' '```' >> "$project/HARNESS.md"
cp "$project/HARNESS.md" "$temp/custom"
printf 'Acceptance\n' > "$project/docs/验收 [1] (draft)#.md"
update --project-path "$project" --source 'docs/验收 [1] (draft)#.md' --source 'docs/work items.md'
head -c "$(wc -c < "$temp/custom")" "$project/HARNESS.md" | cmp - "$temp/custom"
od -An -tu1 -v "$project/HARNESS.md" | awk '{ for (i=1; i<=NF; i++) { if ($i==10 && prev!=13) exit 1; prev=$i } }' || fail 'CRLF not preserved'
cp "$project/HARNESS.md" "$temp/first"
update --project-path "$project" --source 'docs/验收 [1] (draft)#.md'
cmp "$temp/first" "$project/HARNESS.md"
if update --project-path "$project" --source README.md --source missing.md 2>/dev/null; then fail 'Missing input accepted'; fi
cmp "$temp/first" "$project/HARNESS.md"

legacy="$temp/legacy"
printf 'Conventional alternative\n' > "$legacy/TASKS.md"
printf 'Actual source\n' > "$legacy/custom.md"
cat > "$legacy/HARNESS.md" <<'MAP'
# Old map
<!-- project-harness:managed:start -->
- Tasks: `custom.md`
- Decisions: (not mapped)
<!-- project-harness:managed:end -->
MAP
cp "$legacy/HARNESS.md" "$temp/legacy-original"
init --project-path "$legacy"
cmp "$temp/legacy-original" "$legacy/HARNESS.md"
rm "$legacy/custom.md"
if validate "$legacy" 2>/dev/null; then fail 'Broken legacy link accepted'; fi
inspect "$legacy" | grep -Fqx 'tasks=custom.md' || fail 'Broken mapping redirected'

testgit init -q
testgit add -- sample
testgit commit -qm 'Shared handoff'
shared=$(testgit rev-parse HEAD)
printf 'Deployment verified, business check pending.\n' > "$project/docs/work items.md"
printf 'Local receipt\n' > "$project/docs/local only.md"
update --project-path "$project" --source 'docs/local only.md'
check_record() { grep -Fqx -e "$(printf 'handoff_record=%s\t%s' "$1" "$2")" "$temp/inspection" || fail "$1 $2"; }
inspect "$project" --handoff-revision "$shared" > "$temp/inspection"
check_record differs-from-revision 'docs/work items.md'
check_record absent-from-revision 'docs/local only.md'
check_record matches-revision 'docs/验收 [1] (draft)#.md'
check_record verify-separately 'https://example.org/items'
if inspect "$project" --handoff-revision nonexistent-revision >/dev/null 2>&1; then fail 'Invalid ref accepted'; fi
testgit add -- sample
testgit commit -qm 'Verified deployment'
inspect "$project" --handoff-revision HEAD > "$temp/inspection"
check_record matches-revision 'docs/work items.md'
inspect "$project" --handoff-revision "$shared" > "$temp/inspection"
check_record differs-from-revision 'docs/work items.md'
printf '%s\n' '# Map' '- [missing](broken.md)' > "$project/HARNESS.md"
if validate "$project" 2>/dev/null; then fail 'Missing Markdown link accepted'; fi
printf 'PASS: POSIX adoption, file preservation, link checks and handoff revisions\n'
