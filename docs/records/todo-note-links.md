# Tasks and notes, linked both ways (#1152)

How a task in `todo.txt` points at a note, and how a note shows, holds and
makes its tasks. Written before the code (2026-10-22), as the plan the work
follows; the screens are in
[docs/design/todo-note-links](../design/todo-note-links/README.md).

The constraint is the one `todo.txt` and `calendar.txt` already keep: **the
file is the user's, and other todo.txt tools read and write it.** A link is
words on the task's line, and nothing about it is stored anywhere else.

## Where things stood

- The index holds notes only: `indexer.dart` skips `todo.txt` on purpose,
  and every link service — the rename rewrite (`links/rewrite.dart`), *Links
  to this note*, the dead-link list — reads the index's `note_links` edges,
  whose source is a note id. A task's link was nothing to any of them.
- The todo parser keeps unknown text verbatim and reads `+project`,
  `@context`, `#tag` and `key:value` only where a word opens (line start or
  after whitespace), so `[[Note#Heading]]` survives — but `[[Ideas +work]]`
  read `+work` as a project.
- `TodoController` already holds both files, `todo.txt` and `done.txt`, in
  one parsed snapshot, refreshed on the session's revision stream.
- No record had settled "todo.txt is the source of truth" in words; the
  Tasks guide and the kanban record (decision 4) assumed it. It is written
  down here.

## Decisions (2026-10-22)

1. **A task links a note with a wikilink in its text** (option 1 of the
   issue): `(A) Call the plumber [[House/Repairs]] due:2026-11-02`. A
   Markdown link (`[plumber](House/Repairs.md)`) is read too; Niman writes
   wikilinks. Any number per task; a heading or block anchor
   (`[[Repairs#Boiler]]`, `[[Repairs#^b7]]`) counts and is carried through
   a rename, as in a note. Other tools see the words `[[House/Repairs]]`.
2. **Inside `[[…]]` there are no todo tokens.** The parser and the editor's
   colouring treat a wikilink as one run: `+`, `@`, `#` and `key:` inside it
   are link text. This is the one change to how a line is read.
3. **Resolution is the notes' own**, from the library root (where
   `todo.txt` lives), by the same resolver: a bare name anywhere, a path by
   its tail, case-insensitively.
4. **The links are derived in memory, not stored in the index.** The
   controller's snapshot is resolved into a map *note → its tasks* (open
   and done), rebuilt when the snapshot changes and when the index reports
   changed notes. The tasks are thousands, not millions: one batched stem
   lookup per rebuild, measured by a perf test (10 000 tasks, 2 000 links).
   No schema change and no second source: the map is rebuilt from the two
   files at any time.
5. **Rename and move rewrite task lines.** The relocation flow, which asks
   `MovedLinks` before a move which links resolved to a moved file, asks
   the task map the same question; `rewrite.dart` rewrites the line's text
   (it is text in, text out), and each changed file is written once through
   the todo store, inside its write chain. A bare-name link is left alone by
   a move, as in a note.
6. **A dead link in a task is drawn muted**, as one in a note is (the
   issue spoke of a dead-link *list*; there is none — `DeadLinkChecker`
   only tells the views which links to draw muted). The Todo tab asks the
   same checker, one batch per snapshot (19).
7. **Sync needs nothing**: the link is text on a line, and the task files
   already merge line-wise.

### A — a note shows its tasks

8. **Tasks for this note** sits where *Links to this note* sits, in its three
   places, and reads the same map:
   - under the note, a header with the count that opens onto the list (it
     is always there while a library is open and the Todo feature is on);
   - in the side panel, a **Tasks** pane beside Outline, Tags, Links and
     History (beside the note from 1000 px up, over it below);
   - on a phone, a sheet from the note's ⋮ menu.
