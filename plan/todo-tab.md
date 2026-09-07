# Todo tab — a frontend for todo.txt / done.txt

**Status:** Planned (draft — design agreed 2026-09-07; no milestone slot
assigned yet; candidate: its own slice after M3 verification, or M6) ·
**Depends on:** M3 (shell, watcher, indexer, strings) · **Spec:**
user request + the todo.txt syntax diagram in `reference/description.svg`
(the canonical format from the todo.txt project).

## Purpose

The bottom-nav Todo tab (a placeholder since T-UI-10) becomes a GUI over
two plain files at the library root — `todo.txt` (open tasks) and
`done.txt` (completed tasks) — written in the **todo.txt syntax** exactly
as `reference/description.svg` defines it:

```
x (A) 2016-05-20 2016-04-30 measure space for +chapelShelving @chapel due:2016-05-30
┃ ┃   └─ completion  └─ creation     └─ description + tokens (anywhere)
┃ └─ optional priority (A)
└─ optional x = completed (completion date requires a creation date)
```

The files are the source of truth — pure text, readable/editable by any
todo.txt tool (the vault philosophy: never a proprietary store). The GUI
sits on top and keeps the two files in their canonical split: completed
tasks live in `done.txt`, everything else in `todo.txt`.

## Agreed decisions (the user's answers)

1. **Files**: fixed `todo.txt` + `done.txt` at the library root, both
   created empty on the first add when missing.
2. **Filter tokens**: all three kinds are filterable — `+project`,
   `@context` and `#tag` (the note-tag style).
3. **Done/undone moves**: checking prepends `x <today> ` (keeping an
   existing creation date after it) and moves the line to the end of
   `done.txt`, removing it from `todo.txt`; unchecking (also from the
   done view) strips `x <completion date> ` and appends the line back to
   the end of `todo.txt`.
4. **Reminders**: OS-scheduled notifications that fire **even when the
   app is closed** (Android v1); stored in the line as a key/value tag,
   `rem:YYYY-MM-DDTHH:MM` (local time — grammar-conformant key/value tag;
   other todo.txt tools ignore it).
5. **Editing/delete**: tapping a task edits it (dialog over the parsed
   fields); delete removes the line outright (no trash — these are
   todo.txt lines, not notes). Priorities `(A)`–`(Z)` are shown and
   sortable; recurrence `rec:` is out of scope for v1 (parsed as an
   unknown key/value and preserved verbatim).
6. **Done visibility**: `done.txt` is visible in the tab (an Open/Done
   switch over the same list + filters), so tasks can be undone or
   removed from there.
7. **Migration**: whenever the tab loads, completed (`x`) lines found in
   `todo.txt` are moved to `done.txt` (stateless, idempotent, self-heals
   after external tools write `x` lines back into `todo.txt`). The user's
   current file already has three `x` lines; they migrate on first open.

## Tasks

