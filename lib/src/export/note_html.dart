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
import 'package:niman/src/export/math_svg.dart';
import 'package:niman/src/export/note_html_source.dart';
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

  /// The note's body as HTML.
  String body() => TreeHtml(source.text, hooks: _hooks).render();

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
    TreeHtml(source.text, hooks: targets).render();
    return (images: targets.images, embeds: targets.embeds);
  }
}
