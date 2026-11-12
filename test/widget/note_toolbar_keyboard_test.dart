// #1266: on a tablet the formatting toolbar rides the keyboard, as on a
// phone: under the note while the editor has the focus, out of the row
// above it, which keeps the note's own controls. A desktop keeps it above.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/ui/note_editor_options.dart';
import 'package:niman/src/ui/note_services.dart';
import 'package:niman/src/ui/note_top_bar.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_chrome.dart';

Widget _app() => MaterialApp(
  home: Scaffold(
    body: NoteView(
      path: '/n/a.md',
      options: const NoteEditorOptions(
        showLineNumbers: false,
        autofocusEditor: false,
      ),
      toolbarTop: true,
      services: NoteServices(
        readNote: (_) async => '# Title\n\nSome text.',
        writeNote: (_, _) async {},
      ),
    ),
  ),
);

void main() {
  final toolbar = find.byType(NoteToolbarBar);
  final above = find.descendant(of: find.byType(NoteTopBar), matching: toolbar);

  testWidgets('a tablet: the row above stays, the toolbar comes with the '
      'focus, under the note', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.byType(NoteTopBar), findsOne);
    expect(toolbar, findsNothing, reason: 'no focus, no toolbar');

    await tester.tap(find.byType(MarkdownSurface));
    await tester.pumpAndSettle();
    expect(toolbar, findsOne);
    expect(above, findsNothing);
    expect(
      tester.getRect(toolbar).top,
      greaterThan(tester.getRect(find.byType(MarkdownSurface)).top),
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a desktop: the toolbar is in the row above, focus or not', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(above, findsOne);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
}
