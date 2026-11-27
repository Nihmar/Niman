// An entry read from the closed HTML grammar of the pack format
// (docs/records/dictionary.md): the record's own example exactly, the forms,
// and anything outside the grammar read as text.
//
// The HTML is written as adjacent strings, and no space is wanted between
// them.
// ignore_for_file: missing_whitespace_between_adjacent_strings
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/dictionary/dictionary_credit.dart';
import 'package:niman/src/dictionary/dictionary_entry.dart';
import 'package:niman/src/dictionary/dictionary_entry_parser.dart';
import 'package:niman/src/dictionary/dictionary_run.dart';
import 'package:niman/src/dictionary/stardict_ifo.dart';

import 'fixture_packs.dart';

/// The example of "The pack format, version 1", character for character.
const String _record = '''
<div class="entry">
  <h1>caminetto</h1>
  <section data-pos="noun" data-tags="masculine">
    <ol>
      <li><span class="q">figurative</span> Gloss text, with <i>italic</i>
        and <b>bold</b> only.
        <ul class="ex"><li>accendere il caminetto</li></ul></li>
    </ol>
    <p class="form-of" data-tags="plural">camino</p>
  </section>
  <div class="forms"><span data-tags="plural">caminetti</span></div>
</div>''';

const DictionaryCredit _credit = DictionaryCredit(
  bookName: 'Niman it',
  license: 'CC BY-SA 4.0; GFDL',
  source: 'it.wiktionary',
);

DictionaryEntry _parse(
  String html, {
  String matched = 'caminetto',
  String language = 'it',
}) => DictionaryEntryParser.parse(
  html,
  language: language,
  matched: matched,
  credit: _credit,
);

String _gloss(DictionaryEntry entry) =>
    entry.sections.single.senses.single.text;

