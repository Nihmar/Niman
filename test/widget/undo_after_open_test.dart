// A note just opened must not be undone into an empty buffer: the load
// is not an edit. Ctrl+Z right after opening wiped the note, and the save
// that followed wrote the empty text over it (0.0.8 test round, item 11).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

void main() {
  late List<String> writes;

  Future<CodeLineEditingController> open(
    WidgetTester tester, {
    int reloadToken = 0,
    String text = 'hello world',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteView(
            path: '/n/a.md',
            showLineNumbers: true,
            autofocusEditor: false,
            reloadToken: reloadToken,
            readNote: (_) async => text,
            writeNote: (_, content) async => writes.add(content),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.widget<CodeEditor>(find.byType(CodeEditor)).controller!;
  }

  setUp(() => writes = []);

  testWidgets('Ctrl+Z on a note just opened leaves it as it is', (
    tester,
  ) async {
    final controller = await open(tester);
    await tester.tap(find.byType(CodeEditor));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(controller.text, 'hello world');
    expect(controller.canUndo, isFalse);
    expect(writes, isEmpty, reason: 'nothing to save');
  }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

  testWidgets('undo after an edit goes back to the note, no further', (
    tester,
  ) async {
    final controller = await open(tester);
    controller.text = 'hello world!';
    await tester.pump();
    controller.undo();
    await tester.pump();
    expect(controller.text, 'hello world');
    expect(controller.canUndo, isFalse);
  });

  testWidgets('text taken again from disk is where undo starts', (
    tester,
  ) async {
    var disk = 'one';
    await tester.pumpWidget(const SizedBox());
    Widget view(int token) => MaterialApp(
      home: Scaffold(
        body: NoteView(
          path: '/n/a.md',
          showLineNumbers: true,
          autofocusEditor: false,
          reloadToken: token,
          readNote: (_) async => disk,
          writeNote: (_, content) async => writes.add(content),
        ),
      ),
    );
    await tester.pumpWidget(view(0));
    await tester.pumpAndSettle();
    disk = 'two';
    await tester.pumpWidget(view(1));
    await tester.pumpAndSettle();
    final controller = tester
        .widget<CodeEditor>(find.byType(CodeEditor))
        .controller!;
    expect(controller.text, 'two');
    expect(controller.canUndo, isFalse);
  });
}
