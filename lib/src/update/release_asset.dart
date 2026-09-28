/// GitHub release asset mapping (issue #81: auto-update).
///
/// Asset file names are fixed by `.github/workflows/release.yml`:
///
/// - Android: `niman-<V>-android.apk` (the official build; a testing
///   `-android-testing.apk` is attached to the workflow run, never to the
///   release page — see `selectAndroidAsset`)
/// - Linux: `niman-<V>-linux-x64.tar.gz`, `niman-<V>-linux-x64.AppImage`,
///   `niman-<V>-....pkg.tar.zst` (Arch)
/// - Windows: `niman-<V>-windows-x64-setup.exe` (installer),
///   `niman-<V>-windows-x64.zip` (portable, never auto-applied)
library;

/// One downloadable file attached to a GitHub release.
final class ReleaseAsset {
  /// Creates an asset with its release file [name], [downloadUrl]
  /// (`browser_download_url` in the GitHub API) and published [digest].
  const new({required this.name, required this.downloadUrl, this.digest});

  /// The file name as published on the release page.
  final String name;

  /// The direct download URL.
  final String downloadUrl;

  /// The checksum GitHub published for the file, `sha256:<hex>` (the
  /// releases API's `digest` field); null when the surface returned none
  /// (issue #384). Carried so the downloaded bytes can be checked before
  /// the artifact is offered or applied.
  final String? digest;

  /// The expected lowercase hex sha256 parsed out of [digest]; null when
  /// none was published or its algorithm is not sha256, i.e. there is
  /// nothing trustworthy to verify the download against.
  String? get expectedSha256 {
    final raw = digest;
    if (raw == null) return null;
    const prefix = 'sha256:';
    if (!raw.startsWith(prefix)) return null;
    final hex = raw.substring(prefix.length).toLowerCase();
    return hex.isEmpty ? null : hex;
  }
}

/// Which Linux package variant is installed, so the checker downloads the
/// matching asset instead of silently self-replacing the install.
enum LinuxVariant {
  /// Installed from / runs as an AppImage.
  appImage,

  /// Installed from the `.tar.gz` bundle.
  tarball,

  /// Installed from the Arch `.pkg.tar.zst` package.
  archPackage,

  /// Variant unknown: the user picks from the available Linux assets.
  unknown,
}

/// Selects the Android update asset: the release's **official** `.apk`.
///
/// A release page used to carry a testing build beside it
/// (`niman-<V>-android-testing.apk`, issue #106), whose application ID is
/// `dev.niman.niman.beta` and which installs *beside* this app instead of
/// updating it. GitHub lists assets in name order, `-android-testing.apk`
/// before `-android.apk`, so "the first `.apk`" handed the updater the
/// testing build (0.0.10). The official one is the one that is not a
/// testing build; a page carrying nothing else still answers with what it
/// has, so an old release stays updatable.
/// Returns null when the release carries no APK.
ReleaseAsset? selectAndroidAsset(List<ReleaseAsset> assets) {
  ReleaseAsset? first;
  for (final asset in assets) {
    if (!asset.name.endsWith('.apk')) continue;
    first ??= asset;
    if (!asset.name.contains('-testing')) return asset;
  }
  return first;
}

/// Selects the Windows update asset: the Inno Setup installer
/// (`-windows-x64-setup.exe`). The portable `.zip` is never auto-applied.
/// Returns null when the release carries no installer.
ReleaseAsset? selectWindowsAsset(List<ReleaseAsset> assets) {
  for (final asset in assets) {
    if (asset.name.endsWith('-setup.exe')) return asset;
  }
  return null;
}

/// Selects the Linux update asset matching the installed [variant]:
/// `.AppImage`, `.tar.gz`, or `.pkg.tar.zst`. For [LinuxVariant.unknown]
/// (or when the matching file is missing) returns null so the caller can
/// offer the user a picker over [linuxAssets] instead.
ReleaseAsset? selectLinuxAsset(
  List<ReleaseAsset> assets,
  LinuxVariant variant,
) {
  final suffix = switch (variant) {
    LinuxVariant.appImage => '.AppImage',
    LinuxVariant.tarball => '.tar.gz',
    LinuxVariant.archPackage => '.pkg.tar.zst',
    LinuxVariant.unknown => null,
  };
  if (suffix == null) return null;
  for (final asset in assets) {
    if (asset.name.endsWith(suffix)) return asset;
  }
  return null;
}

/// Every Linux asset of a release, for the variant picker shown when the
/// installed variant is unknown.
List<ReleaseAsset> linuxAssets(List<ReleaseAsset> assets) => assets
    .where(
      (asset) =>
          asset.name.endsWith('.AppImage') ||
          asset.name.endsWith('.tar.gz') ||
          asset.name.endsWith('.pkg.tar.zst'),
    )
    .toList();
