// How a conversion's plan finds its way about a book (#1138): which note
// holds a line, whether a line opens a file, where a file with no text
// opens. Asked once per link and per contents entry, so each answer must
// not walk the whole book - and must still be the answer the plain walk
// gave.
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_book.dart';
import 'package:niman/src/epub/epub_book_text.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:path/path.dart' as p;

import '../fakes/epub_builder.dart';

const EpubConvertWords _words = (
  chapter: 'Chapter {n}',
  opening: 'Opening',
  contents: 'Contents',
);

/// What `noteAt` was before it was bisected: a walk of every note.
EpubPlannedNote? _walked(int line, List<EpubPlannedNote> written) {
  if (written.isEmpty) return null;
  var found = written.first;
  for (final note in written) {
    if (note.start > line) break;
    found = note;
  }
  if (line < found.end || identical(found, written.last)) return found;
  return written.firstWhere(
    (note) => note.start >= line,
    orElse: () => written.last,
  );
}

/// A list that counts the notes it is asked for.
final class _CountingList extends ListBase<EpubPlannedNote> {
  new(this._notes);

  final List<EpubPlannedNote> _notes;
  int reads = 0;

  @override
  int get length => _notes.length;

  @override
  set length(int value) => throw UnsupportedError('fixed');

  @override
  EpubPlannedNote operator [](int index) {
    reads++;
    return _notes[index];
  }

  @override
  void operator []=(int index, EpubPlannedNote value) =>
      throw UnsupportedError('fixed');

  @override
  Iterator<EpubPlannedNote> get iterator {
    return _notes.map((note) {
      reads++;
      return note;
    }).iterator;
  }
}

void main() {
  late Directory tmp;
  late EpubPlan plan;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('niman_epub_plan_');
    final source = writeTestEpub(
      p.join(tmp.path, 'two.epub'),
      chapters: [
        (path: 'a.xhtml', body: '<h1>A</h1><p>One.</p>'),
        (path: 'b.xhtml', body: '<h1>B</h1><p>Two.</p>'),
      ],
    );
    final input = InputFileStream(source.path);
    plan = EpubPlan.of(
      parseEpub(EpubArchive.open(input)),
      title: 'Two',
      words: _words,
    );
    input.closeSync();
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  group('noteAt', () {
    test('answers as the walk of every note did, gaps included', () {
      final random = Random(1138);
      for (var round = 0; round < 200; round++) {
        // Notes of ascending lines, some of them not written (a gap).
        final written = <EpubPlannedNote>[];
        var line = random.nextInt(3);
        for (var i = 0; i < random.nextInt(12); i++) {
          final end = line + 1 + random.nextInt(5);
          written.add((path: 'n$i.md', title: 'n$i', start: line, end: end));
          line = end + random.nextInt(4);
        }
        for (var ask = -2; ask < line + 3; ask++) {
          expect(
            plan.noteAt(ask, written),
            _walked(ask, written),
            reason: 'line $ask among $written',
          );
        }
      }
    });

    test('reads a few notes of thousands, not each of them', () {
      final notes = [
        for (var i = 0; i < 5000; i++)
          (path: 'n$i.md', title: 'n$i', start: i * 10, end: i * 10 + 8),
      ];
      final counting = _CountingList(notes);
      for (final line in [0, 7, 8, 9, 24000, 49990, 49999, 60000]) {
        counting.reads = 0;
        expect(plan.noteAt(line, counting), _walked(line, notes));
        expect(counting.reads, lessThan(64), reason: 'line $line');
      }
    });
  });

  group('the book text', () {
    // Four files: the first and the third have text, the second and the
    // last have none.
    EpubBookText text() => EpubBookText(
      ['a', 'a2', '', '---', '', 'c', 'c2'],
      {'a.xhtml': 0, 'c.xhtml': 5},
      {
        'a.xhtml': {'x': 1},
        'c.xhtml': {'y': 6},
      },
      ['a.xhtml', 'b.xhtml', 'c.xhtml', 'd.xhtml'],
    );

    test('a file with no text opens where the next with some does', () {
      expect(text().lineOf('b.xhtml', ''), 5);
      expect(text().lineOf('b.xhtml', 'whatever'), 5);
      expect(text().lineOf('d.xhtml', ''), isNull, reason: 'nothing after it');
      expect(text().lineOf('gone.xhtml', ''), isNull);
    });

    test('a file with text opens at its own line, or at its anchor', () {
      expect(text().lineOf('a.xhtml', ''), 0);
      expect(text().lineOf('c.xhtml', 'y'), 6);
      expect(text().lineOf('c.xhtml', 'missing'), 5);
    });

    test('says which lines open a file', () {
      final book = text();
      expect(
        [for (var i = 0; i < 7; i++) book.opensFile(i)],
        [true, false, false, false, false, true, false],
      );
    });
  });
}
