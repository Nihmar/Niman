// Ctrl+End on a note whose rows come out shorter than estimated: the jump
// is planned on the estimates, and the position must land on the note's
// end rather than past it and spring back (a bounce on the desktop).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

/// Three hundred short lines, then eighty that are all bold marks: estimated
/// by their length, drawn in `live` at a third of it.
String _note() {
  final note = StringBuffer();
  for (var line = 0; line < 300; line++) {
    note.writeln('plain line $line');
  }
  for (var line = 0; line < 80; line++) {
    note.writeln(List.filled(33, '**a**').join(' '));
  }
  return (note..write('end')).toString();
}

void main() {
  for (final mode in MarkdownSurfaceMode.values) {
    testWidgets('Ctrl+End lands on the end, with no spring back ($mode)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => MarkdownSurface(
                buffer: SourceBuffer.fromText(_note()),
                mode: mode,
                theme: markdownThemeOf(context),
                showLineNumbers: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(MarkdownSourceView));
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          position.pixels,
          lessThanOrEqualTo(position.maxScrollExtent),
          reason: 'frame $frame: past the end, the platform springs back',
        );
        expect(position.activity, isNot(isA<BallisticScrollActivity>()));
      }
      expect(position.pixels, position.maxScrollExtent);
    });
  }
}
