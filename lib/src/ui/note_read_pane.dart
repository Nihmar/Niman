import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';
import 'package:niman/src/ui/note_links.dart';
import 'package:niman/src/ui/note_view_parts.dart';

/// The read pane with the frontmatter fields panel over it (#157), or the
/// pane alone when the note has no block to show.
final class NoteReadPane extends StatelessWidget {
  /// The read pane of the note [parts] hold.
  const new({required this.parts, super.key});

  /// The note view's collaborators.
  final NoteViewParts parts;

  @override
  Widget build(BuildContext context) {
    final panel = parts.frontmatter.fields();
    if (panel == null) return _read(context);
    return Column(
      children: [
        NoteColumnPadding(
          column: parts.view.options.noteColumn,
          minInset: NoteColumn.textInset,
          child: panel,
        ),
        Expanded(child: _read(context)),
      ],
    );
  }

  /// The preview, at the *note* text size rather than the interface one
  /// (T-M6-12).
  ///
  /// The app root put the interface scale on every MediaQuery below it;
  /// here it is replaced, so the same note reads the same size whichever
  /// pane shows it.
  ///
  /// The unified surface's read mode: one engine, the same theme as the editor
  /// (docs/records/unified-surface.md).
  Widget _read(BuildContext context) => TodoBlockScope(
    builder: parts.todoBlocks,
    child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: noteTextScalerOf(context)),
      child: MarkdownReadView(
        key: parts.readViewKey,
        buffer: parts.readSnapshot.buffer,
        parser: parts.unifiedParser,
        mathCache: parts.mathCache,
        controller: parts.previewScroll,
        onTapLink: (text, href) =>
            unawaited(openHref(context, href ?? '', parts.links.targets())),
        onTapWikiLink: (inner) => unawaited(
          // The same rule the parser and the preview use, so a wikilink means
          // one thing however it is drawn. `inner` is the `[[…]]` content, and
          // `parseWikiRef` reads it (#477 needs the target it names).
          openWiki(context, parseWikiRef(inner), parts.links.targets()),
        ),
        embedResolver: parts.links.resolveEmbed,
        deadLinks: parts.deadLinks,
        linkPreview: parts.preview.hooks(context),
        column: parts.view.options.noteColumn,
        knownScan: parts.editorScanOf,
        sharedScan: parts.editorScanLater,
        onToggleTask: parts.readTasks.toggle,
      ),
    ),
  );
}
