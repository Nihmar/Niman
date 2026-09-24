// The export seam, D12: the same block painter draws the *whole* note at a
// width of the caller's choosing, with no viewport and no scroll position in
// the way. The property worth asserting is the difference from reading: export
// draws every block, and its layout follows the width it was given rather than
// any window.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_export.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

/// A cache that renders in-line, as the preview's own tests do.
MathCache _syncCache() => MathCache(
  renderer: (tex, {required displayMode}) =>
      renderToBox(tex, options: KatexOptions(displayMode: displayMode)),
);

/// A note of [paragraphs] paragraphs, each long enough to wrap.
String _note(int paragraphs) {
  final buffer = StringBuffer();
  for (var at = 0; at < paragraphs; at++) {
    buffer
      ..writeln('## Heading $at')
      ..writeln()
      ..writeln(
        'Paragraph $at with **bold**, a `code span` and a '
        '[link](https://example.com) that is long enough to wrap at a '
        'narrow width and not at a wide one.',
      )
      ..writeln();
  }
  return buffer.toString();
}

/// Lays the note out at [width] and hands back how large it came out.
///
/// A size rather than the box: two layouts in one test reuse the same render
/// object, so a box kept from the first would report the second's size.
Future<Size> _layout(WidgetTester tester, String document, double width) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Builder(
            builder: (context) => MarkdownExportView(
              buffer: SourceBuffer.fromText(document),
              parser: BlockParser(),
              theme: markdownThemeOf(context),
              mathCache: _syncCache(),
              width: width,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return _boxOf(tester).size;
}

/// The laid-out box, for the tests that record it.
RenderBox _boxOf(WidgetTester tester) =>
    tester.renderObject<RenderBox>(find.byType(MarkdownExportView));

void main() {
  testWidgets('a note is drawn whole, not a window of it', (tester) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // The window is 300 pixels tall; the note is far taller, and every heading
    // of it is in the tree, which is exactly what reading does not do.
    const paragraphs = 30;
    final size = await _layout(tester, _note(paragraphs), 360);
    expect(size.width, 360);
    expect(
      size.height,
      greaterThan(300 * paragraphs / 4),
      reason: 'the whole note, not the window',
    );
    expect(find.textContaining('Heading 0'), findsOneWidget);
    expect(find.textContaining('Heading ${paragraphs - 1}'), findsOneWidget);
  });

  testWidgets("the width is the caller's, not the window's", (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final document = _note(4);
    final narrow = await _layout(tester, document, 240);
    final wide = await _layout(tester, document, 900);
    // The same words: narrower means taller. A width taken from the window
    // would make these equal.
    expect(narrow.width, 240);
    expect(wide.width, 900);
    expect(narrow.height, greaterThan(wide.height));
  });

  testWidgets('it records into an image through a picture', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _layout(tester, _note(3), 400);
    final box = _boxOf(tester);
    final image = await MarkdownExport.capture(box);
    addTearDown(image.dispose);
    expect(image.width, box.size.width * box.size.height > 0 ? 400 : 400);
    expect(image.height, closeTo(box.size.height, 1));
  });

  testWidgets('the device ratio scales the recording', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _layout(tester, _note(2), 300);
    final box = _boxOf(tester);
    final image = await MarkdownExport.capture(box, pixelRatio: 2);
    addTearDown(image.dispose);
    expect(image.width, 600);
    expect(image.height, closeTo(box.size.height * 2, 2));
    expect(MarkdownExport.heightOf(box), box.size.height);
  });

  testWidgets('a formula is typeset in the export too', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _layout(tester, r'a $x^2 + y^2$ b', 400);
    final box = _boxOf(tester);
    final image = await MarkdownExport.capture(box);
    addTearDown(image.dispose);
    expect(image.width, greaterThan(0));
    expect(box.size.height, greaterThan(0));
    // The formula was drawn rather than left as text: the paragraph is taller
    // than one line of plain prose.
    expect(box.size.height, greaterThan(30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty note records without failing', (tester) async {
    await _layout(tester, '', 200);
    final box = _boxOf(tester);
    final image = await MarkdownExport.capture(box);
    addTearDown(image.dispose);
    expect(image.width, greaterThanOrEqualTo(1));
    expect(tester.takeException(), isNull);
  });
}
