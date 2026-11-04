/// What the read view shows: the blocks of the note it scanned, as the
/// entries of its sliver, and the height map over them.
///
/// The map is an estimator (`BlockHeightMap`): the sliver measures the
/// entries it lays out, and the map answers for the ones no frame has
/// reached with what [ReadEntries.estimateOf] says — per kind, at the size
/// the text is read at, and for a side-by-side `columns` block as its
/// columns ([ReadColumnHosts]).
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/column_layout.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/read_code_pieces.dart';
import 'package:niman/src/markdown/render/read_column_hosts.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The read view's entries and their heights.
final class ReadEntries {
  /// The blocks drawn, an entry each: the note's, with its long code blocks
  /// in pieces ([pieces]).
  List<Block> get blocks => _blocks;
  List<Block> _blocks = const <Block>[];

  /// The buffer [blocks] were scanned from: the widget's, or — while a
  /// long note's next revision is scanned in the background — the one
  /// before it, drawn until the scan comes back.
  SourceBuffer? get shown => _shown;
  SourceBuffer? _shown;

  /// The height map over [blocks], or null while there is nothing to draw.
  BlockHeightMap? get heights => _heights;
  BlockHeightMap? _heights;

  /// How many blocks have been built and drawn since [blocks] were taken.
  int built = 0;

  /// Which entries of the block list are pieces of a longer code block, and
  /// where in it.
  final ReadCodePieces pieces = ReadCodePieces();

  /// The note's side-by-side `columns` blocks (#729).
  final ReadColumnHosts hosts = ReadColumnHosts();

  /// Whether the blocks changed since [hosts] last laid them out.
  bool _hostsStale = true;

  /// The width [hosts] last laid the blocks out in.
  double? _hostWidth;

  /// The mark of the editor's hand-over the pane shows, or null when what it
  /// shows was scanned from the text.
  Object? _handed;

  /// The note's theme, as of the last build; a fallback before the first.
  MarkdownTheme get theme => _theme ?? _fallbackTheme;
  set theme(MarkdownTheme value) => _theme = value;
  MarkdownTheme? _theme;

  /// The scaler the note's text is read at, as of the last build.
  TextScaler textScaler = TextScaler.noScaling;

  static const MarkdownTheme _fallbackTheme = MarkdownTheme(
    body: TextStyle(fontSize: 14, height: 1.5),
    heading1: TextStyle(fontSize: 25),
    heading2: TextStyle(fontSize: 21),
    heading3: TextStyle(fontSize: 18),
    heading4: TextStyle(fontSize: 16),
    heading5: TextStyle(fontSize: 14),
    heading6: TextStyle(fontSize: 13),
    code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
    quote: TextStyle(fontSize: 14),
    tableCell: TextStyle(fontSize: 14),
    tableHeader: TextStyle(fontSize: 14),
    link: TextStyle(fontSize: 14),
    wikilink: TextStyle(fontSize: 14),
    tag: TextStyle(fontSize: 14),
    marker: TextStyle(fontSize: 14),
    rule: Color(0xFF888888),
    codeHighlight: <String, TextStyle>{},
    codeBackground: Color(0xFFEEEEEE),
    quoteBar: Color(0xFFCCCCCC),
    tableBorder: Color(0xFFCCCCCC),
    markerDim: Color(0xFF999999),
    blockSpacing: 10,
    listIndentPerLevel: 22,
    quoteIndentPerLevel: 12,
    codePadding: 8,
    quoteBarWidth: 3,
    ruleThickness: 1,
    tableCellPadding: EdgeInsets.all(4),
    lineHeight: 21,
  );

  /// Takes [scan], the blocks of [buffer].
  void show(SourceBuffer buffer, DocumentScan scan) {
    _shown = buffer;
    final changes = scan.changes;
    if (!_follow(changes, scan.blocks)) {
      _blocks = pieces.pieced(scan.blocks);
      // A new map assumes no block side by side, until a layout says.
      hosts.flags = null;
      _hostsStale = true;
      // A block's estimate when a frame first comes near it: every block of
      // the 246 MB stress note, 2.4 M, was most of the frame that showed it.
      _heights = BlockHeightMap.lazy(
        count: _blocks.length,
        estimate: estimateOf,
        estimateSpan: _estimateSpanOf,
      );
      built = 0;
    }
    _handed = changes?.token;
  }

  /// Takes [blocks] by replaying [changes] over the heights the pane has,
  /// when they follow the hand-over it shows: the blocks the edits did not
  /// touch keep the height a frame measured, and only the new ones are
  /// estimated — O(the changes), where a new map was O(blocks), 100–200 ms
  /// on a note of 2 M of them, and forgot every measurement.
  ///
  /// False, with nothing changed, when they do not follow it, were not
  /// worth keeping, or a long code block is involved: the pane lays those
  /// out in pieces that are entries of their own, and the changes count
  /// blocks.
  bool _follow(ScanChanges? changes, List<Block> blocks) {
    final heights = _heights;
    final stretches = changes?.stretches;
    if (changes == null ||
        stretches == null ||
        heights == null ||
        changes.since == null ||
        !identical(changes.since, _handed) ||
        pieces.isNotEmpty) {
      return false;
    }
    var length = heights.length;
    for (final stretch in stretches) {
      length += stretch.inserted - stretch.removed;
      for (
        var at = stretch.start;
        at < stretch.start + stretch.inserted;
        at++
      ) {
        if (ReadCodePieces.isLongCode(blocks[at])) return false;
      }
    }
    if (length != blocks.length) return false;
    // The estimates are asked with the new indices, of the new list.
    _blocks = blocks;
    for (final stretch in stretches) {
      // The side-by-side flags move with the entries; the new ones are
      // ordinary until the next layout says otherwise.
      hosts.flags = hosts.spliced(
        stretch.start,
        stretch.removed,
        stretch.inserted,
      );
      heights.splice(
        stretch.start,
        stretch.removed,
        stretch.inserted,
        estimateOf,
      );
    }
    _hostsStale = true;
    return true;
  }

