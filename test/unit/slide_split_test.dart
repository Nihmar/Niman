import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slides_kind.dart';

List<String> _markdown(String text) =>
    splitSlides(text).map((slide) => slide.markdown).toList();

void main() {
  test('thematic breaks split the slides; the frontmatter is none', () {
    expect(_markdown('---\ntype: slides\n---\n\n# One\n\n---\n\n## Two\n'), [
      '# One',
      '## Two',
    ]);
  });

  test('a note without a break is one slide', () {
    expect(_markdown('# Only\n\ntext\n'), ['# Only\n\ntext']);
  });

  test('*** and ___ break slides too', () {
    expect(_markdown('A\n\n***\n\nB\n\n___\n\nC'), ['A', 'B', 'C']);
  });

  test('a --- in a code fence stays code', () {
    const fence = '```\na\n---\nb\n```';
    expect(_markdown('$fence\n\n---\n\nnext'), [fence, 'next']);
  });

  test('text over --- is a setext heading, not a break', () {
    expect(_markdown('Title\n---\n\nbody'), ['Title\n---\n\nbody']);
  });

  test('a break inside a list item or a quote belongs to it', () {
    expect(_markdown('- a\n\n  ---\n- b'), hasLength(1));
    expect(_markdown('> a\n>\n> ---\n> b'), hasLength(1));
  });

  test('two breaks in a row make an empty slide', () {
    expect(_markdown('A\n\n---\n\n---\n\nB'), ['A', '', 'B']);
  });

  test('Note: starts the speaker notes, up to the next break', () {
    final slides = splitSlides(
      '# One\n\n- point\n\nNote: say this\nand this\n\nmore\n\n---\n\n# Two',
    );
    expect(slides.first.markdown, '# One\n\n- point');
    expect(slides.first.notes, 'say this\nand this\n\nmore');
    expect(slides.last.notes, isNull);
  });

  test('Note: inside a fence or a quote is text', () {
    final slides = splitSlides('```\nNote: code\n```\n\n> Note: quoted');
    expect(slides.single.notes, isNull);
  });

  test('CRLF notes split the same', () {
    expect(_markdown('A\r\n\r\n---\r\n\r\nB\r\n'), ['A', 'B']);
  });

  test('a new slides note is two slides, the second with a note', () {
    final slides = splitSlides(slidesNoteContent('Deck'));
    expect(slides, hasLength(2));
    expect(slides.first.markdown, '# Deck');
    expect(slides.last.notes, isNotEmpty);
  });
}
