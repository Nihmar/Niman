# Release process

CI builds **only from version tags** (`vX.Y.Z`, no suffixes).
Workflow: `.github/workflows/release.yml`.

## Cutting a release

1. Add the release's entries to `CHANGELOG.md` under a new
   `## [X.Y.Z] - YYYY-MM-DD` heading, and bump `version:` in
   `pubspec.yaml`; commit both together. The file ships inside the build
   and feeds the in-app changelog (the launch dialog after an update and
   the screen under Settings → About), so it must describe the version
   the tag is about, not the next one.
2. Tag: `git tag vX.Y.Z`.
3. Push: `git push origin vX.Y.Z`.

The workflow builds all platforms and publishes artifacts on the tag's
GitHub Release page. To re-run: delete the tag locally and remotely,
fix, tag again.

## Artifacts

| Platform | Files |
|----------|-------|
| Android | `.apk`, testing `.apk` (issue #106) |
| Linux | `.tar.gz`, `.AppImage`, `.pkg.tar.zst` (Arch) |
| Windows | Inno Setup installer (`.exe`), portable `.zip` |

See `packaging/` for AppImage, Arch pkg, and Inno Setup details.

## Signing

- **Android:** debug-signed until release keys are added as Actions
  secrets (the workflow picks them up automatically).
- **Linux / Windows:** unsigned, as planned for v1.

## Testing build (Android)

Every Android build is also produced as a testing build: the release
pipeline plus the `beta` product flavor, whose separate application ID
(`dev.niman.niman.beta`) and launcher label ("Niman (Testing)") let it
install side by side with the official app. The testing build is
release-equivalent (same build type, signing, SDK, optimizations); its
update management is disabled in full — no Updates settings section,
no scheduler, no polling — since it is sideloaded and never on the
release channel. See "Testing build" in `docs/dev/building.md`.

## After each commit (local rebuild)

Rebuild and report outcome + artifact path only (no raw logs):

- Linux: `./scripts/niman.sh apk` / `./scripts/niman.sh linux`
- Windows: `scripts\niman.bat apk` / `scripts\niman.bat windows`

Repo-root `niman-release.apk` / `niman-linux-x64.tar.gz` are gitignored
build artifacts, not sources.
