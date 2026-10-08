// Tidying joins a paragraph's lines (`LintRule.joinParagraphLines`): a
// paragraph wrapped by hand comes back on one line, the editor wrapping it
// on screen. Only a soft line break is joined — a hard break stays, and so
// does every block that is not a paragraph, as the engine's block tree
// reads it. Formatting twice changes nothing.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/markdown_format.dart';
import 'package:niman/src/lint/line_join.dart';
import 'package:niman/src/lint/lint_rule.dart';

/// Formats [source] by [rules], and asserts the second pass changes
/// nothing.
String tidy(String source, {Set<LintRule>? rules}) {
  final once = formatMarkdown(source, rules: rules);
  expect(
    formatMarkdown(once, rules: rules),
    once,
    reason: 'formatting is idempotent',
  );
  return once;
}

/// [note] comes back from the tidying exactly as it was written.
void kept(String note) => expect(tidy(note), note);

/// Every rule but this one.
final Set<LintRule> _off = {...LintRule.all}
  ..remove(LintRule.joinParagraphLines);

void main() {
  test("a paragraph's lines are joined, its links byte for byte", () {
    // As reported.
    expect(
      tidy(
        'La lista mette insieme lavori di programmazione, punti da decidere '
        'con il cliente\n'
        "(EasyFrontier) e attività che può fare solo l'utente (testi, "
        'configurazione, ALTER, build).\n'
        'Sotto ogni voce è classificata e ha la soluzione proposta, ricavata '
        'da codice e DOC\n'
        '([DOC/Incarichi/*](DOC/Incarichi/README.md), '
        '[DOC/CustomsCopilot/*](DOC/CustomsCopilot/README.md)). Le voci di '
        'programmazione sono divise in tre ondate.\n',
      ),
      'La lista mette insieme lavori di programmazione, punti da decidere '
      'con il cliente '
      "(EasyFrontier) e attività che può fare solo l'utente (testi, "
      'configurazione, ALTER, build). '
      'Sotto ogni voce è classificata e ha la soluzione proposta, ricavata '
      'da codice e DOC '
      '([DOC/Incarichi/*](DOC/Incarichi/README.md), '
      '[DOC/CustomsCopilot/*](DOC/CustomsCopilot/README.md)). Le voci di '
      'programmazione sono divise in tre ondate.\n',
    );
  });

  test('with the rule off, a paragraph keeps its lines', () {
    const note = 'one\ntwo\nthree\n\n> quoted\n> more\n';
    expect(tidy(note, rules: _off), note);
  });

  test('one space between the lines, whatever was around the break', () {
    expect(tidy('one \n   two\n\tthree\n'), 'one two three\n');
  });

  test('a hard break stays a break', () {
    expect(tidy('one  \ntwo\nthree\n'), 'one  \ntwo three\n');
    expect(tidy('one\\\ntwo\nthree\n'), 'one\\\ntwo three\n');
    // The break a joined line ends with is kept too.
    expect(tidy('one\ntwo  \nthree\n'), 'one two  \nthree\n');
    // An escaped backslash is no break.
    expect(tidy('one\\\\\ntwo\n'), 'one\\\\ two\n');
  });

  test('a fence, indented code, math and HTML keep their lines', () {
    kept('```\nline one\nline two\n```\n');
    kept('    line one\n    line two\n');
    kept('\$\$\nx = 1\ny = 2\n\$\$\n');
    kept('<div>\nline one\nline two\n</div>\n');
    // The paragraph before a fence is joined, the fence is not.
    expect(
      tidy('one\ntwo\n```\ncode\nmore code\n```\n'),
      'one two\n\n```\ncode\nmore code\n```\n',
    );
  });

  test('a table keeps its rows', () {
    kept('| A | B |\n| --- | --- |\n| 1 | 2 |\n| 3 | 4 |\n');
  });

  test('frontmatter keeps its lines', () {
    expect(
      tidy('---\ntitle: x\ntags: y\n---\n\none\ntwo\n'),
      '---\ntitle: x\ntags: y\n---\n\none two\n',
    );
  });

  test('a heading is never joined, setext ones included', () {
    kept('Title\nsecond line\n===========\n');
    kept('Title\n-----\n');
  });

  test('a line that starts a block is not pulled into the paragraph', () {
    expect(tidy('one\n# heading\n'), 'one\n\n# heading\n');
    expect(tidy('one\n- item\n'), 'one\n\n- item\n');
    expect(tidy('one\n> quote\n'), 'one\n\n> quote\n');
    expect(tidy('one\n***\n'), 'one\n\n***\n');
  });

  test('a link reference definition is not joined', () {
    expect(tidy('[a]: /one\ntext\nmore\n'), '[a]: /one\n\ntext more\n');
  });

  test("a quote's paragraph is joined, its marks going with the line", () {
    expect(tidy('> quoted\n> more\nlazy\n'), '> quoted more lazy\n');
    expect(tidy('> > deep\n> > deeper\n'), '> > deep deeper\n');
    // A callout's title stays its own line.
    expect(
      tidy('> [!note] Title\n> body\n> more\n'),
      '> [!note] Title\n> body more\n',
    );
    // Two paragraphs of a quote stay two.
    kept('> one\n>\n> two\n');
  });

  test("a footnote's paragraph is joined", () {
    expect(tidy('[^1]: foot\n    more foot\n'), '[^1]: foot more foot\n');
  });

  test("an item's lines are the other rule's to join", () {
    final itemsOff = {...LintRule.all}..remove(LintRule.joinWrappedItems);
    expect(
      tidy('one\ntwo\n\n- a\nb\n', rules: itemsOff),
      'one two\n\n- a\n  b\n',
    );
  });

  test('a Windows line ending stays on the line it was on', () {
    expect(
      joinWrappedLines(
        'one\r\ntwo\r\n\r\nthree\r\n',
        inItems: true,
        outside: true,
      ),
      'one two\r\n\r\nthree\r\n',
    );
  });
}
