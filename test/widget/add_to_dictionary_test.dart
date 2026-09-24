// Issue #60: a misspelled word offers "Add to dictionary" in the
// right-click menu, in both unified modes, and tapping the entry writes the
// word to the library's dictionary file and unflags the word.
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/personal_dictionary.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/ui/strings.dart';

const MarkdownTheme _theme = MarkdownTheme(
  body: TextStyle(fontSize: 14, height: 1.5, fontFamily: 'monospace'),
  heading1: TextStyle(fontSize: 25),
  heading2: TextStyle(fontSize: 21),
  heading3: TextStyle(fontSize: 18),
  heading4: TextStyle(fontSize: 16),
  heading5: TextStyle(fontSize: 14),
  heading6: TextStyle(fontSize: 13),
  code: TextStyle(fontSize: 14, fontFamily: 'monospace'),
  quote: TextStyle(fontSize: 14),
  tableCell: TextStyle(fontSize: 14),
  tableHeader: TextStyle(fontSize: 14),
  link: TextStyle(fontSize: 14),
  wikilink: TextStyle(fontSize: 14),
  tag: TextStyle(fontSize: 14),
  marker: TextStyle(fontSize: 14),
  codeHighlight: <String, TextStyle>{},
  rule: Color(0xFF888888),
  codeBackground: Color(0xFFEEEEEE),
  quoteBar: Color(0xFFCCCCCC),
  tableBorder: Color(0xFFCCCCCC),
  markerDim: Color(0xFF999999),
  blockSpacing: 10,
  listIndentPerLevel: 22,
  quoteIndentPerLevel: 12,
  codePadding: 8,
  quoteBarWidth: 3,
  ruleThickness: 1,
  tableCellPadding: EdgeInsets.all(4),
  lineHeight: 21,
);

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

/// Column [column] of line 0, as the view lays the text out (14 px a
/// glyph, a 5 px inset, an 8 px top margin).
Offset _at(int column) => Offset(5 + column * 14.0 + 7, 8 + 10);

/// The desktop's menu: flutter_test runs as Android unless told.
final TargetPlatformVariant _desktop = TargetPlatformVariant.only(
  TargetPlatform.linux,
);

Future<void> _pump(
  WidgetTester tester,
  String text,
  EditorSpellCheck check, {
  required bool live,
}) async {
  tester.view.physicalSize = const Size(700, 500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownSourceView(
          buffer: SourceBuffer.fromText(text),
          theme: _theme,
          showLineNumbers: false,
          spellCheck: check,
          hideMarkers: live,
        ),
      ),
    ),
  );
  await tester.pump();
}

/// A right click at column [column] of the first line.
Future<void> _rightClick(WidgetTester tester, int column) async {
  await tester.tapAt(
    _at(column),
    buttons: kSecondaryButton,
    kind: PointerDeviceKind.mouse,
  );
  await tester.pump();
}

void main() {
  for (final live in [false, true]) {
    final mode = live ? 'live' : 'source';

    testWidgets('the entry adds the word ($mode)', (tester) async {
      final dictionary = await _openDictionary(tester);
      final check = EditorSpellCheck(
        createChecker: (_) => const _FakeChecker(),
        dictionary: dictionary,
      );
      addTearDown(check.dispose);
      await _pump(tester, 'hello wrold\n', check, live: live);

      // In 'wrold'.
      await _rightClick(tester, 8);
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
      await _rightClick(tester, 8);
      expect(find.text(AppStrings.addWordToDictionary), findsNothing);
    }, variant: _desktop);

    testWidgets('a right word offers no entry ($mode)', (tester) async {
      final dictionary = await _openDictionary(tester);
      final check = EditorSpellCheck(
        createChecker: (_) => const _FakeChecker(),
        dictionary: dictionary,
      );
      addTearDown(check.dispose);
      await _pump(tester, 'hello world\n', check, live: live);

      await _rightClick(tester, 8);
      expect(tester.takeException(), isNull);
      // The menu still offers the clipboard...
      expect(find.text('Paste'), findsOneWidget);
      // ...but not the dictionary entry.
      expect(find.text(AppStrings.addWordToDictionary), findsNothing);
    }, variant: _desktop);
  }
}
