# Handing work to a person or another agent

Identify the next action, current owner, project-specific constraints and evidence needed to continue. Link the shared task and record any important change there. When several people write the same record, agree on ownership and use the project's existing identifier scheme.

Check the exact revision or workspace the recipient will receive. With a Git handoff, run the existing inspection entry point and supply that revision:

```powershell
./scripts/inspect-project.ps1 -ProjectPath PATH -HandoffRevision HEAD
```

```sh
sh scripts/inspect-project.sh PATH --handoff-revision HEAD
```

`HEAD` compares against the local commit. Supply the recipient's known commit or a verified remote-tracking ref when handing off a different revision. Inspect reports whether the map and its declared local records match, differ, are missing locally or are absent from that revision. Directories, external systems and machine-specific paths need a separate access check. For deeper evidence linked from a task, check the specific document as well.

For a changed record, read its actual difference and identify what the recipient would miss. Share the relevant update through the authorized project channel, or name the gap and give the necessary information in the handoff. A local comparison establishes the contents of the selected commit. Confirm recipient access separately.

When the user asks to create or fork a conversation, use the application's own mechanism and confirm that the receiver got the project location, evidence and next action.