void main() {
  group("the record's example", () {
    final entry = _parse(_record);

    test('headword, language, section and its tags', () {
      expect(entry.headword, 'caminetto');
      expect(entry.language, 'it');
      expect(entry.sections, hasLength(1));
      final section = entry.sections.single;
      expect(section.pos, 'noun');
      expect(section.tags, ['masculine']);
    });

    test('the sense has its qualifier, its runs and its example', () {
      final sense = entry.sections.single.senses.single;
      expect(sense.qualifier, 'figurative');
      expect(sense.gloss, [
        const DictionaryRun('Gloss text, with '),
        const DictionaryRun('italic', italic: true),
        const DictionaryRun(' and '),
        const DictionaryRun('bold', bold: true),
        const DictionaryRun(' only.'),
      ]);
      expect(sense.text, 'Gloss text, with italic and bold only.');
      expect(sense.examples, [
        [const DictionaryRun('accendere il caminetto')],
      ]);
    });

    test('the lemma of a form-of paragraph, and the forms', () {
      final section = entry.sections.single;
      expect(section.formOf.single.text, 'camino');
      expect(section.formOf.single.tags, ['plural']);
      expect(entry.lemmas.single.text, 'camino');
      expect(entry.forms.single.text, 'caminetti');
      expect(entry.forms.single.tags, ['plural']);
    });

    test('the pack credit is carried', () {
      expect(entry.credit.license, 'CC BY-SA 4.0; GFDL');
      expect(entry.credit.source, 'it.wiktionary');
    });
  });

  group('the form that was read', () {
    test('a listed form says its tags', () {
      final entry = _parse(_record, matched: 'caminetti');
      expect(entry.foundForm?.text, 'caminetti');
      expect(entry.foundForm?.tags, ['plural']);
    });

    test('the headword itself is no form', () {
      expect(_parse(_record).foundForm, isNull);
    });

    test('a key the entry does not list is a form without tags', () {
      final entry = _parse(_record, matched: 'camminetto');
      expect(entry.foundForm?.text, 'camminetto');
      expect(entry.foundForm?.tags, isEmpty);
    });
  });

  group('outside the grammar is text', () {
    test('an unknown tag in a gloss is dropped, its words kept', () {
      final entry = _parse(
        '<div class="entry"><h1>x</h1><section data-pos="noun"><ol>'
        '<li>Gloss <u>under</u><a href="y"> link</a> <sup>2</sup></li>'
        '</ol></section></div>',
        matched: 'x',
      );
      expect(_gloss(entry), 'Gloss under link 2');
    });

    test('an entry without the grammar is one section with its words', () {
      final entry = _parse(
        '<p>just some words</p><p>and &amp; more</p>',
        matched: 'word',
      );
      expect(entry.headword, 'word');
      expect(entry.sections.single.pos, '');
      expect(_gloss(entry), 'just some words and & more');
    });

    test('plain text is read as it is, with no tags at all', () {
      final entry = _parse('a plain definition', matched: 'word');
      expect(_gloss(entry), 'a plain definition');
    });

    test('an empty entry has a headword and nothing else', () {
      final entry = _parse('', matched: 'word');
      expect(entry.headword, 'word');
      expect(entry.sections, isEmpty);
    });

    test('a list without its end tags is read as the senses it is', () {
      final entry = _parse(
        '<section data-pos="noun"><ol><li>one<li>two<li>three</ol></section>',
      );
      expect(
        [for (final s in entry.sections.single.senses) s.text],
        ['one', 'two', 'three'],
      );
    });

    test('malformed markup never throws and keeps the words', () {
      for (final html in [
        '<li>a < b</li>',
        '<b',
        '<div class="entry"><h1>x',
        '</x></y>text',
        '<section><ol><li>unclosed <i>style</ol>',
        '<<<>>>',
        '&&;&#xZZ;&#99999999999;',
      ]) {
        expect(() => _parse(html, matched: 'x'), returnsNormally, reason: html);
      }
      expect(_gloss(_parse('<li>a < b</li>', matched: 'x')), 'a < b');
      expect(_gloss(_parse('</x></y>text', matched: 'x')), 'text');
    });

    test('a comment is dropped', () {
      expect(_gloss(_parse('a <!-- hidden --> b', matched: 'x')), 'a b');
    });
  });

  group('text', () {
    test('the four entities, apostrophes and numeric references', () {
      final entry = _parse(
        '<section><ol><li>&amp; &lt;b&gt; &quot;q&quot; &apos;a&apos; '
        '&#39;n&#39; &#x27;h&#x27; &#233; &foo; &nbsp;z</li></ol></section>',
        matched: 'x',
      );
      expect(_gloss(entry), "& <b> \"q\" 'a' 'n' 'h' \u{00E9} &foo; z");
    });

    test('whitespace is collapsed across the styles', () {
      final entry = _parse(
        '<section><ol><li>a <i> b </i> c\n\n   <b> d</b></li></ol></section>',
        matched: 'x',
      );
      expect(entry.sections.single.senses.single.gloss, [
        const DictionaryRun('a '),
        const DictionaryRun('b ', italic: true),
        const DictionaryRun('c '),
        const DictionaryRun('d', bold: true),
      ]);
    });

    test('nested styles and the long tag names', () {
      final entry = _parse(
        '<section><ol><li><b><i>both</i></b> <em>e</em> <strong>s</strong>'
        '</li></ol></section>',
        matched: 'x',
      );
      expect(entry.sections.single.senses.single.gloss, [
        const DictionaryRun('both', italic: true, bold: true),
        const DictionaryRun(' '),
        const DictionaryRun('e', italic: true),
        const DictionaryRun(' '),
        const DictionaryRun('s', bold: true),
      ]);
    });

    test('a line break reads as a space', () {
      final entry = _parse(
        '<section><ol><li>a<br>b<br/>c</li></ol></section>',
        matched: 'x',
      );
      expect(_gloss(entry), 'a b c');
    });
  });

  group('structure', () {
    test('a sense has no qualifier when it has none, or an empty one', () {
      final entry = _parse(
        '<section data-pos="noun"><ol><li>plain</li>'
        '<li><span class="q"></span>empty</li></ol></section>',
      );
      expect(
        [for (final s in entry.sections.single.senses) s.qualifier],
        [null, null],
      );
    });

    test('several sections, senses, examples and forms keep their order', () {
      final entry = _parse(
        '<div class="entry"><h1>ancora</h1>'
        '<section data-pos="noun" data-tags="feminine"><ol>'
        '<li>anchor<ul class="ex"><li>one</li><li>two <i>i</i></li></ul></li>'
        '</ol></section>'
        '<section data-pos="adv"><ol><li>still</li><li>again</li></ol>'
        '</section>'
        '<div class="forms"><span data-tags="plural">a</span>'
        '<span>b</span></div></div>',
        matched: 'ancora',
      );
      expect([for (final s in entry.sections) s.pos], ['noun', 'adv']);
      expect(entry.sections[0].senses.single.examples, hasLength(2));
      expect(
        DictionaryRun.plain(entry.sections[0].senses.single.examples[1]),
        'two i',
      );
      expect(
        [for (final s in entry.sections[1].senses) s.text],
        ['still', 'again'],
      );
      expect([for (final f in entry.forms) f.text], ['a', 'b']);
      expect(entry.forms[1].tags, isEmpty);
    });

    test('a lemma named by two sections is listed once', () {
      final entry = _parse(
        '<section data-pos="noun"><ol><li>x</li></ol>'
        '<p class="form-of">camino</p></section>'
        '<section data-pos="verb"><ol><li>y</li></ol>'
        '<p class="form-of">camino</p><p class="form-of">andare</p></section>',
        matched: 'camini',
      );
      expect([for (final l in entry.lemmas) l.text], ['camino', 'andare']);
    });
  });

  test('every entry of the fixture packs reads, with its headword', () {
    for (final entry in [...itEntries, ...enEntries]) {
      final read = _parse(entry.html, matched: entry.headword);
      expect(read.headword, entry.headword);
      expect(read.sections, isNotEmpty, reason: entry.headword);
      for (final section in read.sections) {
        expect(section.pos, isNotEmpty, reason: entry.headword);
        expect(section.senses, isNotEmpty, reason: entry.headword);
        for (final sense in section.senses) {
          expect(sense.text, isNotEmpty, reason: entry.headword);
        }
      }
    }
  });

  test('the credit is made from an .ifo', () {
    final ifo = StardictIfo.parse(
      "StarDict's dict ifo file\nbookname=Niman it\nlicense=CC BY-SA\n"
      'source=it.wiktionary\ndefinitions=it\nwebsite=w\ndescription=d\n',
    )!;
    final credit = DictionaryCredit.fromIfo(ifo);
    expect(credit.bookName, 'Niman it');
    expect(credit.license, 'CC BY-SA');
    expect(credit.source, 'it.wiktionary');
    expect(credit.definitions, 'it');
    expect(credit.website, 'w');
    expect(credit.description, 'd');
  });
}
