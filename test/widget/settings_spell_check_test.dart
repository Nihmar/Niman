// #493: the Editor settings' spell-check rows are built from the spell
// state, not from a snapshot of `available` taken at build. A dictionary
// pick restarts the engines, so `available` is false until the background
// load lands; a rebuild in that window used to drop the switch and the
// dictionary row until the screen was reopened.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_checker.dart';
import 'package:niman/src/ui/settings_editor.dart';

import '../fakes/fake_library_session.dart';

/// A loaded engine: available at once, so a test decides when a load lands.
final class _ReadyChecker implements SpellChecker {
  const new();

  @override
  bool get available => true;

  @override
  bool isCorrect(String word) => true;

  @override
  List<String> suggest(String word) => const <String>[];

  @override
  void dispose() {}
}

Future<void> _pump(
  WidgetTester tester,
  FakeLibrarySession controller,
  EditorSpellCheck spell,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SettingsEditorScreen(controller: controller, spellCheck: spell),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a dictionary reload does not drop the spell rows', (
    tester,
  ) async {
    final controller = FakeLibrarySession();
    final loads = <Completer<List<SpellChecker>>>[];
    final spell = EditorSpellCheck(
      loadCheckers: (names) {
        final load = Completer<List<SpellChecker>>();
        loads.add(load);
        return load.future;
      },
    );
    addTearDown(spell.dispose);

    // The first load lands: the rows are offered.
    loads.single.complete(const <SpellChecker>[_ReadyChecker()]);
    await _pump(tester, controller, spell);
    expect(spell.available, isTrue);

    final switchRow = find.byKey(const Key('spell-check-setting'));
    final dictionaryRow = find.byKey(const Key('spell-dictionary-setting'));
    await tester.scrollUntilVisible(switchRow, 200);
    expect(switchRow, findsOne);
    expect(dictionaryRow, findsOne);

    // Picking a dictionary restarts the engines, and the pick's setState
    // rebuilds the screen while the load is still in flight.
    spell.setDictionaries(const <String>['en_US']);
    expect(spell.available, isFalse, reason: 'the reload is in flight');
    await _pump(tester, controller, spell);
    expect(switchRow, findsOne, reason: 'the switch stays through the reload');
    expect(dictionaryRow, findsOne, reason: 'the dictionary row stays too');

    // The load lands and the rows are still the ones already offered.
    loads[1].complete(const <SpellChecker>[_ReadyChecker()]);
    await tester.pumpAndSettle();
    expect(spell.available, isTrue);
    expect(switchRow, findsOne);
    expect(dictionaryRow, findsOne);
  });

  testWidgets('turning spelling off does not drop the spell rows', (
    tester,
  ) async {
    // The switch is what turns the checker off, and off is also what
    // `available` reads: keyed on it, the row went away the moment it was
    // used.
    final controller = FakeLibrarySession();
    final spell = EditorSpellCheck(createChecker: (_) => const _ReadyChecker());
    addTearDown(spell.dispose);

    await _pump(tester, controller, spell);
    final switchRow = find.byKey(const Key('spell-check-setting'));
    final dictionaryRow = find.byKey(const Key('spell-dictionary-setting'));
    await tester.scrollUntilVisible(switchRow, 200);
    expect(switchRow, findsOne);

    await tester.tap(switchRow);
    await tester.pumpAndSettle();
    expect(spell.enabled, isFalse);
    expect(switchRow, findsOne, reason: 'the switch that turned it off stays');
    expect(dictionaryRow, findsOne);
  });
}
