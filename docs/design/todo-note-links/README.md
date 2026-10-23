# Tasks and notes — the screens

The mockups #1152 is discussed against (2026-10-22), before any code: seven
desktop screens, six phone screens and two tablet screens, in `html/`.
They are drawn to look like Niman, in the Night palette of
`lib/src/ui/theme/niman.dart`; where a mockup and the app disagree, the app
is what ships. The plan they belong to is the record
[todo-note-links.md](../../records/todo-note-links.md); the numbers below
are its decisions.

| Screen | Desktop | Phone | Tablet |
|---|---|---|---|
| **A — Tasks for this note** in the side panel, beside Outline, Tags, Links and History; the header under the note, below *Links to this note*; a heading the link names kept as `§ Boiler`; Done folded (8–10) | [Desktop-1-TasksPane](html/Desktop-1-TasksPane.html) | [Phone-2-TasksSheet](html/Phone-2-TasksSheet.html) | [Tablet-1-Landscape](html/Tablet-1-Landscape.html), [Tablet-2-Portrait](html/Tablet-2-Portrait.html) (panel over the note below 1000 px) |
| The note's ⋮ menu: **Tasks for this note**, **New task** (8, 10) | — | [Phone-1-NoteMenu](html/Phone-1-NoteMenu.html) | — |
| **B — a `todo` block** drawn as a list, and one with an error row that lists nothing (11–13) | [Desktop-2-TodoBlock](html/Desktop-2-TodoBlock.html) | [Phone-3-TodoBlock](html/Phone-3-TodoBlock.html) | — |
| The same block with the caret inside: its source, coloured (13) | [Desktop-3-TodoBlockSource](html/Desktop-3-TodoBlockSource.html) | — | — |
| **C — Move to tasks** from a checkbox line, and the task dialog it opens, pre-filled with the link and the exact line (15, 16) | [Desktop-4-MoveToTasks](html/Desktop-4-MoveToTasks.html) | [Phone-4-LongPressMove](html/Phone-4-LongPressMove.html), [Phone-5-MoveDialog](html/Phone-5-MoveDialog.html) | — |
| Three items moved at once: gone from the note, *Moved 3 to tasks · Undo* (16, 17) | [Desktop-5-MovedSnackbar](html/Desktop-5-MovedSnackbar.html) | — | — |
| **The Todo tab** with link chips, a heading link `Repairs › Boiler`, a dead link dashed and dimmed (19) | [Desktop-6-TodoTab](html/Desktop-6-TodoTab.html) | [Phone-6-TodoTab](html/Phone-6-TodoTab.html) | — |
| The task dialog completing `[[` with the note suggester (20) | [Desktop-7-DialogCompletion](html/Desktop-7-DialogCompletion.html) | — | — |

## Drawn with them, not yet confirmed

- A `todo` block with filters but no `link` still shows only the tasks that
  link the note; the dashboard in the screens says `link: any` (12).
- On a phone the line's long-press menu is a bottom sheet headed by the
  line, **Move to tasks** first; the dialog it opens is titled *Move to
  tasks* and saves with **Move**.
- The new task carries today's creation date, as every task the dialog
  adds does.