  /// Holds nothing until the next [show].
  void clear() {
    _shown = null;
    _blocks = const <Block>[];
    pieces.clear();
    _heights = null;
    built = 0;
    _handed = null;
    hosts.flags = null;
    _hostsStale = true;
  }

  /// The index of the block holding source [line], or null when the note has
  /// none that early.
  ///
  /// The blocks tile the note and are ordered by line, so this is the last one
  /// that starts at or before [line]: a line inside a wrapped paragraph, or the
  /// blank line under it, belongs to a block either way.
  int? indexAt(int line) {
    if (_blocks.isEmpty) return null;
    var low = 0;
    var high = _blocks.length - 1;
    if (_blocks[low].startLine > line) return null;
    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (_blocks[middle].startLine <= line) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }
    return low;
  }

  /// Block [index]'s height before it has ever been drawn.
  ///
  /// Per kind rather than one global "pixels per line", because the kinds
  /// differ by more than their line count: a heading is set larger, a
  /// formula taller, and the frontmatter takes no room at all. A code block
  /// is its lines' rows, its fences' rows its padding.
  /// A wrong estimate only costs a jump that lands slightly off before the
  /// block is measured.
  double estimateOf(int index) {
    switch (hosts.flagOf(index)) {
      case ReadColumnHosts.hosted:
        // Drawn in its `columns` block, whose entry is the whole height.
        return 0;
      case ReadColumnHosts.host:
        final theme = _theme ?? _fallbackTheme;
        final run = hosts.runAt(index)!;
        final band = textScaler.scale(theme.divBand);
        return hosts.estimateOf(run, gap, run.closed ? 2 * band : band);
    }
    return _rawEstimateOf(index);
  }

  /// Block [index]'s height as a block of its own, drawn in the note's
  /// run of blocks or in a column's.
  double _rawEstimateOf(int index) {
    final block = _blocks[index];
    final theme = _theme ?? _fallbackTheme;
    // A line at the size the text is read at: the theme's is the text's own.
    final line = textScaler.scale(theme.lineHeight);
    // A footnote definition is drawn with the footnotes ([BlockView]).
    if (block.footnote != 0 && block.kind != BlockKind.blank) return 0;
    return switch (block.kind) {
      BlockKind.frontmatter => 0,
      BlockKind.thematicBreak => line,
      BlockKind.heading => line * 1.3,
      BlockKind.math => block.lineCount * line * 1.6,
      BlockKind.div => textScaler.scale(theme.divBand),
      BlockKind.fencedCode ||
      BlockKind.indentedCode ||
      BlockKind.blank ||
      BlockKind.table ||
      BlockKind.html ||
      BlockKind.listItem ||
      BlockKind.paragraph ||
      BlockKind.quote => block.lineCount * line,
    };
  }

  /// Blocks `[first, end)`'s height before they are asked one by one: a line
  /// each of their lines, O(1) — the lines they span are where the first
  /// starts and the next begins. What [estimateOf] adds by kind (a
  /// heading's size, a formula's height) comes in as the blocks are asked.
  double _estimateSpanOf(int first, int end) {
    final from = _blocks[first].startLine;
    final to = end < _blocks.length
        ? _blocks[end].startLine
        : _blocks[end - 1].endLine;
    final theme = _theme ?? _fallbackTheme;
    return (to - from) * textScaler.scale(theme.lineHeight);
  }

  /// An em of the note's text, as read: what a column's minimum and the
  /// gap between columns are counted in.
  double get _em =>
      textScaler.scale((_theme ?? _fallbackTheme).body.fontSize ?? 14);

  /// The room between two columns, and between two rows of them.
  double get gap => ColumnLayout.gapEms * _em;

  /// Lays the `columns` blocks out in [width], when it or the blocks
  /// changed: the entries whose drawing changed — into a side-by-side
  /// block or out of one — are estimated again.
  ///
  /// [enabled] is whether a block may sit side by side at all: not in a
  /// view whose text can be selected.
  void layOutHosts(double width, {required bool enabled}) {
    if (!_hostsStale && _hostWidth == width) return;
    final heights = _heights;
    final shown = _shown;
    if (heights == null || shown == null) return;
    _hostsStale = false;
    _hostWidth = width;
    final theme = _theme ?? _fallbackTheme;
    final changed = hosts.layOut(
      _blocks,
      shown.lineAt,
      width: width,
      em: _em,
      listIndent: theme.listIndentPerLevel,
      enabled: enabled,
      rawEstimate: _rawEstimateOf,
      previous: hosts.flags,
    );
    for (final index in changed) {
      heights.reestimate(index, estimateOf(index));
    }
  }
}
