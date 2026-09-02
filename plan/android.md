# Android — storage & startup issues

**Status:** slow reopen fixed · `.md` visibility open (T-M6-09)

Two issues observed on Android (Linux unaffected).

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

**Known caveat:** the reconciliation walk still runs on the UI isolate — it
no longer gates the first frame, but a large library will hitch briefly
after the tree paints. If that bites, move the walk to a background
isolate.

## 2. `.md` files missing from the tree on Android (open)

**Symptom:** notes created outside the app never appeared in the tree.

**Not a permissions problem:** the app requests no storage permission and
needs none. On Android the library root is the app's own app-specific
external storage (`Android/data/<package>/files`), which the app can
read/write without any runtime permission. The catch: since Android 11 no
*other* app can see or write that folder — file managers can't copy `.md`
files into it. So files elsewhere on the phone (Documents/Downloads) are
invisible to the app, and no permission dialog could change that. Files
that *are* inside the folder (e.g. via `adb push`, or created in-app) are
picked up by the 60 s periodic rescan and on every launch.

**Status:** open — the production fix is user-picked library roots under
scoped storage: **T-M6-09** in [m6-scale-polish.md](m6-scale-polish.md),
originally flagged in the [m1-library-core.md](m1-library-core.md) open
questions.
