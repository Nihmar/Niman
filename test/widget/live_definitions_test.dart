// A note's definitions in `live`: hidden where they stand, as the read view
// does not draw them there, and reached through the footnotes the note ends
// with — which `live` draws, as the read view does.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

const String _note =
    'a note[^1] and a [link][site].\n\n'
    '[^1]: the footnote body\n[site]: https://example.org\n\n'
    'after\n';

/// The paragraph whose text holds [text]: the last one, or the first.
RenderParagraph _paragraph(
  WidgetTester tester,
  String text, {
  bool last = false,
}) {
  final all = tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .where((p) => p.text.toPlainText().contains(text))
      .toList();
  return last ? all.last : all.first;
}

void main() {
  testWidgets('a tap on a footnote puts the caret in its definition, shown', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText(_note);
    SelectionModel? moved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MarkdownSurface(
              buffer: buffer,
              mode: MarkdownSurfaceMode.live,
              theme: markdownThemeOf(context),
              onSelection: (selection) => moved = selection,
              showLineNumbers: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    // The definitions take no room while the caret is not in them.
    expect(_paragraph(tester, 'the footnote body').size.height, lessThan(1));
    expect(_paragraph(tester, 'example.org').size.height, lessThan(1));

    final row = _paragraph(tester, 'the footnote body', last: true);
    await tester.tapAt(row.localToGlobal(row.size.center(Offset.zero)));
    await tester.pump();
    await tester.pump();

    expect(moved?.extent, buffer.offsetOfLine(2));
    // The caret anywhere in them shows them all, one row apiece.
    final definition = _paragraph(tester, 'the footnote body');
    expect(definition.size.height, greaterThan(10));
    expect(_paragraph(tester, 'example.org').size.height, greaterThan(10));
  });
}
