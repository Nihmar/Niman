// #475: the panel's rows come off the index the app already keeps — the
// notes and their aliases from `note_stems` (one query per keystroke, never
// a walk of the tree), a named note's headings from its own text through the
// outline's scan, and a book's place form from the target itself.
import 'package:drift/drift.dart' show InsertMode;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
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

  /// The suggester under test, reading a note's text from [notes].
  IndexWikilinkSuggester suggesterOver(Map<String, String> notes) =>
      IndexWikilinkSuggester(db, readNote: (path) async => notes[path]);

  setUp(() async {
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  test(
    'an empty query lists the library: the stem shown, the folder dimmed',
    () async {
      await addNote('Notes.md', stems: ['notes']);
      await addNote('Guides/Markdown basics.md', stems: ['markdown basics']);
      final suggester = suggesterOver(const <String, String>{});

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
      final suggester = suggesterOver(const <String, String>{});

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
    final suggester = suggesterOver(const <String, String>{});

    final rows = await suggester.notes('NOTE');

    expect(rows.map((r) => (r.name, r.folder)), [
      ('Notes', ''),
      ('Notes', 'Archive'),
      ('Meeting notes', 'Work'),
    ], reason: 'the two prefix matches by path, the contains match after them');
  });

  test('books are listed, other attachments are not', () async {
    await addNote('Dune.pdf', stems: ['dune.pdf']);
    await addNote('Sea.epub', stems: ['sea.epub']);
    await addNote('map.png', stems: ['map']);
    final suggester = suggesterOver(const <String, String>{});

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
    final suggester = suggesterOver(const <String, String>{});

    expect(await suggester.notes(''), hasLength(1));
  });

  test("a note's headings come from its own text, through one read", () async {
    await addNote('Notes.md', stems: ['notes']);
    final reads = <String>[];
    final suggester = IndexWikilinkSuggester(
      db,
      readNote: (path) async {
        reads.add(path);
        return '# Links\n\nbody\n\n## Dead links\n';
      },
    );

    // The target as it was typed, not as the index normalizes it.
    final headings = await suggester.headings('Notes');

    expect(headings.map((h) => h.heading), ['Links', 'Dead links']);
    expect(reads, ['Notes.md'], reason: 'the named note is read once');
  });

  test('a target that names nothing suggests no heading', () async {
    final suggester = suggesterOver(const <String, String>{});
    expect(await suggester.headings('zzz'), isEmpty);
  });

  test('a note gone since it was named suggests no heading', () async {
    await addNote('Notes.md', stems: ['notes']);
    final suggester = IndexWikilinkSuggester(db, readNote: (_) async => null);
    expect(await suggester.headings('Notes'), isEmpty);
  });

  test('a book offers its place form, a note offers none', () async {
    await addNote('Dune.pdf', stems: ['dune.pdf']);
    await addNote('Sea.epub', stems: ['sea.epub']);
    final suggester = suggesterOver(const <String, String>{});

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
    final suggester = suggesterOver(const <String, String>{});

    expect((await suggester.notes('%')).map((r) => r.name), [
      '100% notes',
    ], reason: 'a `%` in the query is a character, not a wildcard');
  });
}
