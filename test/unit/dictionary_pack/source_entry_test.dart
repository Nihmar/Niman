import 'package:flutter_test/flutter_test.dart';

import '../../../tool/dictionary_pack/serbo_croatian.dart';
import '../../../tool/dictionary_pack/source_entry.dart';

Map<String, Object?> _entry({
  Object? word = 'casa',
  Object? senses,
  Map<String, Object?> more = const {},
}) => {
  'word': word,
  'lang_code': 'it',
  'pos': 'noun',
  'senses':
      senses ??
      [
        {
          'glosses': ['house'],
        },
      ],
  ...more,
};

void main() {
  group('EntryParser', () {
    final english = EntryParser(englishEdition: true);
    final other = EntryParser(englishEdition: false);

    test('keeps the last gloss of a sub-sense and skips one without', () {
      final entry = english.parse(
        _entry(
          senses: [
            {
              'glosses': ['to move', 'to move quickly'],
            },
            {
              'tags': ['no-gloss'],
            },
            {
              'glosses': ['  ', ''],
            },
          ],
        ),
      )!;
      expect(entry.senses.map((s) => s.gloss), ['to move quickly']);
    });

    test('the qualifier is the tags and topics of the English edition', () {
      final entry = english.parse(
        _entry(
          senses: [
            {
              'glosses': ['a'],
              'tags': ['masculine', 'figuratively', 'slang'],
              'raw_tags': ['Tuscany'],
              'topics': ['biology'],
            },
          ],
        ),
      )!;
      expect(
        entry.senses.single.qualifier,
        'figuratively, slang, Tuscany, biology',
      );
    });

    test('and what the source printed in another edition', () {
      final entry = other.parse(
        _entry(
          senses: [
            {
              'glosses': ['a'],
              'tags': ['figuratively'],
              'raw_tags': ['figurato'],
            },
          ],
        ),
      )!;
      expect(entry.senses.single.qualifier, 'figurato');
    });

    test('a sense that is a form has no qualifier, and keeps its tags', () {
      final entry = english.parse(
        _entry(
          senses: [
            {
              'glosses': ['plural of casa'],
              'tags': ['form-of', 'plural'],
              'form_of': [
                {'word': 'casa'},
              ],
            },
            {
              'glosses': ['alternative form of casa'],
              'tags': ['alt-of'],
              'alt_of': [
                {'word': 'cassa'},
                'casetta',
              ],
            },
          ],
        ),
      )!;
      expect(entry.senses.first.qualifier, isEmpty);
      expect(entry.senses.first.formOf, ['casa']);
      expect(entry.senses.first.tags, ['plural']);
      expect(entry.senses.last.formOf, ['cassa', 'casetta']);
    });

    test('takes the gender from the head template or the entry tags', () {
      String tags(String expansion) => english
          .parse(
            _entry(
              more: {
                'head_templates': [
                  {'expansion': expansion},
                ],
              },
            ),
          )!
          .tags
          .join(' ');
      expect(tags('casa f (plural case)'), 'feminine');
      expect(tags('libro m or f'), 'masculine feminine');
      expect(tags('amare'), isEmpty);
      expect(tags('ancora adv'), isEmpty);
      expect(tags('m'), isEmpty);
      expect(
        other
            .parse(
              _entry(
                more: {
                  'tags': ['masculine'],
                },
              ),
            )!
            .tags,
        ['masculine'],
      );
    });

    test(
      'keeps examples but not quotations or very long ones, at most two',
      () {
        final entry = english.parse(
          _entry(
            senses: [
              {
                'glosses': ['a'],
                'examples': [
                  {'text': 'one', 'english': 'uno'},
                  {'text': 'quoted', 'type': 'quotation'},
                  {'text': 'x' * 300},
                  {'english': 'only a translation'},
                  {'text': 'two'},
                  {'text': 'three'},
                ],
              },
            ],
          ),
        )!;
        expect(entry.senses.single.examples, ['one', 'two']);
      },
    );

    test("forms: the extractor's bookkeeping and placeholders are dropped", () {
      final entry = english.parse(
        _entry(
          more: {
            'forms': [
              {
                'form': 'case',
                'tags': ['plural'],
              },
              {
                'form': 'casa',
                'tags': ['canonical'],
              },
              {
                'form': 'm',
                'tags': ['gender'],
              },
              {
                'form': 'no-table-tags',
                'tags': ['table-tags'],
              },
              {
                'form': '-',
                'tags': ['plural'],
              },
              {
                'form': 'kasa',
                'tags': ['romanization'],
              },
              {
                'form': 'cas',
                'tags': ['error-unknown-tag'],
              },
              {
                'form': 'a b',
                'tags': ['first-person', 'present tense'],
              },
            ],
          },
        ),
      )!;
      expect(entry.forms.map((f) => f.form), ['case', 'a b']);
      expect(entry.forms.last.tags, ['first-person', 'present-tense']);
      final kept = EntryParser(englishEdition: true, keepRomanization: true);
      expect(
        kept
            .parse(
              _entry(
                more: {
                  'forms': [
                    {
                      'form': 'kasa',
                      'tags': ['romanization'],
                    },
                  ],
                },
              ),
            )!
            .forms,
        hasLength(1),
      );
    });

    test('skips, and counts, what cannot be a headword', () {
      final parser = EntryParser(englishEdition: true);
      expect(parser.parse({'redirect': 'x', 'title': 'y'}), isNull);
      expect(parser.parse(_entry(word: null)), isNull);
      expect(parser.parse(_entry(word: '   ')), isNull);
      expect(parser.parse(_entry(word: 'a' * 300)), isNull);
      expect(parser.parse(_entry(word: 'a\u0000b')), isNull);
      expect(parser.parse(_entry(senses: [])), isNull);
      expect(parser.skipped, {
        'redirect': 1,
        'no word': 2,
        'unusable headword': 2,
        'no sense with a gloss': 1,
      });
    });

    test('a field of the wrong type is absent, not an error', () {
      final entry = english.parse(
        _entry(
          senses: [
            'not a map',
            {'glosses': 'not a list'},
            {
              'glosses': ['ok'],
              'tags': 'plural',
              'examples': {'text': 'x'},
              'form_of': 3,
              'topics': [1, null],
            },
          ],
          more: {'forms': 'none', 'tags': 7, 'head_templates': 'x'},
        ),
      )!;
      expect(entry.senses.map((s) => s.gloss), ['ok']);
      expect(entry.forms, isEmpty);
      expect(entry.tags, isEmpty);
    });

    test('collapses whitespace in a gloss and a headword', () {
      final entry = english.parse(
        _entry(
          word: ' New\n York ',
          senses: [
            {
              'glosses': ['a   big\ncity'],
            },
          ],
        ),
      )!;
      expect(entry.word, 'New York');
      expect(entry.senses.single.gloss, 'a big city');
    });
  });

  group('Serbo-Croatian scripts', () {
    test('a Cyrillic word has its exact Latin spelling', () {
      expect(latinSpelling('кућа'), 'kuća');
      expect(latinSpelling('вода'), 'voda');
      expect(latinSpelling('Београд'), 'Beograd');
    });

    test('the digraphs are lj, nj and dž, in the case of the word', () {
      expect(latinSpelling('љубав'), 'ljubav');
      expect(latinSpelling('Љубав'), 'Ljubav');
      expect(latinSpelling('ЉУБАВ'), 'LJUBAV');
      expect(latinSpelling('њива'), 'njiva');
      expect(latinSpelling('Њујорк'), 'Njujork');
      expect(latinSpelling('џеп'), 'džep');
      expect(latinSpelling('Џон'), 'Džon');
    });

    test('a Latin word gains no Cyrillic key: that map is not exact', () {
      // injekcija is инјекција, which a letter-by-letter map writes with the
      // single letter њ.
      expect(latinSpelling('kuća'), isNull);
      expect(latinSpelling('injekcija'), isNull);
      expect(latinSpelling('lijep'), isNull);
      expect(latinSpelling('džep'), isNull);
    });

    test('a word with no Cyrillic letter, or a foreign one, has none', () {
      expect(latinSpelling('123'), isNull);
      expect(latinSpelling('мышь'), isNull);
    });
  });
}
