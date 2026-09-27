// T-TK-04/09: the list-kind GUI — checkable rows, nesting, the add row,
// in-place text editing and drag reordering/sub-lists.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/kinds/list_drag_handle.dart';
import 'package:niman/src/ui/kinds/list_item_row.dart';
import 'package:niman/src/ui/kinds/list_note.dart';
import 'package:niman/src/ui/strings.dart';

Widget _app(Widget view) => MaterialApp(home: Scaffold(body: view));

Finder _row(int index) => find.byType(ListItemRow).at(index);

Finder _rowCheckbox(int index) =>
    find.descendant(of: _row(index), matching: find.byType(Checkbox));

Finder _rowHandle(int index) =>
    find.descendant(of: _row(index), matching: find.byType(ListDragHandle));

Finder _rowEditField() => find.byKey(const Key('list-edit-field'));

Finder _rowDelete(int index) => find.descendant(
  of: _row(index),
  matching: find.byKey(const Key('list-delete-item')),
);

/// Drags [from] to [to] (the handle drag of T-TK-09).
Future<void> _drag(WidgetTester tester, Finder from, Offset to) async {
  final gesture = await tester.startGesture(tester.getCenter(from));
  await tester.pump();
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
    Widget app() => _app(
      ListNoteView(
        text: text,
        onChanged: (t) {
          text = t;
        },
      ),
    );
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
    Widget app() => _app(
      ListNoteView(
        text: text,
        onChanged: (t) {
          text = t;
        },
      ),
    );
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

  testWidgets('an open edit commits when another row is tapped', (
    tester,
  ) async {
    String? out;
    var text = '---\ntype: list\n---\n- [ ] one\n- [ ] two\n';
    Widget app() => MaterialApp(
      home: Scaffold(
        body: ListNoteView(
          text: text,
          onChanged: (t) {
            text = t;
            out = t;
          },
        ),
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

  testWidgets('dragging the handle below another row reorders it', (
    tester,
  ) async {
    String? out;
    const text = '- [ ] one\n- [ ] two\n';
    await tester.pumpWidget(
      _app(ListNoteView(text: text, onChanged: (t) => out = t)),
    );
    final center = tester.getCenter(_row(1));
    final height = tester.getSize(_row(1)).height;
    // Lower quarter of row 1: the "after" zone.
    await _drag(
      tester,
      _rowHandle(0),
      Offset(center.dx, center.dy + height * 0.4),
    );
    expect(out, '- [ ] two\n- [ ] one\n');
  });

  testWidgets('dragging the row body does not reorder', (tester) async {
    String? out;
    const text = '- [ ] one\n- [ ] two\n';
    await tester.pumpWidget(
      _app(ListNoteView(text: text, onChanged: (t) => out = t)),
    );
    final center = tester.getCenter(_row(1));
    final height = tester.getSize(_row(1)).height;
    await _drag(
      tester,
      find.text('one'),
      Offset(center.dx, center.dy + height * 0.4),
    );
    expect(out, isNull);
  });

  testWidgets('dragging a row onto another makes a sub-list', (tester) async {
    String? out;
    const text = '- [ ] one\n- [ ] two\n';
    await tester.pumpWidget(
      _app(ListNoteView(text: text, onChanged: (t) => out = t)),
    );
    // Center of row 1: the "under" zone.
    await _drag(tester, _rowHandle(0), tester.getCenter(_row(1)));
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
    await _drag(
      tester,
      _rowHandle(0),
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
    await _drag(tester, _rowHandle(0), tester.getCenter(_row(1)));
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
    await tester.pumpWidget(
      _app(
        ListNoteView(
          text: text,
          onChanged: (t) {
            out = t;
          },
        ),
      ),
    );
    // The add field is the TextField outside the item rows.
    await tester.enterText(
      find
          .descendant(
            of: find.byType(ListNoteView),
            matching: find.byType(TextField),
          )
          .last,
      'three',
    );
    await tester.tap(find.byKey(const Key('list-add-button')));
    await tester.pump();
    expect(out, '---\ntype: list\n---\n- [ ] one\n- [ ] three\n');
  });

  testWidgets('the add row scrolls the list to the new item', (tester) async {
    final buffer = StringBuffer('---\ntype: list\n---\n');
    for (var i = 0; i < 12; i++) {
      buffer.writeln('- [ ] item $i');
    }
    var text = buffer.toString();
    Widget app() => _app(
      SizedBox(
        height: 240,
        child: ListNoteView(
          text: text,
          onChanged: (t) {
            text = t;
          },
        ),
      ),
    );
    await tester.pumpWidget(app());
    ScrollPosition position() =>
        tester.widget<ListView>(find.byType(ListView)).controller!.position;
    expect(position().maxScrollExtent, greaterThan(0));
    expect(position().pixels, 0);

    await tester.enterText(find.byKey(const Key('list-add-field')), 'last');
    await tester.tap(find.byKey(const Key('list-add-button')));
    await tester.pump();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(text, endsWith('- [ ] last\n'));
    expect(position().pixels, position().maxScrollExtent);
  });

  testWidgets('the add row slides away while a row is edited', (tester) async {
    var text = '---\ntype: list\n---\n- [ ] one\n';
    Widget app() => _app(
      ListNoteView(
        text: text,
        onChanged: (t) {
          text = t;
        },
      ),
    );
    await tester.pumpWidget(app());
    Size addRow() => tester.getSize(find.byKey(const Key('list-add-row')));
    final shown = addRow().height;
    expect(shown, greaterThan(0));

    await tester.tap(find.text('one'));
    await tester.pumpAndSettle();
    expect(addRow().height, 0);

    // Committing the edit brings it back.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(addRow().height, shown);
  });

  testWidgets(
    'dismissing the keyboard ends the edit and restores the add row',
    (tester) async {
      // Issue #5: on Android the back gesture closes the IME but leaves
      // the row field focused, which used to hide the add row until the
      // note was reopened.
      addTearDown(tester.view.reset);
      var text = '---\ntype: list\n---\n- [ ] one\n';
      Widget app() => _app(
        ListNoteView(
          text: text,
          onChanged: (t) {
            text = t;
          },
        ),
      );
      await tester.pumpWidget(app());
      Size addRow() => tester.getSize(find.byKey(const Key('list-add-row')));
      final shown = addRow().height;

      await tester.tap(find.text('one'));
      await tester.pumpAndSettle();
      expect(addRow().height, 0);
      await tester.enterText(_rowEditField(), 'one edited');
      tester.view.viewInsets = const FakeViewPadding(bottom: 400);
      await tester.pump();
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pumpAndSettle();

      // The edit committed and the add row is back...
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('one edited'), findsOneWidget);
      expect(_rowEditField(), findsNothing);
      expect(addRow().height, shown);

      // ...so the next item is added without reopening the note.
      final addField = find
          .descendant(
            of: find.byType(ListNoteView),
            matching: find.byType(TextField),
          )
          .last;
      await tester.enterText(addField, 'two');
      await tester.tap(find.byKey(const Key('list-add-button')));
      await tester.pump();
      await tester.pumpWidget(app());
      expect(find.text('two'), findsOneWidget);
    },
  );

  testWidgets('the trash deletes an item and its subtree at once', (
    tester,
  ) async {
    var text = '---\ntype: list\n---\n- [ ] one\n  - [ ] child\n- [ ] two\n';
    Widget app() => _app(
      ListNoteView(
        text: text,
        onChanged: (t) {
          text = t;
        },
      ),
    );
    await tester.pumpWidget(app());

    await tester.tap(_rowDelete(0));
    await tester.pump();
    expect(text, '---\ntype: list\n---\n- [ ] two\n');
    expect(find.text(AppStrings.deletedMessage), findsOneWidget);
  });

  testWidgets('Undo puts the deleted block back byte for byte', (tester) async {
    const original =
        '---\ntype: list\n---\n- [ ] one\n  - [ ] child\n- [ ] two\n';
    var text = original;
    Widget app() => _app(
      ListNoteView(
        text: text,
        onChanged: (t) {
          text = t;
        },
      ),
    );
    await tester.pumpWidget(app());

    await tester.tap(_rowDelete(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    await tester.pump();
    expect(text, '---\ntype: list\n---\n- [ ] two\n');

    await tester.tap(find.text(AppStrings.actionUndo));
    await tester.pump();
    expect(text, original);
  });

  testWidgets('deleting the row being edited leaves the next item alone', (
    tester,
  ) async {
    var text = '---\ntype: list\n---\n- [ ] one\n- [ ] two\n';
    Widget app() => _app(
      ListNoteView(
        text: text,
        onChanged: (t) {
          text = t;
        },
      ),
    );
    await tester.pumpWidget(app());

    await tester.tap(find.text('one'));
    await tester.pump();
    await tester.enterText(_rowEditField(), 'one edited');
    await tester.tap(_rowDelete(0));
    await tester.pump();
    await tester.pumpWidget(app());
    // The pending commit must not land on the item that took the row's
    // place.
    await tester.pump();
    expect(text, '---\ntype: list\n---\n- [ ] two\n');
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('a shopping item shows its quantity, and ×1 reads one', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ListNoteView(
          text:
              '---\ntype: shopping-list\n---\n- [ ] Latte ×2\n- [ ] Pane ×1\n',
          shopping: true,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.text('Pane'), findsOneWidget);
    // The row's pill (the add chip carries a ×1 of its own).
    expect(
      find.descendant(of: _row(1), matching: find.text('×1')),
      findsOneWidget,
    );
  });

  testWidgets('the add row reads a typed quantity and writes the marker', (
    tester,
  ) async {
    String? out;
    await tester.pumpWidget(
      _app(
        ListNoteView(
          text: '---\ntype: shopping-list\n---\n- [ ] Pane\n',
          shopping: true,
          onChanged: (t) {
            out = t;
          },
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('list-add-field')), 'Latte x2');
    await tester.tap(find.byKey(const Key('list-add-button')));
    await tester.pump();
    expect(out, '---\ntype: shopping-list\n---\n- [ ] Pane\n- [ ] Latte ×2\n');
  });

  testWidgets('the add chip writes its quantity, then resets to one', (
    tester,
  ) async {
    var text = '---\ntype: shopping-list\n---\n';
    Widget app() => _app(
      ListNoteView(
        text: text,
        shopping: true,
        onChanged: (t) {
          text = t;
        },
      ),
    );
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const Key('list-add-quantity')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('quantity-preset-3')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quantity-ok')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('list-add-field')), 'Uova');
    await tester.tap(find.byKey(const Key('list-add-button')));
    await tester.pump();
    expect(text, '---\ntype: shopping-list\n---\n- [ ] Uova ×3\n');

    // The chip is back to one for the next item.
    await tester.pumpWidget(app());
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('list-add-quantity')),
        matching: find.text('×1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping the pill opens the edit on the quantity', (
    tester,
  ) async {
    var text = '---\ntype: shopping-list\n---\n- [ ] Latte ×2\n';
    Widget app() => _app(
      ListNoteView(
        text: text,
        shopping: true,
        onChanged: (t) {
          text = t;
        },
      ),
    );
    await tester.pumpWidget(app());

    await tester.tap(find.byKey(const Key('list-quantity-pill')));
    await tester.pump();
    expect(find.byKey(const Key('list-quantity-field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('list-quantity-field')), '5');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(text, '---\ntype: shopping-list\n---\n- [ ] Latte ×5\n');
  });

  testWidgets('an edit changes the name and the quantity together', (
    tester,
  ) async {
    var text = '---\ntype: shopping-list\n---\n- [ ] Latte ×2\n';
    Widget app() => _app(
      ListNoteView(
        text: text,
        shopping: true,
        onChanged: (t) {
          text = t;
        },
      ),
    );
    await tester.pumpWidget(app());

    await tester.tap(find.text('Latte'));
    await tester.pump();
    await tester.enterText(_rowEditField(), 'Latte intero');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('list-quantity-field')), '6');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(text, '---\ntype: shopping-list\n---\n- [ ] Latte intero ×6\n');
  });

  testWidgets('a plain list stays plain: no quantity anywhere', (tester) async {
    await tester.pumpWidget(
      _app(ListNoteView(text: '- [ ] Latte ×2\n', onChanged: (_) {})),
    );
    // `×2` is part of the name in a plain list, and there is no pill,
    // no quantity field and no chip.
    expect(find.text('Latte ×2'), findsOneWidget);
    expect(find.byKey(const Key('list-quantity-pill')), findsNothing);
    expect(find.byKey(const Key('list-add-quantity')), findsNothing);
    expect(find.byIcon(Icons.add), findsOneWidget); // the add row's plus
  });

  testWidgets('a long item text marquees instead of clipping', (tester) async {
    final long = 'Latte ' * 60;
    await tester.pumpWidget(
      _app(
        ListNoteView(
          text: '---\ntype: shopping-list\n---\n- [ ] $long\n',
          shopping: true,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('marquee-offset')), findsOneWidget);
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
