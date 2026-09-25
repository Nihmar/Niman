// A heading's hashes, revealed in `live` with the caret on its line, start at
// the note's left margin like any other glyph — where the text is set — and
// the title moves right by what the marks take.
//
// They used to be set into the line's indent, which a heading does not have:
// the `# ` hung out to the left, and with the line numbers off (a phone) it
// reached the pane's own edge (2026-09-25 report, issue #288).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

void main() {
  for (final level in [1, 2, 3]) {
    testWidgets('an H$level’s hashes start at the margin', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final hashes = '#' * level;
      final text = 'body\n\n$hashes Title\n';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => MarkdownSurface(
                buffer: SourceBuffer.fromText(text),
                mode: MarkdownSurfaceMode.live,
                theme: markdownThemeOf(context),
                showLineNumbers: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      tester
          .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
          .placeCaret(text.indexOf('Title'));
      await tester.pumpAndSettle();

      double leftOf(RenderParagraph p, int offset) => p
          .localToGlobal(
            Offset(
              p
                  .getBoxesForSelection(
                    TextSelection(baseOffset: offset, extentOffset: offset + 1),
                  )
                  .first
                  .left,
              0,
            ),
          )
          .dx;

      final body = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText() == 'body');
      final heading = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText().contains('Title'));

      // Every glyph of the note starts on one margin, the marks included.
      expect(leftOf(heading, 0), closeTo(leftOf(body, 0), 0.01));
      // And the title follows the marks, rather than the marks hanging off
      // the margin to keep it where it was.
      expect(leftOf(heading, hashes.length + 1), greaterThan(leftOf(body, 0)));
    });
  }
}
