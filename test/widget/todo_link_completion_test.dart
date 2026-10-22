// #1152: typing `[[` in a task's text lists the library's notes under the
// field, the ones the editor's wikilink panel lists, and picking one writes
// the link the editor would write -- the shortest name that resolves to the
// note alone -- with the field's one line intact. The task dialog and the
// quick-add field share it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/ui/todo_edit_dialog.dart';
import 'package:niman/src/ui/todo_link_query.dart';
import 'package:niman/src/ui/todo_quick_add.dart';

import '../fakes/fake_wikilink_suggester.dart';

void main() {
  final field = find.byKey(const Key('todo-dialog-field'));
  final quick = find.byKey(const Key('todo-quick-add'));

  FakeWikilinkSuggester library() => FakeWikilinkSuggester(
    notes: const <NoteSuggestion>[
      NoteSuggestion(name: 'Repairs', folder: 'House', target: 'Repairs'),
      NoteSuggestion(name: 'Report Q3', folder: 'Finance', target: 'Report Q3'),
      NoteSuggestion(name: 'Twin', folder: 'a', target: 'a/Twin'),
    ],
    headings: const <String, List<HeadingSuggestion>>{
      'Repairs': [
        HeadingSuggestion('Boiler'),
        HeadingSuggestion('Contacts'),
        HeadingSuggestion('Old boiler'),
      ],
    },
    blocks: const <String, List<BlockIdSuggestion>>{
      'Repairs': [BlockIdSuggestion('b7', excerpt: 'Call them')],
    },
  );

  /// The dialog over [suggester], on a window that holds it.
  Future<void> openDialog(
    WidgetTester tester,
    WikilinkSuggester? suggester,
  ) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTodoTaskDialog(
                context,
                today: DateTime(2026, 9, 7),
                linkSuggester: suggester == null ? null : () => suggester,
              ),
              child: const Text('open dialog'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();
  }

  String description(WidgetTester tester) =>
      tester.widget<TextField>(field).controller!.text;

  group('the query', () {
    test('a link open before the caret is the one being typed', () {
      final query = TodoLinkQuery.at('Call [[Rep', 10)!;
      expect(query.start, 7);
      expect(query.target, 'Rep');
      expect(query.hasHash, isFalse);
      expect(query.closeAt, -1);
    });

    test('a heading and a block follow the first #', () {
      final heading = TodoLinkQuery.at('[[Repairs#Boi', 13)!;
      expect(heading.target, 'Repairs');
      expect(heading.heading, 'Boi');
      expect(heading.matchText, 'Boi');
      final block = TodoLinkQuery.at('[[Repairs#^b', 12)!;
      expect(block.isBlock, isTrue);
      expect(block.matchText, 'b');
    });

    test('a link closed before the caret, an alias and an embed are none', () {
      expect(TodoLinkQuery.at('[[Repairs]] and', 15), isNull);
      expect(TodoLinkQuery.at('[[Repairs|the', 13), isNull);
      expect(TodoLinkQuery.at('![[Pic', 6), isNull);
      expect(TodoLinkQuery.at('no link', 7), isNull);
    });

    test('a link closed after the caret is completed in place', () {
      const text = 'See [[Rep]] now';
      final query = TodoLinkQuery.at(text, 9)!;
      expect(query.closeAt, 9);
      final next = query.complete(
        const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: 9),
        ),
        query.start,
        'House/Repairs',
      );
      expect(next.text, 'See [[House/Repairs]] now');
      expect(next.selection.baseOffset, 'See [[House/Repairs]]'.length);
    });
  });

  group('in the dialog', () {
    testWidgets('lists the notes and writes the link of the one picked', (
      tester,
    ) async {
      await openDialog(tester, library());
      await tester.enterText(field, 'Replace the filter [[Rep');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('todo-link-option-0')), findsOneWidget);
      expect(find.text('Repairs'), findsOneWidget);
      expect(find.text('House'), findsOneWidget);
      expect(find.text('Report Q3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('todo-link-option-0')));
      await tester.pump();
      expect(description(tester), 'Replace the filter [[Repairs]]');
      expect(find.byKey(const Key('todo-link-options')), findsNothing);
      final controller = tester.widget<TextField>(field).controller!;
      expect(
        controller.selection.baseOffset,
        'Replace the filter [[Repairs]]'.length,
        reason: 'the caret is past the link',
      );
    });

    testWidgets('writes the shortest name that resolves to the note alone', (
      tester,
    ) async {
      await openDialog(tester, library());
      await tester.enterText(field, '[[Tw');
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const Key('todo-link-option-0')));
      await tester.pump();
      expect(description(tester), '[[a/Twin]]');
    });

    testWidgets('lists the headings of the note after a #', (tester) async {
      final suggester = library();
      await openDialog(tester, suggester);
      await tester.enterText(field, 'Fix [[Repairs#boi');
      await tester.pump();
      await tester.pump();
      // Prefix matches first, the contains match after.
      expect(find.text('Boiler'), findsOneWidget);
      expect(find.text('Old boiler'), findsOneWidget);
      expect(find.text('Contacts'), findsNothing);
      expect(suggester.headingTargets, contains('Repairs'));
      await tester.tap(find.byKey(const Key('todo-link-option-0')));
      await tester.pump();
      expect(description(tester), 'Fix [[Repairs#Boiler]]');
    });

    testWidgets('lists the block ids after #^', (tester) async {
      await openDialog(tester, library());
      await tester.enterText(field, 'Ring [[Repairs#^');
      await tester.pump();
      await tester.pump();
      expect(find.text('^b7'), findsOneWidget);
      await tester.tap(find.byKey(const Key('todo-link-option-0')));
      await tester.pump();
      expect(description(tester), 'Ring [[Repairs#^b7]]');
    });

    testWidgets('the keys move, insert and close', (tester) async {
      await openDialog(tester, library());
      await tester.enterText(field, '[[Rep');
      await tester.pump();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(description(tester), '[[Report Q3]]', reason: 'Enter inserts');
      expect(find.byType(AlertDialog), findsOneWidget, reason: 'and not saves');

      await tester.enterText(field, '[[Rep');
      await tester.pump();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.byKey(const Key('todo-link-options')), findsNothing);
      expect(find.byType(AlertDialog), findsOneWidget, reason: 'Esc was ours');
    });

    testWidgets('with no list up Enter still saves, one line', (tester) async {
      String? saved;
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  saved = await showTodoTaskDialog(
                    context,
                    today: DateTime(2026, 9, 7),
                    linkSuggester: library,
                  );
                },
                child: const Text('open dialog'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open dialog'));
      await tester.pumpAndSettle();
      await tester.enterText(field, 'Call [[Repairs]] today');
      await tester.pump();
      expect(find.byKey(const Key('todo-link-options')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(saved, contains('Call [[Repairs]] today'));
      expect(saved, isNot(contains('\n')));
    });

    testWidgets('a dialog with no library offers no notes', (tester) async {
      await openDialog(tester, null);
      await tester.enterText(field, '[[Rep');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('todo-link-options')), findsNothing);
    });

    testWidgets('the list goes when the caret leaves the link', (tester) async {
      await openDialog(tester, library());
      await tester.enterText(field, '[[Rep');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('todo-link-options')), findsOneWidget);
      await tester.enterText(field, '[[Rep]] done');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('todo-link-options')), findsNothing);
    });
  });

  group('in the quick-add field', () {
    testWidgets('picks a note by tap or Enter, which does not add', (
      tester,
    ) async {
      final added = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodoQuickAdd(
              onAdd: added.add,
              knownTokens: () => const <String>{},
              linkSuggester: library,
            ),
          ),
        ),
      );
      await tester.tap(quick);
      await tester.enterText(quick, 'Pay [[Rep');
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('todo-link-option-0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('todo-link-option-1')));
      await tester.pump();
      expect(
        tester.widget<TextField>(quick).controller!.text,
        'Pay [[Report Q3]]',
      );
      expect(added, isEmpty);

      await tester.enterText(quick, 'Then [[Rep');
      await tester.pump();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        tester.widget<TextField>(quick).controller!.text,
        'Then [[Repairs]]',
      );
      expect(added, isEmpty);

      await tester.enterText(quick, 'Pay [[Repairs]]');
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(added, ['Pay [[Repairs]]']);
    });
  });
}
