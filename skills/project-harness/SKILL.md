---
name: project-harness
description: Set up a collaboration map for a new or existing project, reconcile conflicting project records, prepare a handoff, or trace a build, deployment, or rollback target. Use when one of these outcomes is requested, in English or Chinese. Routine development follows the project's existing map.
---

# Project Harness

Use the project's language and existing rules. Keep discussions and status queries read-only.

## Adopt a project

When the user chooses this method, inspect the project boundary, existing guidance and current work. Create or complete the root `HARNESS.md` with project-specific agreements and links to confirmed sources. Preserve the team's `AGENTS.md`, custom records, identifiers and local work. Start from what can be verified today. On later visits, follow the map. See [adoption and existing projects](references/update-existing-project.md).

## Reconcile or hand off

Check the relevant requirement, task and evidence. Maintain lasting changes in their existing source. When records disagree, identify the last verified event and what is still open. For a handoff, check the actual revision or shared location the recipient will receive, especially for uncommitted material. Provide the current task, verified result and next action. See [project records](references/project-state.md) and [handoffs](references/coordination.md).

## Trace a delivery or rollback

Use the project's Git history, build and maintenance entry points. Identify the version in ordinary language, its source and package, the environment and last verified deployment, and the effect of returning to the proposed version on newly written data. Carry out deployment or data restoration only within the corresponding authorization. See [release and rollback](references/git-release.md).
