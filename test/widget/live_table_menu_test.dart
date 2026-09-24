// A table's menu in `live` (#261): a right click on a cell offers its row,
// its column and the sorts; each action is one edit and one undo step.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';

const String _note =
    'caret\n\n| a | b |\n| --- | --- |\n| uno | 2 |\n| due | 1 |\n\nafter';

Future<MarkdownSourceViewState> _pump(
  WidgetTester tester, {
  MarkdownSurfaceMode mode = MarkdownSurfaceMode.live,
}) async {
  tester.view.physicalSize = const Size(900, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => MarkdownSurface(
            buffer: SourceBuffer.fromText(_note),
            mode: mode,
            theme: markdownThemeOf(context),
            showLineNumbers: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));
}

/// Right-clicks the cell reading [word], on the word itself.
Future<void> _menuOn(WidgetTester tester, String word) async {
  final paragraph = tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .firstWhere((p) {
        final text = p.text.toPlainText();
        return text.contains(word) && !text.contains('caret');
      });
  final text = paragraph.text.toPlainText();
  final at = text.indexOf(word);
  final box = paragraph
      .getBoxesForSelection(
        TextSelection(baseOffset: at, extentOffset: at + word.length),
      )
      .first;
  await tester.tapAt(
    paragraph.localToGlobal(box.toRect().center),
    buttons: kSecondaryMouseButton,
    kind: PointerDeviceKind.mouse,
  );
  await tester.pumpAndSettle();
}

void main() {
  // The desktop's menu, where a submenu takes the menu's place; the phone's
  // face is the test at the end.
  final desktop = TargetPlatformVariant.only(TargetPlatform.linux);

  testWidgets('Row › Add row below: a row under the cell’s, one undo step', (
    tester,
  ) async {
    final view = await _pump(tester);
    final buffer = view.widget.buffer;
    await _menuOn(tester, 'uno');
    expect(find.byKey(const Key('table-row')), findsOneWidget);
    expect(find.byKey(const Key('table-column')), findsOneWidget);
    await tester.tap(find.byKey(const Key('table-row')));
    await tester.pumpAndSettle();
    // The submenu in the menu's place, the way back on top.
    expect(find.byKey(const Key('table-row-back')), findsOneWidget);
    await tester.tap(find.byKey(const Key('table-row-below')));
    await tester.pumpAndSettle();
    expect(
      buffer.text,
      'caret\n\n| a | b |\n| --- | --- |\n| uno | 2 |\n|  |  |\n'
      '| due | 1 |\n\nafter',
    );
    expect(
      buffer.lineOf(view.selection.extent),
      5,
      reason: 'the caret is in the new row',
    );
    expect(view.undo(), isTrue);
    expect(buffer.text, _note);
  }, variant: desktop);

  testWidgets('a row above the header does not apply', (tester) async {
    await _pump(tester);
    await _menuOn(tester, 'a');
    await tester.tap(find.byKey(const Key('table-row')));
    await tester.pumpAndSettle();
    final above = tester.widget<InkWell>(
      find.byKey(const Key('table-row-above')),
    );
    expect(above.onTap, isNull);
  }, variant: desktop);

  testWidgets('sort by the column the cell is in', (tester) async {
    final view = await _pump(tester);
    await _menuOn(tester, '2');
    await tester.tap(find.byKey(const Key('table-sort-ascending')));
    await tester.pumpAndSettle();
    expect(
      view.widget.buffer.text,
      'caret\n\n| a | b |\n| --- | --- |\n| due | 1 |\n| uno | 2 |\n\nafter',
    );
  }, variant: desktop);

  testWidgets('Column › Delete column', (tester) async {
    final view = await _pump(tester);
    await _menuOn(tester, 'uno');
    await tester.tap(find.byKey(const Key('table-column')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('table-column-delete')));
    await tester.pumpAndSettle();
    expect(
      view.widget.buffer.text,
      'caret\n\n| b |\n| --- |\n| 2 |\n| 1 |\n\nafter',
    );
  }, variant: desktop);

  testWidgets('the source mode has no table menu: it is text there', (
    tester,
  ) async {
    await _pump(tester, mode: MarkdownSurfaceMode.source);
    await _menuOn(tester, 'uno');
    expect(find.byKey(const Key('context-copy')), findsNothing);
    expect(find.byKey(const Key('table-row')), findsNothing);
  }, variant: desktop);

  testWidgets('on a phone, Row… opens a sheet of the row’s actions', (
    tester,
  ) async {
    final view = await _pump(tester);
    view.placeCaret(view.widget.buffer.text.indexOf('uno') + 1);
    await tester.pump();
    await tester.longPressAt(
      tester.getCenter(find.textContaining('uno', findRichText: true).first),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('table-row')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('table-row-delete')));
    await tester.pumpAndSettle();
    expect(
      view.widget.buffer.text,
      'caret\n\n| a | b |\n| --- | --- |\n| due | 1 |\n\nafter',
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  group('the + handles', () {
    testWidgets('show on hover, and add a column and a row at the edges', (
      tester,
    ) async {
      final view = await _pump(tester);
      final buffer = view.widget.buffer;
      expect(find.byKey(const Key('table-add-column')), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      final cell = tester.getCenter(
        find.textContaining('uno', findRichText: true).first,
      );
      await mouse.addPointer(location: cell);
      await mouse.moveTo(cell + const Offset(1, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('table-add-column')), findsOneWidget);
      // On to the handle: it stays.
      await mouse.moveTo(
        tester.getCenter(find.byKey(const Key('table-add-column'))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('table-add-column')));
      await tester.pumpAndSettle();
      expect(
        buffer.text,
        'caret\n\n| a | b |  |\n| --- | --- | --- |\n'
        '| uno | 2 |  |\n| due | 1 |  |\n\nafter',
      );
      expect(view.undo(), isTrue);
      await mouse.moveTo(cell);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('table-add-row')));
      await tester.pumpAndSettle();
      expect(
        buffer.text,
        'caret\n\n| a | b |\n| --- | --- |\n| uno | 2 |\n| due | 1 |\n'
        '|  |  |\n\nafter',
      );
      // Off the table, the handles go.
      await mouse.moveTo(
        tester.getCenter(find.textContaining('caret', findRichText: true)),
      );
      // A moment later: the move onto a handle leaves the note first.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('table-add-row')), findsNothing);
    }, variant: desktop);

    testWidgets('on a phone they show while the caret is in the table', (
      tester,
    ) async {
      final view = await _pump(tester);
      await tester.pump();
      expect(find.byKey(const Key('table-add-row')), findsNothing);
      view.placeCaret(view.widget.buffer.text.indexOf('uno'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('table-add-row')), findsOneWidget);
      expect(find.byKey(const Key('table-add-column')), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('source has none: a table is its text there', (tester) async {
      await _pump(tester, mode: MarkdownSurfaceMode.source);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      addTearDown(mouse.removePointer);
      await mouse.addPointer(
        location: tester.getCenter(
          find.textContaining('uno', findRichText: true).first,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('table-add-column')), findsNothing);
    }, variant: desktop);
  });
}
