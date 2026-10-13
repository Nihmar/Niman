// The fold the anchor search compares words with is the word index's own:
// held here to SQLite's `unicode61 remove_diacritics 2` tokenizer, one
// character at a time.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/search/index_fold.dart';

void main() {
  test('every character folds as the tokenizer folds it', () async {
    final db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      'CREATE VIRTUAL TABLE t USING fts5(x, '
      "tokenize = 'unicode61 remove_diacritics 2')",
    );
    await db.customStatement(
      "CREATE VIRTUAL TABLE v USING fts5vocab(t, 'instance')",
    );
    // Each character between two letters: a separator splits the word in
    // two, anything else is part of it and comes back folded.
    await db.batch((batch) {
      for (var c = 0x80; c < 0x20000; c++) {
        if (c >= 0xD800 && c < 0xE000) continue;
        batch.customStatement('INSERT INTO t (rowid, x) VALUES (?, ?)', [
          c,
          'q${String.fromCharCode(c)}q',
        ]);
      }
    });
    final terms = <int, List<String>>{};
    for (final row
        in await db
            .customSelect('SELECT doc, term FROM v ORDER BY doc, offset')
            .get()) {
      terms
          .putIfAbsent(row.read<int>('doc'), () => [])
          .add(row.read<String>('term'));
    }

    final wrong = <String>[];
    var folded = 0;
    for (final MapEntry(key: c, value: words) in terms.entries) {
      if (words.length != 1) continue;
      folded++;
      final ours = foldForIndex('q${String.fromCharCode(c)}q');
      if (ours != words.single) {
        wrong.add('U+${c.toRadixString(16)}: $ours, SQLite ${words.single}');
      }
    }

    expect(folded, greaterThan(50000), reason: 'the letters were compared');
    expect(wrong, isEmpty);
  });

  test('a word with accents, composed or not, folds to its plain letters', () {
    expect(foldForIndex('Résumé'), 'resume');
    expect(foldForIndex('Résumé'), 'resume');
    expect(foldForIndex('ÐØ'), 'ðø', reason: 'SQLite has no plain letter');
  });
}
