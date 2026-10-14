// #912: a heading that ends with a block id (`## Title ^abc`) is the heading
// `Title`: the id names the block for a link, it is not what the heading says.
// Every path that reads the outline, and what is built on it, sees `Title`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/export/export_anchors.dart';
import 'package:niman/src/export/export_note.dart';
import 'package:niman/src/library/note_ops.dart' show headingsOfNoteFile;
import 'package:niman/src/links/anchor.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:path/path.dart' as p;

const String _note = '# Note\n\n## Title ^abc\n\nBody ^para\n\n## Other\n';

List<String> _texts(List<OutlineEntry> outline) => [
  for (final entry in outline) entry.text,
];

void main() {
  group('the outline entry of a heading with a block id', () {
    test('outlineOfText leaves the id out of the text', () {
      expect(_texts(outlineOfText(_note)), ['Note', 'Title', 'Other']);
    });

    test('outlineOf (the tokenizer) and outlineOfBlocks agree', () {
      final tokenized = outlineOf(HighlightDocument.fromText(_note).lines);
      final buffer = SourceBuffer.fromText(_note);
      final index = BlockIndex(
        blocks: BlockScanner(buffer).index.blocks,
        revision: buffer.revision,
      );
      final blocks = outlineOfBlocks(index, buffer.lineAt);
      expect(_texts(tokenized), ['Note', 'Title', 'Other']);
      expect(_texts(blocks), ['Note', 'Title', 'Other']);
    });

    test('a caret that is not a block id stays in the text', () {
      expect(_texts(outlineOfText('# a^b\n## 2 ^ 3\n## x ^y z\n')), [
        'a^b',
        '2 ^ 3',
        'x ^y z',
      ]);
    });

    test("the rule is the scanner's: the heading still anchors its id", () {
      expect(
        [for (final a in blockAnchorsOfText(_note)) (a.id, a.line)],
        [('abc', 2), ('para', 4)],
      );
    });
  });

  group('a link by the heading text', () {
    final outline = outlineOfText(_note);

    test('[[note#Title]] finds the heading that carries the id', () {
      expect(headingLineOf(outline, HeadingAnchor(['Title'])), 2);
    });

    test('the id is no part of the heading to name', () {
      expect(headingLineOf(outline, HeadingAnchor(['Title ^abc'])), isNull);
    });
  });

  group('the headings suggested', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('niman_head_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test("a note's headings are listed without their id", () {
      final file = File(p.join(dir.path, 'Note.md'))..writeAsStringSync(_note);
      expect(headingsOfNoteFile(file.path), ['Note', 'Title', 'Other']);
    });
  });

  group('the export', () {
    test('a link to the heading lands on the id of its text', () {
      expect(ExportAnchors.idOf(_note, HeadingAnchor(['Title'])), 'title');
    });

    test('the page gives the heading the id of its text', () async {
      final payload = await exportNote(
        text: '## Title ^abc\n\n## Title\n',
        title: 'T',
        path: 'Notes/T.md',
        root: '/lib',
        language: 'en',
        format: ExportFileFormat.html,
      );
      final page = String.fromCharCodes(payload.bytes);
      expect(page, contains('id="title"'));
      expect(page, contains('id="title-2"'));
      expect(page, isNot(contains('title-abc')));
    });
  });
}
