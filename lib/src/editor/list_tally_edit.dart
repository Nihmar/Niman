/// Placing a tally in a Markdown document (#136).
///
/// Between the counting (`list_tally.dart`) and the source editor: finds
/// the list the caret is in, finds the block a previous run left after
/// it, and splices the new rows in. Pure text in, [MarkdownEdit] out, so
/// the whole of where-the-block-goes is testable without an editor.
///
/// The WYSIWYG does not come through here — it has the Quill block at
/// the caret and does not need to find anything by line — but it does
/// use the same `list_tally.dart` underneath, so the two surfaces count
/// alike even though they place alike by different means.
library;

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/list_tally.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The list a tally would count and the block it would write.
@immutable
final class TallyTarget {
  /// Creates a target.
  const new({
    required this.sourceStart,
    required this.sourceEnd,
    required this.rows,
    required this.blockStart,
    required this.blockEnd,
    required this.indent,
  });

  /// The first line of the source list.
  final int sourceStart;

  /// One past the last line of the source list.
  final int sourceEnd;

  /// The source list's items, markers and task boxes stripped.
  final List<String> rows;

  /// The first line of the previous run's block, or where a new one
  /// would go when there is none.
  final int blockStart;

  /// One past the last line of the previous run's block; equal to
  /// [blockStart] when there is no previous block.
  final int blockEnd;

  /// The source list's indent, which the generated rows take too.
  final int indent;

  /// Whether a previous block is being replaced rather than a new one
  /// written. The sheet's button reads Update rather than Insert.
  bool get replaces => blockEnd > blockStart;
}

/// A list item's marker run, with the task box that may follow it.
({int contentStart, bool isItem}) _itemStart(StyledLine line) {
  var start = -1;
  for (final token in line.tokens) {
    if (token.kind == TokenKind.listMarker || token.kind == TokenKind.taskBox) {
      if (token.end > start) start = token.end;
    }
  }
  if (start < 0) return (contentStart: 0, isItem: false);
  // The space after the marker belongs to the marker, not to the value.
  if (start < line.text.length && line.text.codeUnitAt(start) == 0x20) {
    start++;
  }
  return (contentStart: start, isItem: true);
}

/// Whether [line] is a row of a source list.
///
/// A generated row never is, even with no blank line between it and the
/// list above: the block's shape is what tells the two apart, which is
/// what lets a re-run count the list rather than count the counts.
bool _isSourceRow(StyledLine line) =>
    _itemStart(line).isItem && parseTallyLine(line.text) == null;

/// Whether [blocks] hold a list item at all.
///
/// The question the tools sheet asks before it offers the count: the sheet
/// lists every tool and greys the ones that cannot run, so answering it by
/// reading the note meant joining it and tokenizing it whole
/// ([tallyTargetsIn]) every time the sheet opened — 190 ms of join and a
/// whole `HighlightDocument` on the 246 MB note, for a yes or a no. The
/// blocks are the pane's own scan, and the scanner already knows a list item
/// when it makes one ([BlockKind.listItem]).
bool blockList(Iterable<Block> blocks) {
  for (final block in blocks) {
    if (block.kind == BlockKind.listItem) return true;
  }
  return false;
}

/// The blocks of [text], for [blockList].
///
/// The fallback for a note whose pane is not on screen and has no scan of
/// its own: O(note), so only the legacy path takes it.
List<Block> scannedBlocksOf(String text) =>
    BlockScanner(SourceBuffer.fromText(text)).index.blocks;

/// Every list in [text] that can be counted, in document order.
///
/// The sheet needs them all, not just the one under the caret: a note
/// with several lists has to say which one it is about to count, and
/// let the writer say otherwise.
List<TallyTarget> tallyTargetsIn(String text) {
  final lines = HighlightDocument.fromText(text).lines;
  final out = <TallyTarget>[];
  var i = 0;
  while (i < lines.length) {
    if (!_isSourceRow(lines[i])) {
      i++;
      continue;
    }
    final start = i;
    while (i < lines.length && _isSourceRow(lines[i])) {
      i++;
    }
    final end = i;
    // At most one blank line between a list and the block that counts
    // it: further down the note it is somebody else's text.
    var blockStart = end;
    if (blockStart < lines.length && lines[blockStart].text.trim().isEmpty) {
      blockStart++;
    }
    var blockEnd = blockStart;
    while (blockEnd < lines.length &&
        parseTallyLine(lines[blockEnd].text) != null) {
      blockEnd++;
    }
    // A blank line stepped over that led to no block is not part of
    // anything: a new block goes straight under the list.
    if (blockEnd == blockStart) {
      blockStart = end;
      blockEnd = end;
    }
    var indent = 0;
    final first = lines[start].text;
    while (indent < first.length && first.codeUnitAt(indent) == 0x20) {
      indent++;
    }
    out.add(
      TallyTarget(
        sourceStart: start,
        sourceEnd: end,
        rows: <String>[
          for (var j = start; j < end; j++)
            lines[j].text.substring(_itemStart(lines[j]).contentStart).trim(),
        ],
        blockStart: blockStart,
        blockEnd: blockEnd,
        indent: indent,
      ),
    );
    i = blockEnd > end ? blockEnd : end;
  }
  return out;
}

/// The list [line] belongs to, or null when it belongs to none.
///
/// The caret counts as in a list from its first row down to the line
/// after whatever the list already has under it, so running the count
/// from the blank line below it, or from inside the block it wrote last
/// time, still means that list.
TallyTarget? tallyTargetAt(String text, int line) {
  for (final target in tallyTargetsIn(text)) {
    final end = target.blockEnd > target.sourceEnd
        ? target.blockEnd
        : target.sourceEnd;
    if (line >= target.sourceStart && line <= end) return target;
  }
  return null;
}

/// The ticks the previous block at [target] carries, for [tallyList].
Map<String, bool> tallyChecksAt(String text, TallyTarget target) {
  if (!target.replaces) return const <String, bool>{};
  final lines = text.split('\n');
  return tallyChecks(
    lines.sublist(
      target.blockStart.clamp(0, lines.length),
      target.blockEnd.clamp(0, lines.length),
    ),
  );
}

/// [text] with [rows] written at [target], replacing a previous block.
///
/// The caret lands on the first generated row, so the result is on
/// screen rather than somewhere the writer has to go looking for.
MarkdownEdit applyTally({
  required String text,
  required TallyTarget target,
  required List<TallyRow> rows,
}) {
  final lines = text.split('\n');
  final written = <String>[
    for (final row in rows) tallyLine(row, indent: target.indent),
  ];
  final after = target.blockEnd.clamp(0, lines.length);
  final rest = lines.sublist(after);
  final out = <String>[
    ...lines.sublist(0, target.blockStart),
    // A new block stands off the list it counts; a replaced one already
    // has its blank line above it.
    if (!target.replaces) '',
    ...written,
    // Without a blank line under it, the text that follows is a lazy
    // continuation of the last row rather than its own paragraph.
    if (!target.replaces && rest.isNotEmpty && rest.first.trim().isNotEmpty) '',
    ...rest,
  ];
  final newText = out.join('\n');
  var offset = 0;
  final caretLine = target.blockStart + (target.replaces ? 0 : 1);
  for (var i = 0; i < caretLine && i < out.length; i++) {
    offset += out[i].length + 1;
  }
  return MarkdownEdit(
    text: newText,
    selection: TextSelection.collapsed(offset: offset),
  );
}
