// #1168: the kanban board on a phone — a tab per column, the cards of the
// selected one in a list, and Move to… instead of a drag; every action one
// byte-stable edit of the note's text.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/kanban/card_edits.dart';
import 'package:niman/src/kanban/column_edits.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_phone_card.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/kanban_harness.dart';
import '../fakes/kanban_samples.dart';

const Size _phone = Size(400, 800);

Future<KanbanTestHost> _show(WidgetTester tester, String text) =>
    showKanbanBoard(tester, text, size: _phone);

Finder _title(String text) => find.textContaining(text, findRichText: true);

/// The tile of the card shown with [title].
Finder _card(String title) =>
    find.ancestor(of: _title(title), matching: find.byType(KanbanPhoneCard));

/// The column on screen: the tab bar's selection.
int _selected(WidgetTester tester) => tester
    .widget<TabBar>(find.byKey(const Key('kanban-tabs')))
    .controller!
    .index;

Future<void> _tab(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(Key('kanban-tab-$index')));
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester, String title) async {
  await tester.longPress(_card(title));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, Key field, String text) async {
  await tester.enterText(find.byKey(field), text);
  await tester.pump();
}

bool _enabled(WidgetTester tester, Key key) =>
    tester.widget<ListTile>(find.byKey(key)).enabled;

/// A board with a column that holds no card.
const String _emptyColumns =
    '---\ntype: kanban\n---\n\n## To do\n- [ ] One\n\n## Later\n';

/// A note with a type and no heading: a board of no column.
const String _noColumns = '---\ntype: kanban\n---\n\nJust a line.\n';

