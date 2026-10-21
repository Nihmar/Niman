/// What a snapshot did, for the log (#1148): `snapshotBeforeWrite`'s
/// answer.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/history/external_write_check.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/snapshot_policy.dart';

/// What `snapshotBeforeWrite` did.
@immutable
final class SnapshotOutcome {
  /// Describes one snapshot attempt.
  const new({
    required this.decision,
    this.version,
    this.rotated = const [],
    this.external,
    this.elapsedMs = 0,
    this.keepMs = 0,
    this.manifestMs = 0,
  });

  /// Whether a version was taken, and why.
  final SnapshotDecision decision;

  /// The version written, when one was.
  final HistoryVersion? version;

  /// The version numbers rotation deleted.
  final List<int> rotated;

  /// How the external check was settled when the stamps alone could not
  /// ([ExternalWriteCheck.note]): the stamps compared and what the bytes
  /// said. Null when they agreed or nothing was expected.
  final String? external;

  /// Time spent, in milliseconds.
  final int elapsedMs;

  /// Of [elapsedMs], the version's object and the log's line, when a
  /// version was taken. Before #1148 they were a whole copy and a whole
  /// manifest, each written, flushed and renamed: 85 ms at the median on a
  /// tablet, as long for 10 KB as for 1.5 MB (device log, 2026-10-20).
  final int keepMs;

  /// See [keepMs].
  final int manifestMs;

  /// A log-ready summary.
  String describe(String rel) {
    final buffer = StringBuffer('snapshot "$rel": $decision');
    final v = version;
    if (v != null) buffer.write(' -> v${v.number} (${v.size} b)');
    if (rotated.isNotEmpty) {
      buffer.write(', rotated out ${rotated.map((n) => 'v$n').join(', ')}');
    }
    final checked = external;
    if (checked != null) buffer.write(' [external check: $checked]');
    buffer.write(' in $elapsedMs ms');
    if (v != null) buffer.write(' (object $keepMs, log $manifestMs)');
    return buffer.toString();
  }
}