9. **A row is a task as the Todo tab draws it** — checkbox, priority,
   description, due badge — with the link to *this* note left out (it is
   the list's own subject; a heading it names stays, as a `§ Boiler` chip)
   and any other link shown as a chip. Above it in each place stays
   *Links to this note*, where it was. Open tasks
   first, by due date; **Done (n)** folded underneath, from `done.txt`.
   Ticking a box ticks the task; tapping the text opens the task dialog.
10. **Add task** at the head of the list opens the task dialog with
    `[[Note]]` already in the description — the shortest form that resolves
    to this note, as the link suggester writes it. The note's ⋮ menu has
    **New task** with the same effect; with text selected, the selection is
    the description.

### B — a note holds a query of tasks

11. **A fenced block named `todo`** draws a live list of tasks:

    ````
    ```todo
    link: any
    due: <=+7d
    project: house
    ```
    ````

    Not `tasks`: Obsidian's Tasks plugin owns that name with its own query
    language, and a note opened there would be misread. On disk the block
    is the question, never the answers; another Markdown tool shows a code
    block.
12. **One `key: value` per line, all of them must match.** `link` (`this`,
    the default; `[[Note]]`; `any`), `project`, `context`, `tag` (each may
    repeat), `due` (`today`, `overdue`, `<=+Nd`, a date, a `..` range),
    `priority` (`A`, `A-B`), `done` (`no`, the default; `yes`; `all`), `sort`
    (`due`, the default; `priority`; `file`). **An empty block is the tasks
    that link this note**, and `link` stays `this` whatever else the block
    filters by — a dashboard over the whole list says `link: any`, so a
    block never widens by itself. An unknown key or a value that does not parse is
    a row in the block saying so, never ignored silently, and a block with
    an error lists no tasks until it is fixed — a half-read filter would
    show a list that looks right. `due: <=+7d` includes the overdue. The filter runs on
    `todo_filter.dart`.
13. **Drawn in read and in `live`**, like a Mermaid fence: with the caret
    outside the block it is the list, with the caret inside it is the source,
    coloured. The list's head says what it shows (*Tasks · linked here · due
    within 7 days*) and the count; its foot has **Add task**, the dialog
    pre-filled from the filters (the link for `link: this`, the project,
    context and tag). A row ticks and opens as in A.
14. **Exported (HTML, PDF, EPUB) as the list it is at export time**, ☐ and
    ☑ as text; the block's source is not printed.

### C — a note makes tasks

15. **Move to tasks** turns a note's checkbox item into a task and takes it
    out of the note. It is on a line whose item is `- [ ]` or `- [x]`: in
    the editor's context menu and the command palette on a desktop, in the
    long-press menu of the line and the editor toolbar's overflow on a
    phone.
16. **One item opens the task dialog**, the description the item's text as
    written plus ` [[Note]]`, so it can be given a date or a priority before
    it is saved. **Several selected items are moved at once** without a
    dialog, each with the link. A ticked item goes to `done.txt` with
    today's completion date.
17. **The move writes `todo.txt` first, then the note**: a crash between
    the two leaves the task in both places, never in neither. A snackbar —
    *Moved 3 to tasks · Undo* — undoes both.
18. **An item with sub-items is not moved** in this round: the command is
    disabled on it, with the reason as its tooltip.

**As built (2026-10-23).** Where the plan left room: a checkbox item is read off
the editor's block scan (`editor/task_items.dart`), so code, front matter and
quotes never count, and an item "has sub-items" when a deeper item or a held
paragraph or code block follows it. The note's lines go in one edit of the open
editor's buffer, and Undo puts them back by looking for the lines around where
they stood (`editor/task_items_edit.dart`), not by replaying the editor's
history, since the note may have changed since. Undo restores the note first
and removes the tasks second, for the same reason as the move's order. The
entry is in the Tools sheet as well as the menus, which is the phone toolbar's
overflow; with no checkbox item at the caret the context menu leaves it out,
and the Tools sheet and the palette say what is needed.

### What the Todo tab gains

19. A link in a task is drawn as a chip with the note's name; a tap opens
    the note (on a phone directly, as a wikilink does; a long press
    previews it); a heading link reads `Repairs › Boiler`. A link to no
    note is a dashed, dimmed chip, and a tap offers to create the note, as
    a dead wikilink does.
20. The task dialog completes `[[` with the note suggester the editor uses.

### Not now

- An id on every task, so a note could link one task
  (`[[todo.txt#^t7k2]]`): lines have no identity — they are sorted,
  archived, edited by other tools — and A and B cover what it would serve.
- Mirroring a note's checkboxes into `todo.txt`: two copies of a task to
  keep equal on every edit and every sync, which is option 3 of the issue
  coming back. **Option 3 — the task living in the note, `todo.txt` an
  aggregate — is rejected**: `todo.txt` stays the source of truth.
- Kanban cards as tasks (kanban.md, decision 4), and a block over
  `calendar.txt`'s events.

## Phases

0. **This record and the mockups.**
1. **Links in tasks.** The parser rule (2) with round-trip tests; the
   in-memory map (4) and its perf test; the Todo tab's chips and the `[[`
   completion (19, 20); the rename rewrite (5); the muted dead links (6);
   the user guide (`tasks.md`, `links.md`).
2. **A.** *Tasks for this note* in its three places, Add task and New task.
3. **C.** Move to tasks, its undo, its tests on a two-file write.
4. **B.** The `todo` block: the query parser with its error rows, the
   read and `live` drawing, export.

One issue per phase; each lands on Android, Linux, Windows, macOS and iOS
together.

## Risks

- **The map rebuild on a big `todo.txt`**: resolving every link on every
  change. Batched, measured, and only the links whose stems changed are
  resolved again when the index changes.
- **Two files in one gesture** (C): the order (17) and the undo are tested
  with a failure injected between the writes.
- **A rename racing another tool's edit of `todo.txt`**: the rewrite reads
  the file again inside the store's write chain, as every task edit does.
- **37 locale files** for every new string.
