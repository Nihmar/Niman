// A note's tags and links as the unified engine reads them — what the index
// keeps of a note besides its text (`docs/records/huge-notes.md`, item 8).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:path/path.dart' as p;

/// A link as the index keys it: its kind and what it points at.
String _key(ParsedLink link) => switch (link) {
  final WikiLink w => 'wiki ${w.ref.target}#${w.ref.heading}|${w.ref.alias}',
  final MarkdownLink m => 'md ${m.href}',
};

List<String> _links(String text) =>
    noteReferencesOf(text).links.map(_key).toList();

void main() {
  test('a link is placed on the note, whatever its line had taken off', () {
    // The parse reads a block without its quote marks and without a list
    // item's indent; an offset past the first line was short by every
    // prefix above it, and a rename rewrote the wrong characters.
    for (final text in <String>[
      '> first line\n> second [[Target]] here\n',
      '> > deep\n> > again [see](u) now\n',
      '- item\n  - nested\n    - deeper [[Target]]\n',
      '> quoted\r\n> on [[Target]]\r\n',
    ]) {
      for (final link in noteReferencesOf(text).links) {
        final written = text.substring(link.start, link.end);
        expect(
          written,
          anyOf('[[Target]]', '[see](u)'),
          reason: text.replaceAll('\n', r'\n'),
        );
      }
      expect(noteReferencesOf(text).links, isNotEmpty, reason: text);
    }
  });

  test('tags and wikilinks in prose, headings, lists, quotes and tables', () {
    final refs = noteReferencesOf(
      '# Title #Heading-Tag\n'
      '\n'
      'Prose with #tag and [[Note]] and [[Other|shown]].\n'
      '\n'
      '- an item [[Item#Part]] #list/tag\n'
      '\n'
      '> quoted [[Quoted]] #quote\n'
      '\n'
      '| a | b |\n'
      '|---|---|\n'
      '| [[Cell]] | #cell |\n',
    );
    expect(refs.tags, <String>[
      'heading-tag',
      'tag',
      'list/tag',
      'quote',
      'cell',
    ]);
    expect(refs.links.map(_key), <String>[
      'wiki Note#null|null',
      'wiki Other#null|shown',
      'wiki Item#Part|null',
      'wiki Quoted#null|null',
      'wiki Cell#null|null',
    ]);
  });

  test('nothing is read where the note shows no tag or link', () {
    final refs = noteReferencesOf(
      '---\n'
      'tags: [front]\n'
      'see: "[[Front]]"\n'
      '---\n'
      '\n'
      '```\n'
      '#code [[Fenced]] [x](fenced.md)\n'
      '```\n'
      '\n'
      r'$$'
      '\n'
      '#math [[Formula]]'
      '\n'
      r'$$'
      '\n'
      '\n'
      'inline `#span [[Span]]` and \$#x [[M]]\$ and ![[image.png]] a#b\n'
      '\n'
      '<!-- #comment [[Hidden]] -->\n'
      '\n'
      'after the comment [[Seen]] #seen\n',
    );
    expect(refs.tags, <String>['seen']);
    expect(refs.links.map(_key), <String>['wiki Seen#null|null']);
  });

  test('Markdown links: inline, by reference and in a footnote', () {
    expect(
      _links(
        'An [inline](a.md) link, a [reference][ref] and a note.[^1]\n'
        '\n'
        '[ref]: b.md\n'
        '\n'
        '[^1]: The note has [its own](c.md) link and [[Its Wiki]].\n',
      ),
      <String>['md a.md', 'md b.md', 'md c.md', 'wiki Its Wiki#null|null'],
      reason: 'a footnote reference is not a link; what its note says is',
    );
    expect(_links('![alt](image.png) and [[]] and [[|]] and [[#]]'), isEmpty);
  });

  test('every tag and link the legacy readers found in the fixtures', () {
    // The index read notes with the legacy tokenizer until this; on the
    // repo's own notes the unified engine finds the same tags and links —
    // and on the worst note, the reference links the tokenizer could not
    // resolve, which the note draws.
    final fixtures = Directory(p.join('test', 'fixtures'))
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.md'));
    expect(fixtures, isNotEmpty);
    for (final file in fixtures) {
      final text = file.readAsStringSync();
      final refs = noteReferencesOf(text);
      expect(refs.tags.toSet(), inlineTags(text).toSet(), reason: file.path);
      final now = refs.links.map(_key).toSet();
      final before = parseLinks(text).map(_key).toSet();
      expect(now, containsAll(before), reason: file.path);
      for (final extra in now.difference(before)) {
        expect(extra, startsWith('md '), reason: '${file.path}: $extra');
      }
    }
  });
}
