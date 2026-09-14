# Release process

CI builds **only from version tags** (`vX.Y.Z`, no suffixes).
Workflow: `.github/workflows/release.yml`.

## Cutting a release

1. Bump `version:` in `pubspec.yaml` and commit.
2. Tag: `git tag vX.Y.Z`.
3. Push: `git push origin vX.Y.Z`.

The workflow builds all platforms and publishes artifacts on the tag's
GitHub Release page. To re-run: delete the tag locally and remotely,
fix, tag again.

## Artifacts

| Platform | Files |
|----------|-------|
| Android | `.apk` |
| Linux | `.tar.gz`, `.AppImage`, `.pkg.tar.zst` (Arch) |
| Windows | Inno Setup installer (`.exe`), portable `.zip` |

See `packaging/` for AppImage, Arch pkg, and Inno Setup details.

## Signing

- **Android:** debug-signed until release keys are added as Actions
  secrets (the workflow picks them up automatically).
- **Linux / Windows:** unsigned, as planned for v1.

## After each commit (local rebuild)

Rebuild and report outcome + artifact path only (no raw logs):

- Linux: `./scripts/niman.sh apk` / `./scripts/niman.sh linux`
- Windows: `scripts\niman.bat apk` / `scripts\niman.bat windows`

Repo-root `niman-release.apk` / `niman-linux-x64.tar.gz` are gitignored
build artifacts, not sources.
