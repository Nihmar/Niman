/// One construct of the cheatsheet: as it is written, and as it is shown.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/footnote_list.dart';
import 'package:niman/src/markdown/render/markdown_export.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/cheatsheet/cheatsheet_entries.dart';
import 'package:niman/src/ui/strings.dart';

/// [entry] as written beside it as shown — side by side on a wide page,
/// one above the other on a narrow one — with a copy, and an insert when
/// there is a note to insert it in ([onInsert]).
///
/// Shown through the read view's own blocks (`MarkdownExportView`), so an
/// example reads exactly as it would in a note.
final class CheatsheetExample extends StatelessWidget {
  /// Creates the example.
  const new({
    required this.entry,
    required this.mathCache,
    this.onInsert,
    super.key,
  });

  /// The construct.
  final CheatsheetEntry entry;

  /// The page's formulas, typeset once.
  final MathCache mathCache;

  /// Puts the example in the open note; null when there is none.
  final ValueChanged<String>? onInsert;

  /// How wide a page holds the two side by side.
  static const double sideBySide = 640;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insert = onInsert;
    return Padding(
      key: Key('cheat-${entry.id}'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(entry.title(), style: theme.textTheme.titleSmall),
              ),
              IconButton(
                key: Key('cheat-${entry.id}-copy'),
                tooltip: AppStrings.cheatsheetCopy,
                icon: const Icon(Icons.content_copy_outlined, size: 18),
                onPressed: () => _copy(context),
              ),
              if (insert != null)
                IconButton(
                  key: Key('cheat-${entry.id}-insert'),
                  tooltip: AppStrings.cheatsheetInsert,
                  icon: const Icon(Icons.post_add_outlined, size: 18),
                  onPressed: () => insert(entry.source),
                ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= sideBySide;
              final width = wide
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              final written = _written(context);
              final shown = _shown(context, width);
              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [written, const SizedBox(height: 8), shown],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: written),
                    const SizedBox(width: 16),
                    Expanded(child: shown),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: entry.source));
    messenger.showSnackBar(
      SnackBar(content: Text(AppStrings.cheatsheetCopied)),
    );
  }

  /// The source, in the code's box and face, selectable.
  Widget _written(BuildContext context) {
    final markdown = markdownThemeOf(context);
    return Container(
      key: Key('cheat-${entry.id}-written'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: markdown.codeBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: SelectableText(entry.source, style: markdown.code),
    );
  }

  /// The example as a note shows it, footnotes and all.
  Widget _shown(BuildContext context, double width) {
    final markdown = markdownThemeOf(context);
    final scheme = Theme.of(context).colorScheme;
    final buffer = SourceBuffer.fromText(entry.source);
    final parser = BlockParser();
    final footnotes = parser.footnotesOf(buffer);
    return Container(
      key: Key('cheat-${entry.id}-shown'),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarkdownExportView(
            buffer: buffer,
            parser: parser,
            theme: markdown,
            mathCache: mathCache,
            width: width - 2,
            padding: const EdgeInsets.all(12),
          ),
          if (footnotes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: FootnoteList(
                footnotes: footnotes,
                theme: markdown,
                parser: parser,
                mathCache: mathCache,
                scope: parser.scope,
              ),
            ),
        ],
      ),
    );
  }
}
