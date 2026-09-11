// The bottom tab bar stays put: a note opened full-screen on a phone
// keeps the tabs, and they still switch.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/todo_tab.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;
  late FakeFilePicker filePicker;

  setUp(() {
    controller = FakeLibrarySession();
    filePicker = useFakeFilePicker();
  });

  /// Opens a phone-sized shell on a library holding one note.
  Future<void> pumpWithNote(WidgetTester tester) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'Note');
    await settle(tester);
    await tester.tap(noteRow('Note.md'));
    await settle(tester);
  }

  testWidgets('an open note keeps the tab bar', (tester) async {
    await pumpWithNote(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.byKey(const Key('shell-tabs')), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('a tab tap from an open note switches tab', (tester) async {
    await pumpWithNote(tester);
    await tester.tap(find.byIcon(Icons.check_box_outlined));
    await settle(tester);

    expect(find.byType(NoteView), findsNothing);
    expect(find.byType(TodoTab), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  testWidgets('tapping the tab the note came from closes the note', (
    tester,
  ) async {
    await pumpWithNote(tester);
    await tester.tap(find.byKey(const Key('tab-files')));
    await settle(tester);

    // Back on the tree, with the note closed.
    expect(find.byType(NoteView), findsNothing);
    expect(noteRow('Note.md'), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  // Issue #4: opening the quick note faded the note in over the window
  // background (a black frame in dark mode). The tab shell stays painted
  // under the fade and hides only once the note has covered it.
  testWidgets('the quick note fades over the tabs, hiding them after', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'Scratch');
    await settle(tester);
    await controller.ops!.setQuickNotePath(path: 'Scratch.md');

    Offstage tabShellOffstage() => tester.widget<Offstage>(
      find.byKey(const ValueKey('tab-shell-offstage')),
    );

    // On the Files tab, nothing open.
    expect(noteRow('Scratch.md'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Quick note'),
      ),
    );
    await tester.pump(); // the tile's async open lands.
    await tester.pump(); // first fade frame, clock held: fade just started.
    expect(find.byType(NoteView), findsOneWidget);
    // Mid-fade the shell still paints underneath (no window-background
    // frame between the tab and the note) — but what it paints is the
    // Quick note tab with an empty body, not the choose/create screen the
    // user already answered (user, 2026-09-09).
    expect(tabShellOffstage().offstage, isFalse);
    expect(find.byKey(const Key('quick-note-choose')), findsNothing);

    // Past the fade the shell hides again (layout/paint/tickers skipped
    // under the opaque note).
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(NoteView), findsOneWidget);
    expect(tabShellOffstage().offstage, isTrue);
    expect(find.byKey(const Key('quick-note-choose')), findsNothing);

    await controller.close();
    await controller.dispose();
  });

  // 2026-09-10 device report: opening the quick note, going back and
  // tapping the tile again showed an empty screen. The tile's "already
  // open, just land on the tab" shortcut only looked at what was
  // selected, and a closed note stays selected — so it landed on a tab
  // whose body is empty by design, with no note over it.
  testWidgets('the quick note reopens after it has been closed', (
    tester,
  ) async {
    setSurfaceSize(tester, const Size(390, 844));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [librarySessionProvider.overrideWithValue(controller)],
        child: const NimanApp(),
      ),
    );
    await tester.pump();
    await openLibrary(tester, filePicker);
    await controller.createNote(parentPath: '', name: 'Scratch');
    await settle(tester);
    await controller.ops!.setQuickNotePath(path: 'Scratch.md');

    Future<void> tapQuickNoteTile() async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Quick note'),
        ),
      );
      await settle(tester);
    }

    await tapQuickNoteTile();
    expect(find.byType(NoteView), findsOneWidget);

    // Back to the tree, the way the phone's back arrow goes.
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(NoteView), findsNothing);

    await tapQuickNoteTile();
    expect(find.byType(NoteView), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  // 2026-09-08 user request: a fullscreen action beside the preview eye,
  // giving the note's text the whole phone screen.
  group('the preview fullscreen', () {
    /// Opens the note and switches it from the editor to the preview.
    Future<void> pumpPreviewing(WidgetTester tester) async {
      await pumpWithNote(tester);
      await tester.tap(find.byKey(const Key('editor-preview-toggle')));
      await settle(tester);
    }

    testWidgets('is offered only while the preview is showing', (tester) async {
      await pumpWithNote(tester);
      expect(find.byKey(const Key('preview-fullscreen')), findsNothing);

      await tester.tap(find.byKey(const Key('editor-preview-toggle')));
      await settle(tester);
      expect(find.byKey(const Key('preview-fullscreen')), findsOneWidget);

      await controller.close();
      await controller.dispose();
    });

    testWidgets('hides the app bar and the tab bar', (tester) async {
      await pumpPreviewing(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen')));
      await settle(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const Key('shell-tabs')), findsNothing);
      // The note itself is still there, and so is the way out.
      expect(find.byType(NoteView), findsOneWidget);
      expect(find.byKey(const Key('preview-fullscreen-exit')), findsOneWidget);

      await controller.close();
      await controller.dispose();
    });

    testWidgets('the exit button brings the chrome back', (tester) async {
      await pumpPreviewing(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen-exit')));
      await settle(tester);

      expect(find.byKey(const Key('shell-tabs')), findsOneWidget);
      expect(find.byKey(const Key('preview-fullscreen')), findsOneWidget);

      await controller.close();
      await controller.dispose();
    });

    testWidgets('switching back to the editor leaves fullscreen', (
      tester,
    ) async {
      // Otherwise the editor would open chromeless, with no eye to
      // press and no obvious way back.
      await pumpPreviewing(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen-exit')));
      await settle(tester);
      await tester.tap(find.byKey(const Key('editor-preview-toggle')));
      await settle(tester);

      expect(find.byKey(const Key('shell-tabs')), findsOneWidget);
      expect(find.byKey(const Key('preview-fullscreen')), findsNothing);

      await controller.close();
      await controller.dispose();
    });

    // Issues #2/#3: the fullscreen background may reach the status bar,
    // but the content must start below it, with no system gap above the
    // bottom toolbar.
    testWidgets('immersive content starts below the status bar', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(top: 47);
      tester.view.viewPadding = const FakeViewPadding(top: 47);
      addTearDown(tester.view.reset);
      await pumpPreviewing(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen')));
      await settle(tester);

      // The opaque transition surface still reaches the screen edge...
      final background = find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.child is Stack,
      );
      expect(
        tester.widget<ColoredBox>(background).color,
        Theme.of(tester.element(find.byType(NoteView))).scaffoldBackgroundColor,
      );
      expect(tester.getTopLeft(background).dy, 0);
      // ...while the note content starts below the status bar.
      expect(
        tester.getTopLeft(find.byType(NoteView)).dy,
        moreOrLessEquals(47, epsilon: 0.5),
      );

      await controller.close();
      await controller.dispose();
    });

    testWidgets('no system gap sits between preview and status row', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 20);
      tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 20);
      addTearDown(tester.view.reset);
      await pumpPreviewing(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen')));
      await settle(tester);

      // The bottom chrome keeps only its bottom inset: with top enabled
      // the 47 px status-bar inset would leak in between the preview and
      // the status row (issue #3).
      final chrome = find.descendant(
        of: find.byType(NoteView),
        matching: find.byWidgetPredicate(
          (widget) => widget is SafeArea && widget.bottom,
        ),
      );
      expect(chrome, findsOneWidget);
      expect(tester.widget<SafeArea>(chrome).top, isFalse);

      await controller.close();
      await controller.dispose();
    });

    testWidgets('toggling fullscreen keeps the open note state', (
      tester,
    ) async {
      // Flipping only insets: entering or leaving fullscreen must not
      // reparent (and dispose) the NoteView, losing focus and scroll.
      await pumpPreviewing(tester);
      await tester.tap(find.byKey(const Key('preview-fullscreen')));
      await settle(tester);
      final state = tester.state(find.byType(NoteView));
      await tester.tap(find.byKey(const Key('preview-fullscreen-exit')));
      await settle(tester);
      expect(find.byType(NoteView), findsOneWidget);
      expect(tester.state(find.byType(NoteView)), same(state));

      await controller.close();
      await controller.dispose();
    });
  });
}
