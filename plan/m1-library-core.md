# M1 — Library core

**Status:** Done · **Depends on:** M0 · **Spec:** *Requirements* (model,
trash), *Milestones → M1*

## Purpose

The Library: open or create a root folder of Markdown notes, browse the note
tree, and perform CRUD (create / rename / move / delete-into-trash) with a
file watcher keeping the UI in sync with disk. The rebuildable index exists and
is maintained.

## Current state

M0 shell with a "no library set" state. No library code, no database, no
indexer.

## Tasks

- [x] **T-M1-01** Library model + open/create flow: user picks a root folder
  path (open existing or create new empty library); root stored in
  `library_settings` (design.md). *AC: both flows work on Android and Linux;
  reopening the app resumes the library.*
- [x] **T-M1-02** Drift `notes` table + full-scan indexer: recursive scan of
  the root (excluding `.trash/`, `.history/`, dotfiles) building `notes` rows
  (directories materialized), content `sha256` with size/mtime shortcut.
  *AC: index equals the disk tree; delete the db file → rescan reproduces it.*
- [x] **T-M1-03** File watcher: recursive watch with debounce (~250 ms) feeding
  the indexer incrementally; periodic full-rescan fallback (~60 s) to catch
  missed events. *AC: external create/rename/delete/move (done from a terminal)
  appears in the tree within one debounce window.*
- [x] **T-M1-04** Tree UI: sidebar tree of folders/notes — expand/collapse,
  select, lazy rendering. *AC: lazy list; renders a 10k-note fixture without
  jank (smoke).*
- [x] **T-M1-05** CRUD: create note (→ `<name>.md`) / folder; rename; move;
  delete → move into `.trash/` (collision-safe timestamped name). Writes via
  atomic temp-file + rename. *AC: every op reflected on disk and in the index
  within one watcher cycle.*
- [x] **T-M1-06** Trash toggle (library setting, design.md): on = delete moves
  to `.trash/`; off = hard delete. Includes listing and restoring trash items.
  *AC: toggle persists across app restart; both paths tested.*
- [x] **T-M1-07** Unified index maintenance: all note ops go through one
  `Indexer` entry point (write → event → index update) so app-originated and
  disk-originated changes converge identically. *AC: same final index from
  app edit vs. external edit.*
- [x] **T-M1-08** Tests: unit (indexer scan/rebuild, note ops, trash logic) and
  widget (tree CRUD flow, trash toggle). *AC: green.*

## Technical design

See [design.md](design.md) → *Data model (drift)*, *Performance strategy*.
M1 slice:

- **Modules:** `library/` (state, watcher, ops), `db/` (database, dao,
  indexer), `ui/tree.dart`, `core/files.dart` (atomic writes, hashing),
  `core/settings/` (`library_settings`).
- **Note naming:** display name = filename; notes stored as `<name>.md` with
  sanitized names. Directories are first-class rows.
- **Hashing:** content `sha256` for note files only; the `(size, mtime)`
  shortcut reuses the stored digest, and attachments are indexed without
  ever being read. Hashing runs on a background isolate together with the
  walk (see [android.md](android.md) issue 3).
- **Watcher:** `dart:io` recursive `Directory.watch`; events debounced into
  indexer batches; the ~60 s rescan doubles as the M5 poll cadence later.
- **Open/create flow:** the native directory picker on both platforms (SAF
  on Android, xdg-desktop-portal on Linux); no manual path entry. Android
  additionally needs "All files access" — see [android.md](android.md).

## Exit criteria

- On Android + Linux: create a library, open it, create/rename/move/delete
  notes and folders, toggle trash; disk-only edits appear in the tree.
  **Not actually met:** the index never notifies the session, so a
  disk-only edit reaches the index but not the tree — T-M1.5-01.
- Index verifiably rebuildable (delete db → rescan → identical tree).
- Unit + widget tests green.

## Risks / open questions

- ~~**Android scoped storage:** how the user picks the production library
  root.~~ **Settled** in [android.md](android.md) issue 2: the native
  directory picker chooses the root and `MANAGE_EXTERNAL_STORAGE`
  ("All files access") makes it readable. A SAF tree grant does not, since
  the library is read with plain `dart:io`. Verified on device; only the
  image-insert paths remain, under T-M6-09.
- Recursive watch reliability on Android (FUSE, inotify limits) — the periodic
  rescan is the safety net. It is also the only thing that catches missed
  events until [m1_5-index-integrity.md](m1_5-index-integrity.md) makes the
  index notify the UI at all.
- Case-sensitive filename handling across platforms (index normalizes
  case-sensitivity per OS at compare time).
- `.history/` versioning lands in M5 (it is the merge base for sync); until
  then no versions are kept — acceptable since sync doesn't exist yet.
