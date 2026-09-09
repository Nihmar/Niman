# Multiple libraries — a library is a folder that describes itself

**Status:** In progress (2026-09-08, user request; T-ML-01 and T-ML-02
done 2026-09-09) · **Depends on:** M1
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
- ~~**Per-library settings are database rows.**~~ Done in T-ML-02: the
  four of them live in `<library>/.copist/settings.json` and travel with
  the folder. The `library_settings` table is gone.
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

- [x] **T-ML-01** Settings as a file. A `LibraryConfig` value object and
  a reader/writer for `<library>/.copist/settings.json` (atomic write,
  unknown keys preserved, a missing or unreadable file giving the
  defaults). *AC: unit tests — round trip, defaults on a missing file, an
  unknown key survives a write, a malformed file does not throw.*
- [x] **T-ML-02** Move the four per-library settings onto it.
  `trash_enabled`, `history_versions`, `quick_note_path` and
  `list_note_folder` are read from and written to the file; the
  `library_settings` table becomes dead weight and goes. Existing rows
  are copied into the file the first time their library is opened, so a
  user loses nothing. *AC: a library opened with old rows and no file
  ends up with a file holding the same values; the table is gone from
  the schema afterwards.* **Clamp `historyVersions` when this lands.**
  `LibraryConfig` takes whatever number the file holds, so a hand-edited
  `-5` or `100000` passes straight through. Harmless while nothing reads
  it; this is the task that starts reading it, and the file is
  user-editable by design, so the range belongs here rather than in a
  later bug. *AC: a negative or absurd value reads back as the default.*
  Done: `LibraryConfigRepo` is what `NoteOps` reads now, schema v14 drops
  the table, and `LegacyLibrarySettings` delivers its rows (see below).
- [x] **T-ML-03** One index per library. `copist.db` becomes
  `<support>/indexes/<hash of the library path>.db`, so switching does
  not re-index and the previous library's rows are not clobbered. The
  index stays rebuildable: deleting the file rebuilds it on the next
  open. *AC: open A, open B, reopen A — A is not re-scanned and its tree
  is intact.* Done: the note index left the app database, which forced
  the split described below; the settings stayed in `copist.db` and the
  index tables were dropped from it at schema v15.
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
- [ ] **T-ML-10** Any setting can be overridden per library (user
  request, 2026-09-09). The four settings T-ML-02 moved have no app-wide
  meaning, but most of the others do and are still a single global value:
  a creative-writing library wants a toolbar without code blocks and
  headings, the programming-notes library next to it wants exactly those.
  Chosen model: **an app default with a per-library override**, the
  user/workspace split VS Code and Obsidian use. Every setting keeps its
  app-wide value; a library may override some in its own
  `settings.json`, and a key that is absent means "follow the app". A
  user with one library sees no change; a user with five does not
  reconfigure the toolbar five times.
  - *Overridable:* `editorToolbar`, `lineNumbers`, `editorAutofocus`,
    `indentWidth`, `linkType`, `treeSort`, `reminderShowTokens`,
    `previewMode`, `splitRatio`.
  - *App-wide only:* `language` (it is about the reader, not the
    library), `debugLogsEnabled` (diagnostics), and the resume pointer.
  - *Neither:* the four T-ML-02 settings stay plain per-library values —
    there is no sensible app-wide "history versions".
  - The reader is one resolver consulted by the session getters:
    library override first, app value second. `LibraryConfig` grows a
    nullable field per overridable setting; absent stays absent through a
    write, so a library that overrides nothing keeps a small file.
  - The settings screen needs a way to say "in this library" on a row,
    and to show which rows are overridden. Design it with the mockups
    the settings redesign used, not in passing.
  - *AC: a setting overridden in library A and left alone in B reads A's
    value in A and the app value in B; changing the app value moves B and
    not A; clearing an override makes A follow the app again; unit tests
    on the resolver, a widget test on the row.*
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
- **The two-step migration out of the table (T-ML-02).** The rows cannot
  be written to their libraries where they are found. The schema
  migration runs on the first query after an upgrade — app startup, which
  on Android is before the storage permission, and a library on a
  disconnected drive is not writable at all. So v14 parks the rows in
  `app_settings.legacy_library_settings` (a JSON object keyed by library
  path) and drops the table; `LegacyLibrarySettings.seed` drains one
  entry per library open, when the folder is known to be reachable. A
  library that already has a settings file keeps it and the entry is
  discarded; a failed write leaves the entry parked for the next open.
  The column empties itself and can be dropped once no install can still
  be carrying one.
- **The settings are read once per session.** `LibraryConfigRepo` caches
  the parsed config for the life of the open library: the trash toggle is
  consulted on every delete and the list folder on UI paths, and a row
  read was cheap where a parse of a file is not. The cost is that editing
  `settings.json` by hand while the app runs takes effect on the next
  open — the watcher ignores `.copist/` by design, so there is nothing to
  notice it.
- **Why not the index too.** The index is derived data: it must be
  deletable without loss, and it must not sync. A database inside the
  library folder would do both wrong. `.copist/` is for what the user
  would want to keep.
- **The path hash.** The per-library index file is named by a digest of
  the absolute path, so two libraries never share one and a moved library
  simply rebuilds. The registry keeps the mapping readable.
- **Two databases, not one (T-ML-03).** Moving the index per library
  split the old `copist.db` in two, because the settings cannot follow it:
  `app_settings` holds the resume pointer, and that has to be readable
  before the app knows which library to open. So `AppDatabase` keeps
  `copist.db` and its whole migration chain, while `IndexDatabase` holds
  the note tables in `indexes/<digest>.db` at schema 1, with no migration
  chain at all — a shape change there means deleting the file and
  rescanning, which costs a walk and loses nothing. The v15 migration
  drops the index tables from `copist.db` and vacuums.
- **The index's lifetime is the library's.** `LibraryController` opens
  the index file in `open` and closes it in the teardown, search
  connection included — otherwise a session that visited four libraries
  would hold four connections and four search worker isolates. That is
  also why the tree reads answer empty rather than throwing when nothing
  is open: the UI asks before the first library exists.
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

- ~~**`.copist/` and the file watcher.**~~ Settled: the indexer already
  skips every dot entry, on the walk and on a watch event, the same way
  it skips `.trash/` and `.history/`. Writing a setting is invisible to
  it.
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
