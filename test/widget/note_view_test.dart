import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/note_editor.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(NoteView view) => MaterialApp(home: Scaffold(body: view));

void main() {
  group('NoteView', () {
    testWidgets('loads the note file into the editor', (tester) async {
      String? readPath;
      await tester.pumpWidget(
        _app(
          NoteView(
            path: '/notes/a.md',
            readNote: (p) async {
              readPath = p;
              return '# Hello\r\nworld';
            },
          ),
        ),
      );
      await tester.pump(); // let the async load land.
      expect(readPath, '/notes/a.md');
      expect(find.byType(NoteEditor), findsOneWidget);
      expect(find.text('saved'), findsOneWidget);
    });

    testWidgets('autosaves ~500 ms after the last edit', (tester) async {
      final writes = <String>[];
      final input = ComposingInput('start');
      await tester.pumpWidget(
        _app(
          NoteView(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
            input: input,
          ),
        ),
      );
      await tester.pump();
      // Type via the IME (the NoteEditor has no TextField).
      input.apply(
        const TextEditingDeltaInsertion(
          oldText: 'start',
          insertionOffset: 5,
          textInserted: '!',
          selection: TextSelection.collapsed(offset: 6),
          composing: TextRange.empty,
        ),
      );
      await tester.pump();
      expect(writes, isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, ['start!']);
      expect(find.text('saved'), findsOneWidget);
    });

    testWidgets('saves on dispose when the debounce has not fired',
        (tester) async {
      final writes = <String>[];
      final input = ComposingInput('start');
      await tester.pumpWidget(
        _app(
          NoteView(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
            input: input,
          ),
        ),
      );
      await tester.pump();
      input.apply(
        const TextEditingDeltaInsertion(
          oldText: 'start',
          insertionOffset: 5,
          textInserted: '!',
          selection: TextSelection.collapsed(offset: 6),
          composing: TextRange.empty,
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump();
      expect(writes, ['start!']);
    });
  });
}
