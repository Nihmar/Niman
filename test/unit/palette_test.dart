// Issue #155: the palette's halves — notes by name from the index, and
// commands ranked recent first, then by how well they answer.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/palette/palette_match.dart';

void main() {
  group('notes by name', () {
    late IndexDatabase db;
    late NoteDao dao;

    setUp(() async {
      db = IndexDatabase(NativeDatabase.memory());
      dao = NoteDao(db);
      for (final (path, dir) in [
        ('Plans', true),
        ('Plans/plan.md', false),
        ('Plans/old plan.md', false),
        ('airplane.md', false),
        ('100%_done.md', false),
        ('1000 done.md', false),
      ]) {
        await db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                path: path,
                parent: 0,
                name: path.split('/').last,
                isDir: dir,
                size: 0,
                modified: DateTime(2026),
              ),
            );
      }
    });
    tearDown(() => db.close());

    Future<List<String>> named(String q) async => [
      for (final n in await dao.named(q)) n.path,
    ];

    test(
      'names holding the query, starting ones first, folders never',
      () async {
        // Same length, then by path.
        expect(await named('PLAN'), [
          'Plans/plan.md',
          'Plans/old plan.md',
          'airplane.md',
        ]);
      },
    );

    test('% and _ are only themselves', () async {
      expect(await named('%_'), ['100%_done.md']);
      expect(await named(''), isEmpty);
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
