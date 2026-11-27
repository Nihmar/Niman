// Which language a selection is looked up in (docs/records/dictionary.md,
// decision 10): a book's own, a PDF's choice, the library's first spelling
// language, the app's; and the tags the surfaces hold said as the packs
// name them.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/dictionary/dictionary_language.dart';

void main() {
  tearDown(AppLanguages.reset);

  group('normalise', () {
    test('a tag is its primary subtag, lowercase', () {
      for (final (tag, code) in [
        ('it', 'it'),
        ('it-IT', 'it'),
        ('it_IT', 'it'),
        ('IT', 'it'),
        ('pt-BR', 'pt'),
        ('pt_PT', 'pt'),
        ('en_GB-large', 'en'),
        ('zh-Hans', 'zh'),
        ('zh-Hant-TW', 'zh'),
        (' fr-CA ', 'fr'),
        ('de_DE_frami', 'de'),
      ]) {
        expect(DictionaryLanguage.normalise(tag), code, reason: tag);
      }
    });

    test('Serbo-Croatian stays as its languages say; the pack serves them', () {
      expect(DictionaryLanguage.normalise('sr-Latn'), 'sr');
      expect(DictionaryLanguage.normalise('sr-Cyrl-RS'), 'sr');
      expect(DictionaryLanguage.normalise('hr'), 'hr');
      expect(DictionaryLanguage.normalise('bs-BA'), 'bs');
      // The macrolanguage's own code is the Croatian one, which that pack
      // serves.
      expect(DictionaryLanguage.normalise('sh'), 'hr');
    });

    test("Norwegian's macrolanguage is Bokmal; Nynorsk has no pack", () {
      expect(DictionaryLanguage.normalise('no'), 'nb');
      expect(DictionaryLanguage.normalise('nb-NO'), 'nb');
      expect(DictionaryLanguage.normalise('nn'), 'nn');
    });

    test('a book may say its language in three letters', () {
      for (final (tag, code) in [
        ('eng', 'en'),
        ('ita', 'it'),
        ('fra', 'fr'),
        ('fre', 'fr'),
        ('deu', 'de'),
        ('ger', 'de'),
        ('spa', 'es'),
        ('por', 'pt'),
        ('rus', 'rus'),
      ]) {
        expect(DictionaryLanguage.normalise(tag), code, reason: tag);
      }
    });

    test('a tag that says nothing is null', () {
      expect(DictionaryLanguage.normalise(null), isNull);
      expect(DictionaryLanguage.normalise(''), isNull);
      expect(DictionaryLanguage.normalise('   '), isNull);
      expect(DictionaryLanguage.normalise('-'), isNull);
      expect(DictionaryLanguage.normalise('1234'), isNull);
    });
  });

  group('a book', () {
    test('is looked up in the language it declares', () {
      expect(
        DictionaryLanguage.forBook('it-IT', spelling: ['en_US'], ui: 'de'),
        'it',
      );
    });

    test('with no language falls back to the library, then the app', () {
      expect(
        DictionaryLanguage.forBook(null, spelling: ['fr_FR', 'en_US']),
        'fr',
      );
      expect(DictionaryLanguage.forBook('', spelling: ['fr_FR']), 'fr');
      expect(DictionaryLanguage.forBook(null, ui: 'es'), 'es');
      AppLanguages.choice = AppLanguage.german;
      expect(DictionaryLanguage.forBook(null), 'de');
    });
  });

  group('a PDF', () {
    test('is looked up in the language chosen for the file', () {
      expect(
        DictionaryLanguage.forPdf('en', spelling: ['it_IT'], ui: 'de'),
        'en',
      );
    });

    test('with no choice is the first spelling language of the library', () {
      expect(
        DictionaryLanguage.forPdf(null, spelling: ['it_IT', 'en_US']),
        'it',
      );
    });

    test("with no choice and no spelling language is the app's", () {
      expect(DictionaryLanguage.forPdf(null, ui: 'pl'), 'pl');
      AppLanguages.choice = AppLanguage.french;
      expect(DictionaryLanguage.forPdf(null), 'fr');
    });

    test('skips a spelling name that is no language', () {
      expect(
        DictionaryLanguage.forPdf(null, spelling: ['', 'pt_BR'], ui: 'de'),
        'pt',
      );
    });
  });

  group('a note or a recognized text', () {
    test("is the library's first spelling language, else the app's", () {
      expect(DictionaryLanguage.forNote(spelling: ['nl_NL', 'en_US']), 'nl');
      expect(DictionaryLanguage.forNote(ui: 'sv'), 'sv');
      AppLanguages.choice = AppLanguage.turkish;
      expect(DictionaryLanguage.forNote(), 'tr');
    });
  });
}
