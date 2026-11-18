# Adopting an existing or new project

Read the team's instructions and any existing `HARNESS.md`. Determine which requirement, work item, build, test, or delivery guide the project actually uses. Inspection can suggest conventional filenames. Confirm their purpose before adding them. External trackers and custom document names are valid sources.

Use the root `HARNESS.md` for supplementary local agreements and links. An empty project can start with this file alone. Add a task or decision record when there is a real item and no suitable place for it. For an existing project, keep its records and history in place. When others need the map, link it from an entry they already use or include its shared path in the handoff.

## Existing command entry points

| Operation | PowerShell | POSIX shell |
| --- | --- | --- |
| Inspect | `inspect-project.ps1 -ProjectPath PATH` | `inspect-project.sh PATH` |
| Adopt or add confirmed sources | `init-project.ps1 -ProjectPath PATH -Language zh-CN -Source 'work/items.md','docs/setup.md'` | `init-project.sh --project-path PATH --language zh-CN --source work/items.md --source docs/setup.md` |
| Refresh | `update-project.ps1` with the same arguments | `update-project.sh` with the same arguments |
| Check the map | `validate-project.ps1 -ProjectPath PATH` | `validate-project.sh PATH` |

The writer creates a plain map, links existing root README and team instructions on first adoption, and appends only explicitly supplied local files. An existing map is checked in place. Edit the ordinary Markdown directly for a changed agreement, renamed link or external source. Use standard inline Markdown links for sources the scripts should check. For example, `[work items](<docs/work items.md>)`. Validation checks local paths. Verify external access with the recipient.

Legacy map entries remain readable, including custom paths. An unmapped category can stay empty. If an old installation added a rule requiring its personal skill, the project owner can replace that block with a pointer to `HARNESS.md` when migrating. Scripts leave team instructions and project history intact.

Reloading the installed skill only refreshes the current instructions. Installation, adopting a project, editing project sources and publishing each follow the requested scope.
