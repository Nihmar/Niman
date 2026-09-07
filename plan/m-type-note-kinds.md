# Type-kinded notes — per-note custom GUIs via `type:` frontmatter

**Status:** Planned (draft — design agreed 2026-09-07; no milestone slot
assigned yet; candidate: its own slice after M4 verification, or M6) ·
**Depends on:** M4 (frontmatter parser/index) for reading `type`; M3 shell,
watcher, indexer, strings. The first renderer (`list`) needs M2's
editor/preview surface (the note screen) · **Spec:** user request +
the checklist mockup in `screenshots/Screenshot_2026-09-07-13-21-24-18_…jpg`
(Google Keep-style toggleable list).

## Purpose

Reserve a `type` key in YAML frontmatter that customizes the GUI of a note.
For `type: list`, a note renders as a **toggleable checklist** (tap a checkbox,
nothing to type — a shopping list, a packing list, a keep-style list), instead
of the standard editor/preview. The whole thing is a clean, extensible
"type → renderer" mechanism: `list` ships first, other kinds can be added
later. On disk the note stays a real, human-readable `.md` file; the list is
ordinary markdown so it opens in any editor and never loses data.

**The list GUI is a completely custom Flutter widget surface** — not the
markdown preview. It is its own `ListView` with its own checkbox rows, its
own indentation and styling, native Flutter look-and-feel (like the
Google Keep checklist screenshot). The markdown *file* is the storage
format only; the list body is never pushed through `flutter_markdown_plus`
or a markdown AST. This keeps the renderer free to look and behave how we
want, independent of the preview's styling and constraints.

## Agreed decisions (the user's answers)

1. **On-disk representation — option A.** Each item is a standard markdown
   task line: `- [ ] Buy milk` / `- [x] Buy milk`. Toggling flips `[ ]`↔`[x]`
   in place. Fully interoperable, readable by any tool, honors the
   "disk is source of truth" rule, and reuses the existing task-list
   highlighting/parsing.
2. **Raw editing still available.** A pencil icon in the top-right app bar
   (over the list GUI) switches to the app's normal markdown editor/preview
   for that note. The list GUI is a *front-end* over the text, not the only
   way in.
3. **Nested items supported from the start.** Indented task lines
   (`- [ ]` → `  - [ ]` → …) render as nested/indented checkboxes, like the
   screenshot's sub-item. Not flat-only.
4. **Extensible by design.** The mechanism is a small "type → renderer
   registry". Only `list` ships in v1, but adding another `type` later is a
   new renderer plus a registry entry, not a re-architecture.
5. **Done-state is disk-only.** The boolean lives solely in `[ ]`/`[x]` on
   disk; no extra drift column, no index field. The indexer ignores it (the
   file is indexed as a normal note).
6. **Separate from the Todo tab.** The Todo tab (`todo-tab.md`) is a GUI over
   `todo.txt`/`done.txt` at the library root — actual *tasks* with due dates,
   priorities, reminders. A `type: list` note is a normal note in the tree —
   a *checklist* (shopping, packing). Different files, different model, no
   interaction.
7. **Placement setting.** A **library-scoped** setting, default folder
   `Lists/`, naming the folder where "new list note" files are created.
8. **Pencil opens the editor directly.** The top-right pencil on a
   type-kinded note switches straight to the app's normal source editor —
   not the preview. Editing there is authoritative; returning to the list
   re-parses.
9. **Inline "add item" input.** A `type: list` note has an inline add row
   (an input at the bottom of the list, matched to the screenshot) to add a
   new item without entering the editor. Styled clearly **differently** from
   the editor/app text surface, so it reads as an add affordance rather than
   an editing pane. It still writes a `- [ ]` line to disk.
   **Prose is ignored** for v1: a `type: list` file's GUI shows *only* task
   lines; paragraphs, headings and blank lines between items are not
   rendered (they remain in the file, untouched, but invisible in the list
   view).

## Scope

- A `type` frontmatter key, reserved and documented; read at note-open time.
- A low-`type` → GUI dispatch that swaps the note screen's body: default
  (no `type`) keeps today's editor/preview; `type: list` shows the checklist
  renderer.
  - The renderer **registry** (map kind → renderer) so other types slot in.
