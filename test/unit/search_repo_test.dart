// T-M3-04 AC: word search ranks (bm25, title over body) with snippets;
// #tag search answers from tags/note_tags, never FTS; superseded queries
// are dropped by invocation id; MATCH vs LIKE behaviors.
import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/search/query.dart';
import 'package:copist/src/search/search_repo.dart';
import 'package:copist/src/search/tag_repo.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late IndexDatabase db;
  late SearchRepo search;
  late TagRepo tags;

  Future<void> indexNote(String path, String title, String body) async {
    await db.customStatement(
      'INSERT INTO notes (path, parent, name, is_dir, size, modified) '
      'VALUES (?1, 0, ?2, 0, ?3, 0)',
      [path, path.split('/').last, body.length],
    );
    final row = await db
        .customSelect(
          'SELECT id FROM notes WHERE path = ?1',
          variables: [Variable<String>(path)],
        )
        .getSingle();
    await db.customStatement(
      'INSERT INTO notes_fts (rowid, title, body) VALUES (?1, ?2, ?3)',
      [row.read<int>('id'), title, body],
    );
  }

  setUp(() async {
    db = IndexDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    search = SearchRepo(db);
    tags = TagRepo(db);
    await indexNote('zebra.md', 'Zebra study', 'zebra facts in the text');
    await indexNote(
      'apple.md',
      'Apple',
      'zebra attacks the apple and '
          'the quick brown fox jumps over it',
    );
    await indexNote(
      'deep.md',
      'Deep note',
      'plain words only, and hello for the contains test',
    );
    await db.into(db.tags).insert(TagsCompanion.insert(name: 'work'));
    await db.into(db.tags).insert(TagsCompanion.insert(name: 'ideas'));
    for (final (note, tag) in [
      ('apple.md', 'work'),
      ('deep.md', 'work'),
      ('deep.md', 'ideas'),
    ]) {
      final row = await db
          .customSelect(
            'SELECT id FROM notes WHERE path = ?1',
            variables: [Variable<String>(note)],
          )
          .getSingle();
      await db
          .into(db.noteTags)
          .insert(
            NoteTagsCompanion.insert(
              tag: tag,
              noteId: row.read<int>('id'),
              isFrontmatter: true,
            ),
          );
    }
  });

  test('word search: ranked bm25 with title over body', () async {
    final id = search.begin();
    final hits = await search.search(buildFtsQuery('zebra'), id: id);
    expect(hits, hasLength(2));
    // "Zebra study" hits the title (weight 10) — it must rank first.
    expect(hits.first.title, 'Zebra study');
    expect(hits.first.snippet, isNotEmpty);
    expect(hits.first.snippet, contains('<mark>'));
  });

  test('superseded queries return no results', () async {
    final early = search.begin();
    final late = search.begin();
    final hits = await search.search(buildFtsQuery('zebra'), id: early);
    expect(hits, isEmpty);
    final current = await search.search(buildFtsQuery('zebra'), id: late);
    expect(current, isNotEmpty);
  });

  test('a query token that never appears returns nothing', () async {
    final id = search.begin();
    final hits = await search.search(buildFtsQuery('missingword'), id: id);
    expect(hits, isEmpty);
  });

  test(
    'MATCH word mode does not find intra-word substrings (unlike LIKE)',
    () async {
      // 'ell' is inside 'hello' but is never a term; a LIKE %ell% would hit.
      final id = search.begin();
      final hits = await search.search(buildFtsQuery('ell'), id: id);
      expect(hits, isEmpty);
      // A real word behaves: 'plain' finds the deep note.
      final hits2 = await search.search(buildFtsQuery('plain'), id: id);
      expect(hits2.map((h) => h.path), ['deep.md']);
    },
  );

  test('punctuation in the query is literal, not FTS syntax', () async {
    final id = search.begin();
    // 'zebra (attacks)' — the parens are quoted; the terms still match.
    final hits = await search.search(buildFtsQuery('zebra (attacks)'), id: id);
    expect(hits, isNotEmpty);
    expect(hits.map((h) => h.path), contains('apple.md'));
  });

  test('tag counts: distinct notes per tag, most used first', () async {
    final counts = await tags.tagCounts();
    expect(counts.map((c) => '${c.name}:${c.count}').toList(), [
      'work:2',
      'ideas:1',
    ]);
  });

  test('#tag search: tag mode, notes in path order, never FTS', () async {
    final t = tagQuery('#Work');
    expect(t, 'work');
    final notes = await tags.notesWithTag(t!);
    expect(notes.map((n) => n.path).toList(), ['apple.md', 'deep.md']);
  });

  group('contains mode (searchContains)', () {
    test('finds intra-word substrings, unlike MATCH; path order', () async {
      final id = search.begin();
      // 'ell' is inside 'hello' but never a term: contains finds it,
      // word mode does not.
      final hits = await search.searchContains('ell', id: id);
      expect(hits.map((h) => h.path).toList(), ['deep.md']);
      // Same input in word mode: nothing (ell is not a term).
      final words = await search.search(buildFtsQuery('ell'), id: id);
      expect(words, isEmpty);
    });

    test('case-insensitive, with the match marked in the excerpt', () async {
      final id = search.begin();
      final hits = await search.searchContains('ATTACK', id: id);
      expect(hits, hasLength(1));
      final hit = hits.single;
      expect(hit.path, 'apple.md');
      expect(hit.snippet, contains('<mark>attack</mark>'));
      expect(hit.snippet, endsWith('…'));
    });

    test('LIKE wildcards in the pattern are literal', () async {
      final id = search.begin();
      expect(await search.searchContains('%', id: id), isEmpty);
      expect(await search.searchContains('_', id: id), isEmpty);
      // A real underscore never matches as a wildcard either.
      final real = await search.searchContains('quick', id: id);
      expect(real.map((h) => h.path), contains('apple.md'));
    });

    test('empty pattern returns nothing; superseded result dropped', () async {
      final early = search.begin();
      final late = search.begin();
      expect(await search.searchContains('', id: late), isEmpty);
      expect(await search.searchContains('zebra', id: early), isEmpty);
      expect(await search.searchContains('zebra', id: late), isNotEmpty);
    });
  });
}
