// T-WYS-05: the WYSIWYG surface replaces the source editor, never sits
// beside the preview, and hides the source-only controls.
import 'package:copist/src/editor/note_editor.dart';
import 'package:copist/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:copist/src/preview/markdown_preview.dart';
import 'package:copist/src/spellcheck/editor_spell_check.dart';
import 'package:copist/src/spellcheck/spell_checker.dart';
import 'package:copist/src/ui/editor_preview_split.dart';
import 'package:copist/src/ui/note_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// A checker whose only misspelling is 'wrold', with one suggestion.
final class _SpellFixChecker implements SpellChecker {
  const _SpellFixChecker();

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) => word != 'wrold';

  @override
  List<String> suggest(String word) =>
      word == 'wrold' ? const <String>['world'] : const <String>[];

  @override
  void dispose() {}
}

NoteView _view({
  bool showWysiwyg = false,
  bool showPreview = false,
  bool splitPreview = false,
}) => NoteView(
  path: '/notes/a.md',
  showLineNumbers: true,
  autofocusEditor: false,
  showWysiwyg: showWysiwyg,
  showPreview: showPreview,
  splitPreview: splitPreview,
  readNote: (_) async => '# Head\n\nbody text',
);

Future<void> _open(WidgetTester tester, Widget view) async {
  await tester.pumpWidget(_app(view));
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('WYSIWYG replaces the source editor and never splits', (
    tester,
  ) async {
    await _open(tester, _view(showWysiwyg: true, splitPreview: true));
    expect(tester.takeException(), isNull);
    expect(find.byType(WysiwygEditor), findsOneWidget);
    expect(find.byType(NoteEditor), findsNothing);
    expect(find.byType(EditorPreviewSplit), findsNothing);
    expect(find.byType(MarkdownPreview), findsNothing);
  });

  testWidgets('the eye switches the WYSIWYG surface to the preview', (
    tester,
  ) async {
    var preview = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  key: const Key('editor-preview-toggle'),
                  icon: Icon(preview ? Icons.edit : Icons.visibility),
                  onPressed: () => setState(() => preview = !preview),
                ),
              ],
            ),
            body: NoteView(
              path: '/notes/a.md',
              showLineNumbers: true,
              autofocusEditor: false,
              showWysiwyg: true,
              showPreview: preview,
              readNote: (_) async => '# Head\n\nbody text',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(WysiwygEditor), findsOneWidget);
    await tester.tap(find.byKey(const Key('editor-preview-toggle')));
    await tester.pump();
    expect(find.byType(MarkdownPreview), findsOneWidget);
    expect(find.byType(WysiwygEditor), findsNothing);
    await tester.tap(find.byKey(const Key('editor-preview-toggle')));
    await tester.pump();
    expect(find.byType(WysiwygEditor), findsOneWidget);
    expect(find.byType(MarkdownPreview), findsNothing);
  });

  testWidgets('find opens over the WYSIWYG surface', (tester) async {
    await _open(tester, _view(showWysiwyg: true));
    expect(find.byKey(const Key('editor-find-open')), findsOneWidget);
    expect(find.byKey(const Key('wysiwyg-find-input')), findsNothing);
    await tester.tap(find.byKey(const Key('editor-find-open')));
    await tester.pump();
    expect(find.byKey(const Key('wysiwyg-find-input')), findsOneWidget);
    await tester.tap(find.byKey(const Key('wysiwyg-find-close')));
    await tester.pump();
    expect(find.byKey(const Key('wysiwyg-find-input')), findsNothing);
  });

  testWidgets('the spell panel fixes a WYSIWYG word', (tester) async {
    final spell = EditorSpellCheck(
      createChecker: (_) => const _SpellFixChecker(),
    );
    addTearDown(spell.dispose);
    await _open(
      tester,
      NoteView(
        path: '/notes/a.md',
        showLineNumbers: true,
        autofocusEditor: false,
        showWysiwyg: true,
        spellCheck: spell,
        readNote: (_) async => 'hello wrold\n',
      ),
    );
    await tester.tap(find.byKey(const Key('spell-check-open')));
    await tester.pumpAndSettle();
    expect(find.text('wrold', findRichText: true), findsWidgets);
    await tester.tap(find.byKey(const Key('suggest-world')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('hello world', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('the toolbar formats the WYSIWYG document', (tester) async {
    await _open(tester, _view(showWysiwyg: true));
    await tester.tap(find.byKey(const Key('toolbar-bold')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
