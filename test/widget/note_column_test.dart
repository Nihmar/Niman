// Issue #171: the note as a centred column. The text keeps to the column
// on both editors and the preview, a pane narrower than the column simply
// is the column, and switching editors does not move the text sideways.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:niman/src/preview/markdown_preview.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:re_editor/re_editor.dart';

const _column = NoteColumn();

/// Pumps [child] alone in a surface [width] wide.
Future<void> _pumpAt(WidgetTester tester, double width, Widget child) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pumpAndSettle();
}

/// Where the source editor's text starts: re_editor paints its lines
/// itself, so the x is read off the layout — the fold markers end the row
/// number column, and the field keeps its own 5 px after it.
double _sourceTextLeft(WidgetTester tester) =>
    tester.getRect(find.byType(DefaultCodeChunkIndicator)).right + 5;

/// Where the WYSIWYG's (or the preview's) paragraph starts.
double _richTextLeft(WidgetTester tester, String text) =>
    tester.getTopLeft(find.textContaining(text, findRichText: true).first).dx;

Future<double> _sourceAt(WidgetTester tester, double width) async {
  final controller = CodeLineEditingController.fromText('plain words here');
  final focus = FocusNode();
  addTearDown(controller.dispose);
  addTearDown(focus.dispose);
  await _pumpAt(
    tester,
    width,
    NoteEditor(controller: controller, focusNode: focus, column: _column),
  );
  return _sourceTextLeft(tester);
}

Future<double> _wysiwygAt(
  WidgetTester tester,
  double width, {
  NoteColumn column = _column,
}) async {
  await _pumpAt(
    tester,
    width,
    WysiwygEditor(data: 'plain words here', onChanged: (_) {}, column: column),
  );
  return _richTextLeft(tester, 'plain words');
}

void main() {
  group('NoteColumn', () {
    test('gives the space left over to the sides', () {
      // 1200 − 700 of text − 2 × 16 of inset, halved.
      expect(_column.sideSpaceIn(1200), 234);
    });

    test('a pane narrower than the column is the column', () {
      expect(_column.sideSpaceIn(400), 0);
      expect(_column.sideSpaceIn(732), 0);
    });

    test('off, the text runs the width of the pane', () {
      expect(NoteColumn.off.sideSpaceIn(1600), 0);
    });
  });

  group('the text keeps to the column', () {
    testWidgets('in the WYSIWYG', (tester) async {
      expect(await _wysiwygAt(tester, 1200), 234 + NoteColumn.textInset);
    });

    testWidgets('in the source editor, row numbers and all', (tester) async {
      expect(await _sourceAt(tester, 1200), 234 + NoteColumn.textInset);
    });

    testWidgets('in the preview', (tester) async {
      await _pumpAt(
        tester,
        1200,
        const MarkdownPreview(data: 'plain words here', column: _column),
      );
      expect(_richTextLeft(tester, 'plain words'), 234 + NoteColumn.textInset);
    });

    testWidgets('switching editors does not move the text sideways', (
      tester,
    ) async {
      final source = await _sourceAt(tester, 1440);
      final wysiwyg = await _wysiwygAt(tester, 1440);
      expect(source, wysiwyg);
    });
  });

  group('without room for the column', () {
    testWidgets("a narrow pane keeps today's layout", (tester) async {
      expect(await _wysiwygAt(tester, 400), NoteColumn.textInset);
    });

    testWidgets('the setting off keeps the full width', (tester) async {
      expect(
        await _wysiwygAt(tester, 1200, column: NoteColumn.off),
        NoteColumn.textInset,
      );
    });
  });

  // #173: the toolbar's first button starts where the text does.
  testWidgets('the toolbar starts at the text', (tester) async {
    await _pumpAt(
      tester,
      1200,
      NoteView(
        path: '/n/a.md',
        showLineNumbers: true,
        autofocusEditor: false,
        toolbarTop: true,
        showWysiwyg: true,
        noteColumn: _column,
        readNote: (_) async => 'plain words here',
      ),
    );
    // In the one row above the note (#173).
    expect(
      find.descendant(
        of: find.byKey(const Key('note-top-bar')),
        matching: find.byKey(const Key('toolbar-bold')),
      ),
      findsOne,
    );
    final icon = find.descendant(
      of: find.byKey(const Key('toolbar-bold')),
      matching: find.byType(Icon),
    );
    expect(tester.getTopLeft(icon).dx, _richTextLeft(tester, 'plain words'));
  });

  testWidgets('the chrome keeps to the same column', (tester) async {
    const bar = Key('bar');
    await _pumpAt(
      tester,
      1200,
      const Column(
        children: [
          NoteColumnPadding(
            column: _column,
            child: SizedBox(key: bar, height: 20, width: double.infinity),
          ),
        ],
      ),
    );
    final rect = tester.getRect(find.byKey(bar));
    expect(rect.left, 234);
    expect(rect.width, 700 + 2 * NoteColumn.textInset);
  });
}
