// #908: the docked spelling review is not modal, so the note can change
// between the pass and a click. A suggestion or a click on an issue then
// acts on a range the pass found in another text: it must check the note
// still holds the word there, and when it does not, touch nothing, drop the
// issue and check again.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_check_sheet.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/ui/note_edit_commands.dart';
import 'package:niman/src/ui/note_task_items.dart';
import 'package:niman/src/ui/note_view_handle.dart';

/// 'teh' is wrong; its suggestion is 'the'.
final class _Checker implements SpellChecker {
  const new();

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) => word != 'teh';

  @override
  List<String> suggest(String word) => word == 'teh' ? const ['the'] : const [];

  @override
  void dispose() {}
}

void main() {
  late EditorSpellCheck spell;
  late MarkdownSurfaceController surface;
  late SpellReview review;
  late ChangeNotifier edited;
  var scans = 0;

  setUp(() {
    spell = EditorSpellCheck(createChecker: (_) => const _Checker());
    surface = MarkdownSurfaceController(
      SourceBuffer.fromText('x and teh end\nmore text'),
    );
    edited = ChangeNotifier();
    scans = 0;
    final commands = NoteEditCommands(
      surface: () => surface,
      focus: () {},
      context: () => throw UnimplementedError(),
      mounted: () => true,
      canInsert: () => true,
      text: () => surface.buffer.substring(0, surface.buffer.length),
      sourceView: () => null,
      readView: () => null,
      activeFormats: ValueNotifier(const {}),
      linkType: () => LinkType.wikilink,
      indentWidth: () => 2,
      toolbarLayout: () => ToolbarLayout.defaults,
      pasteAsMarkdown: () => null,
      taskItems: NoteTaskItems(
        surface: () => surface,
        sourceView: () => null,
        canInsert: () => true,
        focus: () {},
      ),
      moveToTasks: () => null,
      libraryRoot: () => null,
      pickImage: () async => null,
      importImage: (_, _) async => '',
      onInserted: () {},
      spellCheck: () => spell,
      onSpellChecked: () {},
    );
    review = commands.spellReview(edited: edited)!;
  });

  tearDown(() {
    edited.dispose();
    spell.dispose();
  });

  Future<void> pumpPane(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpellCheckSheet(
            docked: true,
            available: true,
            start: () {
              scans++;
              return review.start();
            },
            suggest: review.suggest,
            apply: review.apply,
            reveal: review.reveal,
            edited: edited,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String text() => surface.buffer.substring(0, surface.buffer.length);

  testWidgets('a suggestion after an edit before the word leaves the text '
      'alone, drops the issue and checks again', (tester) async {
    await pumpPane(tester);
    expect(find.text('teh'), findsOne);
    expect(scans, 1);

    // Five characters typed earlier on the line; the rescan has not come.
    surface.replaceRange(0, 0, 'abcde');
    final before = text();
    await tester.tap(find.widgetWithText(ActionChip, 'the'));
    await tester.pumpAndSettle();

    expect(text(), before, reason: 'the stale range was not touched');
    expect(scans, 2, reason: 'checked again');
    // The new pass found the word where it is now.
    expect(find.byKey(const Key('spell-issue-0-11')), findsOne);

    await tester.tap(find.widgetWithText(ActionChip, 'the'));
    await tester.pumpAndSettle();
    expect(text(), 'abcdex and the end\nmore text');
  });

  testWidgets('a click on an issue after the word was deleted selects '
      'nothing', (tester) async {
    await pumpPane(tester);
    // The word is gone, the line shorter than the issue's range.
    surface.replaceRange(0, 13, 'x');
    final selection = surface.selection;
    await tester.tap(find.text('teh'));
    await tester.pumpAndSettle();

    expect(surface.selection, selection, reason: 'nothing selected');
    expect(text(), 'x\nmore text');
    expect(find.text('teh'), findsNothing);
    expect(scans, 2);
  });

  testWidgets('a click on an issue whose word is still there selects it', (
    tester,
  ) async {
    await pumpPane(tester);
    await tester.tap(find.text('teh'));
    await tester.pumpAndSettle();

    expect((surface.selection.start, surface.selection.end), (6, 9));
    expect(scans, 1, reason: 'the word was there: no second pass');
  });
}
