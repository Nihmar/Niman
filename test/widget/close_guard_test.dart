// T-PP-11: the close guard over a fake window — it asks before closing
// while a tracked note is dirty, stays out of the way when clean, and
// degrades to tracking only when the platform is unavailable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/close_guard.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/window_controller.dart';

import '../fakes/fake_window_controller.dart';

/// A note with a settable dirty bit and a counted, controllable save.
final class _FakeNote implements UnsavedNote {
  new(this.path, {this.unsaved = false});

  @override
  final String path;

  @override
  bool unsaved;

  int saveCalls = 0;
  Error? failWith;

  @override
  Future<void> save() async {
    saveCalls++;
    final error = failWith;
    if (error != null) throw error;
    unsaved = false;
  }
}

Widget _host(UnsavedTracker tracker, WindowController window) {
  return MaterialApp(
    home: CloseGuard(
      tracker: tracker,
      window: window,
      child: const Scaffold(body: Text('body')),
    ),
  );
}

void main() {
  testWidgets('arms the veto while dirty and clears it when clean', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    final window = FakeWindowController();
    final note = _FakeNote('/lib/a.md', unsaved: true);
    tracker.register(note);

    await tester.pumpWidget(_host(tracker, window));
    await tester.pump();
    expect(window.preventHistory, [true]);

    note.unsaved = false;
    tracker.noteChanged();
    await tester.pump();
    expect(window.preventHistory, [true, false]);

    tracker.unregister(note);
    await tester.pump();
    expect(window.preventHistory, [true, false]);
  });

  testWidgets('a clean close request lands without asking', (tester) async {
    final tracker = UnsavedTracker();
    final window = FakeWindowController();
    tracker.register(_FakeNote('/lib/a.md'));

    await tester.pumpWidget(_host(tracker, window));
    await tester.pump();
    window.onCloseRequested!();
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(window.closeCalls, 1);
  });

  testWidgets('a dirty close request asks before closing', (tester) async {
    final tracker = UnsavedTracker();
    final window = FakeWindowController();
    final note = _FakeNote('/lib/a.md', unsaved: true);
    tracker.register(note);

    await tester.pumpWidget(_host(tracker, window));
    await tester.pump();
    window.onCloseRequested!();
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(AppStrings.closeUnsavedTitle), findsOneWidget);
    expect(find.textContaining('a.md'), findsOneWidget);

    await tester.tap(find.text(AppStrings.actionCancel));
    await tester.pumpAndSettle();

    expect(window.closeCalls, 0);
    expect(note.saveCalls, 0);
    expect(note.unsaved, isTrue);
  });

  testWidgets('Save and close writes the notes, then closes the window', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    final window = FakeWindowController();
    final note = _FakeNote('/lib/a.md', unsaved: true);
    tracker.register(note);

    await tester.pumpWidget(_host(tracker, window));
    await tester.pump();
    window.onCloseRequested!();
    await tester.pump();
    await tester.tap(find.text(AppStrings.saveAndClose));
    await tester.pumpAndSettle();

    expect(note.saveCalls, 1);
    expect(note.unsaved, isFalse);
    expect(window.closeCalls, 1);
    expect(window.preventHistory.last, isFalse);
  });

  testWidgets('a failed save keeps the window open', (tester) async {
    final tracker = UnsavedTracker();
    final window = FakeWindowController();
    final note = _FakeNote('/lib/a.md', unsaved: true)
      ..failWith = StateError('disk full');
    tracker.register(note);

    await tester.pumpWidget(_host(tracker, window));
    await tester.pump();
    window.onCloseRequested!();
    await tester.pump();
    await tester.tap(find.text(AppStrings.saveAndClose));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.closeSaveFailed), findsOneWidget);
    expect(window.closeCalls, 0);
    expect(note.unsaved, isTrue);
  });

  testWidgets('duplicate close requests while asking are dropped', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    final window = FakeWindowController();
    tracker.register(_FakeNote('/lib/a.md', unsaved: true));

    await tester.pumpWidget(_host(tracker, window));
    await tester.pump();
    window.onCloseRequested!();
    window.onCloseRequested!();
    await tester.pump();

    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text(AppStrings.actionCancel));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('an unavailable platform degrades to tracking only', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    final window = FakeWindowController(failInit: true);
    tracker.register(_FakeNote('/lib/a.md', unsaved: true));

    await tester.pumpWidget(_host(tracker, window));
    await tester.pump();

    expect(window.preventHistory, isEmpty);
    // The in-process ask still works; only the OS veto is off.
    window.onCloseRequested!();
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text(AppStrings.actionCancel));
    await tester.pumpAndSettle();
  });

  testWidgets('disposing the guard clears the platform handler', (
    tester,
  ) async {
    final tracker = UnsavedTracker();
    final window = FakeWindowController();

    await tester.pumpWidget(_host(tracker, window));
    await tester.pump();
    expect(window.onCloseRequested, isNotNull);

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(window.onCloseRequested, isNull);
  });
}
