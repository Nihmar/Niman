// A table in `live`: the read view's grid over the table's own source, the
// caret's row drawn as written.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

const String _note = 'caret\n\n| a | b |\n|---|---|\n| one | two |\n';

/// Pumps [_note] in `live`, the caret at [caret].
Future<void> _pump(WidgetTester tester, int caret) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MarkdownSurface(
            buffer: SourceBuffer.fromText(_note),
            mode: MarkdownSurfaceMode.live,
            theme: markdownThemeOf(context),
            selection: SelectionModel.at(caret),
            showLineNumbers: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// The paragraph of the line whose drawn text holds [text].
RenderParagraph _row(WidgetTester tester, String text) => tester
    .renderObjectList<RenderParagraph>(find.byType(RichText))
    .firstWhere((p) => p.text.toPlainText().contains(text));

void main() {
  testWidgets("a row's pipes are drawn as room, but on the caret's row", (
    tester,
  ) async {
    await _pump(tester, 0);
    // At rest the pipes and the spaces round the cells are room, drawn as
    // nothing: no pipe is on screen.
    expect(_row(tester, 'one').text.toPlainText(), isNot(contains('|')));
    final buffer = SourceBuffer.fromText(_note);
    await _pump(tester, buffer.offsetOfLine(4) + 3);
    expect(_row(tester, 'one').text.toPlainText(), '| one | two |');
  });

  testWidgets('the delimiter row takes no room, but on the caret', (
    tester,
  ) async {
    await _pump(tester, 0);
    expect(_row(tester, '---').size.height, lessThan(1));
    final buffer = SourceBuffer.fromText(_note);
    await _pump(tester, buffer.offsetOfLine(3) + 1);
    expect(_row(tester, '---').size.height, greaterThan(10));
  });
}
