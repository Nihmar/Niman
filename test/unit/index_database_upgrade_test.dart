// The v4 index: a full-text table with no copy of the text, and an index
// file that gives the space the copy took back.
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test(
    'an index that kept the text is rebuilt without it, and shrinks',
    () async {
      final dir = Directory.systemTemp.createTempSync('niman_index_v4_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File(p.join(dir.path, 'index.db'));

      // A v3 index: the full-text table with its copy of every note.
      final old = sqlite3.sqlite3.open(file.path)
        ..execute(
          'CREATE VIRTUAL TABLE notes_fts USING '
          "fts5(title, body, tokenize = 'unicode61 remove_diacritics 2')",
        )
        ..execute('PRAGMA user_version = 3');
      final body = List.generate(40000, (i) => 'word$i text').join(' ');
      for (var i = 1; i <= 20; i++) {
        old.execute(
          'INSERT INTO notes_fts (rowid, title, body) VALUES (?, ?, ?)',
          [i, 'Note $i', body],
        );
      }
      old.close();
      final before = file.lengthSync();

      final db = IndexDatabase(NativeDatabase(file, setup: indexDatabaseSetup));
      await db.customStatement(
        'INSERT INTO notes_fts (rowid, title, body) VALUES (1, ?, ?)',
        ['Kept', 'the words are searchable'],
      );
      final found = await db
          .customSelect(
            'SELECT rowid, body FROM notes_fts WHERE notes_fts MATCH ?',
            variables: [const Variable<String>('searchable')],
          )
          .get();
      expect(found.single.read<int>('rowid'), 1);
      expect(found.single.read<String?>('body'), isNull, reason: 'no copy');
      final vacuum = await db.customSelect('PRAGMA auto_vacuum').getSingle();
      expect(vacuum.read<int>('auto_vacuum'), 2, reason: 'incremental');
      await db.close();

      expect(
        file.lengthSync(),
        lessThan(before ~/ 10),
        reason: 'the pages of the old copy went back: $before bytes before',
      );
    },
  );
}
