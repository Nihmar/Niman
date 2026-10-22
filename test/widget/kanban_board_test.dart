// #1167: the kanban board on a wide window — columns and cards read from the
// note, and every action one byte-stable edit of its text.
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/kanban/card_edits.dart';
import 'package:niman/src/kanban/column_edits.dart';
import 'package:niman/src/ui/kinds/kanban/kanban_card_tile.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/kanban_harness.dart';
import '../fakes/kanban_samples.dart';

Finder _title(String text) => find.textContaining(text, findRichText: true);

/// The tile of the card shown with [title].
Finder _tile(String title) =>
    find.ancestor(of: _title(title), matching: find.byType(KanbanCardTile));

Future<void> _alt(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
  await tester.pumpAndSettle();
}

/// Drags from [from] to [to] with a mouse, in steps.
Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  final gesture = await tester.startGesture(
    from,
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
  const steps = 12;
  for (var i = 1; i <= steps; i++) {
    await gesture.moveTo(Offset.lerp(from, to, i / steps)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();
}

/// A test of the desktop's pointer drag: the platform is a desktop's for its
/// length (the tests run as Android otherwise, where a card is picked up with
/// a long press).
void desktopTest(String name, Future<void> Function(WidgetTester) body) =>
    testWidgets(name, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await body(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

void main() {
  group('the board', () {
    testWidgets('draws the columns and the cards of the note', (tester) async {
      await showKanbanBoard(tester, issueBoard);
      expect(find.byKey(const Key('kanban-board')), findsOneWidget);
      expect(
        [
          for (final w in tester.widgetList<Text>(
            find.byKey(const Key('kanban-column-name')),
          ))
            w.data,
        ],
        ['To do', 'Doing', 'Done'],
      );
      expect(
        [
          for (final w in tester.widgetList<Text>(
            find.byKey(const Key('kanban-column-count')),
          ))
            w.data,
        ],
        ['2', '1', '1'],
      );
      expect(_title('Write the brief'), findsOneWidget);
      expect(_title('Book the venue'), findsOneWidget);
      // The tag and the date are chips, not part of the title.
      expect([
        for (final w in tester.widgetList<Text>(
          find.byKey(const Key('kanban-card-title')),
        ))
          w.textSpan!.toPlainText(),
      ], isNot(contains(contains('#work'))));
      expect(find.text('#work'), findsOneWidget);
      expect(find.text('2026-11-10'), findsOneWidget);
      // The first line of the body is the preview.
      expect(find.text('Outline first, then visuals.'), findsOneWidget);
      expect(find.byKey(const Key('kanban-card-box')), findsNWidgets(4));
    });

    testWidgets('a body narrower than a tablet gets the phone board', (
      tester,
    ) async {
      await showKanbanBoard(tester, issueBoard, size: const Size(500, 800));
      expect(find.byKey(const Key('kanban-tabs')), findsOneWidget);
      expect(find.byKey(const Key('kanban-board')), findsNothing);
    });

    testWidgets('a card has a semantic label with its place', (tester) async {
      final handle = tester.ensureSemantics();
      await showKanbanBoard(tester, issueBoard);
      expect(
        find.bySemanticsLabel(
          RegExp(AppStrings.kanbanCardLabel(2, 2, 'To do')),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('edits', () {
    testWidgets('ticking a box is toggleCard, and the card stays', (
      tester,
    ) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(find.byKey(const Key('kanban-card-box')).first);
      await tester.pumpAndSettle();
      expect(host.edits, [toggleCard(issueBoard, 0, 0)]);
      // Decided 3: a ticked card does not move.
      expect(host.value, contains('- [x] Write the brief #work'));
      expect(
        tester.getTopLeft(_tile('Write the brief')).dx,
        lessThan(tester.getTopLeft(_tile('Draft the slides')).dx),
      );
    });

    testWidgets('only the box character changes in an Obsidian board', (
      tester,
    ) async {
      final host = await showKanbanBoard(tester, obsidianBoard);
      await tester.tap(find.byKey(const Key('kanban-card-box')).first);
      await tester.pumpAndSettle();
      expect(host.value, toggleCard(obsidianBoard, 0, 0));
      var differing = 0;
      for (var i = 0; i < obsidianBoard.length; i++) {
        if (obsidianBoard[i] != host.value[i]) differing++;
      }
      expect(host.value.length, obsidianBoard.length);
      expect(differing, 1);
    });

    testWidgets('adding a card writes it at the end of its column', (
      tester,
    ) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(find.byKey(const Key('kanban-add')).first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('kanban-add-field')),
        'Call the caterer',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.edits, [addCard(issueBoard, 0, 'Call the caterer')]);
      expect(_title('Call the caterer'), findsOneWidget);
      // The field stays open for the next card.
      expect(find.byKey(const Key('kanban-add-field')), findsOneWidget);
    });

    testWidgets('adding a column writes a heading at the end', (tester) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(find.byKey(const Key('kanban-add')).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('kanban-add-field')),
        'Later',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.edits, [addColumn(issueBoard, 'Later')]);
      expect(find.text('Later'), findsOneWidget);
    });

    testWidgets('a tap on the picked card edits its title', (tester) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(_title('Write the brief'));
      await tester.pump();
      expect(find.byKey(const Key('kanban-card-field')), findsNothing);
      await tester.tap(_title('Write the brief'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('kanban-card-field')),
        'Rewrite the brief',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.edits, [
        editCardTitle(issueBoard, 0, 0, 'Rewrite the brief'),
      ]);
    });

    testWidgets('Enter edits the focused card, Esc leaves it as it was', (
      tester,
    ) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(_title('Write the brief'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(const Key('kanban-card-field')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('kanban-card-field')),
        'Something else',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('kanban-card-field')), findsNothing);
      expect(host.edits, isEmpty);
    });

    testWidgets('Delete removes the focused card', (tester) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(_title('Write the brief'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(host.edits, [deleteCard(issueBoard, 0, 0)]);
      expect(_title('Write the brief'), findsNothing);
    });

    testWidgets('a column is renamed and deleted from its menu', (
      tester,
    ) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(find.byKey(const Key('kanban-column-menu')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('kanban-column-rename')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('kanban-column-field')),
        'Backlog',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(host.edits, [renameColumn(issueBoard, 0, 'Backlog')]);

      await tester.tap(find.byKey(const Key('kanban-column-menu')).last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('kanban-column-delete')));
      await tester.pumpAndSettle();
      expect(host.edits.last, deleteColumn(host.edits.first, 2));
    });
  });

  group('moving a card without a drag', () {
    testWidgets('Alt+Right moves it a column on, and the focus follows', (
      tester,
    ) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(_title('Write the brief'));
      await tester.pump();
      await _alt(tester, LogicalKeyboardKey.arrowRight);
      final first = moveCard(
        issueBoard,
        fromColumn: 0,
        fromCard: 0,
        toColumn: 1,
        toIndex: 0,
      );
      expect(host.edits, [first]);
      // The same card, now in Doing, still has the keys.
      await _alt(tester, LogicalKeyboardKey.arrowRight);
      expect(
        host.edits.last,
        moveCard(first, fromColumn: 1, fromCard: 0, toColumn: 2, toIndex: 0),
      );
    });

    testWidgets('Alt+Down moves it within its column, Alt+Left at the edge '
        'does nothing', (tester) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(_title('Write the brief'));
      await tester.pump();
      await _alt(tester, LogicalKeyboardKey.arrowLeft);
      expect(host.edits, isEmpty);
      await _alt(tester, LogicalKeyboardKey.arrowDown);
      expect(host.edits, [
        moveCard(
          issueBoard,
          fromColumn: 0,
          fromCard: 0,
          toColumn: 0,
          toIndex: 1,
        ),
      ]);
    });

    testWidgets('the card menu moves it, and disables what has no place', (
      tester,
    ) async {
      final host = await showKanbanBoard(tester, issueBoard);
      await tester.tap(
        find.descendant(
          of: _tile('Write the brief'),
          matching: find.byKey(const Key('kanban-card-menu')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<MenuItemButton>(find.byKey(const Key('kanban-move-left')))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<MenuItemButton>(find.byKey(const Key('kanban-move-up')))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const Key('kanban-move-right')));
      await tester.pumpAndSettle();
      expect(host.edits, [
        moveCard(
          issueBoard,
          fromColumn: 0,
          fromCard: 0,
          toColumn: 1,
          toIndex: 0,
        ),
      ]);
    });
  });

  group('dragging a card', () {
    desktopTest('to the end of another column', (tester) async {
      final host = await showKanbanBoard(tester, issueBoard);
      final from = tester.getCenter(_tile('Write the brief'));
      final target = tester.getRect(_tile('Draft the slides'));
      await _drag(tester, from, Offset(target.center.dx, target.bottom - 4));
      expect(host.edits, [
        moveCard(
          issueBoard,
          fromColumn: 0,
          fromCard: 0,
          toColumn: 1,
          toIndex: 1,
        ),
      ]);
    });

    desktopTest('to the top of another column', (tester) async {
      final host = await showKanbanBoard(tester, issueBoard);
      final from = tester.getCenter(_tile('Write the brief'));
      final target = tester.getRect(_tile('Pick the date'));
      await _drag(tester, from, Offset(target.center.dx, target.top + 4));
      expect(host.edits, [
        moveCard(
          issueBoard,
          fromColumn: 0,
          fromCard: 0,
          toColumn: 2,
          toIndex: 0,
        ),
      ]);
    });

    desktopTest('down its own column, to the place after the next card', (
      tester,
    ) async {
      final host = await showKanbanBoard(tester, issueBoard);
      final from = tester.getCenter(_tile('Write the brief'));
      final next = tester.getRect(_tile('Book the venue'));
      await _drag(tester, from, Offset(next.center.dx, next.bottom - 4));
      expect(host.edits, [
        moveCard(
          issueBoard,
          fromColumn: 0,
          fromCard: 0,
          toColumn: 0,
          toIndex: 1,
        ),
      ]);
    });

    desktopTest('dropped on its own place, it changes nothing', (tester) async {
      final host = await showKanbanBoard(tester, issueBoard);
      final from = tester.getCenter(_tile('Write the brief'));
      await _drag(tester, from, from + const Offset(0, 30));
      expect(host.edits, isEmpty);
    });

    desktopTest('a drop marker shows where it would land', (tester) async {
      await showKanbanBoard(tester, issueBoard);
      final from = tester.getCenter(_tile('Write the brief'));
      final target = tester.getRect(_tile('Draft the slides'));
      final gesture = await tester.startGesture(
        from,
        kind: PointerDeviceKind.mouse,
      );
      for (var i = 1; i <= 12; i++) {
        await gesture.moveTo(
          Offset.lerp(from, Offset(target.center.dx, target.top + 4), i / 12)!,
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.byKey(const Key('kanban-drop-bar')), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('kanban-drop-bar')), findsNothing);
    });

    desktopTest('held at the edge, the board scrolls under the card', (
      tester,
    ) async {
      await showKanbanBoard(tester, issueBoard, size: const Size(800, 600));
      final scrollable = find
          .descendant(
            of: find.byKey(const Key('kanban-board')),
            matching: find.byType(Scrollable),
          )
          .first;
      expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
      final from = tester.getCenter(_tile('Write the brief'));
      final gesture = await tester.startGesture(
        from,
        kind: PointerDeviceKind.mouse,
      );
      for (var i = 1; i <= 10; i++) {
        await gesture.moveTo(
          Offset.lerp(from, const Offset(796, 300), i / 10)!,
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(100),
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a touch picks a card up with a long press', (tester) async {
      final host = await showKanbanBoard(tester, issueBoard);
      final from = tester.getCenter(_tile('Write the brief'));
      final target = tester.getRect(_tile('Draft the slides'));
      final to = Offset(target.center.dx, target.bottom - 4);
      // A swipe is not a drag.
      await tester.dragFrom(from, const Offset(0, 40));
      await tester.pumpAndSettle();
      expect(host.edits, isEmpty);
      final gesture = await tester.startGesture(from);
      await tester.pump(const Duration(milliseconds: 700));
      for (var i = 1; i <= 12; i++) {
        await gesture.moveTo(Offset.lerp(from, to, i / 12)!);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();
      expect(host.edits, [
        moveCard(
          issueBoard,
          fromColumn: 0,
          fromCard: 0,
          toColumn: 1,
          toIndex: 1,
        ),
      ]);
    });
  });
}
