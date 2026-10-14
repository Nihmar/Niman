// #533: Make flashcards — the frontmatter a note gains to become a deck,
// its body left as it was.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/make_deck.dart';

void main() {
  test('a note without frontmatter gains type and deck', () {
    final text = makeDeckText(
      '| a | b |\n|---|---|\n| x | y |\n',
      deck: 'Lingue/Inglese',
    );
    expect(
      text,
      '---\ntype: flashcard\ndeck: Lingue/Inglese\n---\n\n'
      '| a | b |\n|---|---|\n| x | y |\n',
    );
    expect(
      frontmatterOf(text),
      '---\ntype: flashcard\ndeck: Lingue/Inglese\n---',
    );
  });

  test('keeps the keys there, leaves out an empty deck, names columns', () {
    final text = makeDeckText(
      '---\ntitle: Verbs\ntags: [x]\n---\nbody\n',
      deck: '  ',
      front: 'Verb',
      back: 'Past',
    );
    expect(
      text,
      '---\ntitle: Verbs\ntags: [x]\ntype: flashcard\nfront: Verb\n'
      'back: Past\n---\nbody\n',
    );
  });

  test('a type the note had is replaced', () {
    expect(
      makeDeckText('---\ntype: list\n---\n- a :: b\n', deck: ''),
      '---\ntype: flashcard\n---\n- a :: b\n',
    );
  });

  test('a note with no frontmatter shows none', () {
    expect(frontmatterOf('just text'), '');
  });
}
