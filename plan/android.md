# Android — storage & startup issues

**Status:** all three fixed and verified on device · T-M6-09 partial
(root picking done; image-insert paths remain)

Three issues observed on Android (Linux unaffected).

## 1. Slow library reopen (fixed)

**Symptom:** after opening a library once, closing and reopening the app
took several seconds in the "opening" state, where Linux felt instant.

**Root cause:** every launch resumes via `open()` → `Indexer.fullScan()`,
a full disk walk (`listSync` + `statSync` per entry, plus sha256 for
new/changed files). On Android the library root defaults to
`getApplicationDocumentsDirectory()` —
`/storage/emulated/0/Android/data/<package>/files` — which is FUSE-backed:
each `listSync`/`statSync` is a cross-process call (milliseconds each), so
a library with hundreds of notes costs seconds on *every* launch. On Linux
the same walk runs on ext4 and is negligible. The index DB is unaffected —
it lives in fast internal storage (`getApplicationSupportDirectory()`).

**Fix:** resume no longer blocks on the scan. `open()` gained
`blockingScan` (default `true`, still used by the open screen); `resume()`
passes `false`: the library becomes ready immediately from the last index,
the file watcher starts, and a one-shot reconciliation `fullScan` runs
`resumeReconcileDelay` (1 s) later via `_safeRescan` — same guards as the
60 s periodic fallback, and the pending scan is cancelled in teardown.
Covered by `test/unit/library_state_test.dart`.

**Known caveat, since resolved (it bit — see issue 3):** the
reconciliation walk used to run on the UI isolate. It no longer gated the
first frame, but on a real library it froze the app for seconds; the walk
now runs on a background isolate.

**Status:** verified on device (log 2026-09-03 13:11): resume reached
`open complete: ready` 4 ms after `open start`, with the reconciliation
scan following a second later.

## 2. `.md` files missing from the tree on Android (fixed)

**Symptom:** notes created outside the app never appeared in the tree,
while the same library worked fine on Linux.

**Root cause (confirmed from an exported debug log):** Android scoped
storage. With the library root on shared storage
(`/storage/emulated/0/Vaults/notes`), the full scan logged
`found 69 entr(ies) (0 file, 69 dir)` — the FUSE layer backing
`/storage/emulated/0` hands unprivileged apps a filtered view: directory
entries are enumerable, file entries are invisible. Everything above the
walk (indexer, DB, tree, periodic rescan) was correct given what the OS
returned. On Linux there is no such filtering, hence the platform split.
The app declared no storage permission, and with none of
`MANAGE_EXTERNAL_STORAGE` / `READ_EXTERNAL_STORAGE` / `READ_MEDIA_*`
Android 11+ hides the files. (`READ_MEDIA_*` is no option: `.md` is not
media.)

The earlier "not a permissions problem" note in this file only held for
the then-default root — the app-specific folder
`Android/data/<package>/files`, which the app may always read. That
trade-off is gone: no default root exists anymore (see below).

