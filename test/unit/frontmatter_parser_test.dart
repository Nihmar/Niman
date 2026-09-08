// T-M3-03: minimal frontmatter reader (title/tags/aliases) + inline tag
// extraction, both on the same rules as the editor tokenizer.
import 'package:copist/src/frontmatter/parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseFrontmatter', () {
    test('no frontmatter (and a --- that is not the first line)', () {
      expect(parseFrontmatter('just text'), isNull);
      expect(parseFrontmatter('---\nnot fm'), isNull); // unclosed
      expect(parseFrontmatter('a\n---\n---'), isNull); // not leading
    });

    test('title only', () {
      final fm = parseFrontmatter('---\ntitle: My Title\n---\nbody');
      expect(fm, isNotNull);
      expect(fm!.title, 'My Title');
      expect(fm.tags, isEmpty);
      expect(fm.aliases, isEmpty);
    });

    test(
      'keys are case-insensitive; unknown keys ignored; quotes stripped',
      () {
        final fm = parseFrontmatter(
          '---\nTitle: "Quoted"\ntags: [a, b]\nweight: 42\n---',
        );
        expect(fm!.title, 'Quoted');
        expect(fm.tags, ['a', 'b']);
      },
    );

    test('list and comma-separated tags, empty entries dropped', () {
      expect(
        parseFrontmatter('---\ntags: [Foo, #Bar]\n---')!.tags,
        ['foo', 'bar'],
      );
      expect(
        parseFrontmatter('---\ntags: a, , b\n---')!.tags,
        ['a', 'b'],
      );
      expect(parseFrontmatter('---\ntags: []\n---')!.tags, isEmpty);
      expect(parseFrontmatter('---\ntags:\n---')!.tags, isEmpty);
    });

    test('aliases are kept raw (order preserved, deduped)', () {
      final fm = parseFrontmatter('---\naliases: [One, two, One]\n---');
      expect(fm!.aliases, ['One', 'two']);
    });

    test('closes with ... as well', () {
      final fm = parseFrontmatter('---\ntitle: X\n...\nbody');
      expect(fm!.title, 'X');
    });

    test('a colons-in-value tag value keeps its colons', () {
      final fm = parseFrontmatter('---\ntags: [a:b, c]\n---');
      expect(fm!.tags, ['a:b', 'c']);
    });
  });

  group('inlineTags', () {
    test('finds #tags, normalizes them', () {
      expect(inlineTags('text #Hello world #World again'), ['hello', 'world']);
    });

    test('skips code fences, inline code, math and frontmatter', () {
      const withCode = '```\n#not\n```\n\n`#nope` and \$\$#nope\$\$\n#yes';
      expect(inlineTags(withCode), ['yes']);
      const withFm = '---\ntags: [fm]\n---\n#inline';
      expect(inlineTags(withFm), ['inline']);
    });

    test('a # at the line start counts, a hashtag inside a word does not', () {
      expect(inlineTags('#lead and #word'), ['lead', 'word']);
      expect(inlineTags('C#sharp'), isEmpty);
    });
  });

  group('normalizeTag', () {
    test('lowercases and strips the leading hash', () {
      expect(normalizeTag('#Inbox/Work'), 'inbox/work');
      expect(normalizeTag('Mixed'), 'mixed');
      expect(normalizeTag(' # x '), ' x');
    });
  });
}
