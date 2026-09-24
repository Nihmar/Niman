// #227: tidying a note's Markdown. The wrapped list item is what this is
// for; everything else it touches is a line's whitespace. Fences,
// tables, math, frontmatter and HTML pass through untouched, prose is
// never reflowed, and formatting twice changes nothing.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/markdown_format.dart';

/// Formats [source], and asserts the second pass changes nothing.
String tidy(String source) {
  final once = formatMarkdown(source);
  expect(formatMarkdown(once), once, reason: 'formatting is idempotent');
  return once;
}

void main() {
  test('a wrapped list item is indented to its own text', () {
    expect(
      tidy(
        '1. the first item, which runs on\n'
        'and wraps without any indent\n'
        '2. the second\n',
      ),
      '1. the first item, which runs on\n'
      '   and wraps without any indent\n'
      '2. the second\n',
    );
  });

  test('a bullet wraps to its own column, nested ones kept', () {
    expect(
      tidy('- one that runs on\nand wraps\n  - nested\n'),
      '- one that runs on\n  and wraps\n  - nested\n',
    );
  });

  test('a paragraph is never reflowed', () {
    const note = 'A line.\nAnother line of the same paragraph.\n';
    expect(tidy(note), note);
  });

  test('headings get one space after their hashes', () {
    expect(tidy('##   Spaced\n'), '## Spaced\n');
    // `#Title` is a paragraph, not a heading: tidying does not change
    // what a line means.
    expect(tidy('#Title\n'), '#Title\n');
  });

  // A tag is not a heading, and tidying must never make it one: `#note`
  // written on its own line is a paragraph to Markdown, and stays the
  // text it was.
  test('a #tag is left exactly as it is', () {
    expect(tidy('#tagDiEsempio\n'), '#tagDiEsempio\n');
    expect(
      tidy('Some prose with #tagDiEsempio in it.\n'),
      'Some prose with #tagDiEsempio in it.\n',
    );
    expect(
      tidy('#primo #secondo\nand a wrapped line\n'),
      '#primo #secondo\nand a wrapped line\n',
    );
    // In a list item it is text like any other.
    expect(
      tidy('- a task #tagDiEsempio\n- another\n'),
      '- a task #tagDiEsempio\n- another\n',
    );
    // And a real heading is still tidied.
    expect(tidy('##  Heading #tagDiEsempio\n'), '## Heading #tagDiEsempio\n');
  });

  test('blank runs collapse, and the note ends with one newline', () {
    expect(tidy('# T\n\n\n\nSome prose.\n\n\n'), '# T\n\nSome prose.\n');
  });

  test('trailing spaces go; a hard break is left alone', () {
    expect(tidy('a line \n'), 'a line\n');
    // A hard break survives, written as exactly two spaces: the rule the
    // tidying states. (It was kept as written, three spaces and all, while
    // the WYSIWYG codec's blocks decided what the tidying touched.)
    expect(tidy('a break   \nnext\n'), 'a break  \nnext\n');
    // A trailing break on the last line of a block breaks nothing.
    expect(tidy('last  \n'), 'last\n');
  });

  test('a fence keeps every byte inside it', () {
    const note =
        '```dart\n'
        'void main() {\n'
        '  print("   spaced   ");\n'
        '}\n'
        '```\n';
    expect(tidy(note), note);
  });

  test('frontmatter, a table and math pass through', () {
    const note =
        '---\n'
        'title:   Something\n'
        '---\n'
        '\n'
        '| A | B |\n'
        '| --- | --- |\n'
        '| 1 | 2 |\n'
        '\n'
        r'$$'
        '\n'
        'x^2\n'
        r'$$'
        '\n';
    expect(tidy(note), note);
  });

  test('an empty note stays empty', () {
    expect(formatMarkdown(''), '');
    expect(formatMarkdown('\n\n'), '\n');
  });

  test('a task list keeps its ticks and its wrapped lines', () {
    expect(
      tidy('- [ ] a task that runs on\nand wraps\n- [x] done\n'),
      '- [ ] a task that runs on\n  and wraps\n- [x] done\n',
    );
  });
}
