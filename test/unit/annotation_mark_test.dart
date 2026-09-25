// Where a file was annotated (#285): the links of a note to a place of a
// file, each with the annotation — the section — it belongs to.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/reading/book_location.dart';

void main() {
  const note =
      '---\n'
      'annotates: "[[Books/Dune.pdf]]"\n'
      '---\n'
      '\n'
      '## Dune, p. 3\n'
      '\n'
      '> A passage.\n'
      '> — [[Books/Dune.pdf#page=3&chars=4-9|Dune, p. 3]]\n'
      '\n'
      'A comment linking [[Other note]] and [[Other.pdf#page=1]].\n'
      '\n'
      '## Dune, p. 8\n'
      '\n'
      '[Dune, p. 8](<Books/Dune.pdf#page=8>)\n';

  test('each link to a place, at the section it belongs to', () {
    final links = annotationLinksIn(note);
    expect(
      [for (final l in links) l.target],
      ['Books/Dune.pdf', 'Other.pdf', 'Books/Dune.pdf'],
    );
    final first = links.first;
    expect(first.place, const PdfLocation(page: 3, chars: (start: 4, end: 9)));
    expect(first.markdown, isFalse);
    expect(first.title, 'Dune, p. 3');
    expect(note.substring(first.offset), startsWith('## Dune, p. 3'));
    // A link in the same section opens at the same heading.
    expect(links[1].offset, first.offset);
    final last = links.last;
    expect(last.markdown, isTrue);
    expect(last.place, const PdfLocation(page: 8));
    expect(note.substring(last.offset), startsWith('## Dune, p. 8'));
  });

  test('a link above every heading opens at its own line', () {
    final links = annotationLinksIn('Intro.\nSee [[a.pdf#page=2]].\n');
    expect(links.single.title, isNull);
    expect(links.single.offset, 'Intro.\n'.length);
  });

  test('a link to a heading, or to no place, is no mark', () {
    expect(annotationLinksIn('[[Note#Heading]] [x](a.md) [[a.pdf]]'), isEmpty);
  });
}
