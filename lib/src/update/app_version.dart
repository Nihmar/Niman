/// The app version (issue #81: auto-update from GitHub Releases).
///
/// Releases are cut from tags `vX.Y.Z` (see `docs/dev/releasing.md`); the
/// checker compares the latest release tag against the running app version,
/// so both sides parse through [AppVersion.parse].
library;

import 'package:meta/meta.dart';

/// A `X.Y.Z` semantic version, comparable so the update checker can tell
/// whether a GitHub release tag is newer than the running app.
@immutable
final class AppVersion implements Comparable<AppVersion> {
  /// Creates a version from its numeric parts.
  const new(this.major, this.minor, this.patch);

  /// Parses [raw], accepting an optional leading `v` and surrounding
  /// whitespace (`v1.2.3`, `1.2.3`). Throws [FormatException] otherwise.
  factory parse(String raw) {
    var text = raw.trim();
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1);
    }
    final parts = text.split('.');
    if (parts.length != 3) {
      throw FormatException('expected X.Y.Z, got "$raw"');
    }
    final numbers = parts.map(int.tryParse).toList();
    if (numbers.any((n) => n == null || n < 0)) {
      throw FormatException('expected X.Y.Z, got "$raw"');
    }
    return AppVersion(numbers[0]!, numbers[1]!, numbers[2]!);
  }

  /// Tries [AppVersion.parse], returning null instead of throwing.
  static AppVersion? tryParse(String raw) {
    try {
      return AppVersion.parse(raw);
    } on FormatException {
      return null;
    }
  }

  /// The major component.
  final int major;

  /// The minor component.
  final int minor;

  /// The patch component.
  final int patch;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
