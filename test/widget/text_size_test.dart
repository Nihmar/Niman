// T-M6-12: two sliders, one for the interface and one for the note.
// They are remembered per library, they reach the screen at once, and
// neither one moves what the other one owns.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/app.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/markdown/render/block_view.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/tree.dart';

import '../fakes/fake_library_session.dart';
import '../fakes/shell_harness.dart';

void main() {
  late FakeLibrarySession controller;

  setUp(() async {
    AppTextScales.reset();
    controller = FakeLibrarySession();
    await controller.open('/fake/library', create: true);
  });

  tearDown(() async {
    await controller.close();
    await controller.dispose();
    AppTextScales.reset();
  });

  /// Pumps the settings body alone, tall enough that the whole list is
  /// laid out (it is lazy, and both rows sit far apart).
  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SettingsBody(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens [row]'s dialog, drags its slider to the far right and saves.
  Future<void> dragToMax(
    WidgetTester tester, {
    required Key row,
    required Key slider,
  }) async {
    await tester.tap(find.byKey(row));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(slider), const Offset(1000, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-slider-save')));
    await tester.pumpAndSettle();
  }

  /// Opens [area]'s screen from the settings home (issue #104): the
  /// rows the tests drive live in the pushed area screen.
  Future<void> openArea(WidgetTester tester, Key area) async {
    await tester.tap(find.byKey(area));
    await tester.pumpAndSettle();
  }

  group('the settings rows', () {
    testWidgets('both start at the shipped size', (tester) async {
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-appearance'));
      expect(find.byKey(const Key('ui-text-scale-setting')), findsOneWidget);
      expect(find.text('100%'), findsNWidgets(1));
      // The note slider sits in the editor's own area.
      await tester.tap(find.backButton());
      await tester.pumpAndSettle();
      await openArea(tester, const Key('settings-area-editor'));
      expect(find.byKey(const Key('note-text-scale-setting')), findsOneWidget);
      expect(find.text('100%'), findsNWidgets(1));
    });

    testWidgets('the interface slider is remembered, and only it moves', (
      tester,
    ) async {
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-appearance'));
      await dragToMax(
        tester,
        row: const Key('ui-text-scale-setting'),
        slider: const Key('ui-text-scale-slider'),
      );

      expect(await controller.uiTextScale, maxTextScale);
      expect(await controller.noteTextScale, defaultTextScale);
      expect(AppTextScales.ui, maxTextScale);
      expect(AppTextScales.note, defaultTextScale);
    });

    testWidgets('the note slider is remembered, and only it moves', (
      tester,
    ) async {
      await pumpSettings(tester);
      await openArea(tester, const Key('settings-area-editor'));
      await dragToMax(
        tester,
        row: const Key('note-text-scale-setting'),
        slider: const Key('note-text-scale-slider'),
      );

      expect(await controller.noteTextScale, maxTextScale);
      expect(await controller.uiTextScale, defaultTextScale);
      expect(AppTextScales.note, maxTextScale);
      expect(AppTextScales.ui, defaultTextScale);
    });
  });

  group('what each slider reaches', () {
    /// Opens the shell on a library holding one note, and opens it.
    Future<void> pumpWithNote(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [librarySessionProvider.overrideWithValue(controller)],
          child: const NimanApp(),
        ),
      );
      await settle(tester);
      await controller.createNote(parentPath: '', name: 'Note');
      await settle(tester);
      await tester.tap(noteRow('Note.md'));
      await settle(tester);
    }

    /// The text scale in force where [finder]'s widget is built.
    TextScaler scalerAt(WidgetTester tester, Finder finder) =>
        MediaQuery.textScalerOf(tester.element(finder));

    testWidgets('the interface slider grows the tree', (tester) async {
      await controller.setUiTextScale(1.6);
      await pumpWithNote(tester);

      expect(
        scalerAt(tester, find.byType(NoteTree)).scale(10),
        closeTo(16, 1e-9),
      );
    });

    testWidgets('the note slider leaves the tree alone', (tester) async {
      await controller.setNoteTextScale(1.6);
      await pumpWithNote(tester);

      expect(
        scalerAt(tester, find.byType(NoteTree)).scale(10),
        closeTo(10, 1e-9),
      );
    });

    /// A note pane under the interface scaler the app root installs.
    ///
    /// The shell's own editor never materializes in a widget test — its
    /// note read is off-isolate and never lands under fake async — so
    /// the pane is pumped directly, with the root's MediaQuery around it.
    Future<void> pumpNotePane(
      WidgetTester tester, {
      required bool preview,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: ComposedTextScaler(
                MediaQuery.textScalerOf(context),
                AppTextScales.ui,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: NoteView(
              path: '/notes/a.md',
              showLineNumbers: true,
              autofocusEditor: false,
              showPreview: preview,
              readNote: (_) async => '# Hello\n\n- item',
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('the note slider sets the editor font size', (tester) async {
      await controller.setNoteTextScale(1.6);
      await pumpNotePane(tester, preview: false);

      expect(
        scalerAt(tester, find.byType(MarkdownSurface)).scale(10),
        closeTo(16, 1e-9),
      );
    });

    testWidgets('the interface slider leaves the editor font size alone', (
      tester,
    ) async {
      await controller.setUiTextScale(1.6);
      await pumpNotePane(tester, preview: false);

      expect(
        scalerAt(tester, find.byType(MarkdownSurface)).scale(10),
        closeTo(10, 1e-9),
      );
    });

    testWidgets('the preview reads at the note size, not the interface one', (
      tester,
    ) async {
      await controller.setUiTextScale(1.8);
      await controller.setNoteTextScale(1.2);
      await pumpNotePane(tester, preview: true);

      // The editor's scale and the preview's agree — 1.2 either way — and
      // the interface's 1.8 reaches neither. The editor stays mounted
      // behind the preview, out of the default finders' reach.
      expect(
        scalerAt(tester, find.byType(MarkdownReadView)).scale(10),
        closeTo(12, 1e-9),
      );
      expect(
        scalerAt(
          tester,
          find.byType(MarkdownSurface, skipOffstage: false),
        ).scale(10),
        closeTo(12, 1e-9),
      );
    });

    testWidgets("the unified note's columns grow with the note's size", (
      tester,
    ) async {
      // The note's size is a scaler, which scales its text and nothing
      // else: the list's column and the spacing stayed at 100% around text
      // half as big again. The interface's size reaches neither.
      await controller.setUiTextScale(1.8);
      for (final preview in [false, true]) {
        await controller.setNoteTextScale(1);
        await pumpNotePane(tester, preview: preview);
        await tester.pump();
        final base = _column(tester, preview: preview);
        await controller.setNoteTextScale(1.5);
        await pumpNotePane(tester, preview: preview);
        await tester.pump();
        expect(
          _column(tester, preview: preview),
          closeTo(base * 1.5, 1e-9),
          reason: preview ? 'read' : 'edit',
        );
      }
    });
  });
}

/// The list column the unified note is drawn with: the editor's, or the
/// read view's when [preview].
double _column(WidgetTester tester, {required bool preview}) => preview
    ? tester
          .widget<BlockView>(find.byType(BlockView).first)
          .theme
          .listIndentPerLevel
    : tester
          .widget<MarkdownSurface>(
            find.byType(MarkdownSurface, skipOffstage: false),
          )
          .theme
          .listIndentPerLevel;
