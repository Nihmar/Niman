# M1 — Library core

**Status:** Planned · **Depends on:** M0 · **Spec:** *Requirements* (model,
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

- [ ] **T-M1-01** Library model + open/create flow: user picks a root folder
  path (open existing or create new empty library); root stored in
  `library_settings` (design.md). *AC: both flows work on Android and Linux;
  reopening the app resumes the library.*
- [ ] **T-M1-02** Drift `notes` table + full-scan indexer: recursive scan of
  the root (excluding `.trash/`, `.history/`, dotfiles) building `notes` rows
  (directories materialized), content `sha256` with size/mtime shortcut.
  *AC: index equals the disk tree; delete the db file → rescan reproduces it.*
- [ ] **T-M1-03** File watcher: recursive watch with debounce (~250 ms) feeding
  the indexer incrementally; periodic full-rescan fallback (~60 s) to catch
  missed events. *AC: external create/rename/delete/move (done from a terminal)
  appears in the tree within one debounce window.*
- [ ] **T-M1-04** Tree UI: sidebar tree of folders/notes — expand/collapse,
  select, lazy rendering. *AC: lazy list; renders a 10k-note fixture without
  jank (smoke).*
- [ ] **T-M1-05** CRUD: create note (→ `<name>.md`) / folder; rename; move;
  delete → move into `.trash/` (collision-safe timestamped name). Writes via
  atomic temp-file + rename. *AC: every op reflected on disk and in the index
  within one watcher cycle.*
- [ ] **T-M1-06** Trash toggle (library setting, design.md): on = delete moves
  to `.trash/`; off = hard delete. Includes listing and restoring trash items.
  *AC: toggle persists across app restart; both paths tested.*
- [ ] **T-M1-07** Unified index maintenance: all note ops go through one
  `Indexer` entry point (write → event → index update) so app-originated and
  disk-originated changes converge identically. *AC: same final index from
  app edit vs. external edit.*
- [ ] **T-M1-08** Tests: unit (indexer scan/rebuild, note ops, trash logic) and
  widget (tree CRUD flow, trash toggle). *AC: green in CI.*

## Technical design

See [design.md](design.md) → *Data model (drift)*, *Performance strategy*.
M1 slice:

- **Modules:** `library/` (state, watcher, ops), `db/` (database, dao,
  indexer), `ui/tree.dart`, `core/files.dart` (atomic writes, hashing),
  `core/settings/` (`library_settings`).
- **Note naming:** display name = filename; notes stored as `<name>.md` with
  sanitized names. Directories are first-class rows.
- **Hashing:** content `sha256` computed during scan/ops; `(size, mtime)`
  shortcut skips re-hashing unchanged files.
- **Watcher:** `dart:io` recursive `Directory.watch`; events debounced into
  indexer batches; the ~60 s rescan doubles as the M5 poll cadence later.
- **Open/create flow (M1 scope):** manual path entry — desktop path dialog;
  Android app-specific storage in tests/early builds.

## Exit criteria

- On Android + Linux: create a library, open it, create/rename/move/delete
  notes and folders, toggle trash; disk-only edits appear in the tree.
- Index verifiably rebuildable (delete db → rescan → identical tree).
- Unit + widget tests green in CI.

## Risks / open questions

- **Android scoped storage:** how the user picks the production library root
  (SAF tree URI vs. app-specific dir) — deferred to M6 onboarding; M1 uses
  app-specific storage + manual path entry.
- Recursive watch reliability on Android (FUSE, inotify limits) — the periodic
  rescan is the safety net.
- Case-sensitive filename handling across platforms (index normalizes
  case-sensitivity per OS at compare time).
- `.history/` versioning lands in M5 (it is the merge base for sync); until
  then no versions are kept — acceptable since sync doesn't exist yet.
