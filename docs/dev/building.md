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
./scripts/niman.sh apk       # Android release APK
./scripts/niman.sh linux     # Linux release bundle
scripts\niman.bat check      # Windows equivalent
scripts\niman.bat windows    # Windows build (on a Windows host)
```

## Checks before every commit

1. `dart fix --apply`, then `dart format lib test tool` (both idempotent).
2. `./scripts/niman.sh check` (infos are fatal:
   `flutter analyze --fatal-infos`).
3. `flutter test` runs `test/unit/` + `test/widget/`; single test:
   `flutter test test/unit/<f>.dart --plain-name "<name>"`.
   `integration_test/` is on-device E2E, not part of the default run.
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
