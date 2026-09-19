// Issue #70: typewriter mode. The row being written keeps to the middle of
// the editor, in both editors: a caret moving down a row moves the note by
// that row, and the caret stays where it was on screen.
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

/// Short lines, so a line is one row and rows are all one height.
final String _note = [for (var i = 0; i < 300; i++) 'line $i'].join('\n');

Widget _app({
  required bool typewriter,
  bool wysiwyg = false,
  VoidCallback? onToggle,
}) => MaterialApp(
  home: Scaffold(
    body: SizedBox(
      height: 600,
      child: NoteView(
        path: '/n/a.md',
        showLineNumbers: false,
        autofocusEditor: false,
        toolbarTop: true,
        typewriter: typewriter,
        showWysiwyg: wysiwyg,
        onToggleTypewriter: onToggle,
        onEditorKindChanged: (_) {},
        readNote: (_) async => _note,
        writeNote: (_, _) async {},
      ),
    ),
  ),
);

void main() {
  group('source editor', () {
    Future<ScrollController> open(
      WidgetTester tester, {
      required bool typewriter,
    }) async {
      await tester.pumpWidget(_app(typewriter: typewriter));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CodeEditor));
      await tester.pumpAndSettle();
      return tester
          .widget<CodeEditor>(find.byType(CodeEditor))
          .scrollController!
          .verticalScroller;
    }

    Future<double> caretTo(WidgetTester tester, int line) async {
      tester.widget<CodeEditor>(find.byType(CodeEditor)).controller!.selection =
          CodeLineSelection.collapsed(index: line, offset: 0);
      await tester.pumpAndSettle();
      return tester
          .widget<CodeEditor>(find.byType(CodeEditor))
          .scrollController!
          .verticalScroller
          .offset;
    }

    testWidgets('the caret’s row is held in the middle', (tester) async {
      final scroll = await open(tester, typewriter: true);
      final at100 = await caretTo(tester, 100);
      final at101 = await caretTo(tester, 101);
      final at150 = await caretTo(tester, 150);
      final row = at101 - at100;
      expect(row, greaterThan(0));
      // A row down moves the note by that row: the caret stays put.
      expect(at150 - at100, closeTo(50 * row, 1));
      // And where it stays is the middle of the viewport.
      final viewport = scroll.position.viewportDimension;
      final caretCenter = 100 * row + row / 2 - at100;
      expect(caretCenter, closeTo(viewport / 2, row));
    });

    testWidgets('the last line reaches the middle too', (tester) async {
      final scroll = await open(tester, typewriter: true);
      final at298 = await caretTo(tester, 298);
      final at299 = await caretTo(tester, 299);
      final row = at299 - at298;
      expect(row, greaterThan(0));
      final viewport = scroll.position.viewportDimension;
      expect(299 * row + row / 2 - at299, closeTo(viewport / 2, row));
    });

    // Line 20 is on screen from the start, below the middle: on, the note
    // moves it up there; off, nothing moves.
    testWidgets('on, a line below the middle is brought up', (tester) async {
      await open(tester, typewriter: true);
      expect(await caretTo(tester, 20), greaterThan(0));
    });

    testWidgets('off, the note stays where it is', (tester) async {
      await open(tester, typewriter: false);
      expect(await caretTo(tester, 20), 0);
    });
  });

  testWidgets('WYSIWYG: the caret’s row is held in the middle', (tester) async {
    await tester.pumpWidget(_app(typewriter: true, wysiwyg: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(quill.QuillEditor));
    await tester.pumpAndSettle();
    final editor = tester.widget<quill.QuillEditor>(
      find.byType(quill.QuillEditor),
    );
    // Where each line starts in the document ("line N\n").
    final starts = <int>[];
    var at = 0;
    for (var i = 0; i < 300; i++) {
      starts.add(at);
      at += 'line $i'.length + 1;
    }
    Future<double> caretTo(int line) async {
      editor.controller.updateSelection(
        TextSelection.collapsed(offset: starts[line]),
        quill.ChangeSource.local,
      );
      await tester.pumpAndSettle();
      return editor.scrollController.offset;
    }

    final at100 = await caretTo(100);
    final at101 = await caretTo(101);
    final at150 = await caretTo(150);
    final row = at101 - at100;
    expect(row, greaterThan(0));
    expect(at150 - at100, closeTo(50 * row, 2));
  });

  // The one control in the note that says whether it is on (#70).
  testWidgets('the status row’s switch shows it and turns it', (tester) async {
    var turned = 0;
    await tester.pumpWidget(_app(typewriter: true, onToggle: () => turned++));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const Key('typewriter-toggle'));
    expect(tester.widget<IconButton>(toggle).isSelected, isTrue);
    await tester.tap(toggle);
    expect(turned, 1);
  });

  testWidgets('without a switch handed in, the row has none', (tester) async {
    await tester.pumpWidget(_app(typewriter: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('typewriter-toggle')), findsNothing);
  });

  // 0.0.8 test round: the row being written is lit, faintly.
  testWidgets('the source editor lights the caret row, only when on', (
    tester,
  ) async {
    await tester.pumpWidget(_app(typewriter: true));
    await tester.pumpAndSettle();
    Color? lit() => tester
        .widget<CodeEditor>(find.byType(CodeEditor))
        .style
        ?.cursorLineColor;
    expect(lit(), isNotNull);
    await tester.pumpWidget(_app(typewriter: false));
    await tester.pumpAndSettle();
    expect(lit(), isNull);
  });

  testWidgets('the WYSIWYG lights the caret row while it has the focus', (
    tester,
  ) async {
    await tester.pumpWidget(_app(typewriter: true, wysiwyg: true));
    await tester.pumpAndSettle();
    final band = find.byKey(const Key('wysiwyg-lit-row'));
    expect(band, findsNothing, reason: 'nothing lit before the focus');
    await tester.tap(find.byType(quill.QuillEditor));
    await tester.pumpAndSettle();
    expect(band, findsOne);
    await tester.pumpWidget(_app(typewriter: false, wysiwyg: true));
    await tester.pumpAndSettle();
    expect(band, findsNothing);
  });
}
