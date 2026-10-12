// #789: source mode sets the note in the chosen face, a theme built anew
// in every build (`surfaceThemeFor`). A rebuild with a theme of the same
// values has not moved the caret's line, so it measures nothing again.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

void main() {
  testWidgets('a rebuild with the same theme values measures no caret', (
    tester,
  ) async {
    final buffer = SourceBuffer.fromText('# Title\n\nSome text here.\n');
    final view = GlobalKey<MarkdownSourceViewState>();
    final rebuild = ValueNotifier<int>(0);
    addTearDown(rebuild.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<int>(
            valueListenable: rebuild,
            builder: (context, _, _) => MarkdownSurface(
              viewKey: view,
              buffer: buffer,
              mode: MarkdownSurfaceMode.source,
              theme: markdownThemeOf(context),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = view.currentState!.caretMeasures;

    // The source face's theme is a new instance each of these builds.
    for (var at = 1; at <= 3; at++) {
      rebuild.value = at;
      await tester.pump();
      await tester.pump();
    }
    expect(view.currentState!.caretMeasures, before);
  });
}
