import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';

void main() {
  test('detects headings with level, line and text', () {
    final o = outlineOfText('# Title\n\nplain\n## Sub\nbody');
    expect(o, hasLength(2));
    expect(o[0].line, 0);
    expect(o[0].level, 1);
    expect(o[0].text, 'Title');
    expect(o[1].line, 3);
    expect(o[1].level, 2);
    expect(o[1].text, 'Sub');
  });

  test('a # line inside a code fence is not a heading', () {
    final o = outlineOfText('```\n# not a heading\n```\n# Real');
    expect(o, hasLength(1));
    expect(o[0].line, 3);
    expect(o[0].text, 'Real');
  });

  test('a # with no following space is not a heading', () {
    final o = outlineOfText('#tag\n# real');
    expect(o, hasLength(1));
    expect(o[0].line, 1);
    expect(o[0].text, 'real');
  });

  test('up to six hashes; seven is not a heading', () {
    final o = outlineOfText('###### six\n####### seven');
    expect(o, hasLength(1));
    expect(o[0].level, 6);
    expect(o[0].text, 'six');
  });

  test('no headings in plain text', () {
    expect(outlineOfText('just text\nmore text'), isEmpty);
  });

  group('what block context makes a heading (#1373)', () {
    // The outline is read off the block scan, the engine the editor, the read
    // view and the index read a note with, so block context decides what a `#`
    // is: each case is the list of `line|level|text` it has.
    String describe(List<OutlineEntry> o) =>
        o.map((e) => '${e.line}|${e.level}|${e.text}').join(',');

    void outline(String label, String text, String expected) {
      test(label, () {
        expect(describe(outlineOfText(text)), expected);
        // The editor's own outline, off the scan it already has.
        final buffer = SourceBuffer.fromText(text);
        expect(
          describe(outlineOfBlocks(BlockScanner(buffer).index, buffer.lineAt)),
          expected,
        );
      });
    }

    outline('plain headings', '# A\ntext\n## B\n### C\n', '0|1|A,2|2|B,3|3|C');
    outline('backtick fence', '```\n# no\n```\n# yes\n', '3|1|yes');
    outline('tilde fence', '~~~\n# no\n~~~\n# yes\n', '3|1|yes');
    outline('fence with info string', '```dart\n# no\n```\n# yes\n', '3|1|yes');
    outline('unterminated fence', '# yes\n```\n# no\n# still no\n', '0|1|yes');
    outline('display math block', '\$\$\n# no\n\$\$\n# yes\n', '3|1|yes');
    outline('single-line display math', '\$\$x = 1\$\$\n# yes\n', '1|1|yes');
    outline('unterminated math', '# yes\n\$\$\n# no\n', '0|1|yes');
    outline('frontmatter', '---\ntitle: x\n# no\n---\n# yes\n', '4|1|yes');
    outline('frontmatter closed by dots', '---\na: 1\n...\n# yes\n', '3|1|yes');
    outline('--- below the top is a rule', 'text\n---\n# yes\n', '2|1|yes');
    outline(
      'horizontal rules',
      '# yes\n***\n___\n----\n# also\n',
      '0|1|yes,4|1|also',
    );
    outline('seven hashes', '####### no\n###### yes\n', '1|6|yes');
    outline('hash with no space', '#tag\n# real\n', '1|1|real');
    outline('bare hash', '#\n##\n# x\n', '0|1|,1|2|,2|1|x');
    outline('indented hash', '    # indented\n# yes\n', '1|1|yes');
    outline('trailing whitespace heading', '#   spaced   \n', '0|1|spaced');
    outline('empty document', '', '');
    outline('only newlines', '\n\n\n', '');
    outline('no trailing newline', '# A\n# B', '0|1|A,1|1|B');
    outline('blockquoted hash', '> # quoted\n# yes\n', '1|1|yes');
    outline(
      'maths around the headings',
      '# A\n\$x\$ and \$y\$\n## B\n\$\$\na = b\n\$\$\n### C\n',
      '0|1|A,2|2|B,6|3|C',
    );

    // What the legacy tokenizer listed and the engine does not: a heading
    // inside an HTML block or comment is raw HTML, and one in indented code
    // is code — the index resolved `[[note#hidden]]` to the first and the
    // outline never listed it.
    outline(
      'an HTML block, which a blank line ends',
      '<div>\n# hidden\n</div>\n\n# shown\n',
      '4|1|shown',
    );
    outline('an HTML comment', '<!--\n# hidden\n-->\n# shown\n', '3|1|shown');
    outline(
      'a one-line comment is over on its line',
      '<!-- note -->\n# shown\n',
      '1|1|shown',
    );
    outline('indented code', 'text\n\n    # code\n\n# shown\n', '4|1|shown');
    outline(
      'a raw-text tag',
      '<pre>\n# hidden\n</pre>\n# shown\n',
      '3|1|shown',
    );
  });
}
