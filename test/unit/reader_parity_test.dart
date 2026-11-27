// One reading decides headings, links and tags everywhere (#1373): the outline,
// `parseLinks` (rename, move, export, tasks) and the index (`noteReferencesOf`)
// agree on what an HTML block, an HTML comment and indented code hold — nothing
// a note shows as a heading, a link or a tag.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/link_moves.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/rewrite.dart';
import 'package:niman/src/markdown/note_references.dart';

/// A line of each kind of block, its content a heading, a wikilink, a
/// Markdown link and a tag, then the same four in prose below it.
final Map<String, String> _hidden = {
  'an HTML block': '<div>\n# hidden\n[[Hidden]] [h](hidden.md) #hidden\n</div>',
  'an HTML comment': '<!--\n# hidden\n[[Hidden]] [h](hidden.md) #hidden\n-->',
  'a raw-text tag':
      '<pre>\n# hidden\n[[Hidden]] [h](hidden.md) #hidden\n</pre>',
  'indented code':
      'text\n\n    # hidden\n    [[Hidden]] [h](hidden.md) #hidden',
  'a fenced block': '```\n# hidden\n[[Hidden]] [h](hidden.md) #hidden\n```',
};

const String _shown = '\n\n# Shown\n[[Shown]] [s](shown.md) #shown\n';

List<String> _targets(List<ParsedLink> links) => [
  for (final link in links)
    switch (link) {
      WikiLink(:final ref) => ref.target,
      MarkdownLink(:final href) => href,
    },
];

void main() {
  for (final MapEntry(key: name, value: block) in _hidden.entries) {
    group(name, () {
      final text = '$block$_shown';

      test('has no heading in the outline, only the one below it', () {
        expect([for (final h in outlineOfText(text)) h.text], ['Shown']);
      });

      test('has no link for a rename to follow, only the ones below it', () {
        expect(_targets(parseLinks(text)), ['Shown', 'shown.md']);
      });

      test('has no link or tag for the index, only the ones below it', () {
        final refs = noteReferencesOf(text);
        expect(_targets(refs.links), ['Shown', 'shown.md']);
        expect(refs.tags, ['shown']);
      });

      test('the three agree on the links', () {
        expect(
          _targets(parseLinks(text)),
          _targets(noteReferencesOf(text).links),
        );
      });
    });
  }

  group('a rename', () {
    final moves = LinkMoves({'Old.md': 'New.md'});

    String rename(String text) => rewriteMovedLinks(
      text,
      from: 'root.md',
      moves: moves,
      renamedFrom: 'Old.md',
      renamedTo: 'New.md',
    );

    test('leaves a link in indented code alone', () {
      const text = 'See [[Old]].\n\n    [[Old]] and [x](Old.md)\n';
      expect(rename(text), 'See [[New]].\n\n    [[Old]] and [x](Old.md)\n');
    });

    test('leaves a link in an HTML comment and an HTML block alone', () {
      const comment = '<!--\n[[Old]]\n-->\n\n[[Old]]\n';
      expect(rename(comment), '<!--\n[[Old]]\n-->\n\n[[New]]\n');
      const block = '<div>\n[[Old]] [x](Old.md)\n</div>\n\n[x](Old.md)\n';
      expect(
        rename(block),
        '<div>\n[[Old]] [x](Old.md)\n</div>\n\n[x](New.md)\n',
      );
    });

    test('follows a link in a quote, an item and a table cell, in place', () {
      const text =
          '> a [[Old]]\n\n- b [x](Old.md)\n\n| h |\n|---|\n| [[Old]] |\n';
      expect(
        rename(text),
        '> a [[New]]\n\n- b [x](New.md)\n\n| h |\n|---|\n| [[New]] |\n',
      );
    });

    test('keeps the offsets exact in a CRLF note', () {
      const text = 'a\r\n\r\n> [[Old]]\r\n\r\n[x](Old.md)\r\n';
      expect(rename(text), 'a\r\n\r\n> [[New]]\r\n\r\n[x](New.md)\r\n');
    });
  });
}
