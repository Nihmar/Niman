/// The `columns` blocks of a note's block list that can sit side by side
/// (#729, `docs/records/note-columns.md`): the outermost ones, at the
/// note's margin or in a list item — a quote is one block, and draws the
/// columns inside it itself — with the blocks of each of their columns.
library;

import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_list.dart';
import 'package:niman/src/markdown/div_syntax.dart';

/// One column of a [ColumnsRun]: the indices of its blocks in the list —
/// its fences included, which are the room above and below it — and its
/// `width`, a percentage, or null.
typedef RunColumn = ({List<int> blocks, double? width});

/// An outermost `columns` block of a block list: from its opener to its
/// closer, or to the end of its container when it has none.
final class ColumnsRun {
  /// The run of blocks `[start, end)`.
  const new({
    required this.start,
    required this.end,
    required this.closed,
    required this.items,
    required this.columns,
  });

  /// The run [blocks] has from its opener at [start].
  factory _from(List<Block> blocks, int start, String Function(int) lineAt) {
    final columns = <RunColumn>[];
    // The column blocks go into: an explicit one until its closer, an
    // implicit one until the next column opens.
    List<int>? open;
    var at = start + 1;
    var closed = false;
    for (; at < blocks.length; at++) {
      final block = blocks[at];
      if (block.divDepth == 0) {
        // Its closer, or the first block past its container's end.
        if (block.divRole == DivRole.closesColumns) {
          closed = true;
          at++;
        }
        break;
      }
      if (block.divDepth > 1) {
        (open ?? _implicit(columns, (o) => open = o)).add(at);
        continue;
      }
      switch (block.divRole) {
        case DivRole.opensColumn:
          final blocks = <int>[at];
          open = blocks;
          columns.add((
            blocks: blocks,
            width: DivSyntax.opening(lineAt(block.startLine).trimLeft())?.width,
          ));
        case DivRole.closesColumn:
          open?.add(at);
          open = null;
        case DivRole.opensColumns ||
            DivRole.opensOther ||
            DivRole.closesColumns ||
            DivRole.closesOther ||
            null:
          final column = open;
          if (column != null) {
            column.add(at);
          } else if (block.kind != BlockKind.blank) {
            _implicit(columns, (o) => open = o).add(at);
          }
      }
    }
    final first = blocks[start];
    return ColumnsRun(
      start: start,
      end: at,
      closed: closed,
      items: first.listDepth + 1,
      columns: columns,
    );
  }

  /// The index of its opener.
  final int start;

  /// One past the index of its closer, or of its last block.
  final int end;

  /// Whether its last block is its closer.
  final bool closed;

  /// How many list items it stands in: it is drawn at their indent.
  final int items;

  /// Its columns, in source order; blank lines between two of them are in
  /// none, and drawn nowhere: the gap is the room between them.
  final List<RunColumn> columns;

  /// Whether [index] is one of its blocks.
  bool contains(int index) => index >= start && index < end;

  /// All the runs of [blocks], in order; [lineAt] gives a line's text, a
  /// column's opener its width. [fences] are the indices of the fence
  /// lines among [blocks], in order, when the list knows them
  /// ([BlockList.divIndices]): only those are looked at, and not every
  /// block.
  static List<ColumnsRun> of(
    List<Block> blocks,
    String Function(int) lineAt, {
    Iterable<int>? fences,
  }) {
    final runs = <ColumnsRun>[];
    var after = 0;
    for (final at in fences ?? Iterable<int>.generate(blocks.length)) {
      if (at < after) continue;
      final block = blocks[at];
      if (block.divRole != DivRole.opensColumns ||
          block.divDepth != 0 ||
          block.footnote != 0) {
        continue;
      }
      final run = ColumnsRun._from(blocks, at, lineAt);
      runs.add(run);
      after = run.end;
    }
    return runs;
  }

  /// A new implicit column of [columns], handed to [opened] as the one
  /// open.
  static List<int> _implicit(
    List<RunColumn> columns,
    void Function(List<int>) opened,
  ) {
    final blocks = <int>[];
    columns.add((blocks: blocks, width: null));
    opened(blocks);
    return blocks;
  }
}
