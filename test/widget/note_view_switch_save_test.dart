// Switching note while a save is in flight: the edits made during that save
// must still reach the outgoing note's file (issue #334). A save reads its
// text once, at its start, so the switch takes the newest revision itself and
// chains its write behind the save that is already running — and never lets
// two writers race for one path.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/ui/note_view.dart';

void main() {
  late Map<String, String> disk;

  void type(WidgetTester tester, String text) => tester
      .state<MarkdownSourceViewState>(find.byType(MarkdownSourceView))
      .replaceText(0, 0, text);

  Widget app(NoteView view) => MaterialApp(home: Scaffold(body: view));

  setUp(() {
    disk = {'/notes/a.md': 'a', '/notes/b.md': 'b'};
  });

  testWidgets('an edit made during a save is written when the note switches', (
    tester,
  ) async {
    final firstSave = Completer<void>();
    final events = <String>[];
    var held = false;

    NoteView view(String path) => NoteView(
      path: path,
      showLineNumbers: false,
      autofocusEditor: false,
      readNote: (path) async => disk[path] ?? '',
      writeNote: (path, text) async {
        events.add('start $text');
        if (!held) {
          held = true;
          await firstSave.future;
        }
        disk[path] = text;
        events.add('end $text');
      },
    );

    await tester.pumpWidget(app(view('/notes/a.md')));
    await tester.pump();
    type(tester, 'one ');
    await tester.pump();
    // The debounce runs out: the save starts and hangs inside the seam, so
    // the window is genuinely open.
    await tester.pump(const Duration(seconds: 2));
    expect(events, ['start one a']);

    type(tester, 'two ');
    await tester.pump();
    await tester.pumpWidget(app(view('/notes/b.md')));
    await tester.pump();

    firstSave.complete();
    await tester.pumpAndSettle();

    expect(events, [
      'start one a',
      'end one a',
      'start two one a',
      'end two one a',
    ]);
    expect(disk['/notes/a.md'], 'two one a');
    expect(disk['/notes/b.md'], 'b', reason: 'the incoming note is untouched');
  });

  testWidgets('an edit made during a streamed save survives the switch', (
    tester,
  ) async {
    final firstSave = Completer<void>();
    final started = <String>[];
    final done = <String>[];
    final fallbacks = <String>[];
    var held = false;

    NoteView view(String path) => NoteView(
      path: path,
      showLineNumbers: false,
      autofocusEditor: false,
      readNote: (path) async => disk[path] ?? '',
      writeNote: (_, text) async => fallbacks.add(text),
      saveNoteStream:
          (path, content, {required editSession, references}) async {
            final text = StringBuffer();
            for (var index = 0; ; index++) {
              final slice = await content(index);
              if (slice == null) break;
              text.write(utf8.decode(slice));
            }
            final saved = text.toString();
            started.add('$path: $saved');
            if (!held) {
              held = true;
              await firstSave.future;
            }
            disk[path] = saved;
            done.add('$path: $saved');
          },
    );

    await tester.pumpWidget(app(view('/notes/a.md')));
    await tester.pump();
    type(tester, 'one ');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(started, ['/notes/a.md: one a']);

    type(tester, 'two ');
    await tester.pump();
    await tester.pumpWidget(app(view('/notes/b.md')));
    await tester.pump();

    firstSave.complete();
    await tester.pumpAndSettle();

    expect(started, ['/notes/a.md: one a', '/notes/a.md: two one a']);
    expect(done, started, reason: 'the second write waits for the first');
    expect(fallbacks, isEmpty, reason: 'the stream seam is the one in use');
    expect(disk['/notes/a.md'], 'two one a');
  });
}