- The `list` renderer: a **custom Flutter widget** — toggleable nested
  checkbox rows with their own layout/styling (no markdown preview), wired
  to disk.
- A pencil action in the top-right bars to open the real editor for a
  type-kinded note.
- Files FAB gains a "New list note" choice; it creates a note (with
  `type: list` frontmatter) in the configured folder.
- The "list notes" folder setting (library-scoped) + settings UI.
- Strings + unit/widget tests.

Non-goals (v1): other `type` kinds beyond `list`, reordering/drag of items,
a separate index for checkboxes, any sync-specific behaviour (a list note is
an ordinary note and syncs like one).

## Tasks

- [ ] **T-TK-01** Reserved `type` key + docs. Add `type` (string) to the known
  frontmatter fields in `frontmatter/fields.dart`; note it in the spec's
  frontmatter list. Value is free-form for now (`list`, later others);
  unknown values fall back to the default editor. *AC: `type: list` is read
  by the M4 frontmatter parser; an unknown `type` value does not break
  anything.*
- [ ] **T-TK-02** Type → renderer registry. A small
  `frontmatter/note_kind.dart` (or `ui/kinds/`): `abstract class NoteKindGUI`
  (renders into the note body slot + exposes the app-bar extras, e.g. the
  pencil), a `Map<String, NoteKindGUI>` keyed by `type` value, and a
  `forType(String?)` that returns the default when absent/unknown. The
  shell (or note screen) asks the registry at open. *AC: default (no type)
  is byte-identical behaviour to today; unknown type = default.*
- [ ] **T-TK-03** List renderer: parse. Parse the note body into a tree of
  items from task lines: `- [ ]` / `- [x]` (leading `[ ]`/`[x]`, any fence,
  with `+`/`*`); indentation defines nesting. **Non-task lines (paragraphs,
  headings, blank lines) are ignored — not rendered.** They stay in the file
  untouched but are invisible in the list view. *AC: unit tests over flat,
  nested, and mixed (task + prose) bodies; round-trip of an untouched line
  is byte-stable; prose-only file renders as an empty checklist.*
- [ ] **T-TK-04** List renderer: GUI. A `ListView` of checkbox rows with
  indentation, showing the item text; `[x]` shows checked. Tapping a
  checkbox flips `[ ]`↔`[x]` on disk (write the whole note back, off the UI
  isolate, atomic temp-file write via `core/files.dart`; follow the
  single-writer rule). Optimistic local update so taps feel instant. Plus an
  **inline "add item" input** at the bottom (styled distinctly from the
  editor) that writes a new `- [ ]` line. *AC: widget tests with a fake
  write; a tap flips the line and persists; the add row appends a new item.*
- [ ] **T-TK-05** Pencil → raw editor. A top-right pencil icon (only for
  type-kinded notes) opens the note straight to the app's normal source
  editor (the existing `NoteView` path, editor; not the preview). Editing in
  the editor is authoritative; returning to the list re-parses. *AC:
  from a list note, pencil opens the editor; a change made in the editor
  shows up as the new list state when returning.*
- [ ] **T-TK-06** Files FAB "New list note". The expandable FAB gains a
  mini-FAB (or a menu entry) for "New list note"; it creates a note in the
  configured folder with `type: list` in frontmatter and opens it in the
  list GUI. *AC: choosing it in a folder ≠ the configured folder still
  creates the note under the configured folder; the note opens as a list.*
- [ ] **T-TK-07** List-folder setting (library-scoped). A library setting
  (alongside trash/history/template folder, in `library_settings`) defaulting
  to `Lists/`; settings UI to change it. Creation honours it. *AC: changing
  the folder re-targets subsequent "New list note".*
- [ ] **T-TK-08** Strings + tests. All UI text in `strings.dart`; unit tests
  (list parser, registry fallback, byte-stable round-trip) and widget tests
  (toggle persistence, pencil→editor, FAB choice). *AC: green; a mixed
  library opens each note with the right GUI.*

## Technical design

