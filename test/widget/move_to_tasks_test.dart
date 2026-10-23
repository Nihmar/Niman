// Move to tasks (#1152): a note's checkbox items become tasks that link the
// note and leave it. One item opens the task dialog; several move at once; the
// files are written before the note; Undo gives the lines back to the note and
// takes the tasks out of the files.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/ui/move_to_tasks_flow.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

import '../fakes/note_tasks_fixture.dart';

// Where the shell opens it: on disk, in the fixture's library at `/fake`.
final String _path = p.join('/fake', 'House', 'Repairs.md');

const String _note =
    '# Repairs\n'
    '\n'
    '- [ ] Replace the **bathroom** tap\n'
    '- [ ] Buy sealant\n'
    '- [x] Fix the hallway light\n'
    '- [ ] Paint the loft\n'
    '  - [ ] Buy paint\n'
    '\n'
    'The end.\n';

void main() {
  late NoteTasksFixture fixture;

  Future<NoteViewHandle> open(
    WidgetTester tester,
    String note, {
    bool offered = true,
  }) async {
    fixture = (await tester.runAsync(NoteTasksFixture.open))!;
    addTearDown(fixture.dispose);
    final key = GlobalKey<State<NoteView>>();
    final flow = MoveToTasksFlow(fixture.host);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => NoteView(
              key: key,
              path: _path,
              libraryRoot: '/fake',
              showLineNumbers: false,
              autofocusEditor: false,
              toolbarTop: true,
              readNote: (_) async => note,
              writeNote: (_, _) async {},
              onMoveToTasks: offered
                  ? (note) => unawaited(flow.run(context, note))
                  : null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return key.currentState! as NoteViewHandle;
  }

  MarkdownSourceViewState editor(WidgetTester tester) =>
      tester.state<MarkdownSourceViewState>(find.byType(MarkdownSourceView));

  String text(WidgetTester tester) => editor(tester).widget.buffer.text;

  /// Puts the caret on the line [line] of the note.
  Future<void> caretOn(WidgetTester tester, int line) async {
    final at = _note
        .split('\n')
        .take(line)
        .fold<int>(0, (sum, row) => sum + row.length + 1);
    editor(tester).placeCaret(at + 8);
    await tester.pump();
  }

  /// Selects from line [first] to the end of line [last].
  Future<void> selectLines(WidgetTester tester, int first, int last) async {
    final rows = _note.split('\n');
    int start(int line) =>
        rows.take(line).fold<int>(0, (sum, row) => sum + row.length + 1);
    editor(tester)
        .select(SelectionModel(anchor: start(first), extent: start(last) + 3));
    await tester.pump();
  }

  String dialogText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!.text;

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }

  group('one item', () {
    testWidgets('opens the dialog, pre-filled, titled and saved as a move', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      await caretOn(tester, 2);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(AppStrings.moveToTasks),
        ),
        findsOneWidget,
      );
      expect(dialogText(tester), 'Replace the **bathroom** tap [[Repairs]]');
      expect(
        find.descendant(
          of: find.byKey(const Key('todo-dialog-save')),
          matching: find.text(AppStrings.moveToTasksConfirm),
        ),
        findsOneWidget,
      );
      // Nothing moves before the dialog is answered.
      expect(text(tester), _note);
      expect(fixture.source.todoLines, isEmpty);
    });

    testWidgets('Move writes the task, then takes the item out of the note', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      await caretOn(tester, 3);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      await settle(tester);

      expect(fixture.source.todoLines, ['2026-09-07 Buy sealant [[Repairs]]']);
      expect(text(tester), _note.replaceFirst('- [ ] Buy sealant\n', ''));
      expect(find.text(AppStrings.movedToTasksOne), findsOneWidget);
      expect(find.text(AppStrings.actionUndo), findsOneWidget);
    });

    testWidgets('Cancel changes nothing', (tester) async {
      final handle = await open(tester, _note);
      await caretOn(tester, 3);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);
      await tester.tap(find.text(AppStrings.todoCancel));
      await settle(tester);

      expect(text(tester), _note);
      expect(fixture.source.todoLines, isEmpty);
      expect(fixture.source.doneLines, isEmpty);
      expect(find.text(AppStrings.movedToTasksOne), findsNothing);
    });

    testWidgets('the dialog can give it a project first', (tester) async {
      final handle = await open(tester, _note);
      await caretOn(tester, 3);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);
      await tester.enterText(
        find.byType(TextField).first,
        'Buy sealant [[Repairs]] +house',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      await settle(tester);
      expect(fixture.source.todoLines, [
        '2026-09-07 Buy sealant [[Repairs]] +house',
      ]);
    });

    testWidgets('a ticked item goes to done.txt, completed today', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      await caretOn(tester, 4);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);
      expect(dialogText(tester), 'Fix the hallway light [[Repairs]]');
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      await settle(tester);

      expect(fixture.source.todoLines, isEmpty);
      expect(fixture.source.doneLines, [
        'x 2026-09-07 2026-09-07 Fix the hallway light [[Repairs]]',
      ]);
      expect(
        text(tester),
        _note.replaceFirst('- [x] Fix the hallway light\n', ''),
      );
    });

    testWidgets('Undo puts the line back and takes the task out', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      await caretOn(tester, 3);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      await settle(tester);
      await tester.tap(find.text(AppStrings.actionUndo));
      await settle(tester);

      expect(text(tester), _note);
      expect(fixture.source.todoLines, isEmpty);
    });

    testWidgets('Undo after the note changed above puts it where it belongs', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      await caretOn(tester, 3);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      await settle(tester);

      // The writer types above, then a neighbour is edited.
      editor(tester).placeCaret(0);
      handle.insertAtCaret('Intro line');
      await tester.pump();
      await tester.tap(find.text(AppStrings.actionUndo));
      await settle(tester);

      final lines = text(tester).split('\n');
      final at = lines.indexOf('- [ ] Buy sealant');
      expect(at, greaterThan(0));
      expect(lines[at - 1], '- [ ] Replace the **bathroom** tap');
      expect(lines[at + 1], '- [x] Fix the hallway light');
      expect(fixture.source.todoLines, isEmpty);
    });
  });

  group('several items', () {
    testWidgets('move at once, without a dialog, ticked ones to done', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      await selectLines(tester, 2, 4);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(fixture.source.todoLines, [
        '2026-09-07 Replace the **bathroom** tap [[Repairs]]',
        '2026-09-07 Buy sealant [[Repairs]]',
      ]);
      expect(fixture.source.doneLines, [
        'x 2026-09-07 2026-09-07 Fix the hallway light [[Repairs]]',
      ]);
      expect(
        text(tester),
        '# Repairs\n\n- [ ] Paint the loft\n  - [ ] Buy paint\n\nThe end.\n',
      );
      expect(find.text(AppStrings.movedToTasks(3)), findsOneWidget);

      await tester.tap(find.text(AppStrings.actionUndo));
      await settle(tester);
      expect(text(tester), _note);
      expect(fixture.source.todoLines, isEmpty);
      expect(fixture.source.doneLines, isEmpty);
    });

    testWidgets('an item with sub-items is skipped and not counted', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      await selectLines(tester, 3, 6);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);

      expect(fixture.source.todoLines, [
        '2026-09-07 Buy sealant [[Repairs]]',
        '2026-09-07 Buy paint [[Repairs]]',
      ]);
      expect(fixture.source.doneLines, hasLength(1));
      expect(text(tester), contains('- [ ] Paint the loft'));
      expect(text(tester), isNot(contains('Buy paint')));
      // Three moved; the one with sub-items stayed and is not counted.
      expect(find.text(AppStrings.movedToTasks(3)), findsOneWidget);
    });
  });

  group('the order of the two writes', () {
    testWidgets('a failure after todo.txt keeps the task in both places', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      fixture.source.addLinesFailure = Exception('disk full');
      await selectLines(tester, 3, 4);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);

      // The open-tasks file took the task, the done file did not, and the
      // note is untouched.
      expect(fixture.source.todoLines, ['2026-09-07 Buy sealant [[Repairs]]']);
      expect(text(tester), _note);
      expect(find.text(AppStrings.shellActionFailed), findsOneWidget);
      expect(find.text(AppStrings.actionUndo), findsNothing);
    });

    testWidgets('a failure before any write leaves both as they were', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      fixture.source.addLinesFailureEarly = Exception('read-only');
      await caretOn(tester, 3);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);
      await tester.tap(find.byKey(const Key('todo-dialog-save')));
      await settle(tester);

      expect(fixture.source.todoLines, isEmpty);
      expect(text(tester), _note);
    });

    testWidgets('the note is written after the files, as one undoable edit', (
      tester,
    ) async {
      final handle = await open(tester, _note);
      var noteAtWrite = '';
      final buffer = editor(tester).widget.buffer;
      fixture.source.onAddLines = () => noteAtWrite = buffer.text;
      await selectLines(tester, 2, 3);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);

      // When the files were written the note still had its lines.
      expect(noteAtWrite, _note);
      expect(text(tester), isNot(_note));
      // One undo step of the editor brings both lines back.
      expect(editor(tester).undo(), isTrue);
      expect(text(tester), _note);
    });
  });

  group('when there is nothing to move', () {
    testWidgets('a plain line says what is needed', (tester) async {
      final handle = await open(tester, _note);
      editor(tester).placeCaret(_note.indexOf('The end'));
      await tester.pump();
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);
      expect(find.text(AppStrings.moveToTasksNeedsItem), findsOneWidget);
      expect(text(tester), _note);
    });

    testWidgets('an item with sub-items says why', (tester) async {
      final handle = await open(tester, _note);
      await caretOn(tester, 5);
      unawaited(
        MoveToTasksFlow(fixture.host)
            .run(tester.element(find.byType(NoteView)), handle),
      );
      await settle(tester);
      expect(find.text(AppStrings.moveToTasksHasSubItems), findsOneWidget);
      expect(fixture.source.todoLines, isEmpty);
    });
  });

  group("the toolbar's Tools sheet", () {
    testWidgets('lists Move to tasks, enabled on an item, and runs it', (
      tester,
    ) async {
      await open(tester, '- [ ] Buy sealant\n- [ ] Buy paint\n');
      editor(tester).placeCaret(8);
      await tester.pump();
      await tester.tap(find.byKey(const Key('toolbar-tools')));
      await settle(tester);
      final row = find.byKey(const Key('editor-tool-moveToTasks'));
      expect(tester.widget<ListTile>(row).enabled, isTrue);
      await tester.tap(row);
      await settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(dialogText(tester), 'Buy sealant [[Repairs]]');
    });

    testWidgets('is greyed with its reason on an item with sub-items', (
      tester,
    ) async {
      await open(tester, '- [ ] Paint\n  - [ ] Buy paint\n');
      editor(tester).placeCaret(4);
      await tester.pump();
      await tester.tap(find.byKey(const Key('toolbar-tools')));
      await settle(tester);
      final row = find.byKey(const Key('editor-tool-moveToTasks'));
      expect(tester.widget<ListTile>(row).enabled, isFalse);
      expect(find.text(AppStrings.moveToTasksHasSubItems), findsOneWidget);
    });

    testWidgets('is not listed while the Todo feature is off', (tester) async {
      await open(tester, '- [ ] Buy sealant\n', offered: false);
      await tester.tap(find.byKey(const Key('toolbar-tools')));
      await settle(tester);
      expect(find.byKey(const Key('editor-tool-moveToTasks')), findsNothing);
    });
  });

  group('the editor menu on a desktop', () {
    Future<void> rightClickLine(WidgetTester tester) async {
      await tester.tapAt(
        tester.getTopLeft(find.byType(MarkdownSurface)) + const Offset(30, 18),
        buttons: kSecondaryButton,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('offers Move to tasks on a checkbox item, and runs it', (
      tester,
    ) async {
      await open(tester, '- [ ] Buy sealant\n- [ ] Buy paint\n');
      await rightClickLine(tester);
      expect(find.byKey(const Key('menu-move-to-tasks')), findsOneWidget);
      await tester.tap(find.byKey(const Key('menu-move-to-tasks')));
      await settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(dialogText(tester), 'Buy sealant [[Repairs]]');
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets('is greyed with its reason on an item with sub-items', (
      tester,
    ) async {
      await open(tester, '- [ ] Paint\n  - [ ] Buy paint\n');
      await rightClickLine(tester);
      final row = find.byKey(const Key('menu-move-to-tasks'));
      expect(row, findsOneWidget);
      expect(tester.widget<InkWell>(row).onTap, isNull);
      final tip = find.ancestor(of: row, matching: find.byType(Tooltip));
      expect(
        tester.widget<Tooltip>(tip.first).message,
        AppStrings.moveToTasksHasSubItems,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets('is not there on a plain line', (tester) async {
      await open(tester, 'Just a line\n');
      await rightClickLine(tester);
      expect(find.byKey(const Key('menu-move-to-tasks')), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));

    testWidgets('is not there while the Todo feature is off', (tester) async {
      await open(tester, '- [ ] Buy sealant\n', offered: false);
      await rightClickLine(tester);
      expect(find.byKey(const Key('menu-move-to-tasks')), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.linux));
  });

  group("the phone's long-press menu", () {
    Future<void> longPressLine(WidgetTester tester) async {
      await tester.longPressAt(
        tester.getTopLeft(find.byType(MarkdownSurface)) + const Offset(60, 18),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('has Move to tasks as its first entry', (tester) async {
      await open(tester, '- [ ] Buy sealant\n- [ ] Buy paint\n');
      await longPressLine(tester);
      final move = find.byKey(const Key('menu-move-to-tasks'));
      expect(move, findsOneWidget);
      final first = tester.getTopLeft(
        find.byType(TextSelectionToolbarTextButton).first,
      );
      expect(tester.getTopLeft(move).dx, greaterThanOrEqualTo(first.dx));
      expect(
        find.descendant(
          of: find.byType(TextSelectionToolbarTextButton).first,
          matching: find.byKey(const Key('menu-move-to-tasks')),
        ),
        findsOneWidget,
      );
      await tester.tap(move);
      await settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('on an item with sub-items it gives its reason', (
      tester,
    ) async {
      await open(tester, '- [ ] Paint\n  - [ ] Buy paint\n');
      await longPressLine(tester);
      await tester.tap(find.byKey(const Key('menu-move-to-tasks')));
      await settle(tester);
      expect(find.text(AppStrings.moveToTasksHasSubItems), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));
  });
}
