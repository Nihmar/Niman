// #507: the links that pointed at a note or folder that moved are retargeted,
// one note's text at a time. The pure half: name vs path wikilinks, Markdown
// hrefs, a folder's subtree, the fragment and the alias carried through.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/links/rewrite.dart';

void main() {
  test('a renamed note follows in bare, path and Markdown links', () {
    const source =
        'See [[Old]], [[Old.md]], [[Docs/Old|the doc]], '
        '[[Docs/Old#Head]] and [x](Docs/Old.md).';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: LinkMoves({'Docs/Old.md': 'Docs/New.md'}),
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
      moves: LinkMoves({'Docs/Note.md': 'Other/Note.md'}),
    );
    expect(out, '[[Note]], [[Other/Note]], [x](Other/Note.md)');
  });

  test('a link written between angle brackets follows, and keeps them', () {
    // CommonMark lets a destination with spaces stand between `<` and `>`;
    // the brackets were read as part of the path, and the link never
    // followed its note.
    final out = rewriteMovedLinks(
      '[x](<Docs/Old note.md>) and ![p](<Docs/Old note.md>)',
      from: 'root.md',
      moves: LinkMoves({'Docs/Old note.md': 'Docs/New note.md'}),
    );
    // Encoded, as the rewriter writes every Markdown path.
    expect(out, '[x](<Docs/New%20note.md>) and ![p](<Docs/New%20note.md>)');
  });

  test('a renamed folder follows in every link into its subtree', () {
    const source =
        '[[Docs/Note]], [[Docs/Sub/Deep#H]], [x](Docs/pic.png), '
        '[[Elsewhere]], [[Note]]';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: LinkMoves({
        'Docs/Note.md': 'Books/Note.md',
        'Docs/Sub/Deep.md': 'Books/Sub/Deep.md',
        'Docs/pic.png': 'Books/pic.png',
      }),
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
      moves: LinkMoves({'Docs/My Book.pdf': 'Books/My Book.pdf'}),
    );
    expect(out, '[place](Books/My%20Book.pdf#page=34)');
  });

  test('a target that did not move is left exactly as written', () {
    const source = '[[Elsewhere/Note]], [x](Elsewhere/pic.png), [[Note]]';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: LinkMoves({'Docs/Note.md': 'Other/Note.md'}),
    );
    expect(identical(out, source), isTrue);
  });

  test('an external URL and a local anchor are not paths', () {
    const source = '[web](https://example.com/x.md), [[#Head]]';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: LinkMoves({'example.com/x.md': 'other/x.md'}),
    );
    expect(identical(out, source), isTrue);
  });

  test(
    'a rewritten href encodes non-ASCII as UTF-8, like the app writes it',
    () {
      final out = rewriteMovedLinks(
        '[x](Docs/Citt%C3%A0.pdf)',
        from: 'root.md',
        moves: LinkMoves({'Docs/Città.pdf': 'Books/Città.pdf'}),
      );
      expect(out, '[x](Books/Citt%C3%A0.pdf)');
    },
  );

  test('a Markdown href beside the linking note stays relative to it', () {
    // `Note.md` in a note at `Docs/` names `Docs/Note.md` (the resolver's
    // near path), which is the one that moved: it is written back from the
    // note's folder, as it was written.
    final out = rewriteMovedLinks(
      '[x](Note.md)',
      from: 'Docs/Linker.md',
      moves: LinkMoves({'Docs/Note.md': 'Other/Note.md'}),
    );
    expect(out, '[x](../Other/Note.md)');
  });

  test('a walking href stays relative, a rooted one stays rooted', () {
    final out = rewriteMovedLinks(
      '![](../assets/pic.png) [a](./assets/b.md) [r](/assets/c.md)',
      from: 'Docs/Linker.md',
      moves: LinkMoves({
        'assets/pic.png': 'media/pic.png',
        'Docs/assets/b.md': 'Docs/media/b.md',
        'assets/c.md': 'media/c.md',
      }),
    );
    expect(out, '![](../media/pic.png) [a](./media/b.md) [r](/media/c.md)');
  });

  test('a tail the new path still ends with is left as written', () {
    // Written by the end of the path, found anywhere: the folder above it
    // changed, the tail did not, and the link finds the note as it did.
    const source = '[[sub/Note]] and [x](Note.md)';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: LinkMoves({
        'A/sub/Note.md': 'B/sub/Note.md',
        'Docs/Note.md': 'Other/Note.md',
      }),
    );
    expect(identical(out, source), isTrue);
  });

  test('a note that moved with its targets keeps its relative links', () {
    // Inside a renamed folder: resolved from where it stood, written from
    // where it stands, and a sibling is still a sibling.
    const source = '[x](Sibling.md), [y](./Sibling.md), [[Docs/Sibling]]';
    final out = rewriteMovedLinks(
      source,
      from: 'Docs/Linker.md',
      at: 'Books/Linker.md',
      moves: LinkMoves({
        'Docs/Sibling.md': 'Books/Sibling.md',
        'Docs/Linker.md': 'Books/Linker.md',
      }),
    );
    expect(out, '[x](Sibling.md), [y](./Sibling.md), [[Books/Sibling]]');
  });

  test('an embed follows a folder rename, its bang kept', () {
    const source =
        '![[Docs/pic.png]] and ![alt](Docs/pic.png) and [[Docs/pic.png]]';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: LinkMoves({'Docs/pic.png': 'Books/pic.png'}),
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
      moves: LinkMoves({'Old.md': 'New.md'}),
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
      moves: LinkMoves({'Docs/pic.png': 'Books/pic.png'}),
    );
    expect(identical(out, source), isTrue);
  });
}
