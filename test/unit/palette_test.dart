// Issue #155: the palette's halves — notes by name from the index, and
// commands ranked recent first, then by how well they answer.
import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor, Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/note_finder.dart';
import 'package:niman/src/ui/palette/palette_match.dart';

void main() {
  group('notes by name', () {
    late IndexDatabase db;
    late NoteFinder finder;
    late _StatementLog log;

    /// Adds a row for [path] (its stem too, the way the indexer does for a
    /// file), and the aliases and the title given.
    Future<int> add(
      String path, {
      bool dir = false,
      List<String> aliases = const [],
      String? title,
    }) async {
      final name = path.split('/').last;
      final id = await db
          .into(db.notes)
          .insert(
            NotesCompanion.insert(
              path: path,
              parent: 0,
              name: name,
              isDir: dir,
              size: 0,
              modified: DateTime(2026),
              created: DateTime(2026),
            ),
          );
      if (dir) return id;
      final stem = name.toLowerCase().endsWith('.md')
          ? name.substring(0, name.length - 3)
          : name;
      for (final (s, source) in [
        (stem.toLowerCase(), 'file'),
        for (final a in aliases) (a.toLowerCase(), 'alias'),
      ]) {
        await db
            .into(db.noteStems)
            .insert(
              NoteStemsCompanion.insert(stem: s, noteId: id, source: source),
            );
      }
      await db.customStatement(
        'INSERT INTO notes_fts (rowid, title, body) VALUES (?, ?, ?)',
        <Object?>[id, title ?? stem, ''],
      );
      return id;
    }

    setUp(() async {
      log = _StatementLog();
      db = IndexDatabase(NativeDatabase.memory().interceptWith(log));
      finder = NoteFinder(db);
      await add('Plans', dir: true);
      await add('Plans/plan.md');
      await add('Plans/old plan.md');
      await add('airplane.md');
      await add('100%_done.md');
      await add('1000 done.md');
    });
    tearDown(() => db.close());

    test(
      'names holding the query, the exact one first, folders never',
      () async {
        // The name typed in full, then the names it starts, then the ones
        // that hold it: here `plan` is the name, `airplane` and `old plan`
        // hold it, as long as each other, so by folder.
        expect(await finder.paths('PLAN'), [
          'Plans/plan.md',
          'airplane.md',
          'Plans/old plan.md',
        ]);
      },
    );

    test(
      '% and _ are only themselves; under two characters finds nothing',
      () async {
        expect((await finder.paths('%_d')).first, '100%_done.md');
        expect(await finder.paths('0_'), isEmpty);
        expect(await finder.paths(''), isEmpty);
        expect(await finder.paths('p'), isEmpty);
      },
    );

    test('a note is found by an alias, and by a word of its title', () async {
      await add(
        '1999-03-12.md',
        aliases: ['Wedding'],
        title: 'Honeymoon pictures',
      );
      expect(await finder.paths('wedd'), ['1999-03-12.md']);
      expect(await finder.paths('honey'), ['1999-03-12.md']);
      expect(await finder.paths('pictures'), ['1999-03-12.md']);
    });

    test('a title found twice is listed once, after the names', () async {
      await add('Work/notes.md', title: 'Plan of the week');
      expect(await finder.paths('plan'), [
        'Plans/plan.md',
        'airplane.md',
        'Plans/old plan.md',
        'Work/notes.md',
      ]);
    });

    test('the prefix and the contains lookups read the indexes', () async {
      log.statements.clear();
      await finder.paths('plan');
      final lookups = [
        for (final s in log.statements)
          if (s.sql.contains('note_stems')) s,
      ];
      // The prefix range and the trigram lookup, planned as they ran.
      expect(lookups, hasLength(2));
      final details = <String>[];
      for (final s in lookups) {
        final rows = await db
            .customSelect(
              'EXPLAIN QUERY PLAN ${s.sql}',
              variables: [
                for (final a in s.args)
                  if (a is int) Variable<int>(a) else Variable<String>('$a'),
              ],
            )
            .get();
        details.add(rows.map((r) => r.read<String>('detail')).join(' | '));
      }
      expect(details[0], contains('sqlite_autoindex_note_stems_1 (stem>'));
      expect(details[1], contains('VIRTUAL TABLE INDEX'));
      for (final detail in details) {
        expect(detail, isNot(matches(RegExp('SCAN (s|note_stems)'))));
      }
    });
  });

  group('ranking', () {
    test('every word must be there, in any order', () {
      expect(paletteScore('Editor: Switch to WYSIWYG', 'wys sw'), isNotNull);
      expect(paletteScore('Editor: Switch to WYSIWYG', 'wys zz'), isNull);
    });

    test('a word that starts one outranks one inside a word', () {
      final start = paletteScore('Note: Rename…', 'ren')!;
      final inside = paletteScore('View: Hide the panel', 'ren');
      expect(inside, isNull);
      expect(start, greaterThan(paletteScore('Note: Delete…', 'let')!));
    });

    test('what was used lately comes first', () {
      final ranked = paletteRank(
        ['View: Split right', 'View: Split down', 'Go to: Settings'],
        'split',
        name: (s) => s,
        id: (s) => s,
        recent: ['View: Split down'],
      );
      expect(ranked, ['View: Split down', 'View: Split right']);
    });
  });
}

/// Every SELECT the database ran, with its arguments.
final class _StatementLog extends QueryInterceptor {
  final statements = <({String sql, List<Object?> args})>[];

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
