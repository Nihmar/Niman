# The workspace: open notes, tabs and panes

Issue #23; the plan and its four decisions are in
[the issue's comment](https://github.com/Nihmar/Niman/issues/23).

## The model

`lib/src/workspace/` holds the open notes of one library, on one device:

- `Workspace` has one or two panes (split `right` or `down`), the focused
  pane, and the divider's fraction. It is an immutable value, and every
  change returns a new one.
- `WorkspacePane` holds its tabs in order, plus the index of the tab that
  shows.
- `WorkspaceTab` holds a library-relative path, a `NoteMemento` and a
  runtime `missing` flag.
- `NoteMemento` records where the note was left: selection, scroll,
  editor, preview. It does not hold undo, which lives in a mounted editor
  only.

Its rules are tested in `test/unit/workspace_test.dart`:

| Change | Rule |
|---|---|
| open | A note already open shows where it is: one place only. A new one opens after the showing tab of the focused pane. |
| close | The showing tab gives way to its right neighbour, or its left one at the end of the row. A second pane left empty closes the split. |
| rename / move | The note, or every note under a folder, keeps its tab and memento at the new path. |
| delete | The note, or every note under a folder, closes. |
| gone from disk | The tab stays, marked `missing`. The mark is never stored. |

## Where it is kept

The workspace is stored in the app database, table `workspaces`, one row
per library path (schema v23). It is not in `.niman/settings.json`: that
file syncs, and a phone must not inherit a desktop's tabs.
`WorkspaceStore` reads and writes it, and forgetting a library drops its
row. The stored form is versioned and forgiving: an unreadable form, or
one from a newer build, reads as nothing open.

`WorkspaceController` publishes changes and writes them 500 ms after the
last one in a burst. `adopt` takes what was read back unless the user has
already changed something.

## What drives it

`ShellWorkspace` (`lib/src/ui/shell_workspace.dart`) is the shell's side:

- It loads the workspace when the library opens.
- It follows the note the shell shows. For now that note replaces the
  showing tab (`replaceActive`), one note at a time as before.
- The row actions report every rename, move and delete as `from → to` or
  as a path, so tabs under a renamed folder follow it.

Nothing is drawn from the workspace yet. The tab bar, split panes, the
phone's open-notes switcher and restoring on launch come in the next
steps of #23.