- **Module layout** (per design.md). New:
  - `frontmatter/note_kind.dart` — the `type`→renderer registry + the
    `NoteKindGUI` interface (build the body widget + app-bar actions).
  - `lib/src/ui/kinds/` — one file per kind. `list_note.dart`: parse
    (`list_parser.dart`, pure) + a **hand-built Flutter widget** (checkbox
    rows, indentation, styling — no markdown renderer) + the write
    serialization. Other kinds land here later.
  - The shell/note screen dispatches the body through the registry.
- **No markdown preview for the list body.** An item row is a native Flutter
  `Checkbox`/custom toggle + `Text`, laid out with indentation — parsed
  directly from the task lines, never from a markdown AST. Styling is its own
  (as the screenshot shows), independent of the preview theme.
- **Disk representation.** `type: list` note body example:
  ```markdown
  ---
  type: list
  title: Spesa
  ---
  - [ ] Latte
  - [ ] Pane
    - [ ] Integrale
  - [x] Uova
  ```
  The `type` value (and any frontmatter) is read by the M4 frontmatter parser;
  M4 already indexes arbitrary keys, so `type` rides the existing machinery.
- **Checklist ↔ text.** The boolean and the nesting are entirely in the
  `[ ]`/`[x]` and the indentation — nothing is stored elsewhere. Toggling a
  checkbox rewrites only the leading `[ ]`→`[x]` (or back) on that line,
  leaving item text untouched; the whole note is written back atomically.
  The list GUI never reorders or reformats an untouched line (byte-stable,
  matching the todo-tab philosophy).
- **Where dispatch happens.** The note screen (`NoteView` / the shell around
  `lib/src/ui/shell.dart:606`) currently shows editor|preview. A type-kinded
  note swaps the body through the registry and adds the pencil action to the
  app bar; the raw editor is the existing path, reached via the pencil. The
  title/frontmatter is read when the note opens (already available from M4).
- **Reads/writes off the UI isolate.** The list parser reads the file body
  off the UI isolate and the toggle writes off it (Android FUSE rule in
  `plan/android.md`), same as the editor save path.
- **Data.** No new drift tables. The note is indexed as an ordinary note;
  `type` rides `frontmatter_fields`. The list state needs no index.
- **Creation.** "New list note" in the FAB writes a note with
  `---\ntype: list\n---` (plus title) and the desired starting items
  (empty list or a plain-empty note). The configured folder is created if
  missing.

## Exit criteria

- A note with `type: list` opens as a toggleable, nestable checkbox list;
  tapping persists `[ ]`↔`[x]` and survives reopen.
- The pencil opens the normal source editor directly; edits there are
  reflected back in the list.
- An inline "add item" input appends new items without entering the editor;
  prose between items is not rendered.
- Notes without `type` (or with an unknown `type`) look exactly as today.
- The Files FAB offers "New list note" and creates it in the configured
  folder (default `Lists/`), where it opens as a list.
- Adding a new `type` is a single registry entry + a new kind module.
- Unit + widget tests green.

## Risks / open questions

- **Empty/blank list.** A fresh `type: list` note has zero `- [ ]` lines
  (and prose is ignored), so it renders as an empty checklist with the
  inline add row as the only affordance. Confirm the empty state is clear
  enough on its own.
- **Prose is hidden, not deleted.** Ignoring prose means a `type: list` file
  with a heading or notes between items shows a list that omits them. The text
  is safe on disk but the user may be confused why a line isn't visible in the
  list view. Document this; the pencil lets them see it.
- **Interaction with M4's `pinned`/`title`/`aliases`.** `type` is independent;
  the list note still honours `title` (display) and can be pinned. Confirm no
  conflict.
- **Android IME / keyboard.** The list GUI is tap-first, but the inline
  "add item" input does open the keyboard; Android IME behaviour
  ([android.md](android.md)) applies there. Toggling stays tap-only.
- **Alignment with another type's GUI.** If a `type: list` file already has
  an "add row" and later a second type wants one, keep the add-row pattern
  inside each renderer, not the registry. Confirm no cross-kind leakage.
- **Milestone slot.** Depends on M4 (frontmatter) to read `type`. Candidate:
  its own focused slice after M4 runs, or folded into M6 (polish). Not on
  the M0→M7 critical path.
