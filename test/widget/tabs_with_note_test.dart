// The note opens as a page, not a tab: on a phone the full-screen note
// takes the whole page — the tab bar does not sit under it — and back
// lands where the note was opened from.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/strings.dart';
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

  // Issue #73: on a phone the note is a page, not a tab — the tab bar
  // does not sit under it, and the way back is the app bar's arrow.
  testWidgets('an open note takes the whole page: no tab bar under it', (
    tester,
  ) async {
    await pumpWithNote(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.byKey(const Key('shell-tabs')), findsNothing);
    expect(find.byTooltip('Back'), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  // The note is a page opened from wherever: back lands on the tab the
  // note was opened from — Search here — not on Files.
  testWidgets('back lands on the tab the note was opened from (search)', (
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
    await controller.createNote(parentPath: '', name: 'Note');
    controller.searchHits = [
      const SearchHit(
        noteId: 0,
        path: 'Note.md',
        title: 'Note',
        snippet: 'first',
      ),
    ];
    await settle(tester);

    // Search opens the note from its result row: that is where it comes
    // from.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.search),
      ),
    );
    await settle(tester);
    await tester.enterText(find.byKey(const Key('search-query')), 'first');
    await settle(tester);
    await tester.tap(find.byKey(const Key('search-hit-Note.md')));
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.byKey(const Key('shell-tabs')), findsNothing);

    // Back leaves the note for Search, where the result was tapped.
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(NoteView), findsNothing);
    expect(find.byKey(const Key('shell-tabs')), findsOneWidget);
    expect(find.byKey(const Key('search-query')), findsOneWidget);

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

  // The quick note's tile sits in every tab: it opens from anywhere, and
  // back lands on the tab the tile was tapped from — not on Files.
  testWidgets('the quick note opens from any tab, and back lands there', (
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

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.check_box_outlined),
      ),
    );
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Quick note'),
      ),
    );
    await settle(tester);
    expect(find.byType(NoteView), findsOneWidget);
    expect(find.byKey(const Key('shell-tabs')), findsNothing);

    // Back lands on the Todo tab, where the tile was tapped.
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    expect(find.byType(NoteView), findsNothing);
    expect(find.byType(TodoTab), findsOneWidget);
    expect(find.byKey(const Key('shell-tabs')), findsOneWidget);

    await controller.close();
    await controller.dispose();
  });

  // Issue #73: every note opens with its folder under the name, and the
  // quick note's app bar carries its label as well — it is the quick
  // note whether it opened from the tree or from the tile.
  testWidgets('the app bar shows the note folder, the quick note its label', (
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
    await controller.createFolder(parentPath: '', name: 'Docs');
    await controller.createNote(parentPath: 'Docs', name: 'Scratch');
    await settle(tester);
    await controller.ops!.setQuickNotePath(path: 'Docs/Scratch.md');
    controller.notify(); // the shell re-reads the path on the bump

    // Opened from the tree: the folder sits under the name, and the
    // label marks the quick note.
    await tester.tap(noteRow('Docs')); // select + expand
    await settle(tester);
    await tester.tap(noteRow('Scratch.md'));
    await settle(tester);
    expect(find.text('Scratch.md'), findsOneWidget);
    expect(find.text('Docs'), findsOneWidget);
    expect(find.text(AppStrings.quickNoteTitle.toUpperCase()), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);

    // The same note from the tile: the same bar.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Quick note'),
      ),
    );
    await settle(tester);
    expect(find.text(AppStrings.quickNoteTitle.toUpperCase()), findsOneWidget);
    expect(find.text('Scratch.md'), findsOneWidget);
    expect(find.text('Docs'), findsOneWidget);

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

    // The point of switching back and forth is that it is one tap in one
    // place: the fullscreen button appearing must not slide the toggle
    // out from under the thumb already on it (user, 2026-09-17).
    testWidgets('leaves the preview toggle where it was', (tester) async {
      await pumpWithNote(tester);
      final toggle = find.byKey(const Key('editor-preview-toggle'));
      final editing = tester.getCenter(toggle);

      await tester.tap(toggle);
      await settle(tester);
      expect(tester.getCenter(toggle), editing);

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

      // The note is still open as a page: back is the app bar's arrow.
      expect(find.byKey(const Key('shell-tabs')), findsNothing);
      expect(find.byTooltip('Back'), findsOneWidget);
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

      expect(find.byKey(const Key('shell-tabs')), findsNothing);
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
