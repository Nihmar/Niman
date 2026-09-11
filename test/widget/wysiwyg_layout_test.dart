// T-WYS-05: the WYSIWYG surface replaces the source editor, never sits
// beside the preview, and hides the source-only controls.
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart' as delta;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/editor/toolbar.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:niman/src/preview/markdown_preview.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/ui/editor_preview_split.dart';
import 'package:niman/src/ui/note_view.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

/// A checker whose only misspelling is 'wrold', with one suggestion.
final class _SpellFixChecker implements SpellChecker {
  const new();

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

  testWidgets('a toolbar button stays pressed while its format is on', (
    tester,
  ) async {
    await _open(tester, _view(showWysiwyg: true));
    EditorToolbarButton button() => tester
        .widget<EditorToolbar>(find.byType(EditorToolbar))
        .buttons
        .firstWhere((item) => item.key == const Key('toolbar-bold'));
    expect(button().active, isFalse);
    await tester.tap(find.byKey(const Key('toolbar-bold')));
    await tester.pump();
    expect(button().active, isTrue);
    await tester.tap(find.byKey(const Key('toolbar-bold')));
    await tester.pump();
    expect(button().active, isFalse);
  });

  testWidgets('the status row switches the editor kind', (tester) async {
    EditorKind? chosen;
    await _open(
      tester,
      NoteView(
        path: '/notes/a.md',
        showLineNumbers: true,
        autofocusEditor: false,
        onEditorKindChanged: (kind) => chosen = kind,
        readNote: (_) async => '# Head\n\nbody text',
      ),
    );
    expect(find.byKey(const Key('editor-kind-toggle')), findsOneWidget);
    await tester.tap(find.byKey(const Key('editor-kind-toggle')));
    expect(chosen, EditorKind.wysiwyg);
  });

  testWidgets('the editor switch hides with a single enabled editor', (
    tester,
  ) async {
    // No `onEditorKindChanged` is what the shell passes when the library
    // enables a single editor: nowhere to switch to, no toggle.
    await _open(
      tester,
      NoteView(
        path: '/notes/a.md',
        showLineNumbers: true,
        autofocusEditor: false,
        showWysiwyg: true,
        readNote: (_) async => '# Head\n\nbody text',
      ),
    );
    expect(find.byKey(const Key('editor-kind-toggle')), findsNothing);
  });

  testWidgets('from WYSIWYG the toggle offers the source editor', (
    tester,
  ) async {
    EditorKind? chosen;
    await _open(
      tester,
      NoteView(
        path: '/notes/a.md',
        showLineNumbers: true,
        autofocusEditor: false,
        showWysiwyg: true,
        onEditorKindChanged: (kind) => chosen = kind,
        readNote: (_) async => '# Head\n\nbody text',
      ),
    );
    await tester.tap(find.byKey(const Key('editor-kind-toggle')));
    expect(chosen, EditorKind.source);
  });

  testWidgets('the toolbar formats the WYSIWYG document', (tester) async {
    await _open(tester, _view(showWysiwyg: true));
    await tester.tap(find.byKey(const Key('toolbar-bold')));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the caret past the last character takes no format', (
    tester,
  ) async {
    // A note ending in a closed ~~..~~ run: parking the caret at the end
    // lit the strikethrough button, as if tapped (device report). Every
    // inline span the codec writes is paired, so past the last character
    // the span is closed — the lamp stays off. Inside the run it still
    // lights, so typing there still continues the format.
    await _open(
      tester,
      NoteView(
        path: '/notes/a.md',
        showLineNumbers: true,
        autofocusEditor: false,
        showWysiwyg: true,
        readNote: (_) async => '**bold** plain *italic* more ~~struck~~\n',
      ),
    );
    bool strikeActive() => tester
        .widget<EditorToolbar>(find.byType(EditorToolbar))
        .buttons
        .firstWhere((item) => item.key == const Key('toolbar-strike'))
        .active;
    final state = tester.state<WysiwygEditorState>(find.byType(WysiwygEditor));

    state.controller.updateSelection(
      TextSelection.collapsed(offset: state.controller.document.length - 1),
      quill.ChangeSource.local,
    );
    await tester.pump();
    expect(strikeActive(), isFalse);

    // Inside the closed run (the "u" of "struck") the button still lights.
    state.controller.updateSelection(
      const TextSelection.collapsed(offset: 26),
      quill.ChangeSource.local,
    );
    await tester.pump();
    expect(strikeActive(), isTrue);
  });

  testWidgets('a tap-toggled format survives the typed characters', (
    tester,
  ) async {
    // The end-of-note strip dropped the just-tapped toggle after a single
    // character: the caret rode in on the document change, which the strip
    // mistook for a tap (device report). Typing keeps the toggled format;
    // a later pure tap at the end strips again.
    await _open(
      tester,
      NoteView(
        path: '/notes/a.md',
        showLineNumbers: true,
        autofocusEditor: false,
        showWysiwyg: true,
        readNote: (_) async => '**bold** plain *italic* more ~~struck~~\n',
      ),
    );
    bool strikeActive() => tester
        .widget<EditorToolbar>(find.byType(EditorToolbar))
        .buttons
        .firstWhere((item) => item.key == const Key('toolbar-strike'))
        .active;
    final state = tester.state<WysiwygEditorState>(find.byType(WysiwygEditor));
    final controller = state.controller;

    // Park at the end (the strip clears the inherited strike), then tap
    // the toolbar button for real: the toggle is intentional now.
    controller.updateSelection(
      TextSelection.collapsed(offset: controller.document.length - 1),
      quill.ChangeSource.local,
    );
    await tester.pump();
    expect(strikeActive(), isFalse);
    await tester.tap(find.byKey(const Key('toolbar-strike')));
    await tester.pump();
    expect(strikeActive(), isTrue);

    // Two typed characters, each carrying the kept style with the caret
    // riding in on the document change — the way real input arrives.
    for (var i = 0; i < 2; i++) {
      final at = controller.selection.end;
      final kept = controller.toggledStyle.toJson() ?? const {};
      controller.document.compose(
        delta.Delta()..insert('x', kept),
        quill.ChangeSource.local,
      );
      controller.updateSelection(
        TextSelection.collapsed(offset: at + 1),
        quill.ChangeSource.local,
      );
      await tester.pump();
      expect(strikeActive(), isTrue, reason: 'typed character ${i + 1}');
    }

    // A later pure tap at the end strips again: the span is closed.
    controller.updateSelection(
      TextSelection.collapsed(offset: controller.document.length - 1),
      quill.ChangeSource.local,
    );
    await tester.pump();
    expect(strikeActive(), isFalse);
  });
}
