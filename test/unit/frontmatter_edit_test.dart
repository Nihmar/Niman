// T-M4-04/07: setting and clearing one frontmatter key without touching
// anything else in the file.
import 'package:copist/src/frontmatter/edit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('setFrontmatterKey', () {
    test('a note with no block gains one, body below', () {
      expect(
        setFrontmatterKey('Just a body.\n', 'pinned', 'true'),
        '---\npinned: true\n---\n\nJust a body.\n',
      );
    });

    test('an empty note gains a block and nothing else', () {
      expect(
        setFrontmatterKey('', 'pinned', 'true'),
        '---\npinned: true\n---\n\n',
      );
    });

    test('a new key is appended before the closing fence', () {
      expect(
        setFrontmatterKey('---\ntitle: T\n---\nbody', 'pinned', 'true'),
        '---\ntitle: T\npinned: true\n---\nbody',
      );
    });

    test('an existing key is replaced in place, order kept', () {
      expect(
        setFrontmatterKey(
          '---\ntitle: T\nstatus: draft\ntags: [a]\n---\nbody',
          'status',
          'done',
        ),
        '---\ntitle: T\nstatus: done\ntags: [a]\n---\nbody',
      );
    });

    test('nothing else in the block is reformatted', () {
      const source =
          '---\n# a comment\ntitle:    "spaced   out"\n'
          'tags:\n  - one\n  - two\n---\nbody';
      final out = setFrontmatterKey(source, 'pinned', 'true');
      expect(out.contains('# a comment'), isTrue);
      expect(out.contains('title:    "spaced   out"'), isTrue);
      expect(out.contains('tags:\n  - one\n  - two'), isTrue);
    });

    test('replacing a key takes its continuation lines with it', () {
      expect(
        setFrontmatterKey(
          '---\ntags:\n  - one\n  - two\nafter: x\n---\nbody',
          'tags',
          '[three]',
        ),
        '---\ntags: [three]\nafter: x\n---\nbody',
      );
    });

    test('a nested key of the same name is left alone', () {
      expect(
        setFrontmatterKey(
          '---\nauthor:\n  pinned: nonsense\n---\nbody',
          'pinned',
          'true',
        ),
        '---\nauthor:\n  pinned: nonsense\npinned: true\n---\nbody',
      );
    });

    test('a closing ... fence is respected', () {
      expect(
        setFrontmatterKey('---\ntitle: T\n...\nbody', 'pinned', 'true'),
        '---\ntitle: T\npinned: true\n...\nbody',
      );
    });

    test('a CRLF note keeps its CRLF endings', () {
      expect(
        setFrontmatterKey('---\r\ntitle: T\r\n---\r\nbody', 'pinned', 'true'),
        '---\r\ntitle: T\r\npinned: true\r\n---\r\nbody',
      );
      expect(
        setFrontmatterKey('body\r\n', 'pinned', 'true'),
        '---\r\npinned: true\r\n---\r\n\r\nbody\r\n',
      );
    });

    test('an unclosed block is not a block: a new one goes on top', () {
      expect(
        setFrontmatterKey('---\nnever closed', 'pinned', 'true'),
        '---\npinned: true\n---\n\n---\nnever closed',
      );
    });
  });

  group('removeFrontmatterKey', () {
    test('the key and its continuation lines go', () {
      expect(
        removeFrontmatterKey(
          '---\ntitle: T\ntags:\n  - one\nafter: x\n---\nbody',
          'tags',
        ),
        '---\ntitle: T\nafter: x\n---\nbody',
      );
    });

    test('a block left empty is removed, blank line included', () {
      expect(
        removeFrontmatterKey('---\npinned: true\n---\n\nbody\n', 'pinned'),
        'body\n',
      );
    });

    test('an absent key changes nothing at all', () {
      const source = '---\ntitle: T\n---\nbody';
      expect(removeFrontmatterKey(source, 'pinned'), source);
      expect(removeFrontmatterKey('no block', 'pinned'), 'no block');
    });

    test('set then remove is a round trip', () {
      const source = '---\ntitle: T\n---\nbody';
      final pinned = setFrontmatterKey(source, 'pinned', 'true');
      expect(pinned, isNot(source));
      expect(removeFrontmatterKey(pinned, 'pinned'), source);
    });
  });
}
