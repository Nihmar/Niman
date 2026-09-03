# AGENTS.md

Copist: Flutter Markdown note app (Android + Linux). Requirements source of
truth: `Copist - spec & plan.md`. Work plan: `plan/` (milestones M0→M7, strictly
sequential; check the Status line of each `plan/m*.md` — M1 done, M2 in
progress). Architecture source of truth: `plan/design.md`.

## Commit workflow (required)

- Many small commits: one logical change per commit. Never bundle unrelated
  changes into one commit.
- After **each** commit, rebuild both platforms and report results to the user:
  - `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`
  - `flutter build linux --release` → `build/linux/x64/release/bundle/`

## Environment

- Flutter is **not** on PATH: `export PATH="$PATH:/home/alessandro/develop/flutter/bin"`
- Android SDK at `/home/alessandro/Android/Sdk`, wired via gitignored
  `android/local.properties` (do not commit it)
- Lint: `very_good_analysis` (strict) — keep `flutter analyze` clean
- Previous release artifacts may sit at repo root (`copist-release.apk`,
  `copist-linux-x64.tar.gz`) — gitignored; don't confuse them with sources

## Verify

- `flutter analyze --fatal-infos` (CI treats infos as fatal)
- `flutter test` — unit (`test/unit/`) + widget (`test/widget/`)
- Single test: `flutter test test/unit/<file>.dart --plain-name "<name>"`
- `integration_test/` is on-device E2E (needs a connected device); CI does not
  run it

## Codegen

- drift DB is in `lib/src/db/`; `database.g.dart` is committed. After schema/DAO
  changes run `dart run build_runner build`

## Design rules that change how you code

- Files on disk are the source of truth: one note = one `.md` file. The SQLite
  (drift) DB is a **rebuildable index only** — never store data in the DB that
  cannot be reconstructed by rescanning disk.
- Hard requirement: 1,000,000 notes + novel-length files. No O(n) full scans on
  hot paths; search via FTS5; keep tree rows materialized.
- Copist vocabulary, not Obsidian's: Library (root folder), note, folder, tag,
  template, wikilink, trash, history. No "vault", "canvas", "daily note",
  "backlinks".
- `lib/src/<module>/` layout follows `plan/design.md` (core, library, db,
  editor, preview, links, search, frontmatter, templates, sync, ui).