- [x] **T-TD-01** Parser + line model: exactly the `description.svg`
  grammar — completion flag, priority `(A)`…`(Z)`, completion date,
  creation date (validated: completion requires creation), `due:` date,
  `rem:` timestamp, `+project`/`@context`/`#tag` tokens anywhere in the
  description, and **unknown key/value tags preserved verbatim**. Lines
  are never reformatted except for the intended edit. *AC: unit tests
  over the reference lines + edge cases (uppercase `X`, no space after
  `x`, missing creation date with completion date, `due:` at line end,
  unicode/emoji, trailing whitespace, CRLF; byte-stable round-trip of an
  untouched line.*
- [x] **T-TD-02** File store: reads off the UI isolate (Android FUSE
  rule); one writer chain; atomic rewrites of both files; append
  preserves the file's dominant line ending. Check/uncheck + edit +
  delete are single rewrite operations on both files. *AC: unit tests
  against a temp library root: move semantics (orders preserved,
  untouched lines byte-identical), concurrent ops serialized.*
- [x] **T-TD-03** Migration + refresh: on tab load, `x` lines in
  `todo.txt` move to `done.txt`; the tab reloads when the library
  revision bumps (an external tool edited a file) and after its own ops.
  *AC: migration idempotent; external `x` line is archived on next open.*
- [x] **T-TD-04** List UI + check/uncheck: rows = checkbox, description,
  priority badge, `+proj`/`@ctx`/`#tag` chips, due badge (overdue/today/
  upcoming styling), reminder icon; tapping the row edits, long-press
  shows edit/delete (the app's bottom-sheet pattern); Open/Done switch
  over the same list. *AC: widget tests with a fake store; checking moves
  the row to Done with today's date, unchecking restores it.*
- [x] **T-TD-05** Filters + sort: a horizontal chip bar — due ranges
  (Overdue / Today / Next 7 days / No date / All) and one chip per
  project/context/tag found in the visible file, with counts; chips AND
  together; sort control (due → priority → creation, each with the
  natural default: due soonest first, overdue on top; priority
  `(A)`→`(Z)`; creation newest first). *AC: combos narrow the list;
  counts refresh with the data.*
- [x] **T-TD-06** Add + edit dialogs: description field with completion
  of known `+`/`@`/`#` tokens; due-date picker (writes/updates `due:`);
  optional priority selector; optional reminder (date + time picker,
  writes `rem:`); creation date written on add. Edit keeps unknown
  key/value tags verbatim. *AC: a round trip preserves every token the
  parser keeps.*
- [ ] **T-TD-07** Reminders (Android): flutter_local_notifications +
  timezone; `POST_NOTIFICATIONS` runtime permission flow (13+); an
  inexact scheduled notification at `rem:` (no exact-alarm permission);
  cancel on complete/delete, reschedule on edit; **reconciliation at
  every app/library open**: scheduled notifications are diffed against
  the parsed `rem:` tags (survives external edits and re-installs of the
  files). Notification tap opens the app on the Todo tab. Desktop
  (Linux/Windows): no OS notifications in v1 — the due badges carry the
  state; documented limitation. *AC: on-device — reminder fires with the
  app closed; completing the task before the time cancels it.*
- [ ] **T-TD-08** Strings + tests: all UI text in `strings.dart`; widget
  tests with a fake store for dialogs, filters, Open/Done and the move
  flows; parser/store unit tests per task. *AC: green; on-device pass
  with the user's real `todo.txt`/`done.txt` in `reference/` as the
  fixture.*

## Technical design

- **Module layout** (per design.md): `todo/` — `parser.dart` (pure line
  model + text round-trip), `todo_store.dart` (reads/writes/moves over
  the two files, `Isolate.run` + a serialized chain, atomic writes via
  `core/files.dart`), `reminders.dart` (schedule/cancel/reconcile; the
  plugin seam lives behind the session so Linux/Windows tests use a
  no-op). `ui/todo_tab.dart` grows the screens; `strings.dart` the text.
- **Data**: no drift tables — the files are the state; the store caches
  parsed lines in memory only. The library's indexer already rows the
  two `.txt` files as ordinary files; they stay out of FTS (non-md).
- **Refresh**: the tab listens to the session's revision stream (the
  watcher/indexer already fires on external file changes) and reloads
  when the files' `(size, mtime)` moved; reloads are debounced and the
  read happens off the UI isolate.
- **Conflict rules**: single writer chain (the tab's ops serialize);
  last-write-wins against external editors, documented. The files can
  also be opened in the note editor today — v1 keeps that possible (they
  are plain files); a later polish can hide the two reserved names from
  the Files tree (open item).
- **Reminder identity**: a notification id derived from the task text
  (stable across line moves); `rem:` stores local wall-clock time;
  reconciliation diff on open covers the app-closed + file-edited case.
- **Grammar reference**: `reference/description.svg` (local, never
  committed) is the parser's authority; the user's real files can join it
  as fixtures (their `todo.txt` currently mixes open + `x` lines — the
  T-TD-03 migration fixture).

## Open items (defaults chosen; revisit when building)

- Tree visibility of `todo.txt`/`done.txt` (default: keep visible;
  alternative: hide like `.trash`).
- In-app reminder banner on desktop while running (cheap follow-up).
- Exact alarm permission later if reminders must be precise to the
  minute on Android 12+.
