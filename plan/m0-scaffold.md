# M0 — Scaffold

**Status:** Done · **Depends on:** — · **Spec:** *Milestones → M0*

## Purpose

A working app skeleton that all later milestones build on: Flutter project with
the project's lint setup, the real (but minimal) app shell, placeholder
branding, CI, test scaffolding, and the seeded dependency stack. No feature
logic.

## Current state

Done (verified in repo):

- Flutter project with Android (Kotlin-DSL Gradle) + Linux runners.
- MIT `LICENSE`, README, and the spec document.
- Default template app (`lib/main.dart` counter) + its smoke test.

Missing for M0:

- `very_good_analysis` (only default `flutter_lints` active).
- `lib/src/` module layout (design.md).
- App shell + placeholder branding (still "Flutter Demo" counter).
- Android `minSdk 35` (currently Flutter default via `flutter.minSdkVersion`).
- GitHub Actions CI (no `.github/`).
- `integration_test/` (does not exist).
- Core dependencies from the stack (only `cupertino_icons`).

## Tasks

- [x] **T-M0-01** Adopt `very_good_analysis`: add to `dev_dependencies`,
  switch `analysis_options.yaml` include, fix all resulting lints.
  *AC: `flutter analyze --fatal-infos` is clean under `very_good_analysis`.*
- [x] **T-M0-02** Seed `lib/src/` layout: create `main.dart` → `src/app.dart`
  (`MaterialApp` root) plus `src/core/logging.dart` and `src/core/errors.dart`.
  Remaining modules are created by their owning milestone (first task in each
  file). *AC: layout root exists, analyze clean.*
- [x] **T-M0-03** App shell: replace the counter app with the Copist shell —
  placeholder home screen showing app name, feather-icon placeholder, and a
  "no library set" state (real library UI arrives in M1). Riverpod wired as the
  state tool (app-level state provider). *AC: builds and launches on Android
  and Linux; "Flutter Demo" gone.*
- [x] **T-M0-04** Placeholder branding: app label "Copist", feather icon as
  placeholder launcher icon, theme seed color. Note in code/README that name +
  icon will be renamed before release (first candidate "Inkwell" rejected —
  existing product). *AC: label/icon visible on both platforms.*
- [x] **T-M0-05** Android `minSdk 35`: set `minSdk = 35` in
  `android/app/build.gradle.kts` (compile/target per Flutter defaults).
  *AC: release build compiles; manifest reports minSdk 35.*
- [x] **T-M0-06** GitHub Actions CI: `.github/workflows/ci.yml` on
  push/PR — jobs: `flutter analyze --fatal-infos` and `flutter test`; Flutter
  stable channel, pub cache caching. *AC: workflow runs green on main.*
- [x] **T-M0-07** Test scaffolding: replace counter smoke test with a shell
  smoke test (app boots, shows placeholder branding); create `integration_test/`
  with a first on-device boot test. *AC: unit + widget + integration tests
  green locally and in CI.*
- [x] **T-M0-08** Seed core dependencies in `pubspec.yaml`: `riverpod`, `drift`,
  `path_provider`, `flutter_markdown`, `katex_flutter`, `flutter_highlight`,
  `flutter_secure_storage`, `very_good_analysis`. *AC: `flutter pub get`
  resolves on stable; CI verify job passes.*

### Package substitutions (recorded at M0)

- **`katex_flutter` → `katex_dart` (^0.1.1):** the pub.dev `katex_flutter`
  package is a 2020-era, non-null-safe relic and cannot resolve on current
  Flutter. `katex_dart` is the actively maintained pure-Dart port of KaTeX
  (2026-07); spec math coverage still verified in **M2** (T-M2-03).
- **`flutter_markdown` → `flutter_markdown_plus` (^1.0.12):** `flutter_markdown`
  is discontinued on pub.dev, replaced by `flutter_markdown_plus` (active
  successor, same renderer lineage).
- **Android `compileSdk = 37`** (above the Flutter default of 36) because
  `flutter_secure_storage` requires compiling against API 37; `targetSdk`
  stays at the Flutter default.

## Technical design

See [design.md](design.md) → *Module layout*. M0 owns only:

```
lib/main.dart            → src/app.dart (MaterialApp, theme, root provider scope)
lib/src/core/logging.dart
lib/src/core/errors.dart
```

Shell state: a single Riverpod provider holding app state
(`library path: null` at M0). Theme: system-brightness Material theme only;
the full brightness × palette system lands in M6.

CI matrix: `ubuntu-latest`; Android tooling only for analysis/testing at M0 —
build jobs are added in M7.

## Exit criteria

- `flutter analyze --fatal-infos` and `flutter test` green in CI.
- App builds and launches on **Android (minSdk 35)** and **Linux** with
  placeholder branding; counter app gone.
- `integration_test/` boot test runs on at least one device.
- All T-M0 tasks checked off.

## Risks / open questions

- `very_good_analysis` strictness may flag generated/template code — expect a
  small cleanup pass.
- `katex_flutter` is pinned now but explicitly verified against spec math
  coverage in **M2** (per spec).
- `drift` codegen (`build_runner`) needs to stay out of CI until M1 adds the
  schema.
- Flutter stable version drift: pin the CI channel; re-verify SDK constraint
  in `pubspec.yaml` (`^3.13.2`).
