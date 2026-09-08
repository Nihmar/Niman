# Multiple libraries — a library is a folder that describes itself

**Status:** Planned (2026-09-08, user request) · **Depends on:** M1
(library core), M3 (index) · **Blocks:** nothing, but it changes where
settings live, so it wants to land before M5 sync writes anything of its
own · **Spec:** user request: several libraries like Obsidian's vaults —
a home screen listing them, switching from the settings, forgetting one,
and each library's settings kept as text inside the library folder.

## Purpose

Copist opens one library and remembers only that one. A user with a work
library and a personal one has to re-pick a folder every time, and the
settings they set for one silently apply to the other, because the
settings do not live with the library at all.

Make a library a self-describing folder: its settings travel with it, the
app keeps a list of the ones it knows, and switching between them is a
tap rather than a folder picker.

## Current state

- **One library at a time.** `LibraryController.open` throws if a library
  is already open; `app_settings.library_path` holds the last one, and
  `resume()` reopens it at start.
- **The index is one global file.** `copist.db` in the app support
  directory holds a `notes` table whose paths are library-relative with
  no library id, so it describes whichever library was opened last.
  Opening another one re-indexes over the top of it.
- **Per-library settings are database rows.** `library_settings` is keyed
  by absolute path and holds `trash_enabled`, `history_versions`,
  `quick_note_path` and `list_note_folder`. Copy the folder to another
  machine and those are gone.
- **App-wide settings are separate already** (`app_settings`: language,
  editor toolbar, line numbers, preview mode, indent width, …), and stay
  where they are.

## Agreed decisions

1. **The library folder owns its settings** (point 4, and the foundation
   for the rest). `<library>/.copist/settings.json`, plain JSON, written
   atomically like a note. It moves with the folder, survives a sync, and
   can be read and fixed in any editor — the same bargain the notes
   themselves get.
2. **The index does not move into the library.** It stays a rebuildable
   cache in the app's private storage, one database per known library, so
   a sync never carries a database and a corrupt index is one delete
   away. The `.copist/` folder holds settings, not caches.
3. **A registry of known libraries, app-side.** Path, display name, when
   it was last opened. It is what the home screen lists and what
   "forget" removes. Forgetting touches nothing inside the folder: the
   library is still a library, the app has simply stopped listing it.
4. **Opening is by folder, as today.** A folder becomes a library the
   first time it is opened; a folder that already has `.copist/` is
   recognized as one. No registry entry is needed to open a folder, and
   opening one adds it to the registry.
5. **One library open at a time, still.** Switching closes the current
   one and opens the next. Two libraries at once is a much larger change
   (the index, the watcher, the todo file, the reminders) and buys
   nothing the user asked for.
6. **The home screen is where the app starts** when no library resumes,
   and is reachable from the settings. It lists the known libraries with
   their paths, plus "open a folder" and "create a library".

## Tasks

- [ ] **T-ML-01** Settings as a file. A `LibraryConfig` value object and
  a reader/writer for `<library>/.copist/settings.json` (atomic write,
  unknown keys preserved, a missing or unreadable file giving the
  defaults). *AC: unit tests — round trip, defaults on a missing file, an
  unknown key survives a write, a malformed file does not throw.*
- [ ] **T-ML-02** Move the four per-library settings onto it.
  `trash_enabled`, `history_versions`, `quick_note_path` and
  `list_note_folder` are read from and written to the file; the
  `library_settings` table becomes dead weight and goes. Existing rows
  are copied into the file the first time their library is opened, so a
  user loses nothing. *AC: a library opened with old rows and no file
  ends up with a file holding the same values; the table is gone from
  the schema afterwards.*
- [ ] **T-ML-03** One index per library. `copist.db` becomes
  `<support>/indexes/<hash of the library path>.db`, so switching does
  not re-index and the previous library's rows are not clobbered. The
  index stays rebuildable: deleting the file rebuilds it on the next
  open. *AC: open A, open B, reopen A — A is not re-scanned and its tree
  is intact.*
