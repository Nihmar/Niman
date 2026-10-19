// An inline formula answers the intrinsic questions with its own size (#1108):
// a table cell's paragraph asks its widgets for them to size a column, and a
// formula that answered zero left a column holding one no room.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex/katex.dart' show boxSizePx;
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

void main() {
  testWidgets('a formula is as wide as it is drawn when its width is asked', (
    tester,
  ) async {
    const tex = r'\frac{a_1 + b_2}{c_3 + d_4}';
    const style = MathStyle();
    final cache = MathCache(
      renderer: (tex, {required displayMode}) =>
          renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: IntrinsicWidth(
            child: InlineMathView(cache: cache, tex: tex, style: style),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final drawn = boxSizePx(
      cache.boxFor(tex, displayMode: false)!,
      style.fontSize,
    );
    expect(
      tester.getSize(find.byType(IntrinsicWidth)).width,
      closeTo(drawn.width, 0.01),
    );
  });
}
