# M7 — Packaging & release

**Status:** Planned · **Depends on:** M6 · **Spec:** *Requirements* (platform
packaging, licensing), *Development stack* (packaging, CI), *Milestones → M7*

## Purpose

Ship: final branding (rename from placeholder), signed Android APK/AAB,
Linux tar.gz + AppImage + Arch `.pkg.tar.zst` (PKGBUILD, no AUR), CI build
jobs, and the open-source release (MIT — confirmed).

## Current state

M6 is feature-complete and performant. Branding is still the "Copist"
placeholder (feather icon); no build/packaging pipeline; no release.

## Tasks

- [ ] **T-M7-01** Final branding: decide the real name + icon (placeholder is
  "Copist"/feather; "Inkwell" rejected as an existing product); update app
  labels, launcher icons, window titles, docs. *AC: single source of truth for
  the name across android/, linux/, docs.*
- [ ] **T-M7-02** Android packaging: release-signed APK + AAB; versioning
  (`versionName`/`versionCode`) policy; signing keys via CI secrets (never in
  the repo). *AC: install on a minSdk-35 device; store-ready AAB.*
- [ ] **T-M7-03** Linux packaging: release tar.gz; AppImage (bundled
  offline, Wayland-compatible); Arch `.pkg.tar.zst` built from a PKGBUILD
  (no AUR). *AC: each artifact runs on the target distro; PKGBUILD accepted
  into the repo.*
- [ ] **T-M7-04** CI builds: GitHub Actions build jobs — APK/AAB (android
  toolchain) and Linux artifacts (tar.gz, AppImage, pkg) on tags; artifact
  upload. *AC: pushing a tag produces all artifacts in CI.*
- [ ] **T-M7-05** Open-source release: repo hygiene (README final, LICENSE =
  MIT confirmed, contributing doc), issue/PR templates. *AC: repo is
  fork-and-build ready.*
- [ ] **T-M7-06** Release: tag `vX.Y.0`, changelog, publish artifacts
  (APK/AAB, tar.gz, AppImage, pkg). *AC: a clean install from each artifact
  passes the integration E2E.*

## Technical design

- **Builds:** `flutter build appbundle` / `flutter build apk --release`
  (M7-02); Linux: `flutter build linux --release` → tar.gz (M7-03), AppImage
  from the release build (tooling choice: `mage` or `linuxdeploy` — decide in
  T-M7-03), PKGBUILD packages the tar.gz (M7-03).
- **CI:** extend the M0 workflow — build jobs on `v*` tags, `actions/upload-
  artifact` for outputs; signing secrets from the repo's CI secrets.
- **Versioning:** single `pubspec.yaml` version drives all platforms
  (`flutter build` reads it); changelog maintained per release.
- **Repo layout:** no source changes expected — M7 is build/release work over
  the M6 codebase.

## Exit criteria

- A signed Android APK/AAB installs and passes the on-device E2E.
- Linux tar.gz + AppImage + Arch pkg each run on their targets.
- A tag triggers a full CI build producing all artifacts.
- The repo is releasable as open source under MIT.

## Risks / open questions

- AppImage tooling (`mage` vs `linuxdeploy`) — decide in T-M7-03; both are
  offline-capable.
- Code-signing availability per platform (Linux AppImage signing is
  optional; Android signing keys are the critical path) — set up CI secrets
  early in T-M7-02.
- Arch PKGBUILD packaging of a Flutter app (bundle the whole build dir) —
  verify size/performance of the pkg; keep the PKGBUILD in-repo.
- Final rename (T-M7-01) touches app labels/icons/docs — coordinate with the
  README and any user-facing strings before freezing.