void main() {
  group('the tabs', () {
    testWidgets('one per column with its name and its card count', (
      tester,
    ) async {
      await _show(tester, issueBoard);
      expect(find.byKey(const Key('kanban-board')), findsNothing);
      for (final (i, name, count) in [
        (0, 'To do', '2'),
        (1, 'Doing', '1'),
        (2, 'Done', '1'),
      ]) {
        expect(
          find.descendant(
            of: find.byKey(Key('kanban-tab-$i')),
            matching: find.text(name),
          ),
          findsOneWidget,
        );
        expect(
          tester.widget<Text>(find.byKey(Key('kanban-tab-count-$i'))).data,
          count,
        );
      }
      expect(_selected(tester), 0);
    });

    testWidgets('a tap on a tab shows the cards of its column', (tester) async {
      await _show(tester, issueBoard);
      expect(_title('Write the brief'), findsOneWidget);
      expect(_title('Draft the slides'), findsNothing);
      await _tab(tester, 1);
      expect(_title('Draft the slides'), findsOneWidget);
      expect(_title('Write the brief'), findsNothing);
      expect(find.text('Outline first, then visuals.'), findsOneWidget);
    });

    testWidgets('a swipe changes the column', (tester) async {
      await _show(tester, issueBoard);
      await tester.fling(
        find.byKey(const Key('kanban-pages')),
        const Offset(-300, 0),
        1500,
      );
      await tester.pumpAndSettle();
      expect(_selected(tester), 1);
      expect(_title('Draft the slides'), findsOneWidget);
    });

    testWidgets('tabs are tabs for a screen reader, with their counts', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _show(tester, issueBoard);
      expect(find.bySemanticsLabel(RegExp(r'^Doing\s*1')), findsWidgets);
      handle.dispose();
    });
  });

  group('the cards', () {
    testWidgets('are tiles with a box, title, chips and a first line', (
      tester,
    ) async {
      await _show(tester, issueBoard);
      expect(find.byKey(const Key('kanban-card-box')), findsNWidgets(2));
      expect(find.text('#work'), findsOneWidget);
      expect(find.text('2026-11-10'), findsOneWidget);
      final tile = find.byKey(const Key('kanban-phone-card')).first;
      expect(tester.getSize(tile).height, greaterThanOrEqualTo(44));
      expect(
        tester.getSize(find.byKey(const Key('kanban-card-box')).first).height,
        greaterThanOrEqualTo(44),
      );
      expect(find.byKey(const Key('kanban-long-press-hint')), findsOneWidget);
      expect(find.text(AppStrings.kanbanLongPressHint), findsOneWidget);
    });

    testWidgets('a card has a semantic label with its place', (tester) async {
      final handle = tester.ensureSemantics();
      await _show(tester, issueBoard);
      expect(
        find.bySemanticsLabel(
          RegExp(AppStrings.kanbanCardLabel(2, 2, 'To do')),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('ticking the box is toggleCard, and the card stays', (
      tester,
    ) async {
      final host = await _show(tester, issueBoard);
      await tester.tap(find.byKey(const Key('kanban-card-box')).first);
      await tester.pumpAndSettle();
      expect(host.edits, [toggleCard(issueBoard, 0, 0)]);
      expect(_title('Write the brief'), findsOneWidget);
    });

    testWidgets('a tap on the title edits it in a sheet', (tester) async {
      final host = await _show(tester, issueBoard);
      await tester.tap(_title('Write the brief'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('kanban-sheet-field')), findsOneWidget);
      await _type(tester, const Key('kanban-sheet-field'), 'Rewrite it');
      await tester.tap(find.byKey(const Key('kanban-sheet-save')));
      await tester.pumpAndSettle();
      expect(host.edits, [editCardTitle(issueBoard, 0, 0, 'Rewrite it')]);
      expect(_title('Rewrite it'), findsOneWidget);
    });

    testWidgets('cancelling the edit changes nothing', (tester) async {
      final host = await _show(tester, issueBoard);
      await tester.tap(_title('Write the brief'));
      await tester.pumpAndSettle();
      await _type(tester, const Key('kanban-sheet-field'), 'Nope');
      await tester.tap(find.byKey(const Key('kanban-sheet-cancel')));
      await tester.pumpAndSettle();
      expect(host.edits, isEmpty);
    });
  });

  group('the card sheet', () {
    testWidgets('a long press opens it, titled with the card', (tester) async {
      await _show(tester, issueBoard);
      await _openSheet(tester, 'Write the brief');
      expect(
        tester.widget<Text>(find.byKey(const Key('kanban-sheet-title'))).data,
        'Write the brief',
      );
      expect(find.text(AppStrings.kanbanMoveTo), findsOneWidget);
      // Every other column, not the card's own.
      expect(find.byKey(const Key('kanban-move-to-0')), findsNothing);
      expect(find.byKey(const Key('kanban-move-to-1')), findsOneWidget);
      expect(find.byKey(const Key('kanban-move-to-2')), findsOneWidget);
    });

    testWidgets('Move to… a column puts the card at its end', (tester) async {
      final host = await _show(tester, issueBoard);
      await _openSheet(tester, 'Write the brief');
      await tester.tap(find.byKey(const Key('kanban-move-to-2')));
      await tester.pumpAndSettle();
      expect(host.edits, [
        moveCard(
          issueBoard,
          fromColumn: 0,
          fromCard: 0,
          toColumn: 2,
          toIndex: 1,
        ),
      ]);
      // The view stays on the column the card left.
      expect(_selected(tester), 0);
      expect(_title('Write the brief'), findsNothing);
      expect(_title('Book the venue'), findsOneWidget);
      await _tab(tester, 2);
      expect(
        tester.getTopLeft(_card('Pick the date')).dy,
        lessThan(tester.getTopLeft(_card('Write the brief')).dy),
      );
    });

    testWidgets('Move up and Move down are disabled at the edges', (
      tester,
    ) async {
      final host = await _show(tester, issueBoard);
      await _openSheet(tester, 'Write the brief');
      expect(_enabled(tester, const Key('kanban-move-up')), isFalse);
      expect(_enabled(tester, const Key('kanban-move-down')), isTrue);
      await tester.tap(find.byKey(const Key('kanban-move-up')));
      await tester.pumpAndSettle();
      // A disabled entry does nothing and leaves the sheet open.
      expect(host.edits, isEmpty);
      await tester.tap(find.byKey(const Key('kanban-move-down')));
      await tester.pumpAndSettle();
      expect(host.edits, [
        moveCard(
          issueBoard,
          fromColumn: 0,
          fromCard: 0,
          toColumn: 0,
          toIndex: 1,
        ),
      ]);
      await _openSheet(tester, 'Write the brief');
      expect(_enabled(tester, const Key('kanban-move-up')), isTrue);
      expect(_enabled(tester, const Key('kanban-move-down')), isFalse);
    });

    testWidgets('a move is said to a screen reader', (tester) async {
      final said = <Object?>[];
      final messenger = tester.binding.defaultBinaryMessenger
        ..setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (
          message,
        ) async {
          said.add(message);
          return null;
        });
      addTearDown(
        () => messenger.setMockDecodedMessageHandler<dynamic>(
          SystemChannels.accessibility,
          null,
        ),
      );
      await _show(tester, issueBoard);
      await _openSheet(tester, 'Write the brief');
      await tester.tap(find.byKey(const Key('kanban-move-to-2')));
      await tester.pumpAndSettle();
      expect(said.toString(), contains(AppStrings.kanbanMovedTo('Done', 2, 2)));
    });

    testWidgets('Edit card opens the title sheet', (tester) async {
      final host = await _show(tester, issueBoard);
      await _openSheet(tester, 'Write the brief');
      await tester.tap(find.byKey(const Key('kanban-card-edit')));
      await tester.pumpAndSettle();
      await _type(tester, const Key('kanban-sheet-field'), 'Brief, rewritten');
      await tester.tap(find.byKey(const Key('kanban-sheet-save')));
      await tester.pumpAndSettle();
      expect(host.edits, [editCardTitle(issueBoard, 0, 0, 'Brief, rewritten')]);
    });

    testWidgets('Delete removes the card', (tester) async {
      final host = await _show(tester, issueBoard);
      await _openSheet(tester, 'Write the brief');
      await tester.tap(find.byKey(const Key('kanban-card-delete')));
      await tester.pumpAndSettle();
      expect(host.edits, [deleteCard(issueBoard, 0, 0)]);
      expect(_title('Write the brief'), findsNothing);
    });

    testWidgets('on a board of one column, Move to… is there and disabled', (
      tester,
    ) async {
      final host = await _show(
        tester,
        '---\ntype: kanban\n---\n\n## Only\n- [ ] Alone\n',
      );
      await _openSheet(tester, 'Alone');
      expect(_enabled(tester, const Key('kanban-move-to')), isFalse);
      expect(host.edits, isEmpty);
    });
  });

  group('adding', () {
    testWidgets('a card goes to the end of the selected column', (
      tester,
    ) async {
      final host = await _show(tester, issueBoard);
      await _tab(tester, 1);
      await tester.tap(find.byKey(const Key('kanban-add')));
      await tester.pumpAndSettle();
      await _type(tester, const Key('kanban-add-field'), 'Review it');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.edits, [addCard(issueBoard, 1, 'Review it')]);
      expect(_title('Review it'), findsOneWidget);
      expect(_selected(tester), 1);
    });

    testWidgets('a column is asked for in a sheet and then selected', (
      tester,
    ) async {
      final host = await _show(tester, issueBoard);
      await tester.tap(find.byKey(const Key('kanban-add-column')));
      await tester.pumpAndSettle();
      await _type(tester, const Key('kanban-sheet-field'), 'Later');
      await tester.tap(find.byKey(const Key('kanban-sheet-save')));
      await tester.pumpAndSettle();
      expect(host.edits, [addColumn(issueBoard, 'Later')]);
      expect(_selected(tester), 3);
      expect(
        tester.widget<Text>(find.byKey(const Key('kanban-tab-count-3'))).data,
        '0',
      );
    });
  });

  group('the selected column', () {
    testWidgets('survives an edit', (tester) async {
      final host = await _show(tester, issueBoard);
      await _tab(tester, 1);
      await tester.tap(find.byKey(const Key('kanban-card-box')));
      await tester.pumpAndSettle();
      expect(host.edits, [toggleCard(issueBoard, 1, 0)]);
      expect(_selected(tester), 1);
      expect(_title('Draft the slides'), findsOneWidget);
    });

    testWidgets('stays put when the note changes under it', (tester) async {
      final host = await _show(tester, issueBoard);
      await _tab(tester, 1);
      host.applyEdit(addColumn(host.value, 'Later'));
      await tester.pumpAndSettle();
      expect(_selected(tester), 1);
    });

    testWidgets('is kept inside the board when its column goes', (
      tester,
    ) async {
      final host = await _show(tester, issueBoard);
      await _tab(tester, 2);
      await tester.tap(find.byKey(const Key('kanban-column-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('kanban-column-delete')));
      await tester.pumpAndSettle();
      expect(host.edits, [deleteColumn(issueBoard, 2)]);
      expect(_selected(tester), 1);
      expect(_title('Draft the slides'), findsOneWidget);
    });

    testWidgets('is renamed from the menu', (tester) async {
      final host = await _show(tester, issueBoard);
      await _tab(tester, 1);
      await tester.tap(find.byKey(const Key('kanban-column-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('kanban-column-rename')));
      await tester.pumpAndSettle();
      await _type(tester, const Key('kanban-sheet-field'), 'In progress');
      await tester.tap(find.byKey(const Key('kanban-sheet-save')));
      await tester.pumpAndSettle();
      expect(host.edits, [renameColumn(issueBoard, 1, 'In progress')]);
      expect(find.text('In progress'), findsOneWidget);
      expect(_selected(tester), 1);
    });
  });

  group('empty', () {
    testWidgets('a column says so and still takes a card', (tester) async {
      final host = await _show(tester, _emptyColumns);
      await _tab(tester, 1);
      expect(find.byKey(const Key('kanban-column-empty')), findsOneWidget);
      expect(find.byKey(const Key('kanban-long-press-hint')), findsNothing);
      await tester.tap(find.byKey(const Key('kanban-add')));
      await tester.pumpAndSettle();
      await _type(tester, const Key('kanban-add-field'), 'First');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.edits, [addCard(_emptyColumns, 1, 'First')]);
      expect(find.byKey(const Key('kanban-column-empty')), findsNothing);
    });

    testWidgets('a board of no column offers one, and the menu waits', (
      tester,
    ) async {
      final host = await _show(tester, _noColumns);
      expect(find.byKey(const Key('kanban-tabs')), findsNothing);
      expect(
        tester
            .widget<PopupMenuButton<VoidCallback>>(
              find.byKey(const Key('kanban-column-menu')),
            )
            .enabled,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('kanban-add-column-empty')));
      await tester.pumpAndSettle();
      await _type(tester, const Key('kanban-sheet-field'), 'Backlog');
      await tester.tap(find.byKey(const Key('kanban-sheet-save')));
      await tester.pumpAndSettle();
      expect(host.edits, [addColumn(_noColumns, 'Backlog')]);
      expect(find.byKey(const Key('kanban-tabs')), findsOneWidget);
      expect(_selected(tester), 0);
    });
  });

  group('byte stability', () {
    testWidgets('a move in an Obsidian board leaves the footer alone', (
      tester,
    ) async {
      final host = await _show(tester, obsidianBoard);
      await _openSheet(tester, 'Write the brief');
      await tester.tap(find.byKey(const Key('kanban-move-to-2')));
      await tester.pumpAndSettle();
      final expected = moveCard(
        obsidianBoard,
        fromColumn: 0,
        fromCard: 0,
        toColumn: 2,
        toIndex: 1,
      );
      expect(host.value, expected);
      final footer = obsidianBoard.substring(
        obsidianBoard.indexOf('%% kanban:settings'),
      );
      expect(host.value, endsWith(footer));
      expect(host.value.length, obsidianBoard.length);
    });

    testWidgets('only the box character changes when a card is ticked', (
      tester,
    ) async {
      final host = await _show(tester, obsidianBoard);
      await tester.tap(find.byKey(const Key('kanban-card-box')).first);
      await tester.pumpAndSettle();
      expect(host.value, toggleCard(obsidianBoard, 0, 0));
      var differing = 0;
      for (var i = 0; i < obsidianBoard.length; i++) {
        if (obsidianBoard[i] != host.value[i]) differing++;
      }
      expect(differing, 1);
    });
  });
}
