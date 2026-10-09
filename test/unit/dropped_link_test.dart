// #704: the link a file dropped on a note writes — the library's link
// format, the shortest wiki target, a Markdown href relative to the note,
// and an embed for what the read view draws in place.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/links/rewrite.dart' show hrefFrom;
import 'package:niman/src/ui/dropped_link.dart';

void main() {
  Future<String> target(String path) async => 'T:$path';

  Future<String> link(String path, LinkType type, {String note = 'n.md'}) =>
      droppedLink(path: path, note: note, linkType: type, wikiTarget: target);

  test(
    'a wikilink takes the shortest target, an embed for a picture',
    () async {
      expect(await link('a/b.md', LinkType.wikilink), '[[T:a/b.md]]');
      expect(await link('m/p.png', LinkType.wikilink), '![[T:m/p.png]]');
      expect(await link('m/memo.m4a', LinkType.wikilink), '![[T:m/memo.m4a]]');
      expect(await link('b/book.pdf', LinkType.wikilink), '[[T:b/book.pdf]]');
    },
  );

  test('a Markdown link is relative to the note and encoded', () async {
    expect(
      await link('Work/My note.md', LinkType.markdown, note: 'Journal/d.md'),
      '[My note](../Work/My%20note.md)',
    );
    expect(
      await link('Journal/x/p.png', LinkType.markdown, note: 'Journal/d.md'),
      '![p.png](x/p.png)',
    );
    expect(
      await link('Book.epub', LinkType.markdown, note: 'd.md'),
      '[Book.epub](Book.epub)',
    );
  });

  test('hrefFrom walks up to the folders the two share', () {
    expect(hrefFrom('a/b/c.md', note: 'a/d/e.md'), '../b/c.md');
    expect(hrefFrom('c.md', note: 'a/e.md'), '../c.md');
    expect(hrefFrom('a/c.md', note: 'e.md'), 'a/c.md');
  });
}
