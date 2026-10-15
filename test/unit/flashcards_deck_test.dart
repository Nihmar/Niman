import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/flash_card.dart';

Deck read(String text) => Deck.read(text);

List<String> keys(Deck deck) => [for (final c in deck.cards) c.key];

String cut(String text, NoteRange? range) =>
    text.substring(range!.start, range.end);

void main() {
  group('table rows', () {
    test('the header is not a card; two columns are question and answer', () {
      final deck = read('''
| Verb | Past |
|---|---|
| begin | began |
| choose | chose |
''');
      expect(keys(deck), ['begin', 'choose']);
      expect(deck.cards[0].kind, CardKind.tableRow);
      expect(deck.cards[0].question, 'begin');
      expect(deck.cards[0].answer, 'began');
    });

    test('more than two columns: the first two without front and back', () {
      final deck = read('''
| A | B | C |
|---|---|---|
| a1 | b1 | c1 |
''');
      expect(deck.cards.single.question, 'a1');
      expect(deck.cards.single.answer, 'b1');
    });

    test('front and back name the columns, case and spaces aside', () {
      final deck = read('''
---
type: flashcard
front: " word "
back: MEANING
---

| Id | Word | Note | Meaning |
|---|---|---|---|
| 1 | cat | pet | gatto |
''');
      expect(deck.meta.front, 'word');
      expect(deck.cards.single.question, 'cat');
      expect(deck.cards.single.answer, 'gatto');
    });

    test(
      'front and back that do not both match fall back to the first two',
      () {
        final deck = read('''
---
front: Word
back: Nowhere
---

| Id | Word | Meaning |
|---|---|---|
| 1 | cat | gatto |
''');
        expect(deck.cards.single.question, '1');
        expect(deck.cards.single.answer, 'cat');
      },
    );

    test('front and back are ignored by a two-column table', () {
      final deck = read('''
---
front: B
back: A
---

| A | B |
|---|---|
| q | a |
''');
      expect(deck.cards.single.question, 'q');
    });

    test('every table of the note contributes', () {
      final deck = read('''
| A | B |
|---|---|
| one | 1 |

text

| C | D |
|---|---|
| two | 2 |
''');
      expect(keys(deck), ['one', 'two']);
    });

    test('an escaped pipe stays in its cell', () {
      final deck = read(r'''
| Q | A |
|---|---|
| a \| b | x \| y |
''');
      expect(deck.cards.single.question, 'a | b');
      expect(deck.cards.single.key, 'a | b');
      expect(deck.cards.single.answer, 'x | y');
    });

    test('a row without a question is not a card', () {
      final deck = read('''
| Q | A |
|---|---|
|  | orphan |
| ok | fine |
''');
      expect(keys(deck), ['ok']);
    });

    test('the key is the question as plain text', () {
      final deck = read('''
| Q | A |
|---|---|
| **to** *tread*  `now` | trod |
''');
      expect(deck.cards.single.key, 'to tread now');
      expect(deck.cards.single.question, '**to** *tread*  `now`');
    });
  });

  group('lines', () {
    test('a paragraph and a list item of one line holding a divider', () {
      final deck = read('''
thrive :: throve · thriven

- weave :: wove

* [ ] task :: done

1. a *b* :: c
''');
      expect(keys(deck), ['thrive', 'weave', 'task', 'a b']);
      expect(deck.cards[0].kind, CardKind.line);
      expect(deck.cards[0].answer, 'throve · thriven');
      expect(deck.cards[1].answer, 'wove');
    });

    test('the first divider splits', () {
      final deck = read('a :: b :: c');
      expect(deck.cards.single.question, 'a');
      expect(deck.cards.single.answer, 'b :: c');
    });

    test('a divider in a code span does not split', () {
      final deck = read('use `a :: b` here :: because');
      expect(deck.cards.single.question, 'use `a :: b` here');
      expect(deck.cards.single.answer, 'because');
    });

    test('a divider in a paragraph of several lines is no card', () {
      expect(read('one :: two\nthree').cards, isEmpty);
    });

    test('a divider needs its spaces', () {
      expect(read('a::b\n\nc ::d').cards, isEmpty);
    });
  });

  group('clozes', () {
    test('each highlight is a card with the others plain', () {
      final deck = read('The ==cat== sat on the ==mat==.');
      expect(deck.cards, hasLength(2));
      expect(deck.cards[0].kind, CardKind.cloze);
      expect(deck.cards[0].question, 'The […] sat on the mat.');
      expect(deck.cards[0].answer, 'cat');
      expect(deck.cards[0].key, 'The […] sat on the mat.');
      expect(deck.cards[1].question, 'The cat sat on the […].');
      expect(deck.cards[1].answer, 'mat');
      expect(deck.cards[1].key, 'The cat sat on the […].');
    });

    test('a list item and a marked-up line', () {
      final deck = read('- *To tread*: ==trod==, **pret**.');
      expect(deck.cards.single.key, 'To tread: […], pret.');
      expect(deck.cards.single.question, '*To tread*: […], **pret**.');
    });

    test('a cloze across the lines of a paragraph', () {
      final deck = read('first line\nthe ==hidden==\nlast');
      expect(deck.cards.single.key, 'first line the […] last');
      expect(deck.cards.single.source.firstLine, 0);
      expect(deck.cards.single.source.lastLine, 2);
    });

    test('a literal […] in the sentence is escaped, only the gap is one', () {
      final deck = read('I came […] and ==conquered== and ==saw […]==.');
      expect(deck.cards, hasLength(2));
      expect(deck.cards[0].question, r'I came […\] and […] and saw […\].');
      expect(deck.cards[1].question, r'I came […\] and conquered and […].');
      for (final card in deck.cards) {
        expect(card.question.split(FlashCard.clozeGap), hasLength(2));
      }
    });

    test('a line with a divider is a line card, its highlights marks', () {
      final deck = read('a ==b== :: c');
      expect(deck.cards.single.kind, CardKind.line);
    });
  });

  group('what is not a card', () {
    test('code, math, html and frontmatter', () {
      final deck = read(r'''
---
type: flashcard
note: ==x== :: y
---

```
a :: b
==c==
```

    indented :: code

$$
d :: e
==f==
$$

<div>
g :: h
</div>

# ==heading==
''');
      expect(deck.cards, isEmpty);
    });

    test('a footnote definition', () {
      expect(read('text[^1]\n\n[^1]: ==x==').cards, isEmpty);
    });
  });

  group('keys', () {
    test('a repeated question is numbered by order', () {
      final deck = read('''
| Q | A |
|---|---|
| dup | 1 |
| dup | 2 |

dup :: 3
''');
      expect(keys(deck), ['dup', 'dup (2)', 'dup (3)']);
    });

    test('the answer changing keeps the key', () {
      final a = read('| Q | A |\n|---|---|\n| begin | began |\n');
      final b = read('| Q | A |\n|---|---|\n| begin | something else |\n');
      expect(keys(a), keys(b));
    });

    test('moving a row or making it a line keeps the key', () {
      final table = read('''
| Q | A |
|---|---|
| a | 1 |
| b | 2 |
''');
      final moved = read('''
| Q | A |
|---|---|
| b | 2 |
| a | 1 |
''');
      final line = read('a :: 1\n\n| Q | A |\n|---|---|\n| b | 2 |\n');
      expect(keys(moved).toSet(), keys(table).toSet());
      expect(keys(line).toSet(), keys(table).toSet());
    });

    test('a changed question is a new key', () {
      final a = read('| Q | A |\n|---|---|\n| begin | began |\n');
      final b = read('| Q | A |\n|---|---|\n| begins | began |\n');
      expect(keys(a), isNot(keys(b)));
    });
  });

  group('deck metadata', () {
    test('deck path, tags and title', () {
      final deck = read('''
---
type: flashcard
title: Verbs
deck: " Lingue / Inglese "
tags: [esame, Giugno]
---
''');
      expect(deck.meta.category, ['Lingue', 'Inglese']);
      expect(deck.meta.tags, ['esame', 'giugno']);
      expect(deck.meta.title, 'Verbs');
    });

    test('no deck, or an empty one, is no category', () {
      expect(read('x').meta.category, isEmpty);
      expect(read('---\ndeck:\n---\n').meta.category, isEmpty);
      expect(read('---\ndeck: " / "\n---\n').meta.category, isEmpty);
    });
  });

  group('source locations', () {
    const text = r'''
---
type: flashcard
---

| Q | A |
|---|---|
| a \| b | **x** |

- weave :: wove

The ==cat== sat.
''';

    test('a table row', () {
      final source = read(text).cards[0].source;
      expect(source.firstLine, 6);
      expect(source.lastLine, 6);
      expect(cut(text, source.content), r'| a \| b | **x** |');
      expect(cut(text, source.lines), r'| a \| b | **x** |');
      expect(cut(text, source.question), r'a \| b');
      expect(cut(text, source.answer), '**x**');
    });

    test('a list item line', () {
      final source = read(text).cards[1].source;
      expect(source.firstLine, 8);
      expect(cut(text, source.content), 'weave :: wove');
      expect(cut(text, source.lines), '- weave :: wove');
      expect(cut(text, source.question), 'weave');
      expect(cut(text, source.answer), 'wove');
    });

    test('a cloze', () {
      final source = read(text).cards[2].source;
      expect(source.firstLine, 10);
      expect(cut(text, source.lines), 'The ==cat== sat.');
      expect(cut(text, source.answer), '==cat==');
      expect(source.question, isNull);
    });

    test('with CRLF line endings', () {
      final crlf = text.replaceAll('\n', '\r\n');
      final source = read(crlf).cards[1].source;
      expect(cut(crlf, source.lines), '- weave :: wove');
      expect(cut(crlf, source.answer), 'wove');
    });
  });

  group('readOffUi', () {
    test('a short note is read at once', () {
      final read = Deck.readOffUi('begin :: began\n');
      expect(read, isA<Deck>());
      expect((read as Deck).cards.single.question, 'begin');
    });

    test('a note from Deck.isolateFrom on is read on an isolate', () async {
      final pad = 'filler words\n\n' * (Deck.isolateFrom ~/ 14);
      final text = '$pad- begin :: began\n';
      expect(text.length, greaterThanOrEqualTo(Deck.isolateFrom));
      final read = Deck.readOffUi(text);
      expect(read, isA<Future<Deck>>());
      final deck = await read;
      expect(keys(deck), keys(Deck.read(text)));
      expect(deck.cards.single.question, 'begin');
    });
  });
}
