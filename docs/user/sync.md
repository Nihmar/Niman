# Sync setup

## Today: the folder *is* the sync

A library is a plain folder with its settings in `.niman/`. To move or
mirror it, copy/sync the folder with any tool (Nextcloud client,
Syncthing, rsync, USB). Everything travels: notes, folders, templates,
settings, trash, history.

Tips:

- Close the library on both sides before syncing to avoid half-written
  files (note writes themselves are atomic: temp file + rename).
- The SQLite index rebuilds from disk when needed — never copy the index
  without the files; if in doubt, delete the per-library index file and
  let the app rescan.
- Unknown `settings.json` keys are preserved, so a newer app version's
  settings survive a round-trip through an older one.

## Planned: WebDAV sync

Whole-library sync to Nextcloud, ownCloud, or any WebDAV server is
tracked as [#9](https://github.com/Nihmar/Niman/issues/9): offline queue,
conflict detection, and a hunk-level merge UI. Until it lands, the
folder copy above is the supported path.
