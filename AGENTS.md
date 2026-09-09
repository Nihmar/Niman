# AGENTS.md
Copist: Flutter Markdown notes (Android + Linux + Windows).
Spec: `Copist - spec & plan.md`. Design: `plan/design.md`. Plan: `plan/m*.md`
(M0→M1→M1.5→M2→…→M7, sequential; check each file's Status line — everything
up to M3 is done and device-verified, **M4 is next**). `plan/README.md`
indexes them, including the slices outside the chain.

## Language
- Whatever the conversation language, everything in the repo is written in English: code, comments, documentation, commit messages.

## Env
- Flutter is on PATH (`flutter`, currently 3.47.2 stable). If it ever is not: `export PATH="$PATH:/home/alessandro/develop/flutter/bin"` (`scripts/copist.sh` does this fallback itself).
- Android SDK: `/home/alessandro/Android/Sdk` via gitignored `android/local.properties` (never commit).
- Repo-root `copist-release.apk` / `copist-linux-x64.tar.gz` are gitignored artifacts, not sources.

## Commits
- One logical change per commit; never bundle unrelated changes.
- After each commit, rebuild the platforms the dev machine can build and report **outcome + artifact path** only (not raw logs):
  - `./scripts/copist.sh apk` → `build/app/outputs/flutter-apk/app-release.apk`
  - `./scripts/copist.sh linux` → `build/linux/x64/release/bundle/`
  - Windows (`flutter build windows --release` → `build\windows\x64\runner\Release\`) needs a Windows host; it cannot be cross-built from Linux, so verify it there when the change touches platform code.

## Verify
- **Before analyze and tests, run `dart fix --apply` then `dart format lib test tool`.** Both are idempotent and safe to repeat. `dart fix` is what keeps the tree on the current Dart style — the unnamed constructor is declared `new(...)`, not by repeating the type name — and it settles most new lints from an `analysis_options` bump without hand edits. Formatting first also keeps a later reflow from burying a real diff.
- No CI: nothing runs the checks for you, so `./scripts/copist.sh check` (analyze + tests) before every commit. Terse output; full log `/tmp/copist/copist-check.log`.
- On a Windows host: `scripts\copist.bat <analyze|test|check|apk|windows>` (same output discipline, logs under `%TEMP%\copist`). ~23 tests fail there on path separators (`/fake/library` vs `\`) and on temp-dir cleanup — pre-existing and platform-only, not a regression; the suite is green on Linux. Two more vary run to run and are not regressions either: `file_watcher_test` "coalesces rapid events into a single batch" flakes under full-suite load and passes on its own, and `fixture_10k_test` times out building its 10k-note fixture (a `TimeoutException` with a partial count, not a failed assertion) — so that file shows 3 or 4 failures depending on the run. Check a suspect failure in isolation before calling it a regression. **New tests must be portable**: build expected paths with `p.join`, never a literal `/`, and reach for a real I/O error (a directory where a file belongs) rather than shelling out to `chmod`, which does not exist here.
- `flutter analyze --fatal-infos` (infos are fatal; keep it clean).
- `flutter test` (`test/unit/`, `test/widget/`). Single: `flutter test test/unit/<f>.dart --plain-name "<name>"`.
- `integration_test/` = on-device E2E; not part of the default run.

## Codegen
- drift DB in `lib/src/db/`; `database.g.dart` committed. After schema/DAO changes: `dart run build_runner build`.

## Output discipline
- Never dump large output into context. Redirect, then read selectively. Scratch: `mkdir -p /tmp/copist`.
- `./scripts/copist.sh analyze|test|check|apk|linux` prints only the relevant tail (analyze: issue lines; builds: artifact path); full logs in `/tmp/copist/copist-<cmd>.log`.
- Ad-hoc command: `<cmd> > /tmp/copist/x.log 2>&1`, then `tail`/`grep -n`/`sed -n 'A,Bp'`; `wc -l` if unsure.
- Never `cat` whole: `database.g.dart`, `pubspec.lock`, long `.md`. Use `grep -n`/`sed -n`. Repo search: `grep -rn "<p>" lib/ > /tmp/copist/hits.txt` then read the file.
- Paste log lines only on failure, only the relevant ones.

## Design rules (affect how you code)
- Disk is source of truth: one note = one `.md`. SQLite (drift) is a **rebuildable index only** — store nothing that can't be reconstructed by rescanning disk.
- Android storage: the library is read/written with plain `dart:io` (walk, watch, open by path), so it needs `MANAGE_EXTERNAL_STORAGE` ("All files access"), gated by `core/storage_access.dart`. A SAF tree grant is **not** a substitute — it only opens the DocumentsProvider (`content://`), never the filesystem; two rounds were lost to that. The picker only *chooses* the root. Details: `plan/android.md`.
- The reminder notification icon is referenced by name at runtime only (the plugin's `getIdentifier`), so R8 resource shrinking — on by default in Flutter release builds — strips it from the release APK unless pinned: `tools:keep` in `android/app/src/main/res/raw/dev_copist_copist_keep.xml`. Rename or move the drawable and update the keep file with it; a missed pin shows up as the fallback white block in the status bar (missing from `aapt2 dump resources` on the release APK).
- Scale: 1M notes + novel-length files. No O(n) full scans on hot paths; search via FTS5; keep tree rows materialized.
- Never walk the disk or read file content on the UI isolate: on Android every `listSync`/`statSync` is a FUSE round trip and hashing reads whole files, which is how the app earned an ANR (`plan/android.md` issue 3). Use `Isolate.run`; the drift writes stay on the main isolate.
- Vocabulary: Library (root), note, folder, tag, template, wikilink, trash, history. Not vault/canvas/daily note/backlinks.
- Layout `lib/src/<module>/` per `plan/design.md`: core, library, db, editor, preview, links, search, frontmatter, templates, sync, ui.
- No god classes: keep one class per file, and split a class that grows past a single clear responsibility (or ~300 lines) into smaller classes, each in its own file. A view that mixes IME handling, painting, gestures, and persistence is several classes (e.g. a `…Client` for the IME, a `…Painter`, the widget) wired together — not one big widget. This keeps files short enough to read and reason about.
