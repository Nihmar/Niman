# Release process

CI builds **only from version tags** (`vX.Y.Z`, no suffixes).
Workflow: `.github/workflows/release.yml`.

## Cutting a release

1. Add the release's entries to `CHANGELOG.md` under a new
   `## [X.Y.Z] - YYYY-MM-DD` heading, starting the section with its
   headline on a line of its own (see [The release title](#the-release-title)),
   bump `version:` in `pubspec.yaml`, and raise the `+N` build number on the
   same line (`0.0.9+6`). The `+N` is Android's `versionCode`: the installer
   refuses a package that does not raise it, so it goes up on every tag,
   including a re-cut of a version already released. Commit the two
   together. The changelog ships inside the build and feeds the in-app
   changelog (the launch dialog after an update and the screen under
   Settings → About), so it must describe the version the tag is about,
   not the next one.
2. Tag: `git tag vX.Y.Z`.
3. Push: `git push origin vX.Y.Z`.

The workflow builds all platforms and publishes artifacts on the tag's
GitHub Release page. To re-run: delete the tag locally and remotely,
fix, tag again.

### The release title

The GitHub Release takes its title from the changelog. The first line of
the version's section that is neither a `###` heading nor a bullet is the
title: write it as a short headline, one line, before the sections.
Surrounding `**`/`_` are stripped, so it may be bold.

```markdown
## [0.0.9] - 2026-09-25

Books, a theme of your own, and one Markdown surface.

### Added
- …
```

A section without such a line falls back to `Niman <version>`. The tag
stays `vX.Y.Z`; only the release's displayed name changes, and it can be
corrected after the fact with `gh release edit` without re-tagging.

## Artifacts

| Platform | Files |
|----------|-------|
| Android | `.apk`, testing `.apk` (issue #106) |
| Linux | `.tar.gz`, `.AppImage`, `.pkg.tar.zst` (Arch) |
| Windows | Inno Setup installer (`.exe`), portable `.zip` |

See `packaging/` for AppImage, Arch pkg, and Inno Setup details.

## Signing

- **Android:** signed with the release key, read from the Actions secrets
  `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD` (the workflow picks them
  up automatically). Without them the build falls back to the debug key,
  which changes from run to run — Android then refuses to update over the
  last install, which is what happened to every release up to v0.0.7
  ([#160](https://github.com/Nihmar/Niman/issues/160)). Never ship a
  release from a debug-signed build.
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

Rebuild the **beta** (testing) flavor and report outcome + artifact path
only (no raw logs). It installs beside the official app and never touches
the installed release; the official artifacts are built only when asked:

- Linux: `./scripts/niman.sh apk beta` / `./scripts/niman.sh linux beta`
- Windows: `scripts\niman.bat apk beta` / `scripts\niman.bat windows beta`

Repo-root `niman-release.apk` / `niman-linux-x64.tar.gz` are gitignored
build artifacts, not sources.
