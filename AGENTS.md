# AGENTS.md
Copist: Flutter Markdown notes (Android + Linux).
Spec: `Copist - spec & plan.md`. Design: `plan/design.md`. Plan: `plan/m*.md`
(M0→M7, sequential; check Status line — M1 done, M2 in progress).

## Env
- Flutter not on PATH: `export PATH="$PATH:/home/alessandro/develop/flutter/bin"`
- Android SDK: `/home/alessandro/Android/Sdk` via gitignored `android/local.properties` (never commit).
- Repo-root `copist-release.apk` / `copist-linux-x64.tar.gz` are gitignored artifacts, not sources.

## Commits
- One logical change per commit; never bundle unrelated changes.
- After each commit, rebuild both platforms and report **outcome + artifact path** only (not raw logs):
  - `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
  - `flutter build linux --release` → `build/linux/x64/release/bundle/`

## Verify
- `flutter analyze --fatal-infos` (CI: infos fatal; keep clean).
- `flutter test` (`test/unit/`, `test/widget/`). Single: `flutter test test/unit/<f>.dart --plain-name "<name>"`.
- `integration_test/` = on-device E2E; not in CI.

## Codegen
- drift DB in `lib/src/db/`; `database.g.dart` committed. After schema/DAO changes: `dart run build_runner build`.

## Output discipline
- Never dump large output into context. Redirect, then read selectively. Scratch: `mkdir -p /tmp/copist`.
- Pattern: `<cmd> > /tmp/copist/x.log 2>&1`, then `tail`/`grep -n`/`sed -n 'A,Bp'`; `wc -l` if unsure.
- Always capture these (verbose), read only the tail/matches:
  - `flutter build apk --release > /tmp/copist/apk.log 2>&1; tail -5 /tmp/copist/apk.log`
  - `flutter build linux --release > /tmp/copist/linux.log 2>&1; tail -5 /tmp/copist/linux.log`
  - `flutter analyze --fatal-infos > /tmp/copist/an.log 2>&1; grep -n "•" /tmp/copist/an.log; tail -3 /tmp/copist/an.log`
  - `flutter test > /tmp/copist/test.log 2>&1; tail -20 /tmp/copist/test.log`
  - `dart run build_runner build > /tmp/copist/gen.log 2>&1; tail -10 /tmp/copist/gen.log`
- Never `cat` whole: `database.g.dart`, `pubspec.lock`, long `.md`. Use `grep -n`/`sed -n`. Repo search: `grep -rn "<p>" lib/ > /tmp/copist/hits.txt` then read the file.
- Paste log lines only on failure, only the relevant ones.

## Design rules (affect how you code)
- Disk is source of truth: one note = one `.md`. SQLite (drift) is a **rebuildable index only** — store nothing that can't be reconstructed by rescanning disk.
- Scale: 1M notes + novel-length files. No O(n) full scans on hot paths; search via FTS5; keep tree rows materialized.
- Vocabulary: Library (root), note, folder, tag, template, wikilink, trash, history. Not vault/canvas/daily note/backlinks.
- Layout `lib/src/<module>/` per `plan/design.md`: core, library, db, editor, preview, links, search, frontmatter, templates, sync, ui.
