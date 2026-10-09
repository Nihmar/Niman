import 'package:meta/meta.dart';

/// A path both sides changed differently, left untouched for the merge
/// (docs/records/sync.md, "Conflicts").
@immutable
final class SyncConflict {
  /// A conflict at [path].
  const new({
    required this.path,
    required this.localSha256,
    required this.remoteSha256,
    this.baseVersion,
  });

  /// The library-relative path.
  final String path;

  /// The local content's sha256.
  final String localSha256;

  /// The remote content's sha256.
  final String remoteSha256;

  /// The pinned history version both came from, when there is one.
  final int? baseVersion;

  @override
  String toString() => 'conflict $path (base ${baseVersion ?? 'none'})';
}
