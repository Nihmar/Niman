# Platform notes

Supported today: **Android** (minSdk 35), **Linux** (Wayland),
**Windows**. macOS/iOS are not built yet, but the code is kept portable.
New tests must be portable too (see [conventions](../dev/conventions.md)).

## Android

- **Storage:** plain `dart:io` file access, gated by
  `MANAGE_EXTERNAL_STORAGE`. SAF tree grants are not a substitute — they
  only open `content://`, never the filesystem.
- **FUSE cost:** every file stat/list is a round trip, so all disk reads
  run off the UI isolate (`Isolate.run`); Drift writes stay on main.
- **Reminders:** exact alarms fire with the screen off or the process
  killed. Grant notification permission and exempt the app from battery
  optimization when prompted, or alarms may not arrive.
- **Launcher shortcuts:** long-press the icon (see
  [shortcuts](shortcuts.md)).

## Linux

- Wayland supported; window owns close-request handling (dirty-check on
  close rides it).
- Spellcheck via hunspell (`spellDictionaries` in library settings).
- Tray support where the desktop provides one.

## Windows

- Ships its own SQLite (`sqlite3` package bundles the native library via
  Dart build hooks — Windows has no system `sqlite3.dll`). First build
  on a machine needs network to fetch the prebuilt binary.
- spellcheck via hunspell, same setting as Linux.

## Not yet

Share-in on Android, file association on desktop, single-instance guard
— tracked as [#39](https://github.com/Nihmar/Niman/issues/39).
Debug-signed APKs until release keys land (see
[releasing](../dev/releasing.md)).
