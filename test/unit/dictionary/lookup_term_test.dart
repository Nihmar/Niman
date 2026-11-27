// The candidates a selection is looked up as (docs/records/dictionary.md,
// "The engine"): cleaning, elisions, case, the first word, in that order.
// Escapes are written `\u{...}` so a ligature or a mark is visible.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/lookup_term.dart';

List<String> _of(String selection, [String language = 'it']) =>
    LookupTerm.candidates(selection, language: language);

void main() {
  group('cleaning', () {
    test('punctuation and typographic quotes around a word are trimmed', () {
      expect(_of('camino,').first, 'camino');
      expect(_of('\u{201C}Camino\u{201D}.').first, 'Camino');
      expect(_of('\u{00AB} camino \u{00BB}').first, 'camino');
      expect(_of('(camino)').first, 'camino');
      expect(_of('\u{2018}camino\u{2019}').first, 'camino');
    });

    test('soft hyphens and invisible characters are removed', () {
      expect(_of('cam\u{00AD}mino').first, 'cammino');
      expect(_of('cam\u{200B}mino\u{FEFF}').first, 'cammino');
    });

    test('a PDF ligature is expanded to its letters', () {
      expect(_of('\u{FB01}nestra').first, 'finestra');
      expect(_of('o\u{FB03}ce', 'en').first, 'office');
      expect(_of('\u{FB02}ow', 'en').first, 'flow');
      expect(_of('\u{FB00}', 'en').first, 'ff');
      expect(_of('a\u{FB04}', 'en').first, 'affl');
      expect(_of('\u{FB05}\u{FB06}', 'en').first, 'stst');
    });

    test('a word hyphenated across a line is joined, then tried with the '
        'hyphen', () {
      expect(_of('cam-\nmino'), ['cammino', 'Cammino', 'cam-mino', 'Cam-mino']);
      expect(_of('cam-\r\n   mino').first, 'cammino');
      expect(_of('cam\u{2010}\nmino').first, 'cammino');
      expect(_of('cam\u{00AC}\nmino').first, 'cammino');
      // A hyphen inside a line is part of the word.
      expect(_of('well-known', 'en').first, 'well-known');
    });

    test('decomposed letters are composed', () {
      expect(_of('citta\u{0300}').first, 'citt\u{00E0}');
    });

    test('typographic apostrophes inside a word are straightened', () {
      expect(_of('dell\u{2019}acqua'), contains("dell'acqua"));
      expect(_of('o\u{02BC}clock', 'en').first, "o'clock");
    });

    test('whitespace is collapsed, and nothing is left of an empty '
        'selection', () {
      expect(_of('  a \n priori  ').first, 'a priori');
      expect(_of(''), isEmpty);
      expect(_of('   '), isEmpty);
      expect(_of('...'), isEmpty);
    });
  });

  group('elisions', () {
    test('Italian: the article before the apostrophe goes', () {
      expect(_of("dell'acqua"), ["dell'acqua", "Dell'acqua", 'acqua', 'Acqua']);
      expect(_of("l'amico"), contains('amico'));
      expect(_of("un'ora"), contains('ora'));
      expect(_of("quell'uomo"), contains('uomo'));
    });

    test('French and Catalan', () {
      expect(_of("l'homme", 'fr'), ["l'homme", "L'homme", 'homme', 'Homme']);
      expect(_of("qu'il", 'fr'), contains('il'));
      expect(_of("jusqu'ici", 'fr'), contains('ici'));
      expect(_of("l'aigua", 'ca'), contains('aigua'));
      expect(_of("d'aigua", 'ca'), contains('aigua'));
    });

    test('both apostrophes, straight and typographic', () {
      expect(_of('l\u{2019}homme', 'fr'), contains('homme'));
      expect(_of("l'homme", 'fr'), contains('homme'));
    });

    test('other languages, and other words with an apostrophe, keep it', () {
      expect(_of("l'homme", 'en'), isNot(contains('homme')));
      expect(_of("o'clock"), isNot(contains('clock')));
      expect(_of("aujourd'hui", 'fr'), contains("aujourd'hui"));
    });

    test('a region on the language code still reads as the language', () {
      expect(_of("dell'acqua", 'it-IT'), contains('acqua'));
      expect(_of("l'homme", 'fr_CA'), contains('homme'));
      expect(_of("l'homme", 'FR'), contains('homme'));
    });
  });

  group('case', () {
    test('as selected, then lowercased, then capitalized', () {
      expect(_of('Camino'), ['Camino', 'camino']);
      expect(_of('camino'), ['camino', 'Camino']);
      expect(_of('POLISH', 'en'), ['POLISH', 'polish', 'Polish']);
    });

    test('the Turkish dotted and dotless i', () {
      expect(_of('ISI', 'tr'), ['ISI', '\u{0131}s\u{0131}', 'Is\u{0131}']);
      expect(_of('\u{0130}\u{015E}', 'tr'), contains('i\u{015F}'));
      expect(_of('\u{0130}stanbul', 'tr'), contains('istanbul'));
      expect(_of('istanbul', 'tr'), contains('\u{0130}stanbul'));
      // Elsewhere an I lowercases to i.
      expect(_of('ISI', 'en'), contains('isi'));
    });

    test('Unicode lowercasing, and the final sigma', () {
      expect(_of('\u{00C9}COLE', 'fr'), contains('\u{00E9}cole'));
      expect(
        _of('\u{03BF}\u{03B4}\u{03CC}\u{03A3}', 'el'),
        contains('\u{03BF}\u{03B4}\u{03CC}\u{03C2}'),
      );
      expect(
        _of('\u{0422}\u{0415}\u{0421}\u{0422}', 'bg'),
        contains('\u{0442}\u{0435}\u{0441}\u{0442}'),
      );
    });
  });

  group('the whole selection first, then its first word', () {
    test('an entry of several words is tried before its first word', () {
      final list = _of('a priori');
      expect(list.first, 'a priori');
      expect(list.indexOf('a priori'), lessThan(list.indexOf('a')));
      expect(list, containsAll(['A priori', 'a', 'A']));
    });

    test('the first word is cleaned again', () {
      expect(_of('polish, remover', 'en'), [
        'polish, remover',
        'Polish, remover',
        'polish',
        'Polish',
      ]);
    });

    test('a long selection is not tried whole', () {
      final list = _of(
        'one two three four five six seven eight nine ten',
        'en',
      );
      expect(list, ['one', 'One']);
    });
  });

  test('the selection as it was comes last, for entries with punctuation', () {
    expect(_of('etc.', 'en'), ['etc', 'Etc', 'etc.']);
    expect(_of('-ing', 'en').last, '-ing');
  });

  test('a repeated candidate is listed once', () {
    final list = _of('camino');
    expect(list.toSet().length, list.length);
  });

  group('the keys near a word that was not found', () {
    test('are the first word, without its article, in each case', () {
      expect(LookupTerm.prefixBases('caminett', language: 'it'), [
        'caminett',
        'Caminett',
      ]);
      expect(LookupTerm.prefixBases('Dell\u{2019}acqua,', language: 'it'), [
        'acqua',
        'Acqua',
      ]);
      expect(LookupTerm.prefixBases('polish remover', language: 'en'), [
        'polish',
        'Polish',
      ]);
      expect(LookupTerm.prefixBases('...'), isEmpty);
    });
  });
}
