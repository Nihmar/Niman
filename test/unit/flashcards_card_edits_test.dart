import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/card_edits.dart';
import 'package:niman/src/flashcards/deck.dart';

Deck read(String text) => Deck.read(text);

List<String> keys(String text) => [for (final c in read(text).cards) c.key];

String rewrite(String text, int card, {String? question, String? answer}) {
  final c = read(text).cards[card];
  return rewriteCard(
    text,
    c,
    question: question ?? c.question,
    answer: answer ?? c.answer,
  );
}

String delete(String text, int card) =>
    deleteCard(text, read(text).cards[card]);

String add(String text, String question, String answer) =>
    addCard(text, read(text), question: question, answer: answer);

void main() {
  group('rewriting a table row', () {
    const note =
        '| Verb | Past |\n'
        '|---|---|\n'
        '| begin | began |\n'
        '| choose | chose |\n';

    test('the answer changes and the key stays', () {
      final out = rewrite(note, 0, answer: 'began, begun');
      expect(
        out,
        '| Verb | Past |\n'
        '|---|---|\n'
        '| begin | began, begun |\n'
        '| choose | chose |\n',
      );
      expect(keys(out), keys(note));
    });

    test('the question changes and so does the key', () {
      final out = rewrite(note, 1, question: 'pick');
      expect(out, contains('| pick | chose |\n'));
      expect(keys(out), ['begin', 'pick']);
    });

    test('a pipe is escaped, and reads back as the pipe', () {
      final out = rewrite(note, 0, answer: 'a|b');
      expect(out, contains(r'| begin | a\|b |'));
      expect(read(out).cards[0].answer, 'a|b');
      final again = rewrite(out, 0, question: 'x');
      expect(again, contains(r'| x | a\|b |'));
    });

    test('a pipe already escaped is not escaped twice', () {
      expect(rewrite(note, 0, answer: r'a\|b'), contains(r'| begin | a\|b |'));
    });

    test('a line break typed into a cell becomes a space', () {
      expect(rewrite(note, 0, answer: 'one\ntwo'), contains('| one two |'));
    });

    test('a piece left as it was is left as written', () {
      const odd =
          '| Verb | Past |\n'
          '|---|---|\n'
          '|   begin   |began|\n';
      final out = rewrite(odd, 0, question: 'begin', answer: 'began');
      expect(out, odd);
      final answer = rewrite(odd, 0, answer: 'did begin');
      expect(answer, contains('|   begin   |did begin|'));
    });

    test('the other columns of a wide table keep their bytes', () {
      const wide =
          '---\nfront: Word\nback: Meaning\n---\n\n'
          '| Id | Word | Note | Meaning |\n'
          '|---|---|---|---|\n'
          '| 1 |  cat  | *pet*  | gatto |\n';
      final out = rewrite(wide, 0, answer: 'micio');
      expect(out, wide.replaceFirst('gatto', 'micio'));
      final both = rewrite(wide, 0, question: 'dog', answer: 'cane');
      expect(both, contains('| 1 |  dog  | *pet*  | cane |'));
    });

    test('a padded table keeps its width while the words fit', () {
      const padded =
          '| Verb     | Past         |\n'
          '|----------|--------------|\n'
          '| begin    | began        |\n';
      final shorter = rewrite(padded, 0, answer: 'did');
      expect(shorter, contains('| begin    | did          |'));
      final longer = rewrite(padded, 0, answer: 'a rather long answer.');
      expect(longer, contains('| begin    | a rather long answer. |'));
      final close = rewrite(padded, 0, question: 'beginning');
      expect(close, contains('| beginning | began        |'));
    });

    test('a note with CRLF line endings keeps them all', () {
      final crlf = note.replaceAll('\n', '\r\n');
      final out = rewrite(crlf, 1, answer: 'chosen');
      expect(out, crlf.replaceFirst('chose ', 'chosen '));
      expect(RegExp(r'(?<!\r)\n').hasMatch(out), isFalse);
    });

    test('a row without edge pipes', () {
      const bare =
          'Verb | Past\n'
          '--- | ---\n'
          'begin | began\n';
      expect(rewrite(bare, 0, answer: 'did'), contains('begin | did\n'));
    });

    test('a row with a missing cell gains it', () {
      const short =
          '| Verb | Past |\n'
          '|---|---|\n'
          '| begin |\n';
      final out = rewrite(short, 0, answer: 'began');
      expect(read(out).cards.single.answer, 'began');
    });

    test('a row in a quote keeps the quote', () {
      const quoted =
          '> | Verb | Past |\n'
          '> |---|---|\n'
          '> | begin | began |\n';
      final out = rewrite(quoted, 0, answer: 'did');
      expect(out, contains('> | begin | did |\n'));
      expect(read(out).cards.single.answer, 'did');
    });

    test('the second of two equal questions keeps its (2) key', () {
      const twice =
          '| Q | A |\n'
          '|---|---|\n'
          '| same | one |\n'
          '| same | two |\n';
      final out = rewrite(twice, 1, answer: 'deux');
      expect(keys(out), ['same', 'same (2)']);
      expect(out, contains('| same | deux |'));
    });
  });

  group('rewriting a :: line', () {
    test('a list item, both sides', () {
      const note = '- thrive :: throve\n- tread :: trod\n';
      final out = rewrite(note, 0, question: 'thrive!', answer: 'thriven');
      expect(out, '- thrive! :: thriven\n- tread :: trod\n');
      expect(keys(out), ['thrive!', 'tread']);
    });

    test('only the answer', () {
      const note = 'a :: b\n';
      final out = rewrite(note, 0, answer: 'c d');
      expect(out, 'a :: c d\n');
      expect(keys(out), ['a']);
    });

    test('a divider typed into the question does not split the card', () {
      const note = 'a :: b\n';
      final out = rewrite(note, 0, question: 'x :: y');
      expect(read(out).cards.single.answer, 'b');
      expect(read(out).cards, hasLength(1));
    });

    test('markup stays as typed', () {
      const note = '- *to tread* :: `trod`\n';
      final out = rewrite(note, 0, answer: '`trod` or `treaded`');
      expect(out, '- *to tread* :: `trod` or `treaded`\n');
      expect(keys(out), ['to tread']);
    });
  });

  group('rewriting a cloze', () {
    test('the sentence is the paragraph as written', () {
      const note = 'Intro.\n\nThe past of *to tread* is ==trod==.\n';
      final card = read(note).cards.single;
      expect(clozeSentence(note, card), 'The past of *to tread* is ==trod==.');
      final out = rewriteCloze(
        note,
        card,
        'The past of *to tread* is ==trod== (or ==treaded==).',
      );
      expect(out, startsWith('Intro.\n\nThe past of *to tread* is ==trod== ('));
      expect(read(out).cards, hasLength(2));
    });

    test('one line stays one line', () {
      const note = '- a ==b==\n';
      final card = read(note).cards.single;
      expect(rewriteCloze(note, card, 'a\n==c=='), '- a ==c==\n');
    });

    test('a paragraph of two lines keeps the note line endings', () {
      const note = 'one ==two==\r\nthree\r\n';
      final card = read(note).cards.single;
      final out = rewriteCloze(note, card, 'one ==two==\nthree four');
      expect(out, 'one ==two==\r\nthree four\r\n');
    });
  });

  group('deleting a card', () {
    const note =
        '| Q | A |\n'
        '|---|---|\n'
        '| a | 1 |\n'
        '| b | 2 |\n'
        '| c | 3 |\n';

    test('a row, first, middle and last', () {
      expect(delete(note, 0), '| Q | A |\n|---|---|\n| b | 2 |\n| c | 3 |\n');
      expect(delete(note, 1), '| Q | A |\n|---|---|\n| a | 1 |\n| c | 3 |\n');
      expect(delete(note, 2), '| Q | A |\n|---|---|\n| a | 1 |\n| b | 2 |\n');
    });

    test('the last row of a note without a final line ending', () {
      final bare = note.substring(0, note.length - 1);
      expect(delete(bare, 2), '| Q | A |\n|---|---|\n| a | 1 |\n| b | 2 |');
    });

    test('with CRLF line endings', () {
      final crlf = note.replaceAll('\n', '\r\n');
      expect(
        delete(crlf, 1),
        '| Q | A |\r\n|---|---|\r\n| a | 1 |\r\n| c | 3 |\r\n',
      );
      final bare = crlf.substring(0, crlf.length - 2);
      expect(
        delete(bare, 2),
        '| Q | A |\r\n|---|---|\r\n| a | 1 |\r\n| b | 2 |',
      );
    });

    test('the last row leaves the table with its head', () {
      const one = '| Q | A |\n|---|---|\n| a | 1 |\n';
      final out = delete(one, 0);
      expect(out, '| Q | A |\n|---|---|\n');
      expect(read(out).cards, isEmpty);
      expect(read(out).tables, hasLength(1));
    });

    test('a row in a quote', () {
      const quoted = '> | Q | A |\n> |---|---|\n> | a | 1 |\n> | b | 2 |\n';
      expect(delete(quoted, 0), '> | Q | A |\n> |---|---|\n> | b | 2 |\n');
    });

    test('a :: line takes its line, and a blank line that would double', () {
      const lines = 'Before\n\n- a :: 1\n\nAfter\n';
      expect(delete(lines, 0), 'Before\n\nAfter\n');
      const items = '- a :: 1\n- b :: 2\n';
      expect(delete(items, 0), '- b :: 2\n');
      expect(delete(items, 1), '- a :: 1\n');
    });

    test('a cloze loses its marks and keeps its words', () {
      const note = 'The ==cat== sat on the ==mat==.\n';
      expect(delete(note, 0), 'The cat sat on the ==mat==.\n');
      expect(delete(note, 1), 'The ==cat== sat on the mat.\n');
    });

    test('the other cards keep their keys', () {
      expect(keys(delete(note, 1)), ['a', 'c']);
    });
  });

  group('adding a card', () {
    test('a row at the end of the first table', () {
      const note =
          '| Q | A |\n'
          '|---|---|\n'
          '| a | 1 |\n'
          '\n'
          'Closing words.\n';
      final out = add(note, 'b', '2');
      expect(
        out,
        '| Q | A |\n|---|---|\n| a | 1 |\n| b | 2 |\n\nClosing words.\n',
      );
      expect(keys(out), ['a', 'b']);
    });

    test('into a table with a head and no row', () {
      final out = add(flashcardNoteContent(), 'q', 'a');
      expect(out, endsWith('| Question | Answer |\n|---|---|\n| q | a |\n'));
      expect(read(out).cards.single.question, 'q');
    });

    test('a padded table is padded like its last row', () {
      const note =
          '| Verb     | Past         |\n'
          '|----------|--------------|\n'
          '| begin    | began        |\n';
      expect(add(note, 'do', 'did'), endsWith('| do       | did          |\n'));
    });

    test('a note without a final line ending', () {
      const note = '| Q | A |\n|---|---|\n| a | 1 |';
      expect(add(note, 'b', '2'), '$note\n| b | 2 |');
    });

    test('with CRLF line endings', () {
      const note = '| Q | A |\r\n|---|---|\r\n| a | 1 |\r\n';
      expect(
        add(note, 'b', '2'),
        '| Q | A |\r\n|---|---|\r\n| a | 1 |\r\n| b | 2 |\r\n',
      );
    });

    test('into a quoted table', () {
      const note = '> | Q | A |\n> |---|---|\n> | a | 1 |\n';
      expect(add(note, 'b', '2'), '$note> | b | 2 |\n');
    });

    test('pipes are escaped', () {
      final out = add('| Q | A |\n|---|---|\n', 'a|b', 'c');
      expect(out, contains(r'| a\|b | c |'));
      expect(read(out).cards.single.question, 'a|b');
    });

    test('the columns front and back name; the others stay empty', () {
      const note =
          '---\nfront: Word\nback: Meaning\n---\n\n'
          '| Id | Word | Note | Meaning |\n'
          '|---|---|---|---|\n'
          '| 1 | cat | pet | gatto |\n';
      final out = add(note, 'dog', 'cane');
      expect(
        out,
        endsWith('| 1 | cat | pet | gatto |\n|   | dog |     | cane |\n'),
      );
      final card = read(out).cards.last;
      expect((card.question, card.answer), ('dog', 'cane'));
    });

    test('a table is made when the note has none', () {
      expect(
        add('Some words.\n', 'q', 'a'),
        'Some words.\n\n| Question | Answer |\n|---|---|\n| q | a |\n',
      );
      expect(
        add('', 'q', 'a'),
        '| Question | Answer |\n|---|---|\n| q | a |\n',
      );
      expect(
        add('x\r\n', 'q', 'a'),
        'x\r\n\r\n| Question | Answer |\r\n|---|---|\r\n| q | a |\r\n',
      );
    });

    test('no table in a code block is taken for one', () {
      const note = '```\n| Q | A |\n|---|---|\n```\n';
      final out = add(note, 'q', 'a');
      expect(out, endsWith('| Question | Answer |\n|---|---|\n| q | a |\n'));
      expect(read(out).cards.single.question, 'q');
    });
  });

  test('a new deck note has a table and no card', () {
    final deck = read(flashcardNoteContent());
    expect(deck.cards, isEmpty);
    expect(deck.tables, hasLength(1));
    expect(deck.meta.category, isEmpty);
  });
}
