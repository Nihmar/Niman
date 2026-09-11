// T-M2-05 M-05-3: math in the windowed preview — inline spans, display
// blocks (top-level + in lists), placeholders, errors, cache reuse.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart'
    show BoxNode, KatexOptions, renderToBox;
import 'package:niman/src/preview/markdown_preview.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/math_widget.dart';

Widget _app(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(height: 600, child: child)),
);

MarkdownPreview _preview(String data, MathCache cache) => MarkdownPreview(
  data: data,
  mathCache: cache,
  mathStyle: const MathStyle(color: Color(0xFF112233)),
);

MathCache _syncCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

void main() {
  tests();
}

void tests() {
  group('preview math', () {
    testWidgets('inline math renders inside a paragraph', (tester) async {
      final cache = _syncCache();
      await tester.pumpWidget(
        _app(_preview(r'Text with $x^2$ inline here.', cache)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(InlineMathView), findsOneWidget);
      cache.dispose();
    });

    testWidgets('display math renders centered, also inside a list', (
      tester,
    ) async {
      final cache = _syncCache();
      await tester.pumpWidget(
        _app(
          _preview(r'''
Before

$$
\frac{a}{b}
$$

- item with display: $$
  x
  $$
''', cache),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(BlockMathView), findsNWidgets(2));
      cache.dispose();
    });

    testWidgets('editing reuses the cache for unchanged spans (AC)', (
      tester,
    ) async {
      final cache = _syncCache();
      await tester.pumpWidget(_app(_preview(r'A $x^2$ and b', cache)));
      await tester.pump();
      final missesAfterFirst = cache.misses;
      // The same tex keeps rendering unchanged while only prose changes.
      await tester.pumpWidget(_app(_preview(r'Changed prose $x^2$ b', cache)));
      await tester.pump();
      expect(cache.misses, missesAfterFirst, reason: 'no re-render needed');
      expect(cache.hits, greaterThan(0));
      cache.dispose();
    });

    testWidgets('a failing render shows the red fallback, not a crash', (
      tester,
    ) async {
      final cache = MathCache(
        renderer: (tex, {required displayMode}) =>
            throw const FormatException('bad'),
      );
      await tester.pumpWidget(_app(_preview(r'bad $\frac{a}{}$ math', cache)));
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(InlineMathView), findsOneWidget);
      final text = tester.widget<RichText>(
        find
            .descendant(
              of: find.byType(InlineMathView),
              matching: find.byType(RichText),
            )
            .first,
      );
      expect(text.text.toPlainText(), contains(r'\frac{a}{}'));
      cache.dispose();
    });

    testWidgets('pending span shows the placeholder then the box', (
      tester,
    ) async {
      // Async seam: pending until the test completes it (the real isolate
      // path is covered by the unit test — FakeAsync cannot drive an
      // isolate's completion port).
      final completer = Completer<BoxNode>();
      final cache = MathCache(
        asyncRenderer: (tex, {required displayMode}) => completer.future,
      );
      await tester.pumpWidget(_app(_preview(r'slow $x^2$ math', cache)));
      await tester.pump();
      expect(cache.isPending('x^2', displayMode: false), isTrue);
      expect(find.byType(InlineMathView), findsOneWidget);
      // Still pending: the view stays on its placeholder text.
      await tester.pump();
      completer.complete(renderToBox('x^2', options: const KatexOptions()));
      await tester.pump();
      await tester.pump(); // the notify's setState lands on the next frame
      expect(cache.boxFor('x^2', displayMode: false), isNotNull);
      // The placeholder ('…') is gone; the view now embeds the painted box
      // (the inline leaf paints on its own RenderObject — no CustomPaint
      // widget — so the placeholder's disappearance is the observable).
      expect(
        find.descendant(
          of: find.byType(InlineMathView),
          matching: find.text('…'),
        ),
        findsNothing,
      );
      cache.dispose();
    });

    testWidgets('inline math stays inside the paragraph RichText', (
      tester,
    ) async {
      // Device report, 2026-09-11: every formula stood alone on its line.
      // The package builds a block as a Wrap of its inline children and
      // only merges text widgets — a bare view becomes its own wrap child
      // (an atomic wrap unit). The builder returns a Text instead, so the
      // paragraph stays one RichText and the formula is a WidgetSpan in it.
      final cache = _syncCache();
      await tester.pumpWidget(
        _narrow(
          _preview(r'I segmenti orientati $AB$ e $CD$ si diranno.', cache),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final paras = find
          .byType(RichText)
          .evaluate()
          .map((e) => e.widget as RichText)
          .where((rt) => rt.text.toPlainText().contains('segmenti'))
          .toList();
      expect(paras, hasLength(1));
      expect(_widgetSpans(paras.single.text), 2);
      cache.dispose();
    });

    testWidgets('inline math wraps like plain text', (tester) async {
      // The same sentence with the formulae as words: the line count must
      // match, or the math is stranding neighbours on their own lines.
      final cache = _syncCache();
      const math =
          r'I segmenti orientati $AB$ e $CD$ si diranno equipollenti se '
          'sono entrambi banali oppure se sono uguali.';
      const plain =
          'I segmenti orientati AB e CD si diranno equipollenti se '
          'sono entrambi banali oppure se sono uguali.';
      expect(
        await _lineCount(tester, math, cache),
        await _lineCount(tester, plain, cache),
      );
      cache.dispose();
    });
  });
}

/// A 300 px preview: narrow enough that the sentence must wrap.
Widget _narrow(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 300, height: 800, child: child)),
);

/// How many [WidgetSpan]s [span] holds, at any depth.
int _widgetSpans(InlineSpan span) {
  var count = 0;
  void visit(InlineSpan node) {
    if (node is WidgetSpan) count++;
    if (node is TextSpan) node.children?.forEach(visit);
  }

  visit(span);
  return count;
}

/// Lines the paragraph built for [data] takes at 300 px, replaying its
/// span (with the live math sizes) through a TextPainter.
Future<int> _lineCount(
  WidgetTester tester,
  String data,
  MathCache cache,
) async {
  await tester.pumpWidget(_narrow(_preview(data, cache)));
  await tester.pump();
  expect(tester.takeException(), isNull);
  RichText? para;
  for (final e in find.byType(RichText).evaluate()) {
    final rt = e.widget as RichText;
    if (rt.text.toPlainText().contains('segmenti')) para = rt;
  }
  expect(para, isNotNull);
  final context = tester.element(find.byWidget(para!));
  final painter = TextPainter(
    text: para.text,
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  );
  final holderSizes = [
    for (final e in find.byType(InlineMathView).evaluate())
      tester.getSize(find.byWidget(e.widget)),
  ];
  painter.setPlaceholderDimensions([
    for (final size in holderSizes)
      PlaceholderDimensions(
        size: size,
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        baselineOffset: size.height,
      ),
  ]);
  return (painter..layout(maxWidth: tester.getSize(find.byWidget(para)).width))
      .computeLineMetrics()
      .length;
}
