import 'package:copist/src/ui/note_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The editor field's buffer text.
String _editorText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

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
              return '# Hello\nworld';
            },
          ),
        ),
      );
      await tester.pump(); // let the async load land.
      expect(readPath, '/notes/a.md');
      expect(_editorText(tester), '# Hello\nworld');
      expect(find.text('saved'), findsOneWidget);
    });

    testWidgets('autosaves ~500 ms after the last edit', (tester) async {
      final writes = <String>[];
      await tester.pumpWidget(
        _app(
          NoteView(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'edited');
      await tester.pump();
      expect(writes, isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      expect(writes, ['edited']);
      expect(find.text('saved'), findsOneWidget);
    });

    testWidgets('saves on dispose when the debounce has not fired',
        (tester) async {
      final writes = <String>[];
      await tester.pumpWidget(
        _app(
          NoteView(
            path: '/notes/a.md',
            readNote: (_) async => 'start',
            writeNote: (p, c) async => writes.add(c),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'abandoned');
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump();
      expect(writes, ['abandoned']);
    });
  });
}
