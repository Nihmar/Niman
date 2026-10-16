// #475: the panel's rows come off the index the app already keeps — the
// notes and their aliases from `note_stems` (one query per keystroke, never
// a walk of the tree), a named note's headings through the session's own
// read of it (once per revision, #491), and a book's place form from the
// target itself.
import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart'
    show
        ApplyInterceptor,
        InsertMode,
        QueryExecutor,
        QueryInterceptor,
        Value,
        Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/links/suggester.dart';

void main() {
  late IndexDatabase db;
  late _QueryLog counter;

  /// Adds a note row, and one `note_stems` row per stem given.
  Future<int> addNote(
    String path, {
    List<String> stems = const <String>[],
    String source = 'file',
  }) async {
    final id = await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            path: path,
            parent: 0,
            name: path.split('/').last,
            nameKey: nameSortKey(path.split('/').last),
            isDir: false,
            size: 1,
            modified: DateTime.fromMillisecondsSinceEpoch(0),
            created: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
    for (final stem in stems) {
      await db
          .into(db.noteStems)
          .insert(
            NoteStemsCompanion.insert(stem: stem, noteId: id, source: source),
            mode: InsertMode.insertOrIgnore,
          );
    }
    return id;
  }

  /// The suggester under test, reading a note's headings through
  /// [readHeadings] — none by default, which the notes list never needs.
  IndexWikilinkSuggester suggesterOver([
    Future<List<String>?> Function(String path)? readHeadings,
  ]) => IndexWikilinkSuggester(
    db,
    readHeadings: readHeadings ?? (_) async => null,
  );

  setUp(() async {
    counter = _QueryLog();
    db = IndexDatabase(NativeDatabase.memory().interceptWith(counter));
    addTearDown(db.close);
  });

  test(
    'an empty query lists the library: the stem shown, the folder dimmed',
    () async {
      await addNote('Notes.md', stems: ['notes']);
      await addNote('Guides/Markdown basics.md', stems: ['markdown basics']);
      final suggester = suggesterOver();

      final rows = await suggester.notes('');

      expect(rows.map((r) => r.name), ['Notes', 'Markdown basics']);
      expect(rows.map((r) => r.folder), [
        '',
        'Guides',
      ], reason: 'the folder is what tells two same-named notes apart');
      expect(rows.map((r) => r.target), [
        'Notes',
        'Markdown basics',
      ], reason: 'what is written is the stem, `.md` dropped');
    },
  );

  test(
    'a note found through an alias carries it, its own name does not',
    () async {
      final id = await addNote(
        'Guides/Markdown basics.md',
        stems: ['markdown basics'],
      );
      await db
          .into(db.noteStems)
          .insert(
            NoteStemsCompanion.insert(stem: 'md', noteId: id, source: 'alias'),
            mode: InsertMode.insertOrIgnore,
          );
      final suggester = suggesterOver();

      final byAlias = await suggester.notes('mD');
      expect(byAlias.map((r) => r.name), contains('Markdown basics'));
      expect(
        byAlias.first.alias,
        'md',
        reason: 'the row says how it was found',
      );

      final byName = await suggester.notes('Markdown');
      expect(byName.first.alias, isNull, reason: 'the name itself matched');
    },
  );

  test('prefix matches come first, then by path', () async {
    await addNote('Work/Meeting notes.md', stems: ['meeting notes']);
    await addNote('Archive/Notes.md', stems: ['notes']);
    await addNote('Notes.md', stems: ['notes']);
    final suggester = suggesterOver();

    final rows = await suggester.notes('NOTE');

    expect(rows.map((r) => (r.name, r.folder)), [
      ('Notes', ''),
      ('Notes', 'Archive'),
      ('Meeting notes', 'Work'),
    ], reason: 'the two prefix matches by path, the contains match after them');
  });

  // #1035: the name typed in full is the row Enter writes, whatever the
  // folder sorts like.
  test('the name typed in full ranks first, not the first folder', () async {
    await addNote('Archive/Meeting notes old.md', stems: ['meeting notes old']);
    await addNote('Work/Meeting notes.md', stems: ['meeting notes']);
    final suggester = suggesterOver();

    final rows = await suggester.notes('Meeting notes');

    expect(rows.map((r) => r.name), ['Meeting notes', 'Meeting notes old']);
    expect(rows.first.target, 'Meeting notes');
  });

  test(
    'the name typed in full is found past 200 longer prefix matches',
    () async {
      for (var i = 0; i < 250; i++) {
        await addNote('a/proj-$i.md', stems: ['proj-$i']);
      }
      await addNote('z/proj.md', stems: ['proj']);

      final rows = await suggesterOver().notes('proj');

      expect(rows.first.name, 'proj');
      expect(rows.first.folder, 'z');
    },
  );

  test('the prefix seek runs on the stem index, in stem order', () async {
    await addNote('a.md', stems: ['alpha']);
    counter.reset();
    await suggesterOver().notes('al');
    // The statement the app ran, planned with the arguments it ran with.
    final ran = counter.statements.firstWhere(
      (s) => s.sql.contains('s.stem >='),
    );
    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN ${ran.sql}',
          variables: [
            for (final arg in ran.args)
              if (arg is int) Variable<int>(arg) else Variable<String>('$arg'),
          ],
        )
        .get();
    final detail = plan.map((r) => r.read<String>('detail')).join(' | ');
    expect(detail, contains('INDEX sqlite_autoindex_note_stems_1'));
    expect(detail, contains('stem>? AND stem<?'));
    expect(detail, isNot(contains('TEMP B-TREE')));
  });

  // A bare name two notes share resolves to neither for sure: the row the
  // user picked has to write a target that opens that row's note.
  test('a shared name is qualified until it names the picked note', () async {
    await addNote('Work/Meeting.md', stems: ['meeting']);
    await addNote('Home/Meeting.md', stems: ['meeting']);
    await addNote('Work/Plan.md', stems: ['plan']);
    final suggester = suggesterOver();

    final rows = await suggester.notes('');
    final targets = {for (final r in rows) '${r.folder}/${r.name}': r.target};
    expect(targets, {
      'Home/Meeting': 'Home/Meeting',
      'Work/Meeting': 'Work/Meeting',
      'Work/Plan': 'Plan',
    }, reason: 'a name nobody else has stays bare');

    final resolver = LinkResolver(db);
    for (final row in rows) {
      final resolved = await resolver.resolveWiki(row.target);
      expect(
        resolved,
        isA<ResolvedNote>().having(
          (r) => r.note.path,
          'path',
          '${row.folder}/${row.name}.md',
        ),
        reason: 'what is written is what the link opens: ${row.target}',
      );
    }
  });

  test('books are listed, other attachments are not', () async {
    await addNote('Dune.pdf', stems: ['dune.pdf']);
    await addNote('Sea.epub', stems: ['sea.epub']);
    await addNote('map.png', stems: ['map']);
    final suggester = suggesterOver();

    final rows = await suggester.notes('');

    expect(rows.map((r) => r.name), [
      'Dune.pdf',
      'Sea.epub',
    ], reason: 'a `[[…]]` link names a note or a book; an image is an embed');
  });

  test('a directory is never a row', () async {
    await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            path: 'Guides',
            parent: 0,
            name: 'Guides',
            nameKey: nameSortKey('Guides'),
            isDir: true,
            size: 0,
            modified: DateTime.fromMillisecondsSinceEpoch(0),
            created: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
    await addNote('Guides/Notes.md', stems: ['notes']);
    final suggester = suggesterOver();

    expect(await suggester.notes(''), hasLength(1));
  });

  test("a note's headings come from its own read", () async {
    await addNote('Notes.md', stems: ['notes']);
    final reads = <String>[];
    final suggester = IndexWikilinkSuggester(
      db,
      readHeadings: (path) async {
        reads.add(path);
        return const ['Links', 'Dead links'];
      },
    );

    // The target as it was typed, not as the index normalizes it.
    final headings = await suggester.headings('Notes');

    expect(headings.map((h) => h.heading), ['Links', 'Dead links']);
    expect(reads, ['Notes.md'], reason: 'the named note is read once');
  });

  // A heading is written between `[[Note#` and `]]`: a `|` would start an
  // alias and a bracket end the link, so such a heading has no spelling and
  // is left out; a `#` is no obstacle, the link reads back by the whole
  // fragment (`Issue #12`).
  test('a heading a link cannot spell is not offered, a # is fine', () async {
    await addNote('Notes.md', stems: ['notes']);
    final suggester = IndexWikilinkSuggester(
      db,
      readHeadings: (_) async => const [
        'C#',
        'Issue #12',
        'A|B',
        'Use [x] here',
        'Plain',
      ],
    );

    final headings = await suggester.headings('Notes');

    expect(headings.map((h) => h.heading), ['C#', 'Issue #12', 'Plain']);
  });

  // #491: every key after `#` asked again — the whole target note read,
  // decoded and outlined on the UI isolate, seconds per key on a
  // novel-length one — although the panel filters the same list locally.
  // The list is read once per target and per revision, and only the
  // revision of the note can make it stale.
  test("a note's headings are read once per revision", () async {
    final id = await addNote('Novel.md', stems: ['novel']);
    final reads = <String>[];
    final suggester = IndexWikilinkSuggester(
      db,
      readHeadings: (path) async {
        reads.add(path);
        return const ['Chapter 1', 'Chapter 2'];
      },
    );

    for (var key = 0; key < 5; key++) {
      final headings = await suggester.headings('Novel');
      expect(headings.map((h) => h.heading), ['Chapter 1', 'Chapter 2']);
    }
    expect(reads, ['Novel.md'], reason: 'a run of keys is one read');

    // The note changed under the panel: that revision is read again.
    await (db.update(db.notes)..where((n) => n.id.equals(id))).write(
      NotesCompanion(
        modified: Value(DateTime.fromMillisecondsSinceEpoch(1000)),
        size: const Value(24),
      ),
    );
    expect(await suggester.headings('Novel'), hasLength(2));
    expect(reads, ['Novel.md', 'Novel.md'], reason: 'a new revision re-reads');
  });

  // A note that reads slowly is still being read when the next key lands:
  // each key after `#` asks for the same list, and the read of a novel is the
  // cost, so the ones that arrive while it runs wait for it (#491).
  test('keys typed while a note is read share that read', () async {
    await addNote('Novel.md', stems: ['novel']);
    final reads = <String>[];
    final gate = Completer<List<String>>();
    final suggester = IndexWikilinkSuggester(
      db,
      readHeadings: (path) {
        reads.add(path);
        return gate.future;
      },
    );
    counter.reset();

    final asked = [
      for (var key = 0; key < 5; key++) suggester.headings('Novel'),
    ];
    // Every ask has named its note (two SELECTs each) and is past the check
    // for a read already going; only now does the read finish.
    while (counter.statements.length < 10) {
      await pumpEventQueue(times: 1);
    }
    await pumpEventQueue();
    gate.complete(const ['Chapter 1', 'Chapter 2']);

    for (final headings in await Future.wait(asked)) {
      expect(headings.map((h) => h.heading), ['Chapter 1', 'Chapter 2']);
    }
    expect(reads, ['Novel.md'], reason: 'one read answers the whole run');
    expect((await suggester.headings('Novel')).map((h) => h.heading), [
      'Chapter 1',
      'Chapter 2',
    ], reason: 'and it is kept once it lands');
    expect(reads, hasLength(1));
  });

  test('a read that fails is not kept, the next key reads again', () async {
    await addNote('Novel.md', stems: ['novel']);
    var reads = 0;
    final suggester = IndexWikilinkSuggester(
      db,
      readHeadings: (path) async {
        if (++reads == 1) throw const FileSystemException('gone');
        return const ['Chapter 1'];
      },
    );

    await expectLater(
      suggester.headings('Novel'),
      throwsA(isA<FileSystemException>()),
    );
    expect(await suggester.headings('Novel'), hasLength(1));
    expect(reads, 2);
  });

  test('a target that names nothing suggests no heading', () async {
    final suggester = suggesterOver();
    expect(await suggester.headings('zzz'), isEmpty);
  });

  test('a note gone since it was named suggests no heading', () async {
    await addNote('Notes.md', stems: ['notes']);
    final suggester = IndexWikilinkSuggester(
      db,
      readHeadings: (_) async => null,
    );
    expect(await suggester.headings('Notes'), isEmpty);
  });

  test('a book offers its place form, a note offers none', () async {
    await addNote('Dune.pdf', stems: ['dune.pdf']);
    await addNote('Sea.epub', stems: ['sea.epub']);
    final suggester = suggesterOver();

    expect((await suggester.bookPlaces('Dune.pdf')).map((p) => p.form), [
      'page=',
    ]);
    expect((await suggester.bookPlaces('Sea.epub')).map((p) => p.form), [
      'chapter=',
    ]);
    expect(await suggester.bookPlaces('Notes'), isEmpty);
  });

  test('a query that is not on disk is matched literally', () async {
    await addNote('100% notes.md', stems: ['100% notes']);
    await addNote('Notes.md', stems: ['notes']);
    final suggester = suggesterOver();

    expect((await suggester.notes('% n')).map((r) => r.name), [
      '100% notes',
    ], reason: 'a `%` in the query is a character, not a wildcard');
  });
  // #491, #1036: a contains match has no stem index to use (`q%` does), so
  // it reads the trigram index of the names instead of evaluating a LIKE
  // against every stem. The indexed prefix query is read first; the
  // trigrams are read only when the prefix rows leave room under the fetch
  // cap.
  test('a full cap of prefix rows leaves the contains query unrun', () async {
    // The fetch cap is 200 stems: the query as a prefix of this many fills it.
    for (var i = 0; i < 200; i++) {
      await addNote('aaa$i.md', stems: ['aaa$i']);
    }
    // One note the query reaches only in the middle (`%q%`, not `q%`).
    await addNote('zz.md', stems: ['zzaaa']);
    counter.reset();

    final rows = await suggesterOver().notes('aaa');

    expect(
      counter.ranContains,
      isFalse,
      reason: 'the prefix rows fill the cap, so the trigrams were not read',
    );
    expect(rows, isNotEmpty);
  });

  test('the contains query runs when the prefix rows leave room', () async {
    await addNote('aaa1.md', stems: ['aaa1']);
    await addNote('zz.md', stems: ['zzaaa']);
    counter.reset();

    final rows = await suggesterOver().notes('aaa');

    expect(
      counter.ranContains,
      isTrue,
      reason:
          'the prefix rows did not fill the cap, so the trigrams answered too',
    );
    expect(rows.map((r) => r.name), [
      'aaa1',
      'zz',
    ], reason: 'the prefix match first, the contains match after');
  });

  // #491: a `[[…]]` target has no escape. The link ends at its first `]]`
  // and the parser splits the target at its first `|` or `#`, so a name
  // holding one of those — `C# tips` → target `C`, heading `tips` — is a
  // link to a note that does not exist. Offering every name and trusting
  // the parser to read it back is what wrote those links.
  test('a target that does not read back is not offered', () async {
    await addNote('C# tips.md', stems: ['c# tips']);
    await addNote('A|B.md', stems: ['a|b']);
    await addNote('odd]]name.md', stems: ['odd]]name']);
    // A folder the target has to name breaks it just as well: the row for
    // `A#b/Plan.md` is the one that has to write `A#b/Plan`.
    await addNote('A#b/Plan.md', stems: ['plan']);
    await addNote('Other/Plan.md', stems: ['plan']);
    await addNote('Notes.md', stems: ['notes']);
    final suggester = suggesterOver();

    final rows = await suggester.notes('');

    expect(
      {for (final r in rows) '${r.folder}/${r.name}': r.target},
      {'/Notes': 'Notes', 'Other/Plan': 'Other/Plan'},
      reason: 'what the panel writes is what the parser reads back',
    );
    for (final row in rows) {
      final ref = parseWikiRef(row.target);
      expect(
        (ref.target, ref.heading, ref.alias),
        (row.target, null, null),
        reason: 'the target reads back as itself: ${row.target}',
      );
    }
  });

  // The panel shows [IndexWikilinkSuggester.limit] rows. A name it cannot
  // write must not use one of them: filtered after the cut, a run of them at
  // the head of the ranking left the panel short of notes that were there.
  test('names that do not read back take no slot of the panel', () async {
    for (var i = 0; i < 60; i++) {
      await addNote('A# $i.md', stems: ['a# $i']);
    }
    for (var i = 0; i < 10; i++) {
      await addNote('B $i.md', stems: ['b $i']);
    }

    final rows = await suggesterOver().notes('');

    expect(rows.map((r) => r.name).toSet(), {
      for (var i = 0; i < 10; i++) 'B $i',
    });
    expect(rows, hasLength(10));
  });

  test('a folder that does not read back takes no slot either', () async {
    // Each name is shared, so its row writes the folder too: `X#/n0` for the
    // ones that come first, which cannot be written.
    for (var i = 0; i < 60; i++) {
      await addNote('X#/n$i.md', stems: ['n$i']);
      await addNote('Y/n$i.md', stems: ['n$i']);
    }

    final rows = await suggesterOver().notes('');

    expect(rows, hasLength(IndexWikilinkSuggester.limit));
    expect(rows.every((r) => r.folder == 'Y'), isTrue);
  });

  test("a file's target is its name, qualified when shared (#704)", () async {
    await addNote('Work/Meeting.md', stems: ['meeting']);
    await addNote('Home/Meeting.md', stems: ['meeting']);
    await addNote('Solo.md', stems: ['solo']);
    await addNote('Media/photo.png', stems: ['photo.png']);
    final suggester = suggesterOver();

    expect(await suggester.targetOf('Work/Meeting.md'), 'Work/Meeting');
    expect(await suggester.targetOf('Solo.md'), 'Solo');
    expect(await suggester.targetOf('Media/photo.png'), 'photo.png');
  });

  group('after ![[ (#705)', () {
    IndexWikilinkSuggester embedder() => IndexWikilinkSuggester(
      db,
      readHeadings: (_) async => null,
      attachmentsFolder: () async => 'Media',
    );

    test(
      'the attachments folder first, then the rest, then the notes',
      () async {
        await addNote('Diary.md', stems: ['diary']);
        await addNote('Archive/scan.pdf', stems: ['scan.pdf']);
        await addNote('Media/photo.png', stems: ['photo.png']);
        await addNote('Media/Audio/memo.m4a', stems: ['memo.m4a']);

        final rows = await embedder().embeds('');

        expect(rows.map((r) => r.name), [
          'photo.png',
          'memo.m4a',
          'scan.pdf',
          'Diary',
        ], reason: 'its subfolders are the folder too');
        expect(rows.map((r) => r.target), [
          'photo.png',
          'memo.m4a',
          'scan.pdf',
          'Diary',
        ], reason: 'an attachment keeps its extension');
      },
    );

    test('ranked by the query, a shared name qualified', () async {
      await addNote('Media/photo.png', stems: ['photo.png']);
      await addNote('Trip/photo.png', stems: ['photo.png']);
      await addNote('Media/portrait.jpg', stems: ['portrait.jpg']);
      await addNote('Photos.md', stems: ['photos']);

      final rows = await embedder().embeds('pho');

      expect(rows.map((r) => r.target), [
        'Media/photo.png',
        'Trip/photo.png',
        'Photos',
      ]);
    });
  });

  group('block ids and the headings of the library (#844, #845)', () {
    /// Gives the note [id] its anchors, as the content pass writes them: the
    /// rows and the note's row of the word index.
    Future<void> anchors(
      int id, {
      List<String> headings = const <String>[],
      Map<String, String> blocks = const <String, String>{},
    }) async {
      var line = 0;
      for (final heading in headings) {
        await db.customStatement(
          'INSERT INTO note_headings (note_id, line, level, heading) '
          'VALUES (?, ?, 2, ?)',
          <Object?>[id, line++, heading],
        );
      }
      for (final MapEntry(key: blockId, value: excerpt) in blocks.entries) {
        await db.customStatement(
          'INSERT INTO note_blocks (note_id, block_id, line, excerpt) '
          'VALUES (?, ?, ?, ?)',
          <Object?>[id, blockId, line++, excerpt],
        );
      }
      await db.customStatement(
        'INSERT INTO note_anchors_fts (rowid, headings, blocks) '
        'VALUES (?, ?, ?)',
        <Object?>[
          id,
          headings.join('\n'),
          [for (final e in blocks.entries) '${e.key} ${e.value}'].join('\n'),
        ],
      );
    }

    test(
      "a note's block ids come from its own read, once per revision",
      () async {
        await addNote('Notes.md', stems: ['notes']);
        final reads = <String>[];
        final suggester = IndexWikilinkSuggester(
          db,
          readHeadings: (_) async => null,
          readBlocks: (path) async {
            reads.add(path);
            return const [
              BlockAnchor(id: 'abc', line: 0, excerpt: 'A paragraph'),
              BlockAnchor(id: 'item-1', line: 4, excerpt: 'one'),
            ];
          },
        );

        for (var key = 0; key < 3; key++) {
          final rows = await suggester.blocks('Notes');
          expect(rows.map((r) => r.id), ['abc', 'item-1']);
          expect(rows.first.excerpt, 'A paragraph');
          expect(rows.first.path, isNull, reason: "a note's own list");
        }
        expect(reads, ['Notes.md'], reason: 'a run of keys is one read');
      },
    );

    test(
      'a surface with no block read lists none, an unknown note none',
      () async {
        await addNote('Notes.md', stems: ['notes']);
        final suggester = suggesterOver();

        expect(await suggester.blocks('Notes'), isEmpty);
        expect(
          await IndexWikilinkSuggester(
            db,
            readHeadings: (_) async => null,
            readBlocks: (_) async => const <BlockAnchor>[],
          ).blocks('Nope'),
          isEmpty,
        );
      },
    );

    test('headings across the library name the shortest target', () async {
      final guides = await addNote('Guides/Notes.md', stems: ['notes']);
      final archive = await addNote('Archive/Notes.md', stems: ['notes']);
      final plan = await addNote('Plan.md', stems: ['plan']);
      await anchors(guides, headings: ['Team notes']);
      await anchors(archive, headings: ['Old team']);
      await anchors(plan, headings: ['Team plan', 'Budget']);
      final suggester = suggesterOver();

      final rows = await suggester.headingsAcross('team');

      expect(rows.map((r) => (r.heading, r.path, r.target)), [
        ('Team notes', 'Guides/Notes.md', 'Guides/Notes'),
        ('Team plan', 'Plan.md', 'Plan'),
        ('Old team', 'Archive/Notes.md', 'Archive/Notes'),
      ], reason: 'a name two notes share is qualified, as the note rows are');
    });

    test('a heading in a note a target cannot name is not offered', () async {
      final odd = await addNote('C# tips.md', stems: ['c# tips']);
      final fine = await addNote('Tips.md', stems: ['tips']);
      await anchors(odd, headings: ['Tips for C']);
      await anchors(fine, headings: ['Tips for all', 'Use [brackets] tips']);

      final rows = await suggesterOver().headingsAcross('tips');

      expect(rows.map((r) => r.heading), ['Tips for all']);
    });

    test('a heading with a # is offered across the library too', () async {
      final fine = await addNote('Tips.md', stems: ['tips']);
      await anchors(fine, headings: ['Tips for C#', 'Tips #1', 'Tips | a']);

      final rows = await suggesterOver().headingsAcross('tips');

      expect(
        rows.map((r) => r.heading),
        unorderedEquals(['Tips for C#', 'Tips #1']),
      );
    });

    test('block ids across the library carry the note and the words', () async {
      final a = await addNote('A.md', stems: ['a']);
      final b = await addNote('docs/B.md', stems: ['b']);
      await anchors(a, blocks: {'idea-1': 'The first idea'});
      await anchors(b, blocks: {'idea-2': 'Another idea'});

      final rows = await suggesterOver().blocksAcross('idea');

      expect(rows.map((r) => (r.id, r.path, r.target, r.excerpt)), [
        ('idea-1', 'A.md', 'A', 'The first idea'),
        ('idea-2', 'docs/B.md', 'B', 'Another idea'),
      ]);
      expect((await suggesterOver().blocksAcross('another')).map((r) => r.id), [
        'idea-2',
      ], reason: 'the first words of the block are searched as well');
    });

    test("the lists are cut to the panel's rows", () async {
      for (var i = 0; i < 80; i++) {
        final id = await addNote('n$i.md', stems: ['n$i']);
        await anchors(id, headings: ['Team $i']);
      }

      final rows = await suggesterOver().headingsAcross('team');

      expect(rows, hasLength(IndexWikilinkSuggester.limit));
    });
  });
}

/// Records every SELECT a suggester run issues, with its bound arguments, so
/// a test can pin the work a keystroke is charged rather than its wall clock
/// (#491).
final class _QueryLog extends QueryInterceptor {
  final statements = <({String sql, List<Object?> args})>[];

  void reset() => statements.clear();

  /// Whether any issued SELECT read the trigram index — the contains
  /// lookup, which the prefix rows spare when they fill the cap.
  bool get ranContains =>
      statements.any((s) => s.sql.contains('stem_trigrams'));

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    statements.add((sql: statement, args: args));
    return executor.runSelect(statement, args);
  }
}
