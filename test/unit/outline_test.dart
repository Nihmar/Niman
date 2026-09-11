import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';

void main() {
  test('detects headings with level, line and text', () {
    final doc = HighlightDocument.fromText('# Title\n\nplain\n## Sub\nbody');
    final o = outlineOf(doc.lines);
    expect(o, hasLength(2));
    expect(o[0].line, 0);
    expect(o[0].level, 1);
    expect(o[0].text, 'Title');
    expect(o[1].line, 3);
    expect(o[1].level, 2);
    expect(o[1].text, 'Sub');
  });

  test('a # line inside a code fence is not a heading', () {
    final doc = HighlightDocument.fromText('```\n# not a heading\n```\n# Real');
    final o = outlineOf(doc.lines);
    expect(o, hasLength(1));
    expect(o[0].line, 3);
    expect(o[0].text, 'Real');
  });

  test('a # with no following space is not a heading', () {
    final doc = HighlightDocument.fromText('#tag\n# real');
    final o = outlineOf(doc.lines);
    expect(o, hasLength(1));
    expect(o[0].line, 1);
    expect(o[0].text, 'real');
  });

  test('up to six hashes; seven is not a heading', () {
    final doc = HighlightDocument.fromText('###### six\n####### seven');
    final o = outlineOf(doc.lines);
    expect(o, hasLength(1));
    expect(o[0].level, 6);
    expect(o[0].text, 'six');
  });

  test('no headings in plain text', () {
    final doc = HighlightDocument.fromText('just text\nmore text');
    expect(outlineOf(doc.lines), isEmpty);
  });

  group('outlineOfText matches the tokenizer', () {
    // The outline is derived from the tokenizer precisely so that block
    // context decides what a `#` is. outlineOfText skips the inline scan
    // for speed, so the two must be pinned to the same answer or the fast
    // path quietly invents (or loses) headings.
    String describe(List<OutlineEntry> o) =>
        o.map((e) => '${e.line}|${e.level}|${e.text}').join('\n');

    void sameAsTokenizer(String label, String text) {
      test(label, () {
        expect(
          describe(outlineOfText(text)),
          describe(outlineOf(HighlightDocument.fromText(text).lines)),
          reason: 'fast outline drifted from the tokenizer on: $label',
        );
      });
    }

    sameAsTokenizer('plain headings', '# A\ntext\n## B\n### C\n');
    sameAsTokenizer('backtick fence', '```\n# no\n```\n# yes\n');
    sameAsTokenizer('tilde fence', '~~~\n# no\n~~~\n# yes\n');
    sameAsTokenizer('fence with info string', '```dart\n# no\n```\n# yes\n');
    sameAsTokenizer('unterminated fence', '# yes\n```\n# no\n# still no\n');
    sameAsTokenizer('display math block', '\$\$\n# no\n\$\$\n# yes\n');
    sameAsTokenizer('single-line display math', '\$\$x = 1\$\$\n# yes\n');
    sameAsTokenizer('unterminated math', '# yes\n\$\$\n# no\n');
    sameAsTokenizer('frontmatter', '---\ntitle: x\n# no\n---\n# yes\n');
    sameAsTokenizer('frontmatter closed by dots', '---\na: 1\n...\n# yes\n');
    sameAsTokenizer('--- below the top is a rule', 'text\n---\n# yes\n');
    sameAsTokenizer('horizontal rules', '# yes\n***\n___\n----\n# also\n');
    sameAsTokenizer('seven hashes', '####### no\n###### yes\n');
    sameAsTokenizer('hash with no space', '#tag\n# real\n');
    sameAsTokenizer('bare hash', '#\n##\n# x\n');
    sameAsTokenizer('indented hash', '    # indented\n# yes\n');
    sameAsTokenizer('trailing whitespace heading', '#   spaced   \n');
    sameAsTokenizer('empty document', '');
    sameAsTokenizer('only newlines', '\n\n\n');
    sameAsTokenizer('no trailing newline', '# A\n# B');
    sameAsTokenizer('blockquoted hash', '> # quoted\n# yes\n');
    sameAsTokenizer(
      'maths around the headings',
      '# A\n\$x\$ and \$y\$\n## B\n\$\$\na = b\n\$\$\n### C\n',
    );
  });
}
