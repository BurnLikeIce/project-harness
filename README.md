# Project Harness

Project Harness is an Agent Skill for adopting a project, reconciling conflicting records, handing work to someone else, and tracing a release or rollback. It works with English and Chinese projects. [中文说明](README.zh-CN.md)

## Use it

| Request | What you get |
| --- | --- |
| “Set this project up with my collaboration conventions.” | A root `HARNESS.md` with project-specific agreements and links to the records already in use. |
| “Continue the download fix.” | Follow the existing project map and current task. Setup runs once. |
| “Hand this over to someone using Friday's commit.” | Check whether the receiver's copy contains the current records and explain any gap. |
| “Can we go back to the version before deduplication and keep today's work?” | Locate the release and deployment evidence, then explain what the earlier program can read and process. |

Anyone with the shared project can follow `HARNESS.md` without installing this skill. When sharing the project, link the map from the README or give its path to the next maintainer. Keep changing requirements, progress and deployment results in their existing records.

## Install the current source

Download the [main branch ZIP](https://github.com/BurnLikeIce/codex-project-harness/archive/refs/heads/master.zip) or clone this repository. Copy the single `skills/project-harness` directory into your application's personal skills directory. Local Codex and Cursor support `~/.agents/skills/project-harness/SKILL.md`. If you already use a configured installation path, replace that copy and enable it when you are ready. Open a fresh session and request `project-harness` explicitly to try it. For a named older version use [GitHub Releases](https://github.com/BurnLikeIce/codex-project-harness/releases).

## Existing projects and release records

Adoption preserves team `AGENTS.md` files, custom maps, working files and earlier Protocol 2 source mappings. Existing task trackers and decision records stay in place. During adoption, choose the sources to add and fill in important project-specific agreements in plain Markdown.

The bundled PowerShell and POSIX commands support [setup and link checking](skills/project-harness/references/update-existing-project.md) and [read-only comparison with a handoff revision](skills/project-harness/references/coordination.md). Use the project's own tools for builds, deployment and rollback. See [version and recovery guidance](skills/project-harness/references/git-release.md).

## Development

Run `tests/run-tests.ps1` and `sh tests/run-tests.sh`. These suites exercise project files and Git revision comparisons. Agent discovery and live deployment are separate checks.

Community project. [MIT license](LICENSE).
