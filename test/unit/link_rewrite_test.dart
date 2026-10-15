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

  test('a heading path and a block id ride along with a moved target', () {
    // #844 / #845: the target is rewritten, the whole fragment is kept — the
    // levels of a path (`#H1#H2`) and a block id (`#^id`) alike, with the
    // alias — and a same-note fragment is not a target at all.
    const source =
        '[[Docs/Old#H1#H2]], [[Docs/Old#^37066d|the idea]], '
        '![[Docs/Old#H1#H2]], [[#H1#H2]], [[#^37066d]], [[Old#^a-b]]';
    final out = rewriteMovedLinks(
      source,
      from: 'root.md',
      moves: LinkMoves({'Docs/Old.md': 'Docs/New.md'}),
      renamedFrom: 'Old.md',
      renamedTo: 'New.md',
    );
    expect(
      out,
      '[[Docs/New#H1#H2]], [[Docs/New#^37066d|the idea]], '
      '![[Docs/New#H1#H2]], [[#H1#H2]], [[#^37066d]], [[New#^a-b]]',
    );
  });

  test('a Markdown link with a title follows its note and keeps the title '
      '(#917)', () {
    final moves = LinkMoves({'docs/a.md': 'docs/b.md'});
    for (final title in ['"A title"', "'A title'", '(A title)']) {
      final out = rewriteMovedLinks(
        '[x](docs/a.md $title) and ![p](docs/a.md $title) and '
        '[y](<docs/a.md> $title)',
        from: 'n.md',
        moves: moves,
      );
      expect(
        out,
        '[x](docs/b.md $title) and ![p](docs/b.md $title) and '
        '[y](<docs/b.md> $title)',
        reason: title,
      );
    }
  });

  test('a titled link and an untitled one move together (#917)', () {
    final out = rewriteMovedLinks(
      '[x](docs/a.md "Title") [y](docs/a.md)',
      from: 'n.md',
      moves: LinkMoves({'docs/a.md': 'docs/b.md'}),
    );
    expect(out, '[x](docs/b.md "Title") [y](docs/b.md)');
  });

  test(r'a renamed note follows in a table row and keeps the \| (#920)', () {
    final out = rewriteMovedLinks(
      r'| [[Old\|the doc]] | [[Docs/Old#H\|x]] | [[Old|plain]] |',
      from: 'root.md',
      moves: LinkMoves({'Docs/Old.md': 'Docs/New.md'}),
      renamedFrom: 'Old.md',
      renamedTo: 'New.md',
    );
    expect(out, r'| [[New\|the doc]] | [[Docs/New#H\|x]] | [[New|plain]] |');
  });

  test('a link known to name one moved file is not carried to another of '
      'the same name (#919)', () {
    final moves = LinkMoves({'a/b.md': 'a/c.md', 'z/b.md': 'z/c.md'});
    expect(moves.find('b')?.path, 'a/c.md', reason: 'by name, the first');
    expect(moves.find('b', only: 'z/b.md')?.path, 'z/c.md');
    expect(moves.find('z/b', only: 'Z/B.md')?.path, 'z/c.md');
    expect(moves.find('z/b', only: 'a/b.md'), isNull);
    expect(moves.find('a/b.md', tail: false, only: 'z/b.md'), isNull);
  });

  test('a link is asked about only when it ends with a moved name (#919)', () {
    final moves = LinkMoves({'Docs/Old note.md': 'Docs/New.md'});
    expect(moves.mayName('Old note', markdown: false), isTrue);
    expect(moves.mayName('Docs/Old note.md', markdown: false), isTrue);
    expect(moves.mayName('Docs/Old%20note.md#H', markdown: true), isTrue);
    expect(moves.mayName(r'..\Old note.md', markdown: true), isTrue);
    expect(moves.mayName('Elsewhere', markdown: false), isFalse);
    expect(moves.mayName('Old note/Other.md', markdown: true), isFalse);
    expect(moves.mayName('no-extension', markdown: true), isFalse);
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

  group('link reference definitions (#972)', () {
    final moves = LinkMoves({'Docs/a.md': 'Archive/a.md'});

    String rewrite(String source) =>
        rewriteMovedLinks(source, from: 'root.md', moves: moves);

    test('the destination follows, the label and the title stay', () {
      expect(
        rewrite('see [x][r]\n\n[r]: Docs/a.md "The title"\n'),
        'see [x][r]\n\n[r]: Archive/a.md "The title"\n',
      );
    });

    test('an angled destination keeps its brackets, a fragment rides', () {
      expect(
        rewrite(
          '[x][r] [y][s]\n\n[r]: <Docs/a.md#Part>\n[s]: Docs/a.md#Other\n',
        ),
        '[x][r] [y][s]\n\n[r]: <Archive/a.md#Part>\n[s]: Archive/a.md#Other\n',
      );
    });

    test('a destination on the line after its label follows', () {
      expect(
        rewrite('[x][r]\n\n[r]:\n    Docs/a.md\n'),
        '[x][r]\n\n[r]:\n    Archive/a.md\n',
      );
    });

    test('it follows with the inline links of the note, in order', () {
      expect(
        rewrite('[i](Docs/a.md) [x][r]\n\n[r]: Docs/a.md\n\n[j](Docs/a.md)\n'),
        '[i](Archive/a.md) [x][r]\n\n[r]: Archive/a.md\n\n[j](Archive/a.md)\n',
      );
    });

    test('a path beside the linking note stays relative to it', () {
      final out = rewriteMovedLinks(
        '[x][r]\n\n[r]: a.md\n',
        from: 'Docs/note.md',
        moves: moves,
      );
      expect(out, '[x][r]\n\n[r]: ../Archive/a.md\n');
    });

    test('another file, a URL, a fence and a quote are left as written', () {
      const source =
          '[a][r] [b][s]\n\n[r]: Elsewhere/a.md\n[s]: https://x.y/Docs/a.md\n\n'
          '```\n[t]: Docs/a.md\n```\n\n> [q]: Docs/a.md\n';
      expect(identical(rewrite(source), source), isTrue);
    });
  });
}
