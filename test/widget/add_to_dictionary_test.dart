// Issue #60: a misspelled word offers "Add to dictionary" in the
// right-click menu, in both editors, and tapping the entry writes the
// word to the library's dictionary file and unflags the word.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/personal_dictionary.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:re_editor/re_editor.dart';

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

/// Opens a dictionary in a temp library: the file read is real disk I/O,
/// which only completes inside [WidgetTester.runAsync] — the test body
/// runs in the fake async zone, where the real event loop never spins.
Future<PersonalDictionary> _openDictionary(WidgetTester tester) async {
  final dir = Directory.systemTemp.createTempSync('niman-dict-menu');
  addTearDown(() => dir.deleteSync(recursive: true));
  final opened = await tester.runAsync(() => PersonalDictionary.open(dir.path));
  expect(opened, isNotNull, reason: 'the dictionary file opens');
  final dictionary = opened!;
  addTearDown(dictionary.dispose);
  return dictionary;
}

/// Spins the real event loop until [dictionary] has [word]: the menu's
/// entry fired the disk write inside the fake zone, where each runAsync
/// turn lets one write phase land and its continuation flush.
Future<void> _settle(
  WidgetTester tester,
  PersonalDictionary dictionary,
  String word,
) async {
  while (!dictionary.contains(word)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
  }
}

void main() {
  testWidgets('the source editor offers the entry and adds the word', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final dictionary = await _openDictionary(tester);
    final check = EditorSpellCheck(
      createChecker: (_) => const _FakeChecker(),
      dictionary: dictionary,
    );
    final controller = CodeLineEditingController.fromText('hello wrold');
    final focus = FocusNode();
    // The caret sits in 'wrold': a right click only shows the menu, it
    // does not move the caret.
    controller.selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 6,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(
            controller: controller,
            focusNode: focus,
            spellCheck: check,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tapAt(
      tester.getCenter(find.byType(CodeEditor)),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.addWordToDictionary), findsOneWidget);

    await tester.tap(find.text(AppStrings.addWordToDictionary));
    await tester.pump();
    // The entry closed the menu and fired the disk write; let it land.
    await _settle(tester, dictionary, 'wrold');
    expect(find.text(AppStrings.addWordToDictionary), findsNothing);
    expect(File(dictionary.path).readAsStringSync(), 'wrold\n');
    expect(check.isMisspelled('wrold'), isFalse);

    // A second menu: 'wrold' is now a dictionary word, no entry.
    await tester.tapAt(
      tester.getCenter(find.byType(CodeEditor)),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    expect(find.text(AppStrings.addWordToDictionary), findsNothing);

    // Back inside the body before the tearDowns run.
    debugDefaultTargetPlatformOverride = null;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    controller.dispose();
    focus.dispose();
    check.dispose();
  });

  testWidgets('a right word in the source editor offers no entry', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final dictionary = await _openDictionary(tester);
    final check = EditorSpellCheck(
      createChecker: (_) => const _FakeChecker(),
      dictionary: dictionary,
    );
    final controller = CodeLineEditingController.fromText('hello world');
    final focus = FocusNode();
    // The caret sits in 'world', which the checker accepts.
    controller.selection = const CodeLineSelection.collapsed(
      index: 0,
      offset: 6,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteEditor(
            controller: controller,
            focusNode: focus,
            spellCheck: check,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tapAt(
      tester.getCenter(find.byType(CodeEditor)),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    // The menu still offers the platform items...
    expect(find.text('Paste'), findsOneWidget);
    // ...but not the dictionary entry.
    expect(find.text(AppStrings.addWordToDictionary), findsNothing);

    debugDefaultTargetPlatformOverride = null;
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    controller.dispose();
    focus.dispose();
    check.dispose();
  });

  testWidgets('the WYSIWYG editor offers the entry and adds the word', (
    tester,
  ) async {
    final dictionary = await _openDictionary(tester);
    final check = EditorSpellCheck(
      createChecker: (_) => const _FakeChecker(),
      dictionary: dictionary,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WysiwygEditor(
            data: 'hello wrold',
            spellCheck: check,
            onChanged: (value) {},
          ),
        ),
      ),
    );
    await tester.pump();

    // A right click offers the menu only when the editor already has focus
    // (the writer's caret is there in the app): quill opens the toolbar
    // from a post-frame callback that checks focus before the first
    // right click can take it.
    tester
        .state<WysiwygEditorState>(find.byType(WysiwygEditor))
        .requestEditorFocus();
    await tester.pump();

    // The caret sits in 'wrold' (offset 6).
    final editor = tester.state<quill.QuillEditorState>(
      find.byType(quill.QuillEditor),
    );
    editor.controller.updateSelection(
      const TextSelection.collapsed(offset: 6),
      quill.ChangeSource.local,
    );
    await tester.pump();
    final raw = tester.state<quill.QuillRawEditorState>(
      find.byType(quill.QuillRawEditor),
    );
    expect(
      raw.textEditingValue.selection,
      const TextSelection.collapsed(offset: 6),
    );

    // A right click shows the menu at the caret.
    await tester.tapAt(
      tester.getCenter(find.byType(quill.QuillEditor)),
      buttons: kSecondaryButton,
    );
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.addWordToDictionary), findsOneWidget);

    await tester.tap(find.text(AppStrings.addWordToDictionary));
    await tester.pump();
    // The entry closed the menu and fired the disk write; let it land.
    await _settle(tester, dictionary, 'wrold');
    expect(find.text(AppStrings.addWordToDictionary), findsNothing);
    expect(File(dictionary.path).readAsStringSync(), 'wrold\n');
    expect(check.isMisspelled('wrold'), isFalse);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );
    check.dispose();
  });
}
