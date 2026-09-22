// Opening a very large note, with either engine (#245).
//
// Two costs froze the app on a 22 MB note reopened at start. The shell filled
// the legacy editor's controller although the unified engine never shows it
// (3.8 s of a 4.2 s open at 8 MB). And the legacy highlighter read the note
// line by line through `CodeLines[i]`, which walks the segments, under a
// `CodeLines.length` that folds over them — O(lines × segments), more than a
// minute before the first frame. The bound is generous: the opens it guards
// cost one and two seconds at 21 MB here.
// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

void main() {
  for (final unified in [true, false]) {
    testWidgets(
      'a 21 MB note opens (${unified ? 'unified' : 'legacy'}) without the wait',
      (tester) async {
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
                unifiedMarkdown: unified,
                readNote: (_) async => text,
                writeNote: (_, _) async {},
              ),
            ),
          ),
        );
        await tester.pump();
        clock.stop();
        print('open, ${text.length} chars: ${clock.elapsedMilliseconds} ms');
        expect(
          find.byType(MarkdownSourceView),
          unified ? findsOneWidget : findsNothing,
        );
        expect(clock.elapsedMilliseconds, lessThan(5000));
      },
    );
  }
}
