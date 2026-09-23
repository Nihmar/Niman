// A line `live` draws as nothing — a typeset formula's lines past its
// first, definitions out of the caret's reach, a table's delimiter row —
// takes no room with the line numbers on either: its number is not drawn,
// or it kept the row open around nothing (0.0.9 test round).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:katex_dart/katex_dart.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/preview/math_cache.dart';

/// Where the line reading `after` starts down the pane, numbers or not.
Future<double> _afterTop(
  WidgetTester tester,
  String note, {
  required bool numbers,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MarkdownSurface(
            buffer: SourceBuffer.fromText(note),
            mode: MarkdownSurfaceMode.live,
            theme: markdownThemeOf(context),
            selection: const SelectionModel.at(0),
            showLineNumbers: numbers,
            mathCache: MathCache(
              renderer: (tex, {required displayMode}) => renderToBox(
                tex,
                options: KatexOptions(displayMode: displayMode),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .firstWhere((paragraph) => paragraph.text.toPlainText() == 'after')
      .localToGlobal(Offset.zero)
      .dy;
}

void main() {
  const notes = <String, String>{
    'a formula': 'top\n\n\$\$\nx + y\n\\\\\nz\n\$\$\nafter',
    'definitions': 'top\n\n[^1]: una\n[^2]: due\n\nafter',
    'a table': 'top\n\n| a | b |\n| --- | --- |\n| c | d |\n\nafter',
  };
  for (final MapEntry(key: name, value: note) in notes.entries) {
    testWidgets('$name takes the same room with the numbers on', (
      tester,
    ) async {
      final without = await _afterTop(tester, note, numbers: false);
      expect(await _afterTop(tester, note, numbers: true), without);
    });
  }
}
