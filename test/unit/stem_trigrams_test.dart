// #1043, #1036: the trigram index of the names a note answers to is kept by
// triggers on `note_stems` — every writer of those rows feeds it — is built
// for a file from before it, and its absence only costs the contains tier.
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/db/stem_trigrams.dart';
import 'package:niman/src/links/stem_rows.dart';

void main() {
  late IndexDatabase db;

  Future<int> addNote(String path, List<String> stems) async {
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
            NoteStemsCompanion.insert(
              stem: stem,
              noteId: id,
              source: stem == stems.first ? 'file' : 'alias',
            ),
          );
    }
    return id;
  }

  /// The ids of the notes whose names hold [text], by the trigram index.
  Future<Set<int>> holding(String text) async {
    final rows = await db
        .customSelect(
          'SELECT rowid FROM stem_trigrams WHERE stem_trigrams MATCH ?',
          variables: [Variable<String>(stemTrigramQuery(text))],
        )
        .get();
    return {for (final r in rows) r.read<int>('rowid')};
  }

  setUp(() {
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  test(
    'a note is found by its name and by an alias, anywhere in them',
    () async {
      final id = await addNote('x/airplane.md', ['airplane', 'flying machine']);
      expect(await holding('plan'), {id});
      expect(await holding('ying mac'), {id});
      expect(await holding('absent'), isEmpty);
    },
  );

  test('a rename, a re-index and a delete keep it in step', () async {
    final id = await addNote('a.md', ['alpha', 'first']);
    final other = await addNote('b.md', ['alpine']);
    expect(await holding('alp'), {id, other});

    // The way a re-index writes them: the old rows gone, the new ones in.
    await db.customStatement('DELETE FROM note_stems WHERE note_id = $id');
    expect(await holding('alp'), {other}, reason: 'its stems are gone');
    await db
        .into(db.noteStems)
        .insert(
          NoteStemsCompanion.insert(stem: 'omega', noteId: id, source: 'file'),
        );
    expect(await holding('omeg'), {id});
    expect(await holding('first'), isEmpty);

    // An update of a stem in place.
    await db.customStatement(
      "UPDATE note_stems SET stem = 'sigma' WHERE note_id = $id",
    );
    expect(await holding('omeg'), isEmpty);
    expect(await holding('sigm'), {id});

    await db.customStatement('DELETE FROM note_stems');
    expect(await holding('alp'), isEmpty);
    expect(await holding('sigm'), isEmpty);
  });

  test('a file from before the index gets it, filled from the stems', () async {
    final id = await addNote('a.md', ['alpha']);
    for (final drop in [
      'DROP TRIGGER stem_trigrams_add',
      'DROP TRIGGER stem_trigrams_drop',
      'DROP TRIGGER stem_trigrams_change',
      'DROP TABLE stem_trigrams',
    ]) {
      await db.customStatement(drop);
    }
    expect(await hasStemTrigrams(db), isFalse);
    // Written while the file lacked it: the index never saw this note.
    final late = await addNote('b.md', ['betamax']);

    await db.ensureStemTrigrams();

    expect(await hasStemTrigrams(db), isTrue);
    expect(await holding('alph'), {id});
    expect(await holding('etam'), {late});
    // And it is kept from now on.
    final next = await addNote('c.md', ['gammaray']);
    expect(await holding('mmar'), {next});
    await db.ensureStemTrigrams(); // idempotent
    expect(await holding('mmar'), {next});
  });

  test('without the index the prefix rows still answer', () async {
    await addNote('alpha.md', ['alpha']);
    await addNote('zalp.md', ['zalp']);
    await db.customStatement('DROP TRIGGER stem_trigrams_add');
    await db.customStatement('DROP TRIGGER stem_trigrams_drop');
    await db.customStatement('DROP TRIGGER stem_trigrams_change');
    await db.customStatement('DROP TABLE stem_trigrams');

    final rows = await StemRows(db).rows('alp', StemRows.linkable);

    expect(rows.map((r) => r.stem), ['alpha']);
  });

  test('text shorter than a trigram has no query', () {
    expect(stemTrigramQuery('ab'), isNull);
    expect(stemTrigramQuery('abc'), '"abc"');
    expect(stemTrigramQuery('a"c'), '"a""c"');
  });
}