**Why the SAF grant did not fix it (two wasted rounds):** a persistent
tree grant only opens the *DocumentsProvider* — `content://` URIs read
through `ContentResolver`/`DocumentFile`. It changes nothing about the
FUSE view that `dart:io` sees, and Copist reads the library entirely
through `dart:io`: `Indexer` walks it with `listSync`/`statSync`,
`FileWatcher` watches paths, notes are opened by path. The exported log
of 2026-09-03 13:11 proves it in three lines: the grant *was* taken
(`tree grant taken: content://…/tree/primary%3ADocuments%2FHelixNotes`),
the scan that followed still reported `93 entr(ies) (0 file, 93 dir)`,
and the app's own exported log file — written into that folder through
the SAF save dialog seconds earlier — failed to reopen by path with
`Permission denied, errno = 13`. Same file, same folder, same grant:
the SAF channel works, the POSIX channel does not. (The very first
attempt, a `MANAGE_EXTERNAL_STORAGE` gate, was on the right track but
declared the permission as `android:MANAGE_EXTERNAL_STORAGE` instead of
`android.permission.MANAGE_EXTERNAL_STORAGE`, so the app never appeared
in the system's "All files access" list and could not be granted.)

**Fix:**

- The open/create screen picks the library root with the native directory
  picker (SAF on Android, xdg-desktop-portal on Linux) — no raw path entry.
  The picker only *chooses* the folder. On Android it answers with a tree
  URI, which `resolveLibraryRoot` (`lib/src/core/library_root.dart`) maps
  to the real path (`primary:Documents/HelixNotes` →
  `/storage/emulated/0/Documents/HelixNotes`); the screen stat-checks it
  before `open()`.
- Access comes from `MANAGE_EXTERNAL_STORAGE` ("All files access"),
  declared in the manifest and gated in the UI:
  `core/storage_access.dart` (`hasAllFilesAccess` / `ensureAllFilesAccess`,
  no-ops off Android) over the `copist/storage` channel, which answers
  from `Environment.isExternalStorageManager()` and, on request, opens
  Copist's page in the system settings screen and re-checks on return.
  The open screen replaces its two buttons with a short explanation and a
  "Grant file access" button while the permission is missing, and
  `LibraryHome` skips `resume()` without it — resuming would reconcile
  the index against a root whose files the OS hides and rewrite the tree
  down to its folders.
- On `minSdk 35` there is no lighter permission: `READ_EXTERNAL_STORAGE`
  no longer exists and `READ_MEDIA_*` does not cover `.md`. The Play
  Store route is the file-manager declaration, as Obsidian and Markor do.
- The SAF grant path (`core/tree_grant.dart`, `takeTreeGrant`, the
  `android_file_picker` dependency) is removed. Doing the I/O over
  `DocumentFile` instead remains the theoretical fallback if the Play
  declaration is ever refused, but it means rewriting every read and
  write, and losing the watcher: inotify does not work on content URIs
  and `ContentResolver` observers give no usable per-tree events.

**Status:** verified on device (logs 2026-09-03 13:45 and 13:57): the
scan reports `found 979 entr(ies) (886 file, 93 dir)` where it used to
report zero files, and the tree shows the notes. Two earlier "fixed"
rounds were wrong for the same reason — both chased the SAF grant, which
is not a filesystem permission. **T-M6-09** in [m6-scale-polish.md](m6-scale-polish.md)
stays open for the remaining scope: image-insert paths on both platforms
and on-device verification (real devices, not just app-specific storage),
originally flagged in the [m1-library-core.md](m1-library-core.md) open
questions.

## 3. "Copist isn't responding" during use (fixed)

**Symptom:** with the real library visible at last (885 files, 93
folders), Android put up its ANR dialog now and then while the app was
being used.

**Root cause:** the scan runs on the UI isolate, and it is not cheap.
From the 2026-09-03 13:45 device log, one open cost 6.8 s wall-clock:

| phase | duration |
| --- | --- |
| walk of 978 entries | 0.6 s |
| sha256 of 885 files | 6.2 s |
| index rewrite | 0.02 s |

Android raises the ANR dialog after ~5 s of blocked main thread, so the
open alone cleared the bar. The digests were the bulk of it: the index
hashed *every* file, and this library's `Attachments/` holds hundreds of
images and multi-megabyte e-books, all read end to end. `hashFileSha256`
reads with `readSync`, and `await`ing a synchronously-completing future
only yields to the microtask queue, so no frame ran for the whole pass.
On top of that the 60 s periodic `fullScan` re-walked all 978 entries —
another ~0.6 s of blocked UI every minute, this one recurring.

**Fix:**

- `scanTree` and `hashFiles` are top-level and run through
  `Isolate.run`, so neither the walk nor the digests touch the UI
  isolate. The walk's log lines travel back in `ScanResult.logs` and are
  replayed by the caller, since the log buffer does not exist over there.
  The index write stays on the main isolate: it measured 0.02 s.
- Only note files (`.md`) are digested. Attachments are indexed like any
  other file, they are simply never read.
- `fullScan` checks `_treeChanged` *before* computing digests, so the
  common rescan — nothing changed — costs the walk and no reads at all.
  Digests are no longer part of that comparison: a stored digest is only
  ever reused when `(size, mtime)` already proves the content unchanged,
  so it could never be the deciding difference.
- Separately, `LibraryController.open` created the `FileWatcher` but
  never stored it in `_watcher`, so `_teardown` never stopped it. Every
  library close left its recursive watch alive for the rest of the
  process, and reopening the same root doubled the event batches — each
  duplicate costing a subtree walk and an index rewrite.

**Status:** verified on device (log 2026-09-03 13:57, same library). The
open went from 6.8 s to 1.7 s, and what is left runs off the UI isolate:

| phase | before | after |
| --- | --- | --- |
| walk | 0.6 s | 0.3 s |
| digests + index rewrite | 6.2 s (886 files) | 1.4 s (473 notes) |
| open, end to end | 6.8 s | 1.7 s |

`digests: hashing 473 note(s)` confirms the other half of the fix: of the
886 files, 473 are notes and the rest are attachments that are indexed
without ever being read. The 60 s periodic rescan is not in that log's
window — it stays worth a look on a longer session, though it now takes
the same isolate path.
