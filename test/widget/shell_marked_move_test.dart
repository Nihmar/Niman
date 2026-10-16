// #1012 / #1026: several marked rows dragged into a folder move as one
// piece of work — one report of what moved and what did not, one save of the
// open notes, one drop at a time — and a row keeps its mark until its own
// move has landed.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/todo/todo_source.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/fake_todo_source.dart';
import '../fakes/shell_harness.dart';

/// Marking rows is a desktop's: the shell offers it on Linux and Windows.
final _linux = TargetPlatformVariant.only(TargetPlatform.linux);

/// An open note with edits the disk does not have, counting its saves.
final class _DirtyNote implements UnsavedNote {
  int saves = 0;

  @override
  String get path => 'dirty.md';

  @override
  bool get unsaved => true;

  @override
  String get text => 'edited';

  @override
  Future<void> save() async => saves++;
}

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;
  late UnsavedTracker tracker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
    // Not disposed here: the shell watches it, and the test binding
    // finalizes the tree after tear-down callbacks.
    tracker = UnsavedTracker();
  });

  /// The shell over a library of `Box`, `Other` and the root notes
  /// `alpha`, `bravo`, `charlie`.
  Future<void> pump(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(1400, 900));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          librarySessionProvider.overrideWithValue(controller),
          unsavedTrackerProvider.overrideWithValue(tracker),
          todoSourceFactoryProvider.overrideWithValue((_) => FakeTodoSource()),
        ],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createFolder(parentPath: '', name: 'Box');
    await controller.createFolder(parentPath: '', name: 'Other');
    for (final name in ['alpha', 'bravo', 'charlie']) {
      await controller.createNote(parentPath: '', name: name);
    }
    await settle(tester);
  }

  /// Marks `alpha.md` to `charlie.md`.
  Future<void> markAll(WidgetTester tester) async {
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(noteRow('charlie.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle(tester);
  }

  /// A row of the tree dragged with the mouse and let go on [to].
  Future<void> dragMouse(WidgetTester tester, Finder from, Finder to) async {
    final start = tester.getCenter(from);
    final end = tester.getCenter(to);
    final mouse = await tester.startGesture(
      start,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    for (var step = 1; step <= 10; step++) {
      await mouse.moveTo(Offset.lerp(start, end, step / 10)!);
      await tester.pump();
    }
    await mouse.up();
    await tester.pump();
  }

  /// How many rows the marked menu says are marked, read by a right click
  /// on [row] (and closed again), or null when [row] opens its own menu.
  Future<int?> markedCount(WidgetTester tester, String row) async {
    await tester.tap(noteRow(row), buttons: kSecondaryButton);
    await tester.pump(const Duration(milliseconds: 500));
    final title = find.byWidgetPredicate(
      (widget) =>
          widget is Text && (widget.data ?? '').startsWith('Selected: '),
    );
    final count = title.evaluate().isEmpty
        ? null
        : int.parse(
            tester
                .widget<Text>(title.first)
                .data!
                .substring('Selected: '.length),
          );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    return count;
  }

  testWidgets('one row that fails: the rest move and the report says how '
      'many each way (#1012)', (tester) async {
    await pump(tester);
    controller.failMoves.add('bravo.md');
    await markAll(tester);

    await dragMouse(tester, noteRow('alpha.md'), noteRow('Box'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(await controller.find('Box/alpha.md'), isNotNull);
    expect(await controller.find('Box/charlie.md'), isNotNull);
    expect(await controller.find('bravo.md'), isNotNull);
    // Two moved, one did not — in one message, not one per row.
    expect(find.byType(SnackBar), findsOne);
    final report = tester.widget<Text>(
      find
          .descendant(of: find.byType(SnackBar), matching: find.byType(Text))
          .first,
    );
    expect(report.data, contains('Moved · Selected: 2'));
    expect(report.data, contains('Could not finish that action'));
    expect(report.data, contains('Selected: 1'));
  }, variant: _linux);

  testWidgets('a move that all lands reports how many moved (#1012)', (
    tester,
  ) async {
    await pump(tester);
    await markAll(tester);

    await dragMouse(tester, noteRow('alpha.md'), noteRow('Box'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(await controller.find('Box/bravo.md'), isNotNull);
    expect(find.textContaining('Moved · Selected: 3'), findsOne);
    expect(find.textContaining('Could not finish'), findsNothing);
  }, variant: _linux);

  testWidgets('the open notes are saved once for the whole move (#1012)', (
    tester,
  ) async {
    await pump(tester);
    final dirty = _DirtyNote();
    tracker.register(dirty);
    await markAll(tester);
    final before = dirty.saves;

    await dragMouse(tester, noteRow('alpha.md'), noteRow('Box'));
    await settle(tester);

    expect(await controller.find('Box/charlie.md'), isNotNull);
    expect(dirty.saves - before, 1);
  }, variant: _linux);

  testWidgets('a drop made while a move is out waits for it (#1012)', (
    tester,
  ) async {
    await pump(tester);
    final gate = controller.moveGates['bravo.md'] = Completer<void>();
    await tester.tap(noteRow('alpha.md'));
    await settle(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(noteRow('bravo.md'));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await settle(tester);

    await dragMouse(tester, noteRow('alpha.md'), noteRow('Box'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.moveCalls, ['alpha.md', 'bravo.md'], reason: 'held');

    // charlie is let go on another folder meanwhile: it is not lost, and
    // it does not start before the first drop has finished.
    await dragMouse(tester, noteRow('charlie.md'), noteRow('Other'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.moveCalls, ['alpha.md', 'bravo.md']);

    gate.complete();
    await settle(tester);
    expect(controller.moveCalls, ['alpha.md', 'bravo.md', 'charlie.md']);
    expect(await controller.find('Box/bravo.md'), isNotNull);
    expect(await controller.find('Other/charlie.md'), isNotNull);
  }, variant: _linux);

  testWidgets('a row keeps its mark until its own move lands (#1026)', (
    tester,
  ) async {
    await pump(tester);
    final gate = controller.moveGates['bravo.md'] = Completer<void>();
    await markAll(tester);

    await dragMouse(tester, noteRow('alpha.md'), noteRow('Box'));
    await tester.pump(const Duration(milliseconds: 100));
    // alpha has landed and is gone from the root; bravo is held, charlie
    // waits: both are still marked, none of the three rows demarked early.
    expect(controller.moveCalls, ['alpha.md', 'bravo.md']);
    expect(noteRow('alpha.md'), findsNothing);
    expect(await markedCount(tester, 'charlie.md'), 2);

    gate.complete();
    await settle(tester);
    expect(await controller.find('Box/charlie.md'), isNotNull);
    expect(await markedCount(tester, 'Box'), isNull, reason: 'all let go');
  }, variant: _linux);
}
