// #259: the source editor's face is a setting — the monospace face the
// editor has always been set in unless the writer chooses another — and
// only the source pane follows it: the read view and `live` keep the
// note's own face whatever it says.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_config.dart'
    show defaultSourceFont;
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/settings.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/strings.dart';

import '../fakes/fake_library_session.dart';

/// The face of the note itself: distinct from every face [SourceFont]
/// names, so a choice that hands the note back its own theme shows as this
/// one rather than as a null nobody can tell from "not applied".
const String _noteFace = 'NimanNote';

void main() {
  group("the source pane's face follows the setting", () {
    /// Pumps a surface in [mode] with [font], under a theme whose own face
    /// is [_noteFace], and answers the note's theme.
    Future<MarkdownTheme> pumpSurface(
      WidgetTester tester, {
      MarkdownSurfaceMode mode = MarkdownSurfaceMode.source,
      SourceFont? font,
    }) async {
      late MarkdownTheme note;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: _noteFace),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                note = markdownThemeOf(context, scaler: TextScaler.noScaling);
                return MarkdownSurface(
                  buffer: SourceBuffer.fromText('# Note\n\nprose\n'),
                  mode: mode,
                  theme: note,
                  // The shipped face: what a surface that is handed no
                  // choice at all is set in.
                  sourceFont: font ?? defaultSourceFont,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();
      return note;
    }

    /// The typography the editor is really drawn with.
    MarkdownTheme drawn(WidgetTester tester) => tester
        .widget<MarkdownSourceView>(find.byType(MarkdownSourceView))
        .theme;

    testWidgets('the note under it is set in its own face', (tester) async {
      // The harness: the note's theme is the app's face, so a source pane
      // reading mono or serif is the setting speaking, not the theme.
      final note = await pumpSurface(tester);
      expect(note.body.fontFamily, _noteFace);
    });

    testWidgets('a fresh editor reads in the monospace face', (tester) async {
      final note = await pumpSurface(tester);
      // The surface's own default, for a caller that hands it none: the
      // face the editor shipped in.
      expect(
        MarkdownSurface(
          buffer: SourceBuffer.fromText(''),
          mode: MarkdownSurfaceMode.source,
          theme: note,
        ).sourceFont,
        defaultSourceFont,
      );
      expect(defaultSourceFont, SourceFont.monospace);
      expect(drawn(tester).body.fontFamily, 'monospace');
      // The fallbacks the legacy editor carried, for the platforms where
      // the generic alias does not resolve.
      expect(
        drawn(tester).body.fontFamilyFallback,
        contains('DejaVu Sans Mono'),
      );
    });

    testWidgets('a chosen face is the whole editor, code included', (
      tester,
    ) async {
      await pumpSurface(tester, font: SourceFont.serif);
      expect(drawn(tester).body.fontFamily, 'serif');
      expect(drawn(tester).code.fontFamily, 'serif');
      expect(drawn(tester).marker.fontFamily, 'serif');
    });

    testWidgets('sans serif hands the note its own face back', (tester) async {
      await pumpSurface(tester, font: SourceFont.sansSerif);
      expect(drawn(tester).body.fontFamily, _noteFace);
      // The proportionally set face is the theme's, code blocks included:
      // nothing of the mono face is left over in the editor either.
      expect(drawn(tester).code.fontFamily, 'monospace');
    });

    testWidgets("live keeps the note's face whatever the setting says", (
      tester,
    ) async {
      await pumpSurface(
        tester,
        mode: MarkdownSurfaceMode.live,
        font: SourceFont.serif,
      );
      expect(drawn(tester).body.fontFamily, _noteFace);
    });

    testWidgets('the note pane hands the face down to its editor', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteView(
              path: '/notes/a.md',
              showLineNumbers: true,
              autofocusEditor: false,
              sourceFont: SourceFont.serif,
              readNote: (_) async => '# Note',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(
        tester.widget<MarkdownSurface>(find.byType(MarkdownSurface)).sourceFont,
        SourceFont.serif,
      );
    });
  });

  group('the settings row', () {
    late FakeLibrarySession controller;

    setUp(() async {
      controller = FakeLibrarySession();
      await controller.open('/fake/library', create: true);
    });

    tearDown(() async {
      await controller.close();
      await controller.dispose();
    });

    /// Pumps the settings body and opens the editor's own screen (issue
    /// #104): the row lives there, next to the note's text size.
    ///
    /// The tree is emptied first, so a second call reads the screen as a
    /// fresh one — its state comes out of the library, not out of the
    /// screen already on it.
    Future<void> pumpEditorSettings(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SettingsBody(controller: controller)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-area-editor')));
      await tester.pumpAndSettle();
    }

    /// The row, as the screen holds it.
    Finder row() => find.byKey(SettingsKeys.sourceFont);

    testWidgets('the row reads the shipped face, and offers the three', (
      tester,
    ) async {
      await pumpEditorSettings(tester);
      expect(row(), findsOneWidget);
      expect(
        find.descendant(
          of: row(),
          matching: find.text(AppStrings.sourceFontMonospace),
        ),
        findsOneWidget,
      );

      await tester.tap(row());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('source-font-dialog')), findsOneWidget);
      for (final (font, label) in [
        (SourceFont.sansSerif, AppStrings.sourceFontSansSerif),
        (SourceFont.serif, AppStrings.sourceFontSerif),
      ]) {
        expect(
          find.byKey(Key('settings-choice-$font')),
          findsOneWidget,
          reason: label,
        );
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('a chosen face is kept, and the row reads it back', (
      tester,
    ) async {
      await pumpEditorSettings(tester);
      await tester.tap(row());
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('settings-choice-SourceFont.serif')),
      );
      await tester.pumpAndSettle();

      expect(await controller.sourceFont, SourceFont.serif);
      expect(
        find.descendant(
          of: row(),
          matching: find.text(AppStrings.sourceFontSerif),
        ),
        findsOneWidget,
      );

      // The screen again, from scratch: the choice came out of the
      // library, not out of the screen's own state.
      await pumpEditorSettings(tester);
      expect(
        find.descendant(
          of: row(),
          matching: find.text(AppStrings.sourceFontSerif),
        ),
        findsOneWidget,
      );
    });
  });
}
