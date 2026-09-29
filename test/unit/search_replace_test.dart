// T-M3-10: the exact whole-word replace runner over a real index + disk.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/indexer.dart';
import 'package:niman/src/history/history_manifest.dart';
import 'package:niman/src/history/history_store.dart';
import 'package:niman/src/history/snapshot_policy.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:niman/src/search/replace.dart';
import 'package:path/path.dart' as p;

/// [text] as a UTF-16LE note, BOM included: a file the editor refuses as
/// binary (`looksBinary`), which the index keeps as a `.md` all the same.
List<int> _utf16le(String text) => <int>[
  0xFF,
  0xFE,
  for (final unit in text.codeUnits) ...<int>[unit & 0xFF, unit >> 8],
];

void main() {
  late Directory root;
  late IndexDatabase db;
  late ReplaceRunner replace;

  File file(String rel) => File(p.join(root.path, rel));

  Future<String> read(String rel) => file(rel).readAsString();

  setUp(() async {
    root = await Directory.current.createTemp('niman_replace_');
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    // The corpus: word-boundary traps and a multi-word phrase.
    await file('a.md')
        .writeAsString('cat catalog concatenate cats. Cat CAT.\n');
    await file('b.md')
        .writeAsString('dog hello world, hello\nworld — città cittàx.\n');
    await file('c.md').writeAsString('nothing here\n');
    await Directory(p.join(root.path, 'sub')).create();
    await file('sub/x.md').writeAsString('deep cat\n');
    await Indexer(db).fullScan(root.path);
    replace = ReplaceRunner(db, root.path);
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  group('replaceWholeWords', () {
    test('matches whole words only, case-insensitively by default', () {
      const text = 'cat catalog Cat, cats concatenate (cat) cat!';
      final (count, out) = replaceWholeWords(
        text,
        'cat',
        'dog',
        caseSensitive: false,
      );
      expect(count, 4); // cat, Cat, (cat), cat!
      expect(out, 'dog catalog dog, cats concatenate (dog) dog!');
    });

    test('case-sensitive flag narrows the matches', () {
      const text = 'cat Cat CAT';
      final (count, out) = replaceWholeWords(
        text,
        'Cat',
        'dog',
        caseSensitive: true,
      );
      expect(count, 1);
      expect(out, 'cat dog CAT');
    });

    test('a multi-word term matches across any whitespace', () {
      const text = 'a hello world b\nhello  world c hello\nworld d';
      final (count, out) = replaceWholeWords(
        text,
        'hello world',
        'bye',
        caseSensitive: false,
      );
      expect(count, 3);
      expect(out, 'a bye b\nbye c bye d');
    });

    test('unicode words keep their boundaries', () {
      const text = 'città cittàx la-città (città)';
      final (count, out) = replaceWholeWords(
        text,
        'città',
        'paese',
        caseSensitive: false,
      );
      expect(count, 3);
      expect(out, 'paese cittàx la-paese (paese)');
    });

    test('an empty replacement deletes the word', () {
      const text = 'one cat two';
      final (count, out) = replaceWholeWords(
        text,
        'cat',
        '',
        caseSensitive: false,
      );
      expect(count, 1);
      expect(out, 'one  two');
    });

    test('regex metacharacters in the term are literal', () {
      const text = 'a+b aab a+b.';
      final (count, out) = replaceWholeWords(
        text,
        'a+b',
        'x',
        caseSensitive: false,
      );
      expect(count, 2);
      expect(out, 'x aab x.');
    });
  });

  group('ReplaceRunner', () {
    test('preview lists matching notes with counts and samples', () async {
      final notes = await replace.previewMatches('cat', caseSensitive: false);
      expect(notes.map((n) => n.path), ['a.md', 'sub/x.md']);
      expect(notes[0].occurrences, 3);
      expect(notes[0].samples, hasLength(2));
      // The first match starts the note: no before-context, no ellipsis.
      final first = notes[0].samples.first;
      expect(first.before, isEmpty);
      expect(first.match, 'cat');
      // The second sample is the next occurrence ('Cat', different case).
      expect(notes[0].samples[1].match, 'Cat');
      expect(notes[1].occurrences, 1);
      // A zero-match note is not in the preview at all.
      expect(notes.map((n) => n.path), isNot(contains('c.md')));
    });

    test('preview honors the case flag and the single-note scope', () async {
      final any = await replace.previewMatches('cat', caseSensitive: false);
      final exact = await replace.previewMatches('Cat', caseSensitive: true);
      expect(any.first.occurrences, 3); // cat Cat CAT
      expect(exact.first.occurrences, 1);
      final only = await replace.previewMatches(
        'cat',
        caseSensitive: false,
        onlyPath: 'sub/x.md',
      );
      expect(only.single.path, 'sub/x.md');
    });

    test('preview samples carry the context around each match', () async {
      final notes = await replace.previewMatches(
        'hello world',
        caseSensitive: false,
      );
      expect(notes, hasLength(1));
      expect(notes.single.path, 'b.md');
      expect(notes.single.occurrences, 2);
      final sample = notes.single.samples.first;
      expect(sample.before.endsWith('dog '), isTrue);
      expect(sample.match, 'hello world');
      expect(sample.after.startsWith(','), isTrue);
    });

    test('replaces whole words across every matching note', () async {
      final report = await replace.replaceAll(
        term: 'cat',
        replacement: 'dog',
        caseSensitive: false,
      );
      expect(report.notesScanned, 2);
      expect(report.notesChanged, 2);
      expect(report.occurrences, 4); // a.md 3 + sub/x.md 1
      expect(report.skipped, isEmpty);
      expect(await read('a.md'), 'dog catalog concatenate cats. dog dog.\n');
      expect(await read('sub/x.md'), 'deep dog\n');
      expect(await read('c.md'), 'nothing here\n');
    });

    // A byte that is not UTF-8 was decoded as U+FFFD and written back as
    // one: Replace all changed an accent the user never touched. It is read
    // as the Windows-1252 character it is, and survives in UTF-8.
    test('a Latin-1 note keeps its accents through a replace', () async {
      await file('latin1.md').writeAsBytes(<int>[
        ...utf8.encode('cat caf'),
        0xE9, // é in Latin-1
        0x0A,
      ]);
      await Indexer(db).fullScan(root.path);
      final report = await replace.replaceAll(
        term: 'cat',
        replacement: 'dog',
        caseSensitive: false,
        only: {'latin1.md'},
      );
      expect(report.notesChanged, 1);
      expect(await file('latin1.md').readAsBytes(), utf8.encode('dog café\n'));
    });

    // The editor refuses a UTF-16 note as "not text" (`looksBinary`); the
    // index and this run used to read it leniently all the same, and a
    // replace wrote Windows-1252 mojibake back over it (#496).
    test(
      'a note that looks binary is left alone and reported failed',
      () async {
        final bytes = _utf16le('a cat\n');
        await file('utf16.md').writeAsBytes(bytes);

        final preview = await replace.previewMatches(
          'a',
          caseSensitive: false,
          onlyPath: 'utf16.md',
        );
        expect(preview, isEmpty, reason: 'a binary note is not a match');

        final report = await replace.replaceAll(
          term: 'a',
          replacement: 'Z',
          caseSensitive: false,
          only: {'utf16.md'},
        );
        expect(report.notesScanned, 1);
        expect(report.occurrences, 0);
        expect(report.notesChanged, 0);
        expect(report.failed, ['utf16.md']);
        expect(await file('utf16.md').readAsBytes(), bytes);
      },
    );

    // A note the pass reads is decided on and decoded in one call: a second
    // decode of a 246 MB note is a second transient allocation of it (#496).
    test(
      'a text note is decoded once by the preview and by the replace',
      () async {
        final bytes = utf8.encode('a cat in città\n');
        await file('once.md').writeAsBytes(bytes);

        var decodes = noteBytesNativeDecodes;
        final preview = await previewChunk(
          root.path,
          ['once.md'],
          'cat',
          20,
          3,
          caseSensitive: false,
        );
        expect(preview.single, isNotNull);
        expect(noteBytesNativeDecodes - decodes, 1, reason: 'the preview');

        decodes = noteBytesNativeDecodes;
        final results = await replaceChunk(
          root.path,
          ['once.md'],
          'cat',
          'dog',
          null,
          caseSensitive: false,
        );
        expect(results.single.$1, isTrue);
        expect(noteBytesNativeDecodes - decodes, 1, reason: 'the replace');
        expect(await read('once.md'), 'a dog in città\n');
      },
    );

    test('case-sensitive run touches only the exact case', () async {
      await file('a.md').writeAsString('cat Cat CAT\n');
      await Indexer(db).fullScan(root.path);
      final report = await replace.replaceAll(
        term: 'Cat',
        replacement: 'dog',
        caseSensitive: true,
      );
      expect(report.occurrences, 1);
      expect(await read('a.md'), 'cat dog CAT\n');
    });

    test('a multi-word term replaces across the phrase notes', () async {
      final report = await replace.replaceAll(
        term: 'hello world',
        replacement: 'bye moon',
        caseSensitive: false,
      );
      expect(report.notesChanged, 1);
      expect(report.occurrences, 2); // 'hello world' + 'hello\nworld'
      // The second match spans the newline, so it is replaced by the
      // single-space replacement text.
      expect(await read('b.md'), 'dog bye moon, bye moon — città cittàx.\n');
    });

    test('only limits the run to the given note', () async {
      final report = await replace.replaceAll(
        term: 'cat',
        replacement: 'dog',
        caseSensitive: false,
        only: {'a.md'},
      );
      expect(report.notesScanned, 1);
      expect(report.occurrences, 3);
      expect(await read('sub/x.md'), 'deep cat\n');
    });

    test('skip leaves the given notes alone and reports them', () async {
      final report = await replace.replaceAll(
        term: 'cat',
        replacement: 'dog',
        caseSensitive: false,
        skip: {'a.md'},
      );
      expect(report.notesScanned, 1); // only sub/x.md
      expect(report.skipped, ['a.md']);
      expect(await read('a.md'), contains('cat'));
      expect(await read('sub/x.md'), 'deep dog\n');
    });

    test('a term absent from every file changes nothing', () async {
      final report = await replace.replaceAll(
        term: 'encicl',
        replacement: 'x',
        caseSensitive: false,
      );
      expect(report.notesChanged, 0);
      expect(report.occurrences, 0);
    });

    test('an empty term is refused without touching anything', () async {
      final report = await replace.replaceAll(
        term: '   ',
        replacement: 'x',
        caseSensitive: false,
      );
      expect(report.notesScanned, 0);
      expect(report.occurrences, 0);
    });

    test('a note that cannot be written is reported as failed', () async {
      // A note that reads fine but whose directory refuses the atomic temp
      // write: the read-only/full-disk case. The run must report it as
      // failed instead of letting it pass as a note with no match.
      final locked = Directory(p.join(root.path, 'locked'))..createSync();
      await File(p.join(locked.path, 'note.md')).writeAsString('cat here\n');
      await Indexer(db).fullScan(root.path);
      if (Platform.isWindows) {
        return; // The chmod below is POSIX-only.
      }
      expect((await Process.run('chmod', ['555', locked.path])).exitCode, 0);
      try {
        final report = await replace.replaceAll(
          term: 'cat',
          replacement: 'dog',
          caseSensitive: false,
          only: {'locked/note.md'},
        );

        expect(report.notesScanned, 1);
        expect(report.occurrences, 0); // Nothing was written…
        expect(report.notesChanged, 0);
        // …and the note is named as failed, not silently "no match".
        expect(report.failed, ['locked/note.md']);
        expect(
          await File(p.join(locked.path, 'note.md')).readAsString(),
          'cat here\n',
        );
      } finally {
        await Process.run('chmod', ['755', locked.path]);
      }
    });

    test('a punctuation-only term neither throws nor matches', () async {
      // A lone quote names no token: the phrase builder drops it the way
      // query.dart's buildFtsQuery drops a quote-only token, so no
      // malformed FTS phrase ever reaches SQLite.
      expect(ftsPhraseOf('"'), isNull);
      expect(ftsPhraseOf('  --  '), isNull);

      final preview = await replace.previewMatches('"', caseSensitive: false);
      expect(preview, isEmpty);
      final report = await replace.replaceAll(
        term: '"',
        replacement: 'x',
        caseSensitive: false,
      );
      expect(report.notesScanned, 0);
      expect(report.occurrences, 0);
      expect(report.failed, isEmpty);
    });

    test(
      'each rewritten note keeps its old text as a replace version',
      () async {
        final kept = ReplaceRunner(
          db,
          root.path,
          historyRequest: () async => SnapshotRequest(
            limit: 10,
            interval: const Duration(minutes: 5),
            now: DateTime(2026, 9, 15),
            forced: HistoryReason.replace,
          ),
        );
        final before = file('sub/x.md').readAsStringSync();
        await kept.replaceAll(
          term: 'cat',
          replacement: 'dog',
          caseSensitive: false,
        );
        final manifest = readHistoryManifest(root.path, 'sub/x.md');
        expect(manifest.versions.single.reason, HistoryReason.replace);
        expect(
          utf8.decode(readHistoryVersion(root.path, 'sub/x.md', 1)!),
          before,
        );
      },
    );

    test('rewritten notes are re-indexed through the hook per batch', () async {
      final batches = <List<String>>[];
      final hooked = ReplaceRunner(
        db,
        root.path,
        onNotesReindexed: (paths) async => batches.add(paths),
      );
      await hooked.replaceAll(
        term: 'cat',
        replacement: 'dog',
        caseSensitive: false,
      );
      // One batch for the two changed notes; the unchanged note is not in
      // it, and the paths are absolute.
      expect(batches, hasLength(1));
      final changed = batches.single.toSet();
      expect(changed, {file('a.md').path, file('sub/x.md').path});
    });

    test(
      'the index reflects a replace right away (no watcher needed)',
      () async {
        final indexer = Indexer(db);
        final hooked = ReplaceRunner(
          db,
          root.path,
          onNotesReindexed: (paths) => indexer.rescanFiles(root.path, paths),
        );
        await hooked.replaceAll(
          term: 'cat',
          replacement: 'dog',
          caseSensitive: false,
        );
        // The rewritten notes are searchable under the new word…
        final hits = await db
            .customSelect(
              'SELECT notes.path FROM notes JOIN notes_fts '
              "ON notes.id = notes_fts.rowid WHERE notes_fts MATCH 'dog'",
            )
            .get();
        expect(
          hits.map((r) => r.read<String>('path')),
          containsAll(['a.md', 'sub/x.md']),
        );
        // …and the old word is gone from the index.
        final old = await db
            .customSelect(
              'SELECT count(*) c FROM notes_fts WHERE notes_fts MATCH ?',
              variables: [const Variable<String>('cat')],
            )
            .getSingle();
        expect(old.read<int>('c'), 0);
      },
    );
  });
}
