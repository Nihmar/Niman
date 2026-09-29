// T-M4-04/07: setting and clearing one frontmatter key without touching
// anything else in the file.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/frontmatter/edit.dart';

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

    // The lines an entry covers are the YAML parser's answer: a guess from
    // indentation never found a quoted key (the field panel added a second
    // `due date:`, and the block stopped parsing) and left the rest of a
    // value behind when a blank line or a line at column 0 was part of it.
    test('a quoted key is found, and keeps its quotes', () {
      expect(
        setFrontmatterKey(
          '---\n"due date": 2026-01-01\nb: 1\n---\nbody',
          'due date',
          'later',
        ),
        '---\n"due date": later\nb: 1\n---\nbody',
      );
      expect(
        removeFrontmatterKey("---\n'due date': x\nb: 1\n---\nbody", 'due date'),
        '---\nb: 1\n---\nbody',
      );
    });

    test('every line of a value goes with it', () {
      // A literal block with a blank line inside.
      expect(
        setFrontmatterKey(
          '---\ndesc: |\n  one\n\n  two\nnext: x\n---\nbody',
          'desc',
          '"new"',
        ),
        '---\ndesc: "new"\nnext: x\n---\nbody',
      );
      // A quoted value that goes on at column 0.
      expect(
        setFrontmatterKey(
          '---\nt: "line one\nline two"\nnext: 1\n---\nbody',
          't',
          'x',
        ),
        '---\nt: x\nnext: 1\n---\nbody',
      );
    });

    test('a new key YAML would misread is quoted', () {
      final out = setFrontmatterKey(
        '---\ntitle: T\n---\nbody',
        'due: date',
        'x',
      );
      expect(out, '---\ntitle: T\n"due: date": x\n---\nbody');
      expect(
        setFrontmatterKey(out, 'due: date', 'y'),
        '---\ntitle: T\n"due: date": y\n---\nbody',
        reason: 'and found again under the quotes it was given',
      );
    });

    test('a block YAML refuses is still edited by its lines', () {
      expect(
        setFrontmatterKey(
          '---\ntitle: [unclosed\npinned: false\n---\nbody',
          'pinned',
          'true',
        ),
        '---\ntitle: [unclosed\npinned: true\n---\nbody',
      );
    });

    test('an unclosed block is not a block: a new one goes on top', () {
      expect(
        setFrontmatterKey('---\nnever closed', 'pinned', 'true'),
        '---\npinned: true\n---\n\n---\nnever closed',
      );
    });

    // #497: an edit writes the entry back as it found it — the indentation
    // it was written with, the `&anchor` a `*alias` points at, and the
    // comment after the value — and a key it adds joins its siblings at
    // their indentation.
    test('an indented entry keeps its indentation', () {
      expect(
        setFrontmatterKey(
          '---\n  title: A\n  tags: [x]\n---\nbody',
          'title',
          'B',
        ),
        '---\n  title: B\n  tags: [x]\n---\nbody',
      );
    });

    test("an inserted key takes its siblings' indentation", () {
      expect(
        setFrontmatterKey(
          '---\n  title: A\n  tags: [x]\n---\nbody',
          'pinned',
          'true',
        ),
        '---\n  title: A\n  tags: [x]\n  pinned: true\n---\nbody',
      );
    });

    test('an anchored entry keeps its anchor, so its alias survives', () {
      expect(
        setFrontmatterKey(
          '---\ntags: &t [a, b]\nalias: *t\n---\nbody',
          'tags',
          '[a]',
        ),
        '---\ntags: &t [a]\nalias: *t\n---\nbody',
      );
    });

    test('a trailing comment survives an edit', () {
      expect(
        setFrontmatterKey('---\ntitle: A # keep\n---\nbody', 'title', 'B'),
        '---\ntitle: B # keep\n---\nbody',
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
