/// Formulas as inline SVG for an exported page (#24).
///
/// The typesetter is the app's own (`katex_dart`, the one the read view
/// paints from), so a formula in the export is the formula on screen, drawn
/// as vectors and needing no script. `renderToSvg` makes each drawing a
/// standalone document, fonts and all — about half a megabyte of base64 per
/// formula. On a page that is waste twice over: the glyphs are drawn as
/// paths wherever the port has one, and a page can declare the fonts once
/// for every drawing on it. So each drawing loses its fonts here, and the
/// page takes them once, and only when a drawing still writes text.
library;

import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/render/math_text.dart' show mathScale;

/// The user units one em is drawn at: the serializer's default scale.
const double _unitsPerEm = 44;

/// `<defs><style>…</style></defs>`: the fonts a drawing carries.
final RegExp _fontDefs = RegExp(
  '<defs><style>(.*?)</style></defs>',
  dotAll: true,
);

/// The root's size and the baseline's offset from its top, in user units.
final RegExp _size = RegExp(r'<svg [^>]*width="([\d.]+)" height="([\d.]+)"');
final RegExp _baseline = RegExp(
  r'<g transform="translate\([\d.]+,([\d.]+)\)">',
);

/// Renders formulas for one page and remembers the fonts they need.
final class MathSvg {
  /// A renderer for one page.
  new();

  String? _fonts;
  bool _needsFonts = false;

  /// The `@font-face` rules the page must declare, or null when no drawing
  /// on it writes text.
  String? get fontFaces => _needsFonts ? _fonts : null;

  /// [tex] as an inline `<svg>` element, sized in the text's own em and sat
  /// on its baseline; or null when the TeX does not parse, for the caller to
  /// show the source instead.
  String? render(String tex, {required bool display}) {
    final String svg;
    try {
      svg = renderToSvg(
        tex,
        // The default throws on an error, which is what the null below
        // needs; an inline error mark would be the port's, not the note's.
        options: KatexOptions(displayMode: display, color: 'currentColor'),
      );
    } on Object {
      // A parse error (or a construct the port does not cover) is the
      // note's to show as written, not the export's to fail on.
      return null;
    }
    final defs = _fontDefs.firstMatch(svg);
    _fonts ??= defs?.group(1);
    final body = defs == null
        ? svg
        : svg.replaceRange(defs.start, defs.end, '');
    if (body.contains('<text')) _needsFonts = true;
    final size = _size.firstMatch(body);
    final base = _baseline.firstMatch(body);
    if (size == null || base == null) return null;
    final width = double.parse(size.group(1)!);
    final height = double.parse(size.group(2)!);
    final baseline = double.parse(base.group(1)!);
    // In em of the surrounding text, at the read view's maths scale.
    String em(double units) =>
        '${(units / _unitsPerEm * mathScale).toStringAsFixed(3)}em';
    final style =
        'width:${em(width)};height:${em(height)};'
        'vertical-align:-${em(height - baseline)}';
    final cls = display ? 'math math-display' : 'math';
    return body.replaceFirst(
      RegExp(r' width="[\d.]+" height="[\d.]+"'),
      ' class="$cls" style="$style" role="img" aria-label="${_attr(tex)}"',
    );
  }

  static String _attr(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
