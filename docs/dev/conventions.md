# Code conventions

- **English everywhere:** code, comments, docs, commits — regardless of
  conversation language.
- **One logical change per commit;** never bundle unrelated changes.
- **No god classes:** one class per file, split at ~300 lines or when
  responsibilities mix. Layout: `lib/src/<module>/` (see
  [architecture](architecture.md)).
- **Vocabulary:** Library, note, folder, tag, template, wikilink, trash,
  history. Not vault/canvas/daily note/backlinks.
- **Design rules:**
  - Disk is source of truth — store nothing in SQLite that cannot be
    rebuilt from files.
  - No disk I/O on the UI isolate — use `Isolate.run` (every
    `listSync`/`statSync` is a FUSE round trip on Android). Drift writes
    stay on main.
  - No O(n) full scans on hot paths; FTS5 for search; tree rows
    materialized. Target: 1M notes + novel-length files.
  - Android storage is plain `dart:io` (`MANAGE_EXTERNAL_STORAGE`, gated
    by `core/storage_access.dart`) — SAF grants are not a substitute.
  - R8 strips the reminder icon unless pinned via `tools:keep` in
    `android/app/src/main/res/raw/dev_niman_niman_keep.xml` — update the
    keep file when renaming the drawable.
- **Interface rules:**
  - Icons are outline. A filled icon says a state is on: the selected
    tab, a pinned note, the current library, the note in use as the
    quick note. Two weights in one list with no state behind them is a
    bug.
  - A control that shows in only some states keeps its place. Disable
    it instead of dropping it, or put it on the side the row grows
    from, so nothing already on screen slides under a thumb that is
    already on it.
- **Portability:** new tests must be portable — `p.join` for paths
  (never literal `/`), no `chmod`.
- **Output discipline:** never dump large output into context. Redirect
  to scratch dir (`/tmp/niman`, `%TEMP%\niman`), read selectively;
  never `cat` whole large files (`grep -n` / `sed -n`); paste log lines
  only on failure, only the relevant ones.
- **Docs in the same PR:** when a feature is added, modified, or removed,
  update the corresponding `docs/` page in the same PR (see `AGENTS.md`).
