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
  const new();

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

  testWidgets('an empty note renders an empty editor', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(data: '', onChanged: (value) {}),
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

  testWidgets('the code block follows the theme', (tester) async {
    // Quill's default is a near-white box: in the dark theme it read as a
    // white rectangle (device report, 2026-09-11).
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: WysiwygEditor(data: '~~~\ncode\n~~~\n', onChanged: (value) {}),
        ),
      ),
    );
    await tester.pump();
    final editor = tester.widget<quill.QuillEditor>(
      find.byType(quill.QuillEditor),
    );
    final decoration = editor.config.customStyles?.code?.decoration;
    final expected = Theme.of(tester.element(find.byType(quill.QuillEditor)))
        .colorScheme
        .surfaceContainerHighest;
    expect(decoration?.color, expected);
    expect(decoration?.color, isNot(Colors.grey.shade50));
  });

  testWidgets('a stale parent echo does not reset the document', (
    tester,
  ) async {
    // The parent stores what the surface emits; while the writer keeps
    // typing its copy lags behind. Rebuilding with that copy must not
    // re-decode the note (device report: text jumped back to the start).
    var data = 'hello\n';
    final key = GlobalKey<WysiwygEditorState>();
    late StateSetter rebuild;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return MaterialApp(
            home: Scaffold(
              body: WysiwygEditor(
                key: key,
                data: data,
                onChanged: (value) => data = value,
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();
    final controller = key.currentState!.controller;
    // Three type/emit/rebuild cycles: the real app rebuilds the surface on
    // every save and preview pass, so one stale echo is not the worst case.
    for (var cycle = 0; cycle < 3; cycle++) {
      final at = controller.document.length - 1;
      // The two edits are separate typing events, not one cascade.
      controller.replaceText(
        at,
        0,
        'X',
        TextSelection.collapsed(offset: at + 1),
      );
      // The debounce fires: the parent now holds the text without the Y.
      await tester.pump(const Duration(milliseconds: 600));
      controller.replaceText(
        at + 1,
        0,
        'Y',
        TextSelection.collapsed(offset: at + 2),
      );
      await tester.pump();
      // The parent rebuilds with its stale copy.
      rebuild(() {});
      await tester.pump();
      expect(
        controller.selection.start,
        at + 2,
        reason: 'the caret moved in cycle $cycle',
      );
    }
    expect(controller.document.toPlainText(), contains('helloXYXYXY'));
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

  testWidgets('Enter after a heading does not continue the heading', (
    tester,
  ) async {
    final key = GlobalKey<WysiwygEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            key: key,
            data: '# Heading\n\nA paragraph.\n',
            onChanged: (value) {},
          ),
        ),
      ),
    );
    await tester.pump();
    final controller = key.currentState!.controller;
    // The caret at the end of the heading, Enter, then a word: two
    // separate events, not one cascade.
    // ignore: cascade_invocations
    controller.replaceText(
      7,
      0,
      '\n',
      const TextSelection.collapsed(offset: 8),
    );
    await tester.pump();
    controller.replaceText(
      8,
      0,
      'plain',
      const TextSelection.collapsed(offset: 13),
    );
    await tester.pump();
    expect(controller.getSelectionStyle().attributes['header'], isNull);
    final headings = controller.document.toDelta().toJson().where(
      (op) =>
          op['insert'] == '\n' &&
          (op['attributes'] as Map<Object?, Object?>?)?['header'] != null,
    );
    expect(headings, hasLength(1), reason: 'only the original heading line');
  });

  testWidgets('Enter in a list continues the list', (tester) async {
    final key = GlobalKey<WysiwygEditorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            key: key,
            data: '- one\n- two\n',
            onChanged: (value) {},
          ),
        ),
      ),
    );
    await tester.pump();
    final controller = key.currentState!.controller;
    // Enter, then the next item: two separate events, not one cascade.
    // ignore: cascade_invocations
    controller.replaceText(
      3,
      0,
      '\n',
      const TextSelection.collapsed(offset: 4),
    );
    await tester.pump();
    controller.replaceText(
      4,
      0,
      'three',
      const TextSelection.collapsed(offset: 9),
    );
    await tester.pump();
    expect(controller.getSelectionStyle().attributes['list']?.value, 'bullet');
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
