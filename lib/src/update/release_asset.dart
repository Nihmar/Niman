/// GitHub release asset mapping (issue #81: auto-update).
///
/// Asset file names are fixed by `.github/workflows/release.yml`. Only
/// Android updates itself, from `niman-<V>-android.apk` (the official
/// build; a testing `-android-testing.apk` is attached to the workflow run,
/// never to the release page — see `selectAndroidAsset`). A computer's
/// assets are downloaded from the release page by hand (#1270).
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

/// Selects the Android update asset: the release's **official** `.apk`.
///
/// A release page used to carry a testing build beside it
/// (`niman-<V>-android-testing.apk`, issue #106), whose application ID is
/// `dev.niman.niman.beta` and which installs *beside* this app instead of
/// updating it. GitHub lists assets in name order, `-android-testing.apk`
/// before `-android.apk`, so "the first `.apk`" handed the updater the
/// testing build (0.0.10). Only the official `.apk` is ever selected: a
/// testing APK cannot update this install, so a page carrying nothing but
/// testing builds has no update to offer at all.
/// Returns null when the release carries no official APK.
ReleaseAsset? selectAndroidAsset(List<ReleaseAsset> assets) {
  for (final asset in assets) {
    if (!asset.name.endsWith('.apk')) continue;
    if (asset.name.contains('-testing')) continue;
    return asset;
  }
  return null;
}
