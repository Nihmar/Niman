# Contributing

Niman is a Flutter app for Android, Linux, Windows, macOS and iOS (the last two
in preview): a Markdown note-taking app whose notes are ordinary `.md` files
and whose database is a rebuildable index. Work is tracked in the
[issue tracker](https://github.com/Nihmar/Niman/issues), and the user guides are
published at <https://nihmar.github.io/Niman/>.

Two documents hold the rules, and this page points at them rather than restating
them:

- **[`AGENTS.md`](AGENTS.md)** — the environment, the checks, the commits, the
  design rules, the release.
- **[`docs/dev/conventions.md`](docs/dev/conventions.md)** — the code and
  interface conventions. The architecture is in
  [`docs/dev/architecture.md`](docs/dev/architecture.md).

Everything in the repository is written in English: code, comments, docs and
commit messages.

## Set up

- **Flutter 3.47.2 stable** on `PATH` — the version CI pins
  (`.github/workflows/check.yml`). `flutter doctor` is the arbiter;
  `scripts/niman.sh` looks under `~/develop/flutter/bin` when Flutter is not on
  `PATH` (`AGENTS.md`, Env).
- **Android**: the SDK, and NDK 29.0.13113456 (`whisper_ggml` builds against
  it). Flutter writes the SDK path into `android/local.properties`, which is
  gitignored — never commit it.
- **Linux desktop**: the GTK stack and the plugins' system libraries — the list
  CI installs is in
  [building, Prerequisites](docs/dev/building.md#prerequisites).
- **Windows desktop**: Visual Studio with the *Desktop development with C++*
  workload; the installer additionally needs Inno Setup 6.
- **macOS and iOS**: a Mac with Xcode, plus `cmake` and `ninja` for the OCR
  engine the app bundles
  ([building, Prerequisites](docs/dev/building.md#prerequisites)).
- The **first build on a machine needs network**: `sqlite3` and `pdfrx` fetch
  prebuilt native libraries through Dart build hooks.

```
git clone https://github.com/Nihmar/Niman.git
cd Niman
flutter pub get
flutter run -d linux            # the Linux desktop
flutter run --flavor official   # an Android device or emulator
```

The Android flavour is not optional: `flutter run` on an Android device needs
`--flavor official` too (issue #106). Build and run the **beta (testing)
flavour** while you work — it installs beside the official app, with an
application ID of its own on Android and a support folder of its own on the
desktop, so the installed release, its settings database and its indexes are
left alone. The wrappers keep the full log in
`/tmp/niman/niman-<cmd>.log` (`%TEMP%\niman\` on Windows) and print only the
tail:

```
./scripts/niman.sh apk beta      # Android testing build
./scripts/niman.sh linux beta    # Linux testing build
./scripts/niman.sh check         # analyze + test
./scripts/niman.sh integration   # the end-to-end suite
scripts\niman.bat windows beta   # Windows testing build, on a Windows host
./scripts/niman.sh macos beta    # macOS testing build and disk image, on a Mac
./scripts/niman.sh ios beta      # iOS testing build (unsigned), on a Mac
```

[docs/dev/building.md](docs/dev/building.md) has the flavours, the artifacts and
what each command does.

## The checks a change must pass

Before every commit, from the repository root:

```
dart fix --apply
dart format lib test tool
./scripts/niman.sh check
```

- **Formatting**: `dart format lib test tool` is idempotent and required; CI
  runs `dart format --output=none --set-exit-if-changed lib test tool` and fails
  the job on drift.
- **Analysis**: `check` is `flutter analyze --fatal-infos` followed by
  `flutter test`. An info is a failure — and `flutter test` does not catch one
  in a file it merely compiles, so analyze again after adding any file.
- **Tests**: `flutter test` runs `test/unit/`, `test/widget/` and `test/perf/`.
  A perf file prints its numbers and holds its absolute bar behind
  `NIMAN_PERF=1 flutter test test/perf/<file>.dart`. New tests are portable:
  `p.join` for paths, never a literal `/`, no `chmod`.
- **Integration**: `./scripts/niman.sh integration` runs the three files in
  `integration_test/`; the default run leaves them out. Run it once a feature's
  implementation is finished, not after an intermediate commit — the WebDAV flow
  needs a Linux display, and the freeze harness skips unless a library is seeded
  at `/tmp/niman/repro_lib`.
- **Docs site**: a change to `_config.yml`, `_layouts/`, `_includes/`,
  `assets/css/` or a page is built by `.github/workflows/site.yml` on the pull
  request. There is no Ruby in the build environment to try it by hand.
- **Windows**: `scripts\niman.bat check`, and `pwsh scripts/newfail.ps1` prints
  only the failures that are not already in `scripts/known-failures.txt`.

CI (`.github/workflows/check.yml`) runs on every pull request and on `main`, in
four jobs: the formatting gate, analyze, the unit, widget and perf suites, and
the integration files, the WebDAV flow included; the Android module's Kotlin
unit tests and API-level lint; the suite, a beta build and the integration files
on a Mac; and an iOS beta build with the integration files in a simulator.

## How a change is proposed

- **One issue, one pull request.** An issue says what happens, where, why it
  matters, what the test will pin and what is accepted when it is done — the
  shape in [.github/ISSUE_TEMPLATE/issue.md](.github/ISSUE_TEMPLATE/issue.md).
  The pull request closes it with `Closes #NNN.`
- **One logical change per commit;** never bundle unrelated changes. The message
  is the sentence the commit makes true, in this shape:

  ```text
  fix(markdown): the four parity gaps between live, the read view and the export (#361)
  ```

  Lowercase after the prefix, no full stop, the issue number at the end. No
  `Co-authored-by` trailer of any kind: the history has none and none is added
  (`AGENTS.md`).
- **A bug fix ships with a test that fails on the unmodified code.** Write the
  test first and watch it fail, apply the fix and watch it pass; the pull request
  says what the test did before the fix, with the command you ran.
- **Documentation moves with the code:** a feature added, changed or removed
  updates the corresponding page under `docs/` in the same pull request.
- **Every platform ships every feature.** A capability lands on Android, Linux,
  Windows, macOS and iOS in the same round — the same capability, not the same
  UI; the shape adapts to the surface while the model underneath stays one.
  macOS and iOS are the most neglected platforms, because developing and
  testing on them is the hardest, so they may lag behind; a gap there is still
  stated in the issue and in [docs/user/platforms.md](docs/user/platforms.md),
  as for any platform. A platform that genuinely cannot have a capability says
  so in the same places, as a decision rather than an omission (`AGENTS.md`,
  Design rules).
- [.github/pull_request_template.md](.github/pull_request_template.md) is the
  shape the pull request body takes: what changed, the tests, the docs the
  change updates, and **what was left out**.

Releases are cut by the maintainers from version tags and follow
[docs/dev/releasing.md](docs/dev/releasing.md); CI builds only from a `vX.Y.Z`
tag.

## License

By contributing, you agree that your contribution is licensed under the
[MIT license](LICENSE) that covers the project.
