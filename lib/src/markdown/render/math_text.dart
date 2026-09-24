/// The TeX of a display formula, read out of its block's source: shared by
/// the read view, which draws the block, and `live` mode, which draws it in
/// place of its lines while the caret is elsewhere.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/preview/math_widget.dart';

/// How much larger than the text around it a formula is set: KaTeX's own
/// (`.katex { font-size: 1.21em }`).
///
/// Its fonts are Computer Modern's, whose strokes are hairlines next to a UI
/// face's: set at the text's size, a subscript or a matrix entry is a few
/// pixels tall and its strokes thinner than one, and on a 1× screen they read
/// as grey smudges while the parentheses — drawn as paths, not glyphs — stay
/// sharp beside them (device report, 2026-09-23). The web sets KaTeX larger for
/// the same reason, and a note reads the same in the app as in a browser.
const double mathScale = 1.21;

/// The formula style for maths set among [text]: its colour, at [mathScale]
/// times its size.
MathStyle mathStyleFor(TextStyle text) =>
    MathStyle(fontSize: (text.fontSize ?? 14) * mathScale, color: text.color);

/// The TeX of a display block whose source is [text], its `$$` fences out —
/// a one-line `$$x$$` keeps what is between them.
String displayTexOf(String text) {
  final lines = text.split('\n');
  final body = <String>[];
  for (var at = 0; at < lines.length; at++) {
    final trimmed = lines[at].trim();
    if (trimmed.startsWith(r'$$')) {
      final inner = trimmed.replaceAll(r'$$', '').trim();
      if (inner.isNotEmpty) body.add(inner);
      continue;
    }
    body.add(lines[at]);
  }
  return body.join('\n').trim();
}
