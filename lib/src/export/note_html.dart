/// A note as HTML (#24): the body of an exported page.
///
/// The note is read as the read view reads it — the tree, our inline parser
/// (`docs/dev/block-tree.md`, phase 7) — and written by the writer
/// (`TreeHtml`), `cmark-gfm`'s HTML, so lists, footnotes and link references
/// read as a document's. What the page draws its own way, as the read view
/// draws it, it draws through the writer's hooks ([ExportHooks]): coloured
/// code, formulas and diagrams as SVG, a raw HTML block as its source, a
/// callout's frame, wikilinks and embeds, and the pictures and links the
/// export points elsewhere.
library;

import 'package:niman/src/export/export_hooks.dart';
import 'package:niman/src/export/kanban_html.dart';
import 'package:niman/src/export/kanban_sheet.dart';
import 'package:niman/src/export/math_svg.dart';
import 'package:niman/src/export/note_html_source.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/kanban/board_parser.dart';
import 'package:niman/src/kanban/kanban_board.dart';
import 'package:niman/src/markdown/html/html_hooks.dart';
import 'package:niman/src/markdown/html/tree_html.dart';

/// Builds one page's body.
final class NoteHtml {
  /// A builder over [source].
  new(this.source) : _math = MathSvg() {
    _hooks = ExportHooks(source, _math);
  }

  /// What the page is built from.
  final NoteHtmlSource source;

  final MathSvg _math;
  late final ExportHooks _hooks;

  /// The board the note is, or null for any other note (#1170): a
  /// `type: kanban` note with the Kanban feature on. Read once.
  late final KanbanBoard? _board =
      source.kanban && parseFrontmatter(source.text)?.type == 'kanban'
      ? parseKanban(source.text)
      : null;

  /// The note's body as HTML.
  String body() => _render(_hooks);

  /// The sheet a printed page of this note wants, or null when it is no
  /// board, or a board with no column: the plain A4 page (#1170).
  KanbanSheet? get boardSheet {
    final columns = _board?.columns.length ?? 0;
    return columns == 0 ? null : kanbanSheetFor(columns);
  }

  /// [source] written with [hooks]: a board by [KanbanHtml], any other note
  /// by the writer alone.
  String _render(HtmlHooks hooks) {
    final board = _board;
    return board == null
        ? TreeHtml(source.text, hooks: hooks).render()
        : KanbanHtml(board, hooks).render();
  }

  /// The `@font-face` rules the body's formulas need, or null.
  String? get fontFaces => _math.fontFaces;

  /// Whether the body drew a formula or a diagram as inline SVG; the EPUB
  /// package declares the `svg` property for a chapter that did (E6).
  bool get usesSvg => _math.usesSvg || _hooks.usedDiagram;

  /// The pictures the page will draw, as written: each image's `src` and
  /// each embed's target, in order — what an export resolves before the
  /// page is built (#24). Nothing is typeset for it.
  ({List<String> images, List<String> embeds}) pictureTargets() {
    final targets = PictureTargets();
    _render(targets);
    return (images: targets.images, embeds: targets.embeds);
  }
}
