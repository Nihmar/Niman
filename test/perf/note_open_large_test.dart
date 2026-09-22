// Opening a very large note with the unified engine on (#245).
//
// The shell filled the legacy editor's controller on every open, although the
// unified engine never shows it: its line model and its highlighter over every
// line took 3.8 s of a 4.2 s open at 8 MB, and a 22 MB note — reopened at
// start — froze the app before it drew. The bound is generous; the open it
// guards costs about half a second at 21 MB here.
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

void main() {
  testWidgets('a 21 MB note opens in the unified pane without the wait', (
    tester,
  ) async {
    final text = List<String>.generate(
      1000000,
      (at) => '26ITQTG4TNS6194${at % 10}S4 2',
    ).join('\n');
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final clock = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/notes/a.md',
            showLineNumbers: true,
            autofocusEditor: false,
            toolbarTop: true,
            unifiedMarkdown: true,
            readNote: (_) async => text,
            writeNote: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pump();
    clock.stop();
    print('open, ${text.length} chars: ${clock.elapsedMilliseconds} ms');
    expect(find.byType(MarkdownSourceView), findsOneWidget);
    expect(clock.elapsedMilliseconds, lessThan(5000));
  });
}
