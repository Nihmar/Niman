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

- **Loading.** The workspace loads when the library opens. The desktop
  draws its tabs from it at once; the phone's switcher lists the same
  notes.
- **Opening.** On the desktop, a click in the tree shows a note in the
  focused pane's tab (`replaceActive`). Ctrl+click, the row menu's Open
  in new tab and the tab row's + open alongside (`open`). Open to the
  side opens it in the other pane (`openBeside`). On the phone a note
  opened joins the open ones (`follow(alongside: true)`).
- **Library changes.** The row actions report every rename, move and
  delete as `from → to` or as a path, so tabs under a renamed folder
  follow it.
- **Keeping editors alive.** `mounted()` decides which editors stay
  mounted: each pane's showing tab, plus the four most recently shown,
  minus notes over 200K characters. Each mounted note has a `GlobalKey`,
  so a tab moved to the other pane takes its editor, and its undo, along.

### Mementos

`NoteView` hands in a `NoteMemento`:

- when its tab goes behind another, and when it goes away;
- one second after the last move, scroll or edit of the note on screen;
- when the app leaves the foreground.

The second trigger matters because a window closed with nothing unsaved
closes without the app being asked (the close guard only intercepts
while there are edits to protect). A memento still arrives while the
editor is being taken down, so `ShellWorkspace.remember` applies it in
a microtask. The shell flushes the workspace when the app leaves the
foreground, after those microtasks. The shell rebuilds only when
something it draws changes: tabs, panes, and each tab's editor and
preview. A caret or a scroll handed in redraws nothing.

A new `NoteView` gets its tab's memento as `initialMemento`. The
selection is put back only in the editor it was taken in, because source
and WYSIWYG offsets count different things. The scroll is put back
after the first layout.

### The acceptance criteria

`test/widget/workspace_acceptance_test.dart` checks #23's criteria on
the deck the shell runs:
- two notes edited independently keep their text and their own undo
  across a switch;
- where a note was left survives the store and a new view;
- closing the window asks once about every unsaved note and writes
  them all.

`shell_split_test` covers the split and `open_notes_switcher_test`
covers the phone.
