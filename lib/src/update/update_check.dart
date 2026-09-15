/// Latest-release parsing and check outcome (issue #81: auto-update).
///
/// The network fetch itself (off the UI isolate) lands with the platform
/// appliers; this file stays pure and unit-tested: it decodes the
/// `GET /repos/Nihmar/Niman/releases/latest` JSON payload and compares its
/// tag against the running version.
library;

import 'package:niman/src/update/app_version.dart';
import 'package:niman/src/update/release_asset.dart';

/// The latest published GitHub release.
final class LatestRelease {
  /// Creates a release with its [version] and downloadable [assets].
  const new({required this.version, required this.assets});

  /// Decodes a `releases/latest` JSON payload (already `jsonDecode`d).
  /// Throws [FormatException] when the tag is missing or not `X.Y.Z`.
  factory fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String?;
    final version = tag == null ? null : AppVersion.tryParse(tag);
    if (version == null) {
      throw FormatException('release has no parseable tag_name: "$tag"');
    }
    final rawAssets = json['assets'];
    final assets = <ReleaseAsset>[];
    if (rawAssets is List) {
      for (final entry in rawAssets) {
        if (entry is! Map<String, dynamic>) continue;
        final name = entry['name'] as String?;
        final url = entry['browser_download_url'] as String?;
        if (name == null || url == null) continue;
        assets.add(ReleaseAsset(name: name, downloadUrl: url));
      }
    }
    return LatestRelease(version: version, assets: assets);
  }

  /// The release version, from the `vX.Y.Z` tag.
  final AppVersion version;

  /// The downloadable files attached to the release.
  final List<ReleaseAsset> assets;
}

/// The outcome of comparing [LatestRelease] against the running version.
sealed class UpdateCheck {
  const new();
}

/// A newer release exists: offer its asset for download.
final class UpdateAvailable extends UpdateCheck {
  /// Creates an available update for [version] downloadable at [asset].
  const new({required this.version, required this.asset});

  /// The newer release version.
  final AppVersion version;

  /// The per-platform asset selected for this device.
  final ReleaseAsset asset;
}

/// The running version is current (or newer, e.g. a dev build).
final class UpToDate extends UpdateCheck {
  /// Creates an up-to-date outcome for [version].
  const new(this.version);

  /// The version that was checked.
  final AppVersion version;
}

/// Compares [release] against [current] and selects this device's asset:
/// [selectAndroidAsset] on Android, [selectWindowsAsset] on Windows,
/// [selectLinuxAsset] with the installed [linuxVariant] on Linux.
/// Returns [UpToDate] when nothing is newer or no asset matches (the
/// Linux picker case surfaces through [linuxAssets] instead).
UpdateCheck checkForUpdate({
  required LatestRelease release,
  required AppVersion current,
  required bool isAndroid,
  required bool isWindows,
  required LinuxVariant linuxVariant,
}) {
  if (release.version.compareTo(current) <= 0) {
    return UpToDate(current);
  }
  final ReleaseAsset? asset;
  if (isAndroid) {
    asset = selectAndroidAsset(release.assets);
  } else if (isWindows) {
    asset = selectWindowsAsset(release.assets);
  } else {
    asset = selectLinuxAsset(release.assets, linuxVariant);
  }
  if (asset == null) return UpToDate(current);
  return UpdateAvailable(version: release.version, asset: asset);
}
