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
import 'package:niman/src/markdown/block_changes.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Where a scan handed over by the editor stands in the line of them: the
/// hand-over it follows (`since`, null for the first), its own mark
/// (`token`), and what the edits did to the block list in between — null
/// when that was not worth keeping ([BlockChanges.limit]).
///
/// The marks are objects, compared by identity, so two editors' hand-overs
/// can never be taken for one another.
typedef ScanChanges = ({
  Object? since,
  Object token,
  List<BlockChange>? stretches,
});

/// A note's blocks and definitions, as of one revision of its buffer.
final class DocumentScan {
  /// Wraps a finished scan.
  const new({
    required this.blocks,
    required this.scope,
    required this.revision,
    this.changes,
  });

  /// Scans [buffer] here, now.
  factory of(SourceBuffer buffer) => DocumentScan(
    blocks: BlockScanner(buffer).index.blocks,
    scope: DocumentScope.scan(buffer, buffer.revision),
    revision: buffer.revision,
  );

  /// Scans the top of [buffer] here, now: its first [lines] lines, and on to
  /// the next blank line so the last block is not cut — up to [lines] more.
  ///
  /// What a pane draws while the whole note is scanned in the background:
  /// the blocks of the top are the whole note's, since a block is decided
  /// by the lines above it, and the rest arrives with the full scan. Only
  /// the definitions are the top's alone — a citation whose definition is
  /// further down reads as text until then.
  factory head(SourceBuffer buffer, int lines) {
    final total = buffer.lineCount;
    var end = lines < total ? lines : total;
    final limit = end + lines < total ? end + lines : total;
    while (end < limit && buffer.lineAt(end).trim().isNotEmpty) {
      end++;
    }
    final top = end < total
        ? SourceBuffer.fromText(buffer.substring(0, buffer.offsetOfLine(end)))
        : buffer;
    return DocumentScan(
      blocks: BlockScanner(top).index.blocks,
      scope: DocumentScope.ofLines(
        buffer,
        buffer.revision,
        Iterable<int>.generate(end),
      ),
      revision: buffer.revision,
    );
  }

  /// The blocks, in line order.
  final List<Block> blocks;

  /// The link and footnote definitions.
  final DocumentScope scope;

  /// The buffer revision scanned.
  final int revision;

  /// For a scan the editor handed over, what changed since its last one;
  /// null for a scan made from the text.
  final ScanChanges? changes;
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
