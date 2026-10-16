// "Links to this note" reads a referrer a slice at a time and stops at the
// first mention (#1040): a link on line 3 of a manuscript costs a slice, not
// the manuscript.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/links/link_spot_slices.dart';
import 'package:niman/src/links/mention_reader.dart';
import 'package:niman/src/links/mentions.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:path/path.dart' as p;

void main() {
  group('one slice of a note', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.current.createTemp('niman_slices_');
    });

    tearDown(() async {
      await dir.delete(recursive: true);
    });

    /// Every slice of [text] cut at [bytes], in order.
    List<SpotSlice> slicesOf(String name, String text, int bytes) {
      final path = p.join(dir.path, name);
      File(path).writeAsStringSync(text);
      final slices = <SpotSlice>[];
      SpotCursor? at = spotCursorStart;
      while (at != null) {
        final slice = linkSpotSliceOfFile(path, at, sliceBytes: bytes);
        slices.add(slice);
        at = slice.next;
      }
      return slices;
    }

    test('the slices together hold the links of the whole note', () {
      final text = [
        for (var i = 0; i < 60; i++) 'Paragraph $i with [[Link$i]] in it.\n',
      ].join('\n');

      final slices = slicesOf('a.md', text, 200);

      expect(slices.length, greaterThan(5));
      expect([for (final s in slices) ...s.spots], linkSpotsOf(text));
    });

    test('lines count from the start of the note, CRLF or not', () {
      const text = 'one\r\n\r\ntwo [[A]]\r\n\r\nthree\r\n\r\nfour [[B]]\r\n';

      final slices = slicesOf('crlf.md', text, 12);

      expect(slices.length, greaterThan(1));
      expect([for (final s in slices) ...s.spots], linkSpotsOf(text));
      expect([for (final s in slices) ...s.spots].map((s) => s.line), [2, 6]);
    });

    test('a slice is not cut inside a code fence', () {
      const text =
          'intro\n\n```\nfirst\n\n[[Hidden]]\n\nsecond\n```\n\n'
          'after [[Seen]]\n';

      final slices = slicesOf('fence.md', text, 20);

      expect([for (final s in slices) ...s.spots].map((s) => s.target), [
        'Seen',
      ], reason: 'a link inside a fence is no link, wherever the slice ends');
    });

    test('a block longer than a slice grows the slice, not cuts the link', () {
      final text = '${'word ' * 400}[[Far]]${' more' * 400}\n\nend [[Near]]\n';

      final slices = slicesOf('long.md', text, 100);

      expect([for (final s in slices) ...s.spots], linkSpotsOf(text));
    });

    test('a byte-order mark is dropped, once', () {
      final path = p.join(dir.path, 'bom.md');
      File(path)
          .writeAsBytesSync(<int>[0xEF, 0xBB, 0xBF, ...'[[A]]\n'.codeUnits]);

      final slice = linkSpotSliceOfFile(path, spotCursorStart);

      expect(slice.spots.single.context, '[[A]]');
    });
  });

  group('the mention in a big referrer', () {
    late Directory root;
    late Directory data;
    late IndexDatabase db;
    late Indexer indexer;
    late int bytesRead;
    late MentionReader reader;

    // A note of [megabytes] MB of filler paragraphs, with [lead] on its
    // third line and [late] after the ninth megabyte.
    void writeBig(
      String name, {
      required int megabytes,
      String lead = '',
      String late = '',
    }) {
      final out = File(p.join(root.path, name)).openSync(mode: FileMode.write);
      final paragraph = '${'lorem ipsum dolor sit amet ' * 3}\n' * 3;
      out.writeStringSync('# Manuscript\n\n$lead\n\n');
      var written = 0;
      var lateWritten = late.isEmpty;
      while (written < megabytes * 1024 * 1024) {
        out.writeStringSync('$paragraph\n');
        written += paragraph.length + 1;
        if (!lateWritten && written > 9 * 1024 * 1024) {
          out.writeStringSync('$late\n\n');
          lateWritten = true;
        }
      }
      out.closeSync();
    }

    setUp(() async {
      root = await Directory.current.createTemp('niman_big_');
      data = await Directory.current.createTemp('niman_big_db_');
      File(p.join(root.path, 'B.md')).writeAsStringSync('b\n');
      File(p.join(root.path, 'Early.md')).writeAsStringSync('See [[B]] now.\n');
      File(p.join(root.path, 'Late.md')).writeAsStringSync('Far [[B]] away.\n');
      db = IndexDatabase(NativeDatabase(File(p.join(data.path, 'i.sqlite'))));
      indexer = Indexer(db);
      await indexer.fullScan(root.path);
      bytesRead = 0;
      reader = MentionReader(
        db,
        LinkResolver(db),
        readSpots: (path, from) async {
          final file = p.join(root.path, path);
          final slice = linkSpotSliceOfFile(file, from);
          bytesRead +=
              (slice.next?.offset ?? File(file).lengthSync()) - from.offset;
          return slice;
        },
      );
    });

    tearDown(() async {
      await db.close();
      await root.delete(recursive: true);
      await data.delete(recursive: true);
    });

    test('a 30 MB note with the link on line 3 reads one slice', () async {
      writeBig('Early.md', megabytes: 30, lead: 'See [[B]] first.');

      final mention = await reader.mentionIn('Early.md', 'B.md');

      expect(mention.context, 'See [[B]] first.');
      expect(
        bytesRead,
        lessThan(1024 * 1024),
        reason: 'read $bytesRead bytes of a 30 MB note',
      );
    });

    test('a mention past the budget is "further down", not read', () async {
      writeBig('Late.md', megabytes: 12, late: 'Far [[B]] away.');

      final mention = await reader.mentionIn('Late.md', 'B.md');

      expect(mention.further, isTrue);
      expect(mention.context, isEmpty);
      expect(
        bytesRead,
        lessThan(MentionReader.byteBudget + spotSliceBytes + 1),
        reason: 'the budget bounds the read, not the length of the note',
      );
    });

    test('a note read to its end that names nothing is unread', () async {
      File(p.join(root.path, 'Late.md')).writeAsStringSync('nothing here\n');

      expect(await reader.mentionIn('Late.md', 'B.md'), same(Mention.unread));
    });
  });
}
