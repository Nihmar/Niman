/// The whole-note scans, off the UI isolate.
///
/// A note's first look costs two passes over every line: the block scan and
/// the document's definitions. On a 246 MB note that was 2.2 s and 0.65 s of a
/// frozen window before the preview's first frame (0.0.9 stress test). Both
/// are pure functions of the lines, so they run in an isolate; sending the
/// buffer there copies its line list, not its text — a string is shared
/// between isolates of a group — which measured 100 ms against 1.9 s of scan.
/// What comes back is handed over without a copy (`Isolate.exit`).
///
/// Only the first look moves: the per-block parse of what the viewport shows
/// stays where it is, a few milliseconds a frame.
library;

import 'dart:isolate';

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A note's blocks and definitions, as of one revision of its buffer.
final class DocumentScan {
  /// Wraps a finished scan.
  const new({
    required this.blocks,
    required this.scope,
    required this.revision,
  });

  /// Scans [buffer] here, now.
  factory of(SourceBuffer buffer) => DocumentScan(
    blocks: BlockScanner(buffer).index.blocks,
    scope: DocumentScope.scan(buffer, buffer.revision),
    revision: buffer.revision,
  );

  /// The blocks, in line order.
  final List<Block> blocks;

  /// The link and footnote definitions.
  final DocumentScope scope;

  /// The buffer revision scanned.
  final int revision;
}

/// Scans [buffer] as it is now in an isolate, and answers with the scope's
/// source set to [buffer] itself rather than the isolate's copy of it.
///
/// The copy is taken by the call: an edit made while the scan runs is not in
/// the answer, whose [DocumentScan.revision] says which one is.
Future<DocumentScan> scanInBackground(SourceBuffer buffer) async {
  final scan = await Isolate.run(() => DocumentScan.of(buffer));
  return DocumentScan(
    blocks: scan.blocks,
    scope: scan.scope.on(buffer, scan.revision),
    revision: scan.revision,
  );
}
