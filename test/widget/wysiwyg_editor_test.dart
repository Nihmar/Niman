// T-WYS-04/08: the WYSIWYG surface opens a note, edits it, reports
// Markdown, underlines misspellings and applies a range replacement.
import 'package:copist/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:copist/src/spellcheck/editor_spell_check.dart';
import 'package:copist/src/spellcheck/spell_checker.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';

/// A checker whose only misspelling is 'wrold'.
final class _FakeChecker implements SpellChecker {
  const _FakeChecker();

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) => word != 'wrold';

  @override
  List<String> suggest(String word) => const <String>[];

  @override
  void dispose() {}
}

void main() {
  testWidgets('opens a note without errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            data: '# Heading\n\nA paragraph.\n',
            onChanged: (value) {},
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(quill.QuillEditor), findsOneWidget);
  });

  testWidgets('reports an edit as Markdown after the pause', (tester) async {
    String? reported;
    final key = GlobalKey<WysiwygEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            key: key,
            data: '# Heading\n\nA paragraph.\n',
            onChanged: (value) => reported = value,
          ),
        ),
      ),
    );
    await tester.pump();
    key.currentState!.controller.document.insert(0, 'Edited ');
    await tester.pump(const Duration(milliseconds: 600));
    expect(reported, isNotNull);
    expect(reported, contains('Edited'));
  });

  testWidgets('underlines the misspelled words', (tester) async {
    final spell = EditorSpellCheck(createChecker: (_) => const _FakeChecker());
    addTearDown(spell.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            data: 'hello wrold\n',
            onChanged: (value) {},
            spellCheck: spell,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    TextStyle? found;
    for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
      final walk = <InlineSpan>[rich.text];
      while (walk.isNotEmpty) {
        final node = walk.removeLast();
        if (node is TextSpan) {
          if (node.text == 'wrold') found = node.style;
          walk.addAll(node.children ?? const <InlineSpan>[]);
        }
      }
    }
    expect(found?.decorationStyle, TextDecorationStyle.wavy);
  });

  testWidgets('replaces a range of the document', (tester) async {
    final key = GlobalKey<WysiwygEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            key: key,
            data: 'hello wrold\n',
            onChanged: (value) {},
          ),
        ),
      ),
    );
    await tester.pump();
    key.currentState!.replaceDocumentRange(0, 6, 11, 'world');
    await tester.pump();
    expect(key.currentState!.plainTextLines.first, 'hello world');
  });

  testWidgets('a novel-length note offers the source editor', (tester) async {
    // Quill builds the whole document; above the guard the surface refuses
    // rather than stalls (T-WYS-07).
    final large = 'word ' * 50000;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(data: large, onChanged: (value) {}),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(AppStrings.wysiwygTooLarge), findsOneWidget);
    expect(find.byType(quill.QuillEditor), findsNothing);
  });
}
