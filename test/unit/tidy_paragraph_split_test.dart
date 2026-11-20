// Tidying sets a paragraph's lines apart (`LintRule.splitParagraphLines`):
// text pasted with its paragraphs one per line, no blank line between
// them, comes back with each line a paragraph of its own. Only a soft line
// break is split — a hard break stays — and only a paragraph outside a
// quote and a list: a quote's lines stay together, code and every other
// block that is not a paragraph keep theirs. A line that would read as
// something else on its own stays where it was. Formatting twice changes
// nothing.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/markdown_format.dart';
import 'package:niman/src/lint/line_split.dart';
import 'package:niman/src/lint/lint_rule.dart';

/// Formats [source] by [rules], every rule by default, and asserts the
/// second pass changes nothing.
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

void main() {
  test("a paragraph's lines become paragraphs", () {
    // As reported: a story pasted with a paragraph on each line.
    expect(
      tidy(
        'It had been eight years since he’d last crossed this threshold.\n'
        'And now, at twenty-six, he returned as a professor.\n'
        'The castle stood in the distance like a patient ghost. Quiet.\n'
        'He didn’t feel ready.\n',
      ),
      'It had been eight years since he’d last crossed this threshold.\n'
      '\n'
      'And now, at twenty-six, he returned as a professor.\n'
      '\n'
      'The castle stood in the distance like a patient ghost. Quiet.\n'
      '\n'
      'He didn’t feel ready.\n',
    );
  });

  test('the rule is on unless a library turns it off', () {
    expect(LintRule.all, contains(LintRule.splitParagraphLines));
    final off = {...LintRule.all}..remove(LintRule.splitParagraphLines);
    // Off, the lines are joined, as they were before the rule.
    expect(tidy('one\ntwo\n', rules: off), 'one two\n');
  });

  test('paragraphs already apart are left alone', () {
    kept('one\n\ntwo\n');
  });

  test('a hard break keeps the line under it', () {
    expect(tidy('one  \ntwo\nthree\n'), 'one  \ntwo\n\nthree\n');
    kept('one\\\ntwo\n');
  });

  test("a quote's lines stay together", () {
    // Joined, as the join rule writes a quote.
    expect(tidy('> quoted\n> more\nlazy\n'), '> quoted more lazy\n');
    // Kept as written with the join off.
    final noJoin = {...LintRule.all}..remove(LintRule.joinParagraphLines);
    const quote = '> quoted\n> more\n';
    expect(tidy(quote, rules: noJoin), quote);
    // An annotation's link back stays on the line under its quote.
    kept(
      '> The spice must flow.\n'
      '> — [[Books/Dune.pdf#page=34|Dune, p. 34]]\n',
    );
  });

  test('code and the other blocks keep their lines', () {
    kept('```\nline one\nline two\n```\n');
    kept('    line one\n    line two\n');
    kept('\$\$\nx = 1\ny = 2\n\$\$\n');
    kept('<div>\nline one\nline two\n</div>\n');
    kept('| A | B |\n| --- | --- |\n| 1 | 2 |\n');
    kept('Title\nsecond line\n===========\n');
    // The paragraph before a fence is split, the fence is not.
    expect(
      tidy('one\ntwo\n```\ncode\nmore code\n```\n'),
      'one\n\ntwo\n\n```\ncode\nmore code\n```\n',
    );
  });

  test("a list item's lines are the list's", () {
    expect(tidy('one\ntwo\n\n- a\n  b\n'), 'one\n\ntwo\n\n- a b\n');
  });

  test('a line that would open a block on its own stays in place', () {
    // `2001.` goes on with the paragraph — an ordered list interrupts one
    // only from 1 — and after a blank line would open a list.
    expect(
      tidy('The year\n2001. A space odyssey\nThe end\n'),
      'The year\n2001. A space odyssey\n\nThe end\n',
    );
  });

  test("a footnote's lines split where they stay in the footnote", () {
    expect(
      tidy('[^1]: foot\n    more foot\n'),
      '[^1]: foot\n\n    more foot\n',
    );
    // A lazy line would leave the definition after a blank line.
    kept('[^1]: foot\nlazy\n');
  });

  test("a column's lines split inside the column", () {
    expect(
      tidy(':::: columns\n::: column\none\ntwo\n:::\n::::\n'),
      ':::: columns\n::: column\none\n\ntwo\n:::\n::::\n',
    );
  });

  test('a Windows line ending stays on the line it was on', () {
    expect(splitParagraphLines('one\r\ntwo\r\n'), 'one\r\n\r\ntwo\r\n');
  });
}