- [ ] **T-ML-04** The known-library registry. An app-side list (path,
  name, last opened) with add/touch/forget, kept in `app_settings` or its
  own table. *AC: unit tests — opening adds or touches an entry, forget
  removes only the entry.*
- [ ] **T-ML-05** The home screen (point 1). The library list as the
  app's start screen when nothing resumes: each row is name, path and
  when it was last opened; tapping one opens it. Plus "Open a folder" and
  "Create a library", which are today's two actions. *AC: widget tests —
  the list shows known libraries, a tap opens, an unreachable path is
  shown as such rather than opening onto an empty tree.*
- [ ] **T-ML-06** Switching from the settings (point 2). A "Library" row
  in the settings opens the same list; picking another closes the current
  one and opens it, landing on its tree. *AC: widget test — switching
  swaps the tree, the todo list and the per-library settings together.*
- [ ] **T-ML-07** Forgetting a library (point 3). A per-row action on the
  list, confirmed, that removes the registry entry and its index file and
  leaves the folder untouched. *AC: widget test — the row goes, the
  folder and its `.copist/settings.json` are still there, and opening the
  folder again lists it again with its settings.*
- [ ] **T-ML-08** What travels with a switch. Reminders are reconciled
  against the newly open library's todo file, the quick note follows the
  new library's setting, and the open note is closed. *AC: widget test —
  switching from a library with a reminder to one without cancels the
  alarm rather than leaving it pointing at a task that is no longer
  there.*
- [ ] **T-ML-09** Strings + docs. Everything in `strings.dart`, in both
  languages; `README.md` gains the `.copist/` folder and the multi-library
  behaviour. *AC: analyze clean; no user-facing literal outside the
  strings file.*

## Technical design

- **`.copist/settings.json`.** One object, one key per setting, written
  with the same atomic temp-file-and-rename `core/files.dart` uses for
  notes. Unknown keys are read into a map and written back untouched, so
  a newer build's settings survive an older one opening the library.
  Example:
  ```json
  {
    "trashEnabled": true,
    "historyVersions": 10,
    "quickNotePath": "Quick note.md",
    "listNoteFolder": "Lists"
  }
  ```
- **Why not the index too.** The index is derived data: it must be
  deletable without loss, and it must not sync. A database inside the
  library folder would do both wrong. `.copist/` is for what the user
  would want to keep.
- **The path hash.** The per-library index file is named by a digest of
  the absolute path, so two libraries never share one and a moved library
  simply rebuilds. The registry keeps the mapping readable.
- **Where the current library lives.** `app_settings.library_path` stays
  as "the one to resume"; the registry is the list, not the pointer.
- **Migration order.** T-ML-01 and T-ML-02 first: they are what makes a
  library self-describing, and everything else assumes it. T-ML-03 can
  land independently and is what makes switching cheap.

## Exit criteria

- A library folder carries its own settings, readable and editable as
  text, and moving the folder moves them with it.
- The app lists the libraries it knows, opens one in a tap, and forgets
  one without touching the folder.
- Switching libraries does not re-index and does not leak the previous
  library's settings, reminders or quick note.
- Analyze clean, unit + widget tests green.

## Risks / open questions

- **`.copist/` and the file watcher.** The watcher must ignore it, or
  writing a setting looks like a library change and triggers a rescan.
- **`.copist/` and sync (M5).** It should sync — the settings are the
  user's — but the conflict rules for a JSON file are not the ones for a
  note. Settle it when M5 lands, not here.
- **A library on removable or network storage** can be listed and gone.
  The list has to say so rather than opening onto an empty tree.
- **The history folder.** `historyVersions` is a per-library setting and
  `.history/` is per-library data; both move with the folder, which is
  consistent, but M6's history work should be told about it.
- **Two libraries pointing at nested folders.** Nothing stops a user from
  opening both a folder and its parent. The registry allows it; the index
  is per path, so they are simply two libraries that overlap on disk.
