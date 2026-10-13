// A note written with Windows line endings is the same note: its block ids and
// headings are found in the index rows, the `[[Note#^` panel's read of its
// file, and the library-wide `[[^^` search, as they are in the same note with
// `\n`.
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/anchor_index.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/library/note_ops.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:path/path.dart' as p;

void main() {
  const lf =
      '# Title\n\nA paragraph ^para-1\n\n- one ^item-1\n- two\n\n'
      '```\n# not a heading ^nor-an-id\n```\n\n> a quote\n\n^quote-1\n';
  final crlf = lf.replaceAll('\n', '\r\n');
  final cr = lf.replaceAll('\n', '\r');

  group('the text functions', () {
    test('the block anchors of CRLF text are those of LF text', () {
      final expected = blockAnchorsOfText(lf);
      expect(expected.map((a) => a.id), ['para-1', 'item-1', 'quote-1']);

      expect(blockAnchorsOfText(crlf), expected);
      expect(blockAnchorsOfText(cr), expected, reason: 'old Mac endings too');
    });

    test('a line that ends with the id before a CRLF is a trailing id', () {
      final anchors = blockAnchorsOfText('Intro ^id1\r\n\r\nNext ^id2\r\n');
      expect(anchors.map((a) => (a.id, a.line)), [('id1', 0), ('id2', 2)]);
      expect(anchors.first.excerpt, 'Intro');
    });

    test('the headings of CRLF text are those of LF text', () {
      final expected = [
        for (final h in outlineOfText(lf)) (h.line, h.level, h.text),
      ];
      expect(expected, [(0, 1, 'Title')]);
      expect([
        for (final h in outlineOfText(crlf)) (h.line, h.level, h.text),
      ], expected);
    });
  });

  group('a CRLF note in a library', () {
    late Directory root;
    late Directory data;
    late IndexDatabase db;

    setUp(() async {
      root = await Directory.current.createTemp('niman_crlf_');
      data = await Directory.current.createTemp('niman_crlf_db_');
      File(p.join(root.path, 'Win.md')).writeAsBytesSync(crlf.codeUnits);
      File(p.join(root.path, 'Unix.md')).writeAsStringSync(lf);
      db = IndexDatabase(NativeDatabase(File(p.join(data.path, 'i.sqlite'))));
      await Indexer(db).fullScan(root.path);
    });

    tearDown(() async {
      await db.close();
      await root.delete(recursive: true);
      await data.delete(recursive: true);
    });

    test("its index rows are its LF twin's", () async {
      Future<List<(String, int)>> blocks(String path) async {
        final rows = await db
            .customSelect(
              'SELECT b.block_id AS id, b.line AS line FROM note_blocks b '
              'JOIN notes n ON n.id = b.note_id WHERE n.path = ? '
              'ORDER BY b.line',
              variables: [Variable.withString(path)],
            )
            .get();
        return [
          for (final r in rows) (r.read<String>('id'), r.read<int>('line')),
        ];
      }

      Future<List<(int, String)>> headings(String path) async {
        final rows = await db
            .customSelect(
              'SELECT h.line AS line, h.heading AS heading '
              'FROM note_headings h '
              'JOIN notes n ON n.id = h.note_id WHERE n.path = ? '
              'ORDER BY h.line',
              variables: [Variable.withString(path)],
            )
            .get();
        return [
          for (final r in rows)
            (r.read<int>('line'), r.read<String>('heading')),
        ];
      }

      final unix = await blocks('Unix.md');
      expect(unix.map((b) => b.$1), ['para-1', 'item-1', 'quote-1']);
      expect(await blocks('Win.md'), unix);
      expect(await headings('Win.md'), await headings('Unix.md'));
    });

    test('the library-wide search finds its ids', () async {
      final hits = await AnchorIndex(db).blocks('para', limit: 10);
      expect(hits.map((h) => h.path).toSet(), {'Unix.md', 'Win.md'});
    });

    test("the panel's read of its file lists its ids", () async {
      final spy = IndexWikilinkSuggester(
        db,
        readHeadings: (_) async => const <String>[],
        readBlocks: (path) async => blocksOfNoteFile(p.join(root.path, path)),
      );

      final rows = await spy.blocks('Win');

      expect(rows.map((r) => r.id), ['para-1', 'item-1', 'quote-1']);
    });
  });
}
