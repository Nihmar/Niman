import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/history/snapshot_policy.dart';

/// Whether the file a save is about to replace was written by somebody
/// other than this app (#1055), and how that was told.
///
/// The stamps decide when they can: a file that matches what the editor last
/// saw, or what the app's writer last left, is not a stranger's. When it
/// matches neither, the bytes decide: a file that still hashes to the app's
/// last write is that write, whatever its modification time now says. Only
/// a file whose bytes differ from it is another program's.
@immutable
final class ExternalWriteCheck {
  const new _({required this.foreign, this.bytes, this.note});

  /// Checks [note] (which exists) against what [asked] believes of it.
  factory of(File note, SnapshotRequest asked) {
    final expected = asked.expected;
    if (expected == null) return const ExternalWriteCheck._(foreign: false);
    final lastWritten = asked.lastWritten;
    final now = DiskStamp.of(note.path);
    if (expected.sameAs(now) || (lastWritten?.sameAs(now) ?? false)) {
      return const ExternalWriteCheck._(foreign: false);
    }
    final stamps =
        'on disk ${_describe(now)}, editor saw ${_describe(expected)}, '
        'app wrote ${_describe(lastWritten)}';
    final digest = asked.lastWrittenSha256;
    // A different size is different bytes: nothing to read to know it.
    if (digest == null ||
        lastWritten == null ||
        now?.size != lastWritten.size) {
      return ExternalWriteCheck._(foreign: true, note: '$stamps; foreign');
    }
    final bytes = note.readAsBytesSync();
    final own = sha256.convert(bytes).toString() == digest;
    return ExternalWriteCheck._(
      foreign: !own,
      bytes: bytes,
      note: own
          ? "$stamps; same bytes as the app's last write"
          : "$stamps; bytes differ from the app's last write",
    );
  }

  /// Whether the file holds a version somebody else wrote.
  final bool foreign;

  /// The file's bytes, when the check had to read them: the snapshot keeps
  /// them rather than reading the file twice.
  final List<int>? bytes;

  /// A log-ready account of a check the stamps could not settle; null when
  /// they did.
  final String? note;

  static String _describe(DiskStamp? stamp) => stamp == null
      ? 'nothing'
      : '${stamp.size} b @ ${stamp.modified.toUtc().toIso8601String()}';
}
