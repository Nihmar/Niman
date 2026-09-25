# Building

## Prerequisites

- Flutter on PATH (currently 3.47.2 stable).
  - Linux fallback: `export PATH="$PATH:~/develop/flutter/bin"`
    (`scripts/niman.sh` does this itself).
- Android SDK (Linux): `~/Android/Sdk` via gitignored
  `android/local.properties` (never commit).
- First build needs network (the `sqlite3` package fetches a prebuilt
  native binary via Dart build hooks — required on Windows, which ships
  no `sqlite3.dll`).

- Android NDK 29.0.13113456 (required by `whisper_ggml`).
- The APK is 64-bit only (`arm64-v8a`, `x86_64`): `armeabi-v7a` is
  excluded at packaging in `android/app/build.gradle.kts`.

## Helper scripts

Terse output; full logs in `/tmp/niman/niman-<cmd>.log`
(`%TEMP%\niman\` on Windows):

```
./scripts/niman.sh analyze   # flutter analyze --fatal-infos
./scripts/niman.sh test      # flutter test (unit + widget)
./scripts/niman.sh check     # analyze + test; run before every commit
./scripts/niman.sh integration  # integration_test/; run before every commit (issue #241)
./scripts/niman.sh apk       # Android release APK
./scripts/niman.sh apk beta  # Android testing build (issue #106)
./scripts/niman.sh linux     # Linux release bundle
./scripts/niman.sh linux beta  # Linux testing build (its own data folder)
scripts\niman.bat check      # Windows equivalent
scripts\niman.bat integration  # the headless integration_test/ files (sync_e2e needs Linux)
scripts\niman.bat apk beta   # Android testing build, from Windows
scripts\niman.bat windows    # Windows build (on a Windows host)
scripts\niman.bat windows beta  # Windows testing build (its own data folder)
```

`check` (`.github/workflows/check.yml`) runs analyze, `flutter test`
and the headless integration tests on every pull request, so the suite
cannot rot unnoticed again (issue #241). The WebDAV sync flow needs a
Linux display (`flutter test -d linux`) and stays a local run inside
`integration`.

## The two Android builds (issue #106)

The app ships in two flavors of the `channel` dimension, so the
official app and the testing build install side by side on the same
device. Once a flavor dimension has a flavor, AGP drops the no-flavor
variant, so the official app is the explicit `official` flavor — no
application ID suffix, no per-flavor manifest, the ID stays
`dev.niman.niman`:

- `./scripts/niman.sh apk` (or `scripts\niman.bat apk` on a Windows
  host) builds the official APK:
  `flutter build apk --release --flavor official`, artifact
  `build/app/outputs/flutter-apk/app-official-release.apk`.
- `flutter run` on an Android device needs the flavor too:
  `flutter run --flavor official`.

`./scripts/niman.sh apk beta` (or `scripts\niman.bat apk beta` on a
Windows host) builds the testing build: the release pipeline plus
the `beta` product flavor.

- Application ID `dev.niman.niman.beta` (the flavor's
  `applicationIdSuffix` in `android/app/build.gradle.kts`), launcher
  label "Niman (Testing)" (per-flavor manifest
  `android/app/src/beta/AndroidManifest.xml`).
- Release-equivalent: same build type, signing, SDK, R8 and
  desugaring — only the ID and the label differ.
- The flavor passes `--dart-define=APP_CHANNEL=testing`; the Dart side
  (`lib/src/core/app_channel.dart`) hides the Updates settings section
  and never starts the update scheduler, whatever the stored
  auto-update toggle says. A build that forgets the define reads as
  `release` and keeps full update behavior.
- The two installs are fully independent by design: separate storage,
  separate SQLite indexes, separate `MANAGE_EXTERNAL_STORAGE` grant
  (the permission is per application ID, so grant it to the testing
  install too).
- AGP forbids flavor names starting with `test` (reserved for test
  variants), hence `beta`.

A local rebuild after a commit uses **`beta`** by default; the official
artifacts are built only when asked (see `AGENTS.md`).

## The desktop testing build

On Windows and Linux both builds are one `niman` executable under one
product name, so without help they share one support folder — one
settings database, one set of indexes, one single-instance claim. A
testing build that migrated the database to a newer schema broke the
installed release, which took the version back down and left the next
migration to redo what was done (2026-09-22). So the testing build keeps
its own folder:

- `scripts\niman.bat windows beta` (`./scripts/niman.sh linux beta`)
  passes `--dart-define=APP_CHANNEL=testing`.
- `appSupportDirectory()` (`lib/src/core/app_channel.dart`) answers a
  sibling of the platform folder, `…\dev.niman\niman-testing` on
  Windows, for everything the app keeps: `niman.db`, `indexes/`, the log,
  the single-instance claim. Libraries have to be opened once again in
  the testing build; the notes themselves are the same files.
- The window and the tray say "Niman (testing)", and the two can run at
  the same time.
- The settings database refuses to be opened by a build older than the
  one that last migrated it, rather than let drift stamp it back down.

CI (`.github/workflows/release.yml`) publishes the testing APK from
every release tag as `niman-<version>-android-testing.apk`.

## Checks before every commit

1. `dart fix --apply`, then `dart format lib test tool` (both idempotent).
2. `./scripts/niman.sh check` (infos are fatal:
   `flutter analyze --fatal-infos`).
3. `flutter test` runs `test/unit/` + `test/widget/`; single test:
   `flutter test test/unit/<f>.dart --plain-name "<name>"`.
   `integration_test/` is E2E, not part of the default run: `app_boot` +
   `template_backlink` run headless (in CI too), `sync_e2e` needs
   `-d linux` on a Linux host with a display. `./scripts/niman.sh
   integration` runs all three (issue #241).
4. Windows note: ~20 tests fail on path separators and temp-dir cleanup
   (pre-existing, green on Linux). Use `pwsh scripts/newfail.ps1` — it
   prints only failures not in `scripts/known-failures.txt` (exit 1 =
   something new broke; `-Update` rewrites the baseline).

## Codegen

Two drift databases in `lib/src/db/`, `.g.dart` committed:

- `AppDatabase` (`app_database.dart`): settings, long migration chain.
- `IndexDatabase` (`index_database.dart`): one per library, schema 1, no
  migrations — delete the file to rebuild.

After schema/DAO changes: `dart run build_runner build`.
