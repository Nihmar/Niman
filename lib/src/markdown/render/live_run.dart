/// The `columns` blocks of the note `live` draws (#729,
/// `docs/records/note-columns.md`, "Rows: a columns block is one row of
/// the note"): the outermost ones, by line — their opener, their end, and
/// their columns' lines — read off the scanner's fence lines.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/callout.dart';
import 'package:niman/src/markdown/quote_content.dart';
import 'package:niman/src/markdown/render/columns_run.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// One column of a [LiveRun]: its lines `[start, end)`, its fences
/// included, and its `width`, a percentage, or null.
typedef LiveColumn = ({int start, int end, double? width});

/// An outermost `columns` block, by line.
@immutable
final class LiveRun {
  /// The block from its opener on [start] to [end], exclusive.
  const new({
    required this.start,
    required this.end,
    required this.closed,
    required this.items,
    required this.columns,
    this.quoteDepth = 0,
    this.callout,
    this.fences,
  });

  /// How many quotes the block stands in: 0 for a block of the note's own,
  /// 1 for one in a quote or a callout (#729), whose content is read again
  /// for it.
  final int quoteDepth;

  /// The callout the block stands in, if it stands in one: what its box
  /// is drawn in.
  final Callout? callout;

  /// What each of the block's fence lines does, for a block in a quote:
  /// the note's scan sees the quote, not its fences. Null for a block of
  /// the note's own, whose fences are blocks of the scan.
  final Map<int, DivRole>? fences;

  /// Its opener's line.
  final int start;

  /// One past its last line: its closer's, or its container's end.
  final int end;

  /// Whether its last line is its closer.
  final bool closed;

  /// How many list items it stands in.
  final int items;

  /// Its columns, in source order.
  final List<LiveColumn> columns;

  /// Whether [line] is one of its lines.
  bool contains(int line) => line >= start && line < end;

  /// The column holding [line], or -1: a fence of the block's own, or a
  /// blank line between two columns.
  int columnOf(int line) {
    for (var at = 0; at < columns.length; at++) {
      final column = columns[at];
      if (line >= column.start && line < column.end) return at;
    }
    return -1;
  }

  @override
  bool operator ==(Object other) =>
      other is LiveRun &&
      other.start == start &&
      other.end == end &&
      other.closed == closed &&
      other.items == items &&
      other.quoteDepth == quoteDepth &&
      _sameColumns(other.columns, columns);

  static bool _sameColumns(List<LiveColumn> a, List<LiveColumn> b) {
    if (a.length != b.length) return false;
    for (var at = 0; at < a.length; at++) {
      if (a[at] != b[at]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(start, end, closed, items, columns.length);

  /// The same block, [delta] lines further down.
  LiveRun shifted(int delta) => delta == 0
      ? this
      : LiveRun(
          start: start + delta,
          end: end + delta,
          closed: closed,
          items: items,
          quoteDepth: quoteDepth,
          callout: callout,
          fences: fences == null
              ? null
              : {
                  for (final MapEntry(key: line, value: role)
                      in fences!.entries)
                    line + delta: role,
                },
          columns: [
            for (final column in columns)
              (
                start: column.start + delta,
                end: column.end + delta,
                width: column.width,
              ),
          ],
        );

  /// The outermost `columns` blocks among [fences] — the note's fence
  /// lines, in order — each read off the blocks [blockAt] gives from its
  /// opener on: O(fence lines + the blocks of each run). [lineAt] gives a
  /// line's text, a column's opener its width.
  static List<LiveRun> of(
    Iterable<Block> fences,
    Block? Function(int line) blockAt,
    String Function(int line) lineAt,
  ) {
    final runs = <LiveRun>[];
    var after = 0;
    for (final fence in fences) {
      if (fence.startLine < after ||
          fence.divRole != DivRole.opensColumns ||
          fence.divDepth != 0 ||
          fence.footnote != 0) {
        continue;
      }
      final blocks = <Block>[fence];
      var line = fence.endLine;
      while (true) {
        final block = blockAt(line);
        if (block == null) break;
        if (block.divDepth == 0) {
          if (block.divRole == DivRole.closesColumns) blocks.add(block);
          break;
        }
        blocks.add(block);
        line = block.endLine;
      }
      final run = ColumnsRun.of(blocks, lineAt).first;
      runs.add(
        LiveRun(
          start: fence.startLine,
          end: blocks[run.end - 1].endLine,
          closed: run.closed,
          items: run.items,
          columns: [
            for (final column in run.columns)
              (
                start: blocks[column.blocks.first].startLine,
                end: blocks[column.blocks.last].endLine,
                width: column.width,
              ),
          ],
        ),
      );
      after = runs.last.end;
    }
    return runs;
  }

  /// The outermost `columns` blocks inside [quotes] — the note's quote
  /// blocks, in order — each read off its quote's content, read again
  /// (`QuoteContent`). Only a quote of one level at the note's margin, and
  /// of at most [maxLines] lines: a quote's content is scanned again at
  /// each revision, and a quote is a few lines — a longer one draws its
  /// columns stacked.
  static List<LiveRun> inQuotes(
    Iterable<Block> quotes,
    SourceBuffer buffer, {
    int maxLines = 2000,
  }) {
    final runs = <LiveRun>[];
    for (final quote in quotes) {
      if (quote.quoteDepth != 1 ||
          quote.listDepth >= 0 ||
          quote.footnote != 0 ||
          quote.lineCount > maxLines ||
          !_holdsFence(quote, buffer)) {
        continue;
      }
      final content = QuoteContent.of(quote, buffer);
      final base = quote.startLine + content.skipped;
      final blocks = content.blocks;
      for (final run in ColumnsRun.of(blocks, (line) => content.lines[line])) {
        runs.add(
          LiveRun(
            start: base + blocks[run.start].startLine,
            end: base + blocks[run.end - 1].endLine,
            closed: run.closed,
            items: 0,
            quoteDepth: 1,
            callout: content.callout,
            fences: {
              for (var at = run.start; at < run.end; at++)
                if (blocks[at].kind == BlockKind.div &&
                    blocks[at].divRole!.laysOut)
                  base + blocks[at].startLine: blocks[at].divRole!,
            },
            columns: [
              for (final column in run.columns)
                (
                  start: base + blocks[column.blocks.first].startLine,
                  end: base + blocks[column.blocks.last].endLine,
                  width: column.width,
                ),
            ],
          ),
        );
      }
    }
    return runs;
  }

  /// Whether a line of [quote] — past its one `>` — opens with three
  /// colons: one comparison a line, before its content is read again.
  static bool _holdsFence(Block quote, SourceBuffer buffer) {
    for (var line = quote.startLine; line < quote.endLine; line++) {
      final text = buffer.lineAt(line).trimLeft();
      final inside = text.startsWith('>') ? text.substring(1).trimLeft() : text;
      if (inside.startsWith(':::')) return true;
    }
    return false;
  }

  /// The run of [runs] — in order — holding [line], or null.
  static LiveRun? holding(List<LiveRun> runs, int line) {
    var low = 0;
    var high = runs.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (runs[middle].start <= line) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    if (low == 0) return null;
    final run = runs[low - 1];
    return run.contains(line) ? run : null;
  }
}
