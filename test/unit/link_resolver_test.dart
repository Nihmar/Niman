// T-M3-02 AC: the resolver resolves exact stem → shortest unique path prefix
// → ambiguous candidate list, in O(log n) over the stems index; aliases go
// through the same table (source `alias`).
import 'package:copist/src/db/database.dart';
import 'package:copist/src/links/resolver.dart';
import 'package:drift/drift.dart' show InsertMode;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CopistDatabase db;
  late LinkResolver resolver;

  Future<Note> addNote(
    String path, {
    String? stem,
    String source = 'file',
  }) async {
    final name = path.split('/').last;
    final id = await db
        .into(db.notes)
        .insert(
          NotesCompanion.insert(
            path: path,
            parent: 0,
            name: name,
            isDir: false,
            size: 1,
            modified: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
    if (stem != null) {
      await db
          .into(db.noteStems)
          .insert(
            NoteStemsCompanion.insert(stem: stem, noteId: id, source: source),
            mode: InsertMode.insertOrIgnore,
          );
    }
    return (await db.select(db.notes).get()).firstWhere((n) => n.id == id);
  }

  setUp(() async {
    db = CopistDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    resolver = LinkResolver(db);
  });

  test('unique stem resolves to the single note', () async {
    final note = await addNote('My Note.md', stem: 'my note');
    final r = await resolver.resolveWiki('My Note');
    expect(r, isA<ResolvedNote>());
    expect((r as ResolvedNote).note.id, note.id);
  });

  test('resolution is case-insensitive', () async {
    final note = await addNote('note.md', stem: 'note');
    final r = await resolver.resolveWiki('NOTE');
    expect((r as ResolvedNote).note.id, note.id);
    final r2 = await resolver.resolveWiki('NoTe.Md');
    expect((r2 as ResolvedNote).note.id, note.id);
  });

  test('unicode stems resolve', () async {
    final note = await addNote('日本語.md', stem: '日本語');
    final r = await resolver.resolveWiki('日本語');
    expect((r as ResolvedNote).note.id, note.id);
  });

  test('ambiguous bare stem returns candidates, shortest path first', () async {
    await addNote('a/note.md', stem: 'note');
    await addNote('b/note.md', stem: 'note');
    final r = await resolver.resolveWiki('note');
    expect(r, isA<AmbiguousNote>());
    final amb = r as AmbiguousNote;
    expect(amb.candidates.map((n) => n.path), ['a/note.md', 'b/note.md']);
    // Shortest path first: same length → alphabetical, so `a/` wins.
    expect(amb.candidates.first.path, 'a/note.md');
  });

  test('a path-qualified target disambiguates same-stem notes', () async {
    await addNote('a/note.md', stem: 'note');
    await addNote('b/note.md', stem: 'note');
    final r = await resolver.resolveWiki('a/note');
    expect(r, isA<ResolvedNote>());
    expect((r as ResolvedNote).note.path, 'a/note.md');
  });

  test('an unambiguous shorter prefix wins over longer paths', () async {
    // A bare stem with a single note anywhere resolves directly.
    final note = await addNote('x/y/Nested.md', stem: 'nested');
    final r = await resolver.resolveWiki('Nested');
    expect((r as ResolvedNote).note.id, note.id);
    // And the fully-qualified form works too.
    final r2 = await resolver.resolveWiki('x/y/nested');
    expect((r2 as ResolvedNote).note.id, note.id);
  });

  test('suffix match never crosses a folder boundary', () async {
    await addNote('xa/note.md', stem: 'note');
    await addNote('note.md', stem: 'note');
    // `[[a/note]]` must not claim `xa/note.md`.
    final r = await resolver.resolveWiki('a/note');
    expect(r, isA<UnresolvedNote>());
  });

  test('alias source rows resolve like file stems', () async {
    final note = await addNote('Real Name.md', stem: 'real name');
    await db
        .into(db.noteStems)
        .insert(
          NoteStemsCompanion.insert(
            stem: 'nickname',
            noteId: note.id,
            source: 'alias',
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final r = await resolver.resolveWiki('nickname');
    expect((r as ResolvedNote).note.id, note.id);
  });

  test('unknown targets are unresolved', () async {
    await addNote('note.md', stem: 'note');
    expect(await resolver.resolveWiki('missing'), isA<UnresolvedNote>());
    expect(await resolver.resolveWiki(''), isA<UnresolvedNote>());
    expect(await resolver.resolveWiki('a/none'), isA<UnresolvedNote>());
  });

  group('resolveMarkdown', () {
    test('http(s) and other schemes are external', () async {
      expect(
        await resolver.resolveMarkdown('https://example.com/x'),
        isA<ExternalLink>(),
      );
      expect(
        await resolver.resolveMarkdown('http://x.y/z#frag'),
        isA<ExternalLink>(),
      );
    });

    test('a # anchor is local', () async {
      final r = await resolver.resolveMarkdown('#My Heading');
      expect(r, isA<LocalAnchor>());
      expect((r as LocalAnchor).heading, 'My Heading');
    });

    test('relative .md paths resolve (with ./ and #fragment)', () async {
      await addNote('docs/Deep Note.md', stem: 'deep note');
      var r = await resolver.resolveMarkdown('./docs/Deep Note.md');
      expect((r as ResolvedNote).note.path, 'docs/Deep Note.md');
      r = await resolver.resolveMarkdown('docs/Deep Note.md#Heading');
      expect(r, isA<ResolvedNote>());
      // The fragment is normalized (lowercased) like the rest of the
      // target; the heading lookup slugs it, so case does not matter.
      expect((r as ResolvedNote).heading, 'heading');
    });

    test('non-md hrefs are unresolved', () async {
      expect(await resolver.resolveMarkdown('img.png'), isA<UnresolvedNote>());
      expect(
        await resolver.resolveMarkdown('mailto:a@b.c'),
        isA<UnresolvedNote>(),
      );
      expect(await resolver.resolveMarkdown(''), isA<UnresolvedNote>());
    });
  });
}
