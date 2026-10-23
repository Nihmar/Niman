/// The `todo` fences of a page drawn as the lists they were at the moment of
/// the export, for the PDF drawn as pictures (#1152).
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/export/printed_todo_block.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';

const String _openBox = '☐';
const String _doneBox = '☑';

/// Draws a `todo` fence as its [PrintedTodoBlock]: the head, then ☐ and ☑
/// and the words of each task — the page the printed HTML makes, in the
/// theme's own type, with no Material to lean on: the offscreen layout has
/// none.
final class PrintedTodoBuilder implements TodoBlockBuilder {
  /// A builder over the [blocks] the export found.
  const new(this.blocks);

  /// The blocks, by `todoBlockKey` of their source.
  final PrintedTodoBlocks blocks;

  @override
  Widget? build(
    BuildContext context, {
    required String source,
    required MarkdownTheme theme,
    void Function(int line)? onTapSource,
  }) {
    final block = blocks[todoBlockKey(source)];
    if (block == null) return null;
    final failed = block.problems.isNotEmpty;
    final line = theme.body;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.blockSpacing / 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: failed ? const Color(0xFFE45649) : theme.tableBorder,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.codePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                block.head,
                style: line.copyWith(fontWeight: FontWeight.w600),
              ),
              for (final problem in block.problems)
                Text(
                  problem,
                  style: line.copyWith(color: const Color(0xFFE45649)),
                ),
              if (!failed)
                for (final (:done, :text) in block.tasks)
                  Text(
                    '${done ? _doneBox : _openBox} $text',
                    style: done
                        ? line.copyWith(
                            color: theme.markerDim,
                            decoration: TextDecoration.lineThrough,
                          )
                        : line,
                  ),
              if (!failed && block.empty != null)
                Text(
                  block.empty!,
                  style: line.copyWith(color: theme.markerDim),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
