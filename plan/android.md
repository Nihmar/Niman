# Android — storage & startup issues

**Status:** both fixed · T-M6-09 partial (root picking done; image-insert
paths + on-device verification remain)

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

**Fix:**

- `AndroidManifest.xml` declares `MANAGE_EXTERNAL_STORAGE`, and
  `MainActivity.kt` exposes a `copist/storage` method channel:
  `hasManageStorageAccess`, and `requestManageStorageAccess` (launches
  the system "All files access" screen, resolves when the user returns,
  with the grant state at that point). Dart side:
  `StorageAccess.ensureAllFilesAccess()` (`lib/src/core/storage_access.dart`),
  a no-op on non-Android platforms.
- The open/create screen picks the library root with the native directory
  picker (SAF on Android, xdg-desktop-portal on Linux) — no raw path entry
  — and both flows pass the `StorageAccess` gate first, so the permission
  prompt precedes any picking.

**Status:** fixed. **T-M6-09** in
[m6-scale-polish.md](m6-scale-polish.md) stays open for the remaining
scope: image-insert paths on both platforms and on-device verification
(real devices, not just app-specific storage), originally flagged in the
[m1-library-core.md](m1-library-core.md) open questions.
