// #712: where a pointer aims, the frontmatter panel edits in place — a
// value turns into a field, a date opens a calendar under itself, a list
// takes an item from a field, a new key is typed in a row, and the type
// chip is a menu. No dialog.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/frontmatter_fields.dart';

void main() {
  late List<(String, String)> set;

  Future<void> pump(
    WidgetTester tester, {
    String note = '---\ntitle: Hello\ntags: [a]\ndate: 2026-10-01\n---\n',
  }) async {
    set = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(visualDensity: VisualDensity.compact),
        home: Scaffold(
          body: FrontmatterFields(
            note: note,
            panel: FrontmatterPanel.open,
            onToggle: () {},
            onSet: (key, yaml) => set.add((key, yaml)),
            onRemove: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final field = find.byKey(const Key('frontmatter-inline-field'));

  testWidgets('a value is edited where it is; Esc leaves it', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('frontmatter-value-title')));
    await tester.pump();
    expect(find.byType(Dialog), findsNothing);
    await tester.enterText(field, 'Bye');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(set, isEmpty);

    await tester.tap(find.byKey(const Key('frontmatter-value-title')));
    await tester.pump();
    await tester.enterText(field, 'Bye');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set.single.$1, 'title');
    expect(set.single.$2, contains('Bye'));
  });

  testWidgets('a date opens a calendar under itself', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('frontmatter-value-date')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-popover')), findsOne);
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(set.single, ('date', '2026-10-15'));
  });

  testWidgets('a list takes an item, a key is added in a row, the type is '
      'a menu', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('frontmatter-add-item-tags')));
    await tester.pump();
    await tester.enterText(field, 'b');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set.last, ('tags', '[a, b]'));

    await tester.tap(find.byKey(const Key('frontmatter-add')));
    await tester.pump();
    await tester.enterText(field, 'author');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set.last.$1, 'author');

    await tester.tap(find.byKey(const Key('frontmatter-type-menu-title')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('frontmatter-retype-list')));
    await tester.pumpAndSettle();
    expect(set.last, ('title', '[Hello]'));
  });

  // #959: an item typed into a flow list is quoted for a flow list.
  testWidgets('an item with a comma or a bracket stays one item', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('frontmatter-add-item-tags')));
    await tester.pump();
    await tester.enterText(field, 'Doe, J');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set.last, ('tags', '[a, "Doe, J"]'));

    await tester.tap(find.byKey(const Key('frontmatter-add-item-tags')));
    await tester.pump();
    await tester.enterText(field, 'x]');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set.last, ('tags', '[a, "x]"]'));
  });

  testWidgets('retyping text with a comma to a list makes one item', (
    tester,
  ) async {
    await pump(tester, note: "---\ntitle: 'Doe, J'\n---\n");
    await tester.tap(find.byKey(const Key('frontmatter-type-menu-title')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('frontmatter-retype-list')));
    await tester.pumpAndSettle();
    expect(set.last, ('title', '["Doe, J"]'));
  });

  // #960: the year grid reports a change too, and it is not a day pick.
  testWidgets('picking a year leaves the calendar open; a day closes it', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('frontmatter-value-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('October 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2019'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-popover')), findsOne);
    expect(set, isEmpty);

    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-popover')), findsNothing);
    expect(set.single, ('date', '2019-10-15'));
  });

  // #962: a key that is already there is opened, not written over.
  testWidgets('adding an existing key opens its row and writes nothing', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('frontmatter-add')));
    await tester.pump();
    await tester.enterText(field, 'title');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set, isEmpty);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: field, matching: find.byType(EditableText)),
          )
          .controller
          .text,
      'Hello',
    );
  });

  testWidgets('adding the key of a list opens a new item, and writes '
      'nothing', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('frontmatter-add')));
    await tester.pump();
    await tester.enterText(field, 'tags');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set, isEmpty);
    expect(field, findsOne);
    await tester.enterText(field, 'b');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set.single, ('tags', '[a, b]'));
  });

  testWidgets('adding a key that is there with nothing in it fills it in', (
    tester,
  ) async {
    await pump(tester, note: '---\ntitle: Hello\nsubtitle:\n---\n');
    await tester.tap(find.byKey(const Key('frontmatter-add')));
    await tester.pump();
    await tester.enterText(field, 'subtitle');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set.single.$1, 'subtitle');
  });

  testWidgets('a key the panel has no row for is not written over', (
    tester,
  ) async {
    await pump(tester, note: '---\ntitle: Hello\nmeta:\n  a: 1\n---\n');
    await tester.tap(find.byKey(const Key('frontmatter-add')));
    await tester.pump();
    await tester.enterText(field, 'meta');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(set, isEmpty);
  });
}
