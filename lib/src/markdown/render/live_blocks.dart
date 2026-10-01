/// What `live` mode draws *instead of* source it hides: a display formula in
/// place of its `$$` lines, a picture under the line that embeds it.
///
/// Both are laid out beside the line's paragraph rather than inside it: the
/// paragraph keeps the source, every character at its own offset, so the
/// caret, the hit test and the selection go on measuring text and nothing
/// else (approach B, `docs/records/unified-surface.md` §8.6.0). A widget *inside*
/// the paragraph would be a code unit the source does not have — the
/// correction table §8.6.0 point 3 describes — which the inline cases need
/// and these do not.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/diagrams/diagram_cache.dart';
import 'package:niman/src/markdown/render/diagram_view.dart';
import 'package:niman/src/markdown/render/embed_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/math_text.dart';
import 'package:niman/src/markdown/source_styler.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

/// A display formula as `live` draws it: its lines, `[start, end)`, and its
/// TeX.
typedef LiveFormula = ({int start, int end, String tex});

/// A Mermaid diagram as `live` draws it: its fence's lines, `[start, end)`,
/// and the source between them (#530).
typedef LiveDiagram = ({int start, int end, String source});

/// [line] — the formula's first line, its source hidden — with the formula
/// typeset under it, centred as the read view centres it.
///
/// A tap on the formula lands on the line, which puts the caret in the block
/// and shows its source.
Widget liveFormulaUnder(
  Widget line, {
  required MathCache cache,
  required String tex,
  required MarkdownTheme theme,
  required double maxWidth,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[
    line,
    Padding(
      padding: EdgeInsets.symmetric(vertical: theme.blockSpacing / 2),
      // Center hands the view its own width back: a formula laid out on the
      // column's tight width is drawn from its left edge (#252).
      child: Center(
        child: BlockMathView(
          cache: cache,
          maxWidth: maxWidth,
          tex: tex,
          style: mathStyleFor(theme.body),
        ),
      ),
    ),
  ],
);

/// [line] — the fence's first line, its source hidden — with the diagram
/// drawn under it, as the read view draws it.
///
/// A tap on the diagram lands on the line, which puts the caret in the block
/// and shows its source again.
Widget liveDiagramUnder(
  Widget line, {
  required DiagramCache cache,
  required String source,
  required MarkdownTheme theme,
}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: <Widget>[
    line,
    Center(
      child: BlockDiagramView(source: source, theme: theme, cache: cache),
    ),
  ],
);

/// [line] with its [pictures] drawn under it, each as the read view draws an
/// embed: the image when it resolves to one, the note's own words when not.
Widget livePicturesUnder(
  Widget line,
  List<LinePicture> pictures,
  Future<String?> Function(String target) resolve,
) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    line,
    for (final picture in pictures)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: EmbedView(
          target: picture.target,
          display: picture.display,
          placeholder: picture.source,
          onResolve: resolve,
        ),
      ),
  ],
);
