import 'dart:io';

import 'package:meta/meta.dart';

/// The size and the modification time of one of a pack's files, as the
/// sidecar index recorded them when it was built.
///
/// A sidecar whose stamps differ from the files' own is stale: the pack
/// was replaced (a new `dictionary-pack-N`), and the offsets it holds
/// point into a file that is no longer there.
@immutable
final class IndexStamp {
  /// A file of [size] bytes last changed at [modifiedMs] (milliseconds
  /// since the epoch).
  const new(this.size, this.modifiedMs);

  /// What a file that does not exist stamps (a pack may have no `.syn`).
  static const IndexStamp absent = IndexStamp(0, 0);

  /// The stamp of the file at [path].
  static Future<IndexStamp> of(String path) async {
    final stat = await File(path).stat();
    if (stat.type == FileSystemEntityType.notFound) return absent;
    return IndexStamp(stat.size, stat.modified.millisecondsSinceEpoch);
  }

  /// The file's length in bytes.
  final int size;

  /// The file's modification time, in milliseconds since the epoch.
  final int modifiedMs;

  @override
  bool operator ==(Object other) =>
      other is IndexStamp &&
      other.size == size &&
      other.modifiedMs == modifiedMs;

  @override
  int get hashCode => Object.hash(size, modifiedMs);

  @override
  String toString() => 'IndexStamp($size, $modifiedMs)';
}
