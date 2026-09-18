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
- After each commit, **on a Linux host only**, rebuild and report **outcome + artifact path** only (no raw logs): `./scripts/niman.sh apk` / `./scripts/niman.sh linux`.
- On a Windows host, do **not** rebuild after commits: builds are far too slow there. Build (`scripts\niman.bat apk` / `scripts\niman.bat windows`) only when explicitly asked.
- An APK build that fails with `package dev.flutter.plugins.integration_test does not exist` is a stale plugin registrant, not a code fault: `flutter pub get` writes `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` with every plugin, and only `flutter build --release` rewrites it without the dev dependencies. Delete that file (gitignored, regenerated), `flutter pub get`, build again.

## Verify
- **Before analyze and tests**, run `dart fix --apply` then `dart format lib test tool` (both idempotent).
- No CI — run checks locally before every commit:
  - Linux: `./scripts/niman.sh check` (logs: `/tmp/niman/niman-check.log`)
  - Windows: `scripts\niman.bat check` (logs: `%TEMP%\niman\`)
- On Windows, ~20 tests fail on path separators and temp-dir cleanup (pre-existing, green on Linux). Use `pwsh scripts/newfail.ps1` — it prints only failures not in `scripts/known-failures.txt`. Exit code 1 = something new broke. Options: optional path filter, `-Update` to rewrite the baseline.
- `flutter analyze --fatal-infos` (infos are fatal).
- `flutter test` runs `test/unit/` + `test/widget/`. Single test: `flutter test test/unit/<f>.dart --plain-name "<name>"`.
- `integration_test/` = on-device E2E, not part of the default run.
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
  (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). Without them the build
  falls back to the debug key, which changes per run — that is what made
  every release up to v0.0.7 refuse to update over the last one (#160).
- Bump the `+N` build number on every tag, including a re-cut of an
  existing version: it is the Android `versionCode`, and the installer
  rejects a package that does not raise it.
- To re-run: delete the tag locally and remotely, fix, tag again.
