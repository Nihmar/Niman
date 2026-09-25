// Characters of a block tinted (#283, #285): painted behind its text from
// the boxes its paragraphs lay out, across the paragraphs in order.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/range_highlight.dart';

void main() {
  const tint = Color(0x66FFD60A);

  Future<RenderObject> pump(WidgetTester tester, List<CharRange> ranges) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            child: RangeHighlight(
              ranges: [],
              color: tint,
              child: Column(children: [Text('Hello world'), Text('Again')]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            child: RangeHighlight(
              ranges: ranges,
              color: tint,
              child: const Column(
                children: [Text('Hello world'), Text('Again')],
              ),
            ),
          ),
        ),
      ),
    );
    return tester.renderObject(find.byType(RangeHighlight));
  }

  testWidgets('a range in one paragraph is one box', (tester) async {
    final box = await pump(tester, [(start: 6, end: 11)]);
    expect(box, paints..rrect(color: tint));
    expect(
      box,
      isNot(
        paints
          ..rrect()
          ..rrect(),
      ),
    );
  });

  testWidgets('a range over two paragraphs is a box in each', (tester) async {
    // "Hello world" is 11 characters; "Again" follows it.
    final box = await pump(tester, [(start: 6, end: 13)]);
    expect(
      box,
      paints
        ..rrect(color: tint)
        ..rrect(color: tint),
    );
  });

  testWidgets('no range paints nothing but the text', (tester) async {
    final box = await pump(tester, const []);
    expect(box, isNot(paints..rrect()));
  });
}
