// T-M4-01: the frontmatter block parsed as real YAML — every key kept,
// the known fields read out, malformed blocks reported rather than thrown.
// Inline tag extraction rides along on the editor tokenizer's rules.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/frontmatter/parser.dart';

void main() {
  group('block detection', () {
    test('no frontmatter (and a --- that is not the first line)', () {
      expect(parseFrontmatter('just text'), isNull);
      expect(parseFrontmatter('---\nnot fm'), isNull); // unclosed
      expect(parseFrontmatter('a\n---\n---'), isNull); // not leading
    });

    test('closes with ... as well', () {
      expect(parseFrontmatter('---\ntitle: X\n...\nbody')!.title, 'X');
    });

    test('an empty block parses to nothing, not to an error', () {
      final fm = parseFrontmatter('---\n---\nbody');
      expect(fm, isNotNull);
      expect(fm!.error, isNull);
      expect(fm.fields, isEmpty);
      expect(fm.title, isNull);
    });

    test('the block reports the lines it occupies', () {
      final block = frontmatterBlock('---\ntitle: X\n---\nbody');
      expect(block!.text, 'title: X');
      expect(block.startLine, 0);
      expect(block.endLine, 2);
      expect(frontmatterBlock('no block here'), isNull);
    });
  });

  group('known fields', () {
    test('title, case-insensitive key, quotes handled by YAML', () {
      final fm = parseFrontmatter('---\nTitle: "Quoted"\n---');
      expect(fm!.title, 'Quoted');
      expect(fm.tags, isEmpty);
      expect(fm.aliases, isEmpty);
      expect(fm.error, isNull);
    });

    test('tags: flow list, block list, and a comma-separated scalar', () {
      expect(parseFrontmatter('---\ntags: [Foo, Bar]\n---')!.tags, [
        'foo',
        'bar',
      ]);
      expect(parseFrontmatter('---\ntags:\n  - one\n  - Two\n---')!.tags, [
        'one',
        'two',
      ]);
      expect(parseFrontmatter('---\ntags: a, , b\n---')!.tags, ['a', 'b']);
      expect(parseFrontmatter('---\ntags: []\n---')!.tags, isEmpty);
      expect(parseFrontmatter('---\ntags:\n---')!.tags, isEmpty);
    });

    test('a quoted #tag keeps working; a bare one is a YAML comment', () {
      expect(parseFrontmatter('---\ntags: [Foo, "#Bar"]\n---')!.tags, [
        'foo',
        'bar',
      ]);
      // `, #Bar]` is a comment to every YAML parser, which leaves the flow
      // sequence unterminated. Reported, not silently half-read.
      expect(parseFrontmatter('---\ntags: [Foo, #Bar]\n---')!.error, isNotNull);
    });

    test('aliases keep their case, order and uniqueness', () {
      final fm = parseFrontmatter('---\naliases: [One, two, One]\n---');
      expect(fm!.aliases, ['One', 'two']);
    });

    test('date reads a YAML timestamp and an ISO string', () {
      expect(
        parseFrontmatter('---\ndate: 2026-03-01\n---')!.date,
        DateTime(2026, 3),
      );
      expect(
        parseFrontmatter("---\ndate: '2026-03-01'\n---")!.date,
        DateTime(2026, 3),
      );
      expect(parseFrontmatter('---\ndate: someday\n---')!.date, isNull);
      expect(parseFrontmatter('---\ntitle: X\n---')!.date, isNull);
    });

    test('pinned reads a YAML bool and the yes/on spellings', () {
      expect(parseFrontmatter('---\npinned: true\n---')!.pinned, isTrue);
      expect(parseFrontmatter('---\npinned: yes\n---')!.pinned, isTrue);
      expect(parseFrontmatter('---\npinned: false\n---')!.pinned, isFalse);
      expect(parseFrontmatter('---\ntitle: X\n---')!.pinned, isFalse);
    });

    test('type names the note kind', () {
      expect(parseFrontmatter('---\ntype: list\n---')!.type, 'list');
      expect(parseFrontmatter('---\ntype:\n---')!.type, isNull);
    });
  });

  group('arbitrary keys', () {
    test('every key is kept, with its values as text', () {
      final fm = parseFrontmatter(
        '---\ntitle: X\nstatus: draft\nweight: 42\nratio: 0.5\n---',
      );
      expect(fm!.fields['status'], ['draft']);
      expect(fm.fields['weight'], ['42']);
      expect(fm.fields['ratio'], ['0.5']);
      expect(fm.first('Status'), 'draft');
      expect(fm.first('missing'), isNull);
    });

    test('a nested map flattens onto dotted keys', () {
      final fm = parseFrontmatter(
        '---\nauthor:\n  name: Ale\n  city: Padova\n---',
      );
      expect(fm!.fields['author.name'], ['Ale']);
      expect(fm.fields['author.city'], ['Padova']);
    });

    test('a list key keeps one value per item', () {
      final fm = parseFrontmatter('---\nprojects: [alpha, beta]\n---');
      expect(fm!.fields['projects'], ['alpha', 'beta']);
    });

    test('a date value is stored back in the form it was written', () {
      final fm = parseFrontmatter('---\ndate: 2026-03-01\nseen: someday\n---');
      expect(fm!.fields['date'], ['2026-03-01']);
      expect(fm.fields['seen'], ['someday']);
    });

    test('an empty value contributes no field at all', () {
      final fm = parseFrontmatter('---\ntitle: X\nempty:\n---');
      expect(fm!.fields.containsKey('empty'), isFalse);
    });
  });

  group('malformed blocks', () {
    test('broken YAML yields an error and no fields, never a throw', () {
      final fm = parseFrontmatter('---\ntitle: [unclosed\n---\nbody');
      expect(fm, isNotNull);
      expect(fm!.error, isNotNull);
      expect(fm.fields, isEmpty);
      expect(fm.title, isNull);
    });

    test('a block that is not a mapping is malformed', () {
      final fm = parseFrontmatter('---\n- just\n- a list\n---');
      expect(fm!.error, isNotNull);
    });

    test('a duplicate key is an error, as YAML says', () {
      expect(parseFrontmatter('---\na: 1\na: 2\n---')!.error, isNotNull);
    });
  });

  group('frontmatterTypeOf', () {
    test('reads the kind without parsing the block', () {
      expect(frontmatterTypeOf('---\ntype: list\n---\nbody'), 'list');
      expect(frontmatterTypeOf('---\ntitle: X\ntype: "list"\n---'), 'list');
      expect(frontmatterTypeOf('---\ntitle: X\n---'), isNull);
      expect(frontmatterTypeOf('---\ntype: list\nno close'), isNull);
      expect(frontmatterTypeOf('plain note'), isNull);
    });

    test('it answers even for a block the YAML parser rejects', () {
      // The note-kind path runs on every note open and must not depend on
      // the rest of the block being well-formed.
      expect(frontmatterTypeOf('---\ntype: list\nbad: [\n---'), 'list');
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
