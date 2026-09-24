// A heading's hashes, revealed in `live` with the caret on its line, hang
// out to the left of the title rather than push it right — but never onto
// the line numbers (2026-09-24 report: the `#` of an H1 sat on its number).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

void main() {
  for (final level in [1, 2, 3]) {
    testWidgets('an H$level’s hashes stay off its number', (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1;
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

      final number = tester.getRect(find.text('3'));
      final heading = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText().contains('Title'));
      final hash = heading
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
          )
          .first
          .toRect();
      final left = heading.localToGlobal(hash.topLeft).dx;
      expect(
        left,
        greaterThanOrEqualTo(number.right),
        reason: 'the # starts past the number ($left < ${number.right})',
      );
    });
  }

  testWidgets('a heading that folds keeps its arrow clear', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const text = '# Hello\n\nSome text.\n';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MarkdownSurface(
              buffer: SourceBuffer.fromText(text),
              mode: MarkdownSurfaceMode.live,
              theme: markdownThemeOf(context),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    tester
        .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
        .placeCaret(text.indexOf('Hello') + 2);
    await tester.pumpAndSettle();

    final arrow = tester.getRect(find.byKey(const ValueKey<String>('fold-0')));
    final heading = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .firstWhere((p) => p.text.toPlainText().contains('Hello'));
    final hash = heading
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 1),
        )
        .first
        .toRect();
    expect(
      heading.localToGlobal(hash.topLeft).dx,
      greaterThanOrEqualTo(arrow.right),
    );
    // And the arrow still takes its click.
    await tester.tap(find.byKey(const ValueKey<String>('fold-0')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Some text.', findRichText: true), findsNothing);
  });
}
