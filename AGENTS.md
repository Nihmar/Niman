# AGENTS.md
Niman: Flutter Markdown notes (Android + Linux + Windows).
Pending work is tracked in [GitHub Issues](https://github.com/Nihmar/Niman/issues).

## Language
- Everything in the repo is written in English: code, comments, docs, commits — regardless of conversation language.

## Env
- Flutter on PATH (currently 3.47.2 stable).
  - Linux fallback: `export PATH="$PATH:~/develop/flutter/bin"` (`scripts/niman.sh` does this itself).
  - Android SDK (Linux): `~/Android/Sdk` via gitignored `android/local.properties` (never commit).
- Repo-root `niman-release.apk` / `niman-linux-x64.tar.gz` are gitignored artifacts, not sources.

## Commits
- One logical change per commit; never bundle unrelated changes.
- **No co-authoring signatures**: a commit message carries no `Co-authored-by:`
  trailer — not a tool's, not another agent's. The history has none, and none
  is to be added.
- **Build the beta (testing) flavor by default** — `./scripts/niman.sh apk beta` /
  `./scripts/niman.sh linux beta`, `scripts\niman.bat apk beta` /
  `scripts\niman.bat windows beta`. It carries its own application ID /
  support folder and never disturbs the installed release. Build the
  **official** artifacts only when explicitly asked.
- After each commit, **on a Linux host only**, rebuild and report **outcome + artifact path** only (no raw logs): `./scripts/niman.sh apk beta` / `./scripts/niman.sh linux beta`.
- On a Windows host, do **not** rebuild after commits: builds are far too slow there. Build (`scripts\niman.bat apk beta` / `scripts\niman.bat windows beta`) only when explicitly asked.
- An APK build that fails with `package dev.flutter.plugins.integration_test does not exist` is a stale plugin registrant, not a code fault: `flutter pub get` writes `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` with every plugin, and only `flutter build --release` rewrites it without the dev dependencies. Delete that file (gitignored, regenerated), `flutter pub get`, build again.

## Verify
- **Before analyze and tests**, run `dart fix --apply` then
  `dart format lib test tool` (both idempotent); CI gates the result with
  `dart format --output=none --set-exit-if-changed lib test tool`, so drift
  fails the job.
- CI (`.github/workflows/check.yml`) runs that gate + analyze + `flutter test` +
  the integration files on every PR, and installs `hunspell`, `hunspell-en-us`
  and `hunspell-it` so the live cases of `test/unit/spell_check_test.dart` check
  real words there instead of skipping, and `tesseract-ocr` + `tesseract-ocr-eng`
  for the live case of `test/unit/ocr_engine_test.dart` (`NIMAN_OCR_ENGINE=<path>`
  runs it against a build of `scripts/ocr-engine.sh` instead). Run checks
  locally too:
  - Linux: `./scripts/niman.sh check` (logs: `/tmp/niman/niman-check.log`),
    plus `./scripts/niman.sh integration` for `integration_test/`
  - Windows: `scripts\niman.bat check` (logs: `%TEMP%\niman\`),
    plus `scripts\niman.bat integration` for the headless files there
- A second workflow (`.github/workflows/site.yml`) builds the documentation
  site on every PR, with the deploy's own Jekyll steps and read-only (issue
  #470): a change to `_config.yml`, `_layouts/`, `_includes/`, `assets/css/` or
  a page has to pass it, and there is no Ruby here to try it by hand.
- The suite is green on Linux, and on Windows too: the eighteen entries
  `scripts/known-failures.txt` used to carry were real bugs, fixed rather than
  tolerated (2026-09-10). What remains on Windows is five flakes — the same
  fault under full-suite load, a rename or a delete on a file another process
  still holds; they pass in isolation. Use `pwsh scripts/newfail.ps1` — it prints only failures not in `scripts/known-failures.txt`. Exit code 1 = something new broke. Options: optional path filter, `-Update` to rewrite the baseline.
- `flutter analyze --fatal-infos` (infos are fatal, and `flutter test` does not
  catch one in a file it merely compiles: re-run analyze after adding any file).
- `flutter test` runs `test/unit/`, `test/widget/` **and `test/perf/`** — which
  is why a perf file's bars are gated (see below). Single test: `flutter test test/unit/<f>.dart --plain-name "<name>"`.
- **Performance tests print; the absolutes do not gate.** `test/perf/` measures
  wall-clock, and a shared CI runner read 365 ms for the fixture this host reads
  at 168 **on the same commit** — a ceiling calibrated here fails there for the
  hardware, not for the code. So every run asserts a backstop, and the design's
  ceiling is asserted by a run that asks for it:
  `NIMAN_PERF=1 flutter test test/perf/<file>.dart`. A new perf test follows that
  shape: print the number, say which bar it was held to, and put the absolute
  one behind `NIMAN_PERF`.
- `integration_test/` = E2E, not part of the default `flutter test` run,
  and it rots when nothing runs it (#241): CI runs `app_boot` headless and
  `sync_e2e` on `-d linux` under `xvfb-run`, the device the headless runner
  cannot give it; `template_backlink` is a repro harness that skips unless
  a library is seeded at `/tmp/niman/repro_lib`. Run all three via
  `integration` **only once a feature's implementation is finished** —
  never after intermediate commits of work in progress.
- **New tests must be portable**: use `p.join` for paths (never literal `/`), no `chmod`.

## Codegen
- Two drift DBs in `lib/src/db/`, `.g.dart` committed:
  - `AppDatabase` (`app_database.dart`): settings, long migration chain.
  - `IndexDatabase` (`index_database.dart`): one per library, schema 1, no migrations — delete the file to rebuild.
- After schema/DAO changes: `dart run build_runner build`.

## Output discipline
- Never dump large output into context. Redirect to scratch dir (`/tmp/niman` on Linux, `%TEMP%\niman` on Windows), then read selectively.
- Never `cat` whole large files. Use `grep -n` / `sed -n`.
- Paste log lines only on failure, only the relevant ones.

## Design rules
- **Disk is source of truth**: one note = one `.md`. SQLite is a rebuildable index — store nothing that can't be reconstructed from disk.
- **Android storage**: plain `dart:io` (needs `MANAGE_EXTERNAL_STORAGE`, gated by `core/storage_access.dart`). SAF tree grants are not a substitute — they only open `content://`, never the filesystem.
- **Notification icon pinning**: R8 strips the reminder icon unless pinned via `tools:keep` in `android/app/src/main/res/raw/dev_niman_niman_keep.xml`. Update the keep file when renaming the drawable.
- **Scale**: 1M notes + novel-length files. No O(n) full scans on hot paths; FTS5 for search; tree rows materialized.
- **No disk I/O on UI isolate**: use `Isolate.run` (every `listSync`/`statSync` is a FUSE round trip on Android). Drift writes stay on main.
- **Vocabulary**: Library, note, folder, tag, template, wikilink, trash, history. Not vault/canvas/daily note/backlinks.
- **Every platform ships every feature**: a feature lands on Android, Linux and Windows in the same round — no platform is left behind, forgotten or quietly skipped. Same capability, not the same UI: the shape adapts to the surface (desktop tabs are an open-notes switcher on a phone) while the model underneath stays one. A platform that genuinely cannot have it says so in the issue and in `docs/user/platforms.md` — as a decision, not an omission.
- **Interface**: icons are outline — a filled one says a state is on (selected tab, pinned note, current library). A control that shows in only some states keeps its place: disable it, or put it on the side the row grows from, so nothing on screen moves under a thumb already on it.
- **Layout**: `lib/src/<module>/` — core, library, db, editor, preview, links, search, frontmatter, templates, sync, ui.
- **No god classes**: one class per file, split at ~300 lines or when responsibilities mix.

## Documentation
- When a feature is added, modified, or removed, update the corresponding documentation in `docs/` in the same PR.

## Release
- CI builds **only from version tags** (`vX.Y.Z`, no suffixes).
- Update `CHANGELOG.md` at every release: a new `## [X.Y.Z] - YYYY-MM-DD` section describing the tagged version. It ships as an asset and feeds the in-app changelog (launch dialog after an update, Settings → About).
- Cut a release: bump `version:` in `pubspec.yaml`, commit both with the changelog, `git tag vX.Y.Z`, `git push origin vX.Y.Z`.
- Workflow: `.github/workflows/release.yml`. Artifacts: Android `.apk`; Linux `.tar.gz` + `.AppImage` + `.pkg.tar.zst`; Windows `.exe` (Inno Setup) + `.zip`.
- Android APK is signed with the release key from the Actions secrets
  (`ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Without them the build
  falls back to the debug key, which changes per run — that is what made
  every release up to v0.0.7 refuse to update over the last one (#160).
  The names are the repository's own: #449 read a documented
  `ANDROID_KEYSTORE_PASSWORD` no secret carried, and the v0.1.4 release
  failed at signing with an empty password.
- Bump the `+N` build number on every tag, including a re-cut of an
  existing version: it is the Android `versionCode`, and the installer
  rejects a package that does not raise it.
- To re-run: delete the tag locally and remotely, fix, tag again.
