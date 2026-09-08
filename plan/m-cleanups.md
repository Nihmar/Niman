# Cleanups — what a read through the code turned up

**Status:** T-CL-01 and T-CL-02 done 2026-09-08; T-CL-03 (measure the
list parser) and T-CL-04 (the oversized files) open · **Depends on:** nothing ·
**Spec:** user request: look over the code and list the quick wins.

## What this is

A read of the current code looking for defects and waste that are cheap
to fix. Anything already fixed is recorded here with its commit so the
list stays honest about what remains. Nothing here is a feature.

## Fixed during the pass

- **The list drag's auto-scroll never scrolled on its own** (`b5bc7a7`).
  It moved the offset with `ScrollPosition.correctBy`, a layout-time
  correction that notifies nobody, so the list only actually moved on
  frames the drop indicator happened to rebuild. Now `jumpTo`, clamped.

## Tasks

- [x] **T-CL-01** One shell test harness. `_FakeFilePicker`, `settle()`,
  `dialogField()` and `openLibrary()` are copy-pasted across six widget
  test files (`fab`, `library_flow`, `list_note_shell`, `shell_reminders`,
  `tab_bar`, `shortcuts_shell`), with `settle()` in a seventh. Move them
  to `test/fakes/shell_harness.dart` and delete the copies. *AC: the six
  files import the harness, the suite stays green, ~150 duplicated lines
  go.*
- [x] **T-CL-02** Drop the `_nameDialog` indirection. `ui/shell.dart`
  wraps `showNameDialog` in a private function that adds nothing, called
  from four places. Call the real one. *AC: analyze clean, tests green.*
- [ ] **T-CL-03** The list parser tokenizes the whole note per edit.
  `parseListItems` runs `HighlightDocument.fromText` over the entire
  text, and the list kind re-parses on every toggle, edit and drop. Fine
  for a shopping list, wasteful on a long note that happens to hold task
  lines. Measure first on a large one; only then decide whether a
  line-scan fast path is worth its own code. *AC: a benchmark says
  whether this matters at all before anything changes.*
- [ ] **T-CL-04** The three files that broke the size rule. `AGENTS.md`
  asks for one class per file and a split past roughly 300 lines;
  `db/indexer.dart` (1464), `ui/shell.dart` (1463) and
  `ui/note_view.dart` (1427) are far past it. The shell is the worst
  offender by kind, not just size: it owns tabs, the FAB, dialogs,
  reminders, shortcuts, the quick note, the todo controller and the tree.
  This is the project's main structural debt and it is not a quick fix —
  it wants its own slice, split by responsibility with the tests moving
  with each piece. *AC: no behaviour change; each extracted piece keeps
  its tests.*

## Not worth doing (recorded so it is not re-found)

- The list drag's hit testing walks every row per pointer move
  (`_dropAt`). It is O(items) with a `localToGlobal` each, but a list
  long enough to matter would not fit a drag anyway.
- `_createNote` opens its name dialog outside `_guard`, so in theory two
  very fast taps could stack two dialogs. The FAB menu closes on the
  first tap, which makes the second one land on nothing.
