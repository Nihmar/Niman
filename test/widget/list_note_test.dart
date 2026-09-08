// T-TK-04/09: the list-kind GUI — checkable rows, nesting, the add row,
// in-place text editing and drag reordering/sub-lists.
import 'package:copist/src/ui/kinds/list_item_row.dart';
import 'package:copist/src/ui/kinds/list_note.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(ListNoteView view) =>
    MaterialApp(home: Scaffold(body: view));

Finder _row(int index) => find.byType(ListItemRow).at(index);

Finder _rowCheckbox(int index) => find.descendant(
  of: _row(index),
  matching: find.byType(Checkbox),
);

Finder _rowEditField() => find.descendant(
  of: find.byType(ListItemRow),
  matching: find.byType(TextField),
);

/// Long-presses [from] and drags to [to] (the row drag of T-TK-09).
Future<void> _longPressDrag(WidgetTester tester, Finder from, Offset to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump(const Duration(milliseconds: 600));
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('renders items; tapping the checkbox flips byte-stably', (
    tester,
  ) async {
    // The host feeds the edited text back, like NoteView does (the
    // controller's text changes and the kind body re-parses).
    var text = '---\ntype: list\n---\n- [ ] one\n  - [x] two\n';
    Widget app() => _app(ListNoteView(text: text, onChanged: (t) {
          text = t;
        }));
    await tester.pumpWidget(app());
    expect(find.text('one'), findsOneWidget);
    expect(find.text('two'), findsOneWidget);

    await tester.tap(_rowCheckbox(0));
    await tester.pump();
    expect(text, '---\ntype: list\n---\n- [x] one\n  - [x] two\n');

    // The host rebuilds with the new text; tapping again flips it back.
    await tester.pumpWidget(app());
    await tester.tap(_rowCheckbox(0));
    await tester.pump();
    expect(text, '---\ntype: list\n---\n- [ ] one\n  - [x] two\n');
  });

  testWidgets('tapping the text edits it in place', (tester) async {
    var text = '---\ntype: list\n---\n- [ ] one\n  - [x] two\n';
    Widget app() => _app(ListNoteView(text: text, onChanged: (t) {
          text = t;
        }));
    await tester.pumpWidget(app());

    // Tapping the text (not the checkbox) starts the in-place edit.
    await tester.tap(find.text('one'));
    await tester.pump();
    expect(_rowEditField(), findsOneWidget);

    await tester.enterText(_rowEditField(), 'one edited');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(text, '---\ntype: list\n---\n- [ ] one edited\n  - [x] two\n');

    // The host rebuilds with the new text; the field is gone.
    await tester.pumpWidget(app());
    await tester.pump();
    expect(_rowEditField(), findsNothing);
    expect(find.text('one edited'), findsOneWidget);
  });

  testWidgets('an open edit commits when another row is tapped',
      (tester) async {
    String? out;
    var text = '---\ntype: list\n---\n- [ ] one\n- [ ] two\n';
    Widget app() => MaterialApp(
      home: Scaffold(
        body: ListNoteView(text: text, onChanged: (t) {
          text = t;
          out = t;
        }),
      ),
    );
    await tester.pumpWidget(app());
    await tester.pump();

    // Start editing the first row, then tap the second row's text: the
    // first edit commits, the second opens.
    await tester.tap(find.byType(ListItemRow).first);
    await tester.pump();
    await tester.enterText(_rowEditField(), 'one edited');

    await tester.tap(find.byType(ListItemRow).last);
    await tester.pump();
    await tester.pump(); // The focus change commits the first edit.
    expect(out, '---\ntype: list\n---\n- [ ] one edited\n- [ ] two\n');

    // The second row is in edit mode; finish it.
    await tester.pumpWidget(app());
    await tester.pump();
    expect(_rowEditField(), findsOneWidget);
    await tester.enterText(_rowEditField(), 'two edited');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(out, '---\ntype: list\n---\n- [ ] one edited\n- [ ] two edited\n');

    await tester.pumpWidget(app());
    await tester.pump();
    expect(_rowEditField(), findsNothing);
  });

  testWidgets('an unchanged text edit is a no-op', (tester) async {
    String? out;
    const text = '- [ ] one\n';
    await tester.pumpWidget(
      _app(ListNoteView(text: text, onChanged: (t) => out = t)),
    );
    await tester.tap(find.text('one'));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(out, isNull);
  });

  testWidgets('the add button is a check icon, not a plus', (tester) async {
    await tester.pumpWidget(
      _app(ListNoteView(text: '- [ ] one\n', onChanged: (_) {})),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('list-add-button')),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('dragging a row below another reorders it', (tester) async {
    String? out;
    const text = '- [ ] one\n- [ ] two\n';
    await tester.pumpWidget(
      _app(ListNoteView(text: text, onChanged: (t) => out = t)),
    );
    final center = tester.getCenter(_row(1));
    final height = tester.getSize(_row(1)).height;
    // Lower quarter of row 1: the "after" zone.
    await _longPressDrag(
      tester,
      _row(0),
      Offset(center.dx, center.dy + height * 0.4),
    );
    expect(out, '- [ ] two\n- [ ] one\n');
  });

  testWidgets('dragging a row onto another makes a sub-list', (tester) async {
    String? out;
    const text = '- [ ] one\n- [ ] two\n';
    await tester.pumpWidget(
      _app(ListNoteView(text: text, onChanged: (t) => out = t)),
    );
    // Center of row 1: the "under" zone.
    await _longPressDrag(tester, _row(0), tester.getCenter(_row(1)));
    expect(out, '- [ ] two\n  - [ ] one\n');
  });

  testWidgets('a dragged item takes its children with it', (tester) async {
    String? out;
    const text = '- [ ] one\n  - [ ] child\n- [ ] two\n';
    await tester.pumpWidget(
      _app(ListNoteView(text: text, onChanged: (t) => out = t)),
    );
    final center = tester.getCenter(_row(2));
    final height = tester.getSize(_row(2)).height;
    await _longPressDrag(
      tester,
      _row(0),
      Offset(center.dx, center.dy + height * 0.4),
    );
    expect(out, '- [ ] two\n- [ ] one\n  - [ ] child\n');
  });

  testWidgets('dragging onto its own subtree is a no-op', (tester) async {
    String? out;
    const text = '- [ ] one\n  - [ ] child\n';
    await tester.pumpWidget(
      _app(ListNoteView(text: text, onChanged: (t) => out = t)),
    );
    await _longPressDrag(tester, _row(0), tester.getCenter(_row(1)));
    expect(out, isNull);
  });

  testWidgets('nested items are indented by depth', (tester) async {
    await tester.pumpWidget(
      _app(ListNoteView(text: '- [ ] a\n  - [ ] b\n', onChanged: (_) {})),
    );
    expect(
      tester.getTopLeft(find.text('b')).dx,
      greaterThan(tester.getTopLeft(find.text('a')).dx),
    );
  });

  testWidgets('the add row appends an unchecked item', (tester) async {
    String? out;
    const text = '---\ntype: list\n---\n- [ ] one\n';
    await tester.pumpWidget(_app(ListNoteView(text: text, onChanged: (t) {
      out = t;
    })));
    // The add field is the TextField outside the item rows.
    await tester.enterText(
      find.descendant(
        of: find.byType(ListNoteView),
        matching: find.byType(TextField),
      ).last,
      'three',
    );
    await tester.tap(find.byKey(const Key('list-add-button')));
    await tester.pump();
    expect(out, '---\ntype: list\n---\n- [ ] one\n- [ ] three\n');
  });

  testWidgets('a note without task items shows the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(ListNoteView(text: '---\ntype: list\n---\n', onChanged: (_) {})),
    );
    expect(find.text(AppStrings.listEmpty), findsOneWidget);
  });

  testWidgets('prose lines are not rendered', (tester) async {
    await tester.pumpWidget(
      _app(
        ListNoteView(
          text: 'a prose line\n- [ ] one\nanother line\n',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('one'), findsOneWidget);
    expect(find.text('a prose line'), findsNothing);
    expect(find.text('another line'), findsNothing);
  });
}
