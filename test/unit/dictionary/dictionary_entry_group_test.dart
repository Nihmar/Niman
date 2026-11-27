// Entries as the panel draws them: two entries of one word in two scripts
// (a Serbo-Croatian pair) are one, the other spelling named.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dictionary_credit.dart';
import 'package:niman/src/dictionary/dictionary_entry.dart';
import 'package:niman/src/dictionary/dictionary_entry_group.dart';
import 'package:niman/src/dictionary/dictionary_run.dart';
import 'package:niman/src/dictionary/dictionary_section.dart';
import 'package:niman/src/dictionary/dictionary_sense.dart';

DictionaryEntry _entry(
  String headword,
  List<String> glosses, {
  String pos = 'noun',
  String language = 'sr',
}) => DictionaryEntry(
  headword: headword,
  language: language,
  credit: const DictionaryCredit(bookName: 'Niman'),
  sections: [
    DictionarySection(
      pos,
      senses: [
        for (final gloss in glosses) DictionarySense([DictionaryRun(gloss)]),
      ],
    ),
  ],
);

void main() {
  test('an entry on its own is a group with no other spelling', () {
    final groups = DictionaryEntryGroup.of([
      _entry('knjiga', ['book']),
    ]);
    expect(groups, hasLength(1));
    expect(groups.single.entry.headword, 'knjiga');
    expect(groups.single.otherSpellings, isEmpty);
  });

  test('the same senses in the two scripts are shown once, the first drawn '
      'and the other named', () {
    final groups = DictionaryEntryGroup.of([
      _entry('књига', ['book', 'volume']),
      _entry('knjiga', ['book', 'volume']),
    ]);
    expect(groups, hasLength(1));
    expect(groups.single.entry.headword, 'књига');
    expect(groups.single.otherSpellings, ['knjiga']);
  });

  test('the Latin entry first is the one drawn', () {
    final groups = DictionaryEntryGroup.of([
      _entry('knjiga', ['book']),
      _entry('књига', ['book']),
    ]);
    expect(groups.single.entry.headword, 'knjiga');
    expect(groups.single.otherSpellings, ['књига']);
  });

  test('a different sense, or part of speech, keeps the two apart', () {
    final cyrillic = _entry('књига', ['book']);
    expect(
      DictionaryEntryGroup.of([
        cyrillic,
        _entry('knjiga', ['tome']),
      ]),
      hasLength(2),
    );
    expect(
      DictionaryEntryGroup.of([
        cyrillic,
        _entry('knjiga', ['book'], pos: 'verb'),
      ]),
      hasLength(2),
    );
  });

  test('two lemmas in one script that gloss alike stay two', () {
    final groups = DictionaryEntryGroup.of([
      _entry('amo', ['a hook'], language: 'it'),
      _entry('amare', ['a hook'], language: 'it'),
    ]);
    expect(groups, hasLength(2));
    expect(groups.map((g) => g.otherSpellings), everyElement(isEmpty));
  });

  test('entries with no senses are never folded together', () {
    final groups = DictionaryEntryGroup.of([
      _entry('књига', const []),
      _entry('knjiga', const []),
    ]);
    expect(groups, hasLength(2));
  });
}
