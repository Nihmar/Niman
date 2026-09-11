# AGENTS.md
Copist: Flutter Markdown notes (Android + Linux + Windows).
Pending work is tracked in [GitHub Issues](https://github.com/Nihmar/Copist/issues).

## Language
- Everything in the repo is written in English: code, comments, docs, commits — regardless of conversation language.

## Env
- Flutter on PATH (currently 3.47.2 stable).
  - Linux fallback: `export PATH="$PATH:~/develop/flutter/bin"` (`scripts/copist.sh` does this itself).
  - Android SDK (Linux): `~/Android/Sdk` via gitignored `android/local.properties` (never commit).
- Repo-root `copist-release.apk` / `copist-linux-x64.tar.gz` are gitignored artifacts, not sources.

## Commits
- One logical change per commit; never bundle unrelated changes.
- After each commit, rebuild and report **outcome + artifact path** only (no raw logs):
  - Linux: `./scripts/copist.sh apk` / `./scripts/copist.sh linux`
  - Windows: `scripts\copist.bat apk` / `scripts\copist.bat windows`

## Verify
- **Before analyze and tests**, run `dart fix --apply` then `dart format lib test tool` (both idempotent).
- No CI — run checks locally before every commit:
  - Linux: `./scripts/copist.sh check` (logs: `/tmp/copist/copist-check.log`)
  - Windows: `scripts\copist.bat check` (logs: `%TEMP%\copist\`)
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
- Never dump large output into context. Redirect to scratch dir (`/tmp/copist` on Linux, `%TEMP%\copist` on Windows), then read selectively.
- Never `cat` whole large files. Use `grep -n` / `sed -n`.
- Paste log lines only on failure, only the relevant ones.

## Design rules
- **Disk is source of truth**: one note = one `.md`. SQLite is a rebuildable index — store nothing that can't be reconstructed from disk.
- **Android storage**: plain `dart:io` (needs `MANAGE_EXTERNAL_STORAGE`, gated by `core/storage_access.dart`). SAF tree grants are not a substitute — they only open `content://`, never the filesystem.
- **Notification icon pinning**: R8 strips the reminder icon unless pinned via `tools:keep` in `android/app/src/main/res/raw/dev_copist_copist_keep.xml`. Update the keep file when renaming the drawable.
- **Scale**: 1M notes + novel-length files. No O(n) full scans on hot paths; FTS5 for search; tree rows materialized.
- **No disk I/O on UI isolate**: use `Isolate.run` (every `listSync`/`statSync` is a FUSE round trip on Android). Drift writes stay on main.
- **Vocabulary**: Library, note, folder, tag, template, wikilink, trash, history. Not vault/canvas/daily note/backlinks.
- **Layout**: `lib/src/<module>/` — core, library, db, editor, preview, links, search, frontmatter, templates, sync, ui.
- **No god classes**: one class per file, split at ~300 lines or when responsibilities mix.

## Documentation
- When a feature is added, modified, or removed, update the corresponding documentation in `docs/` in the same PR.

## Release
- CI builds **only from version tags** (`vX.Y.Z`, no suffixes).
- Cut a release: bump `version:` in `pubspec.yaml`, commit, `git tag vX.Y.Z`, `git push origin vX.Y.Z`.
- Workflow: `.github/workflows/release.yml`. Artifacts: Android `.apk`; Linux `.tar.gz` + `.AppImage` + `.pkg.tar.zst`; Windows `.exe` (Inno Setup) + `.zip`.
- Android APK is debug-signed until release keys are added as Actions secrets.
- To re-run: delete the tag locally and remotely, fix, tag again.
