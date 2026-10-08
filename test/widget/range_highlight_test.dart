// Characters of a block tinted (#283, #285): painted behind its text from
// the boxes its paragraphs lay out, across the paragraphs in order. A
// highlight in its colour, an annotation over it, underlined (#626).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/markdown/render/marked_block.dart';
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

  group('a block marked (#626)', () {
    const green = Color(0x664CD07D);

    Future<void> mark(WidgetTester tester, List<BlockMark> marks) =>
        tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: Brightness.light),
            home: Center(
              child: SizedBox(
                width: 400,
                child: MarkedBlock(
                  marks: marks,
                  child: const Column(
                    children: [Text('Hello world'), Text('Again')],
                  ),
                ),
              ),
            ),
          ),
        );

    List<RangeHighlight> layers(WidgetTester tester) =>
        tester.widgetList<RangeHighlight>(find.byType(RangeHighlight)).toList();

    testWidgets('a highlight wears its colour, with no underline', (
      tester,
    ) async {
      await mark(tester, [
        (line: 0, chars: (start: 0, end: 5), highlight: HighlightColour.green),
      ]);
      final layer = layers(tester).single;
      expect(layer.color, green);
      expect(layer.underline, isNull);
    });

    testWidgets('an annotation is drawn over a highlight, underlined', (
      tester,
    ) async {
      await mark(tester, [
        (line: 0, chars: (start: 0, end: 5), highlight: null),
        (line: 0, chars: (start: 2, end: 9), highlight: HighlightColour.green),
      ]);
      // Outermost first: the highlight's layer paints before the one
      // inside it.
      final [outer, inner] = layers(tester);
      expect(outer.color, green);
      expect(inner.color, tint);
      expect(inner.underline, annotationUnderlineFor(dark: false));
      expect(
        tester.renderObject(find.byWidget(inner)),
        paints
          ..rrect(color: tint)
          ..rect(color: annotationUnderlineFor(dark: false)),
      );
    });
  });
}
