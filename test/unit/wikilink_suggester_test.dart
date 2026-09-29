// #475: the panel's rows come off the index the app already keeps — the
// notes and their aliases from `note_stems` (one query per keystroke, never
// a walk of the tree), a named note's headings through the session's own
// read of it (once per revision, #491), and a book's place form from the
// target itself.
import 'package:drift/drift.dart' show InsertMode, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/links/suggester.dart';

void main() {
  late IndexDatabase db;

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
            isDir: false,
            size: 1,
            modified: DateTime.fromMillisecondsSinceEpoch(0),
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
    db = IndexDatabase(NativeDatabase.memory());
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
            isDir: true,
            size: 0,
            modified: DateTime.fromMillisecondsSinceEpoch(0),
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

    expect((await suggester.notes('%')).map((r) => r.name), [
      '100% notes',
    ], reason: 'a `%` in the query is a character, not a wildcard');
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
}
