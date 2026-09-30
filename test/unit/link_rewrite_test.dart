// #507: the links that pointed at a note or folder that moved are retargeted,
// one note's text at a time. The pure half: name vs path wikilinks, Markdown
// hrefs, a folder's subtree, the fragment and the alias carried through.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/rewrite.dart';

void main() {
  test('a renamed note follows in bare, path and Markdown links', () {
    const source =
        'See [[Old]], [[Old.md]], [[Docs/Old|the doc]], '
        '[[Docs/Old#Head]] and [x](Docs/Old.md).';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: {'Docs/Old.md': 'Docs/New.md'},
      renamedFrom: 'Old.md',
      renamedTo: 'New.md',
    );
    expect(
      out,
      'See [[New]], [[New.md]], [[Docs/New|the doc]], '
      '[[Docs/New#Head]] and [x](Docs/New.md).',
    );
  });

  test('a moved note keeps a bare link and follows a path', () {
    const source = '[[Note]], [[Docs/Note]], [x](Docs/Note.md)';
    final out = rewriteMovedLinks(
      source,
      from: 'Docs/Other.md',
      moves: {'Docs/Note.md': 'Other/Note.md'},
    );
    expect(out, '[[Note]], [[Other/Note]], [x](Other/Note.md)');
  });

  test('a renamed folder follows in every link into its subtree', () {
    const source =
        '[[Docs/Note]], [[Docs/Sub/Deep#H]], [x](Docs/pic.png), '
        '[[Elsewhere]], [[Note]]';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: {
        'Docs/Note.md': 'Books/Note.md',
        'Docs/Sub/Deep.md': 'Books/Sub/Deep.md',
        'Docs/pic.png': 'Books/pic.png',
      },
    );
    expect(
      out,
      '[[Books/Note]], [[Books/Sub/Deep#H]], [x](Books/pic.png), '
      '[[Elsewhere]], [[Note]]',
    );
  });

  test('a Markdown href keeps its fragment and re-encodes the path', () {
    final out = rewriteMovedLinks(
      '[place](Docs/My%20Book.pdf#page=34)',
      from: 'root.md',
      moves: {'Docs/My Book.pdf': 'Books/My Book.pdf'},
    );
    expect(out, '[place](Books/My%20Book.pdf#page=34)');
  });

  test('a target that did not move is left exactly as written', () {
    const source = '[[Elsewhere/Note]], [x](Elsewhere/pic.png), [[Note]]';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: {'Docs/Note.md': 'Other/Note.md'},
    );
    expect(identical(out, source), isTrue);
  });

  test('an external URL and a local anchor are not paths', () {
    const source = '[web](https://example.com/x.md), [[#Head]]';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: {'example.com/x.md': 'other/x.md'},
    );
    expect(identical(out, source), isTrue);
  });

  test('a Markdown href beside the linking note follows that note', () {
    // `Note.md` in a note at `Docs/` names `Docs/Note.md` (the resolver's
    // near path), which is the one that moved.
    final out = rewriteMovedLinks(
      '[x](Note.md)',
      from: 'Docs/Linker.md',
      moves: {'Docs/Note.md': 'Other/Note.md'},
    );
    expect(out, '[x](Other/Note.md)');
  });

  test('an embed follows a folder rename, its bang kept', () {
    const source =
        '![[Docs/pic.png]] and ![alt](Docs/pic.png) and [[Docs/pic.png]]';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: {'Docs/pic.png': 'Books/pic.png'},
    );
    expect(
      out,
      '![[Books/pic.png]] and ![alt](Books/pic.png) and [[Books/pic.png]]',
    );
  });

  test('an embed by name follows a renamed file, and keeps its heading', () {
    final out = rewriteMovedLinks(
      '![[Old]] and ![[Old#Head|big]]',
      from: 'root.md',
      moves: {'Old.md': 'New.md'},
      renamedFrom: 'Old.md',
      renamedTo: 'New.md',
    );
    expect(out, '![[New]] and ![[New#Head|big]]');
  });

  test('an embed that did not move is left exactly as written', () {
    const source = '![[Elsewhere/pic.png]] and ![alt](Elsewhere/pic.png)';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: {'Docs/pic.png': 'Books/pic.png'},
    );
    expect(identical(out, source), isTrue);
  });
}
