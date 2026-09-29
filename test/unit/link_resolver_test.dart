// T-M3-02 AC: the resolver resolves exact stem → shortest unique path prefix
// → ambiguous candidate list, in O(log n) over the stems index; aliases go
// through the same table (source `alias`).
import 'package:drift/drift.dart' show InsertMode;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/resolver.dart';

void main() {
  late IndexDatabase db;
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
    db = IndexDatabase(NativeDatabase.memory());
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

  test(
    'a qualified target with one candidate is dead, not wrong (#330)',
    () async {
      await addNote('xa/note.md', stem: 'note');
      // The only `note` in the library is not at `a/`, so the link is dead —
      // it used to resolve to `xa/note.md` because the single-candidate
      // shortcut ran before the path was looked at.
      expect(await resolver.resolveWiki('a/note'), isA<UnresolvedNote>());
    },
  );

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

  // #491: `sanitizeName` moves a Windows device stem aside with a `_` on
  // every platform, so the note `[[Aux]]` creates is `_Aux.md`. The
  // resolver answers to the same name, or the link stays dead, the
  // dead-link offer repeats and makes `_Aux_1.md`.
  group('reserved device stems', () {
    test('a bare reserved stem resolves to the note it made', () async {
      final note = await addNote('_Aux.md', stem: '_aux');
      expect(
        await resolver.resolveWiki('Aux'),
        isA<ResolvedNote>().having((r) => r.note.id, 'note', note.id),
      );
      expect(
        await resolver.resolveWiki('_Aux'),
        isA<ResolvedNote>().having((r) => r.note.id, 'note', note.id),
      );
    });

    test('a path-qualified reserved stem resolves, batch too', () async {
      final note = await addNote('Sub/_Aux.md', stem: '_aux');
      expect(
        await resolver.resolveWiki('Sub/Aux'),
        isA<ResolvedNote>().having((r) => r.note.id, 'note', note.id),
      );
      final batch = await resolver.resolveBatch(['Sub/Aux.md']);
      expect(
        batch['Sub/Aux.md'],
        isA<ResolvedNote>().having((r) => r.note.id, 'note', note.id),
      );
    });

    test('a library that really holds an Aux.md keeps it', () async {
      final note = await addNote('Aux.md', stem: 'aux');
      expect(
        await resolver.resolveWiki('Aux'),
        isA<ResolvedNote>().having((r) => r.note.id, 'note', note.id),
      );
    });
  });

  // A link written on Windows may carry a single `\` between its folders;
  // it is a separator, not a character of the name.
  test('a backslash separates the folders of a target', () async {
    final a = await addNote('a/note.md', stem: 'note');
    await addNote('b/note.md', stem: 'note');
    expect(
      await resolver.resolveWiki(r'a\note'),
      isA<ResolvedNote>().having((r) => r.note.id, 'note', a.id),
    );
    expect(
      await resolver.resolveMarkdown(r'.\a\note.md'),
      isA<ResolvedNote>().having((r) => r.note.id, 'note', a.id),
    );
    final batch = await resolver.resolveBatch([r'a\note.md']);
    expect(
      batch[r'a\note.md'],
      isA<ResolvedNote>().having((r) => r.note.id, 'note', a.id),
    );
  });

  test('unknown targets are unresolved', () async {
    await addNote('note.md', stem: 'note');
    expect(await resolver.resolveWiki('missing'), isA<UnresolvedNote>());
    expect(await resolver.resolveWiki(''), isA<UnresolvedNote>());
    expect(await resolver.resolveWiki('a/none'), isA<UnresolvedNote>());
  });

  // #491: a path is read the way Markdown reads it. `..` and `.` walk from
  // the folder of the note the link is written in; a leading `/` is the
  // library root; either names exactly the path it ends at, so what climbs
  // out of the library names nothing, and neither collapses into a bare stem
  // that the one-candidate shortcut would hand to an unrelated note (#330).
  group('relative and rooted paths', () {
    Matcher opens(Note note) =>
        isA<ResolvedNote>().having((r) => r.note.id, 'note', note.id);

    // Without a linking note the library root stands in: what `..` climbs
    // past it is dropped, as it always was.
    test('without a source they end at the path they name', () async {
      final note = await addNote('Notes/a.md', stem: 'a');
      for (final form in ['../Notes/a', '/Notes/a', 'sub/../Notes/a']) {
        expect(await resolver.resolveWiki(form), opens(note), reason: form);
        expect(
          await resolver.resolveMarkdown('$form.md'),
          opens(note),
          reason: '$form.md',
        );
      }
    });

    test('a `..` walks from the folder of the linking note', () async {
      final deep = await addNote('Deep/Notes/a.md', stem: 'a');
      final far = await addNote('Notes/a.md', stem: 'a');
      const from = 'Deep/Sub/b.md';
      expect(
        await resolver.resolveMarkdown('../Notes/a.md', from: from),
        opens(deep),
      );
      expect(await resolver.resolveWiki('../Notes/a', from: from), opens(deep));
      expect(
        await resolver.resolveMarkdown('../../Notes/a.md', from: from),
        opens(far),
      );
      expect(
        await resolver.resolveMarkdown('../Notes/a.md', from: 'Other/Sub/b.md'),
        isA<UnresolvedNote>(),
        reason: 'Notes/a.md is there, but that is not where the link points',
      );
    });

    test('the sole candidate is followed from where the link is', () async {
      final note = await addNote('Notes/a.md', stem: 'a');
      expect(
        await resolver.resolveMarkdown('../Notes/a.md', from: 'Sub/b.md'),
        opens(note),
      );
      expect(
        await resolver.resolveMarkdown('./../Notes/a.md', from: 'Sub/b.md'),
        opens(note),
      );
      expect(
        await resolver.resolveMarkdown('x/../../Notes/a.md', from: 'Sub/b.md'),
        opens(note),
      );
    });

    test('a leading `/` names the library root, not a tail', () async {
      final root = await addNote('docs/a.md', stem: 'a');
      await addNote('x/docs/a.md', stem: 'a');
      for (final from in [null, 'Sub/b.md', 'x/b.md']) {
        expect(
          await resolver.resolveMarkdown('/docs/a.md', from: from),
          opens(root),
          reason: '$from',
        );
        expect(
          await resolver.resolveWiki('/docs/a', from: from),
          opens(root),
          reason: '$from',
        );
      }
    });

    test('a rooted bare name is the root one, or nothing', () async {
      final root = await addNote('a.md', stem: 'a');
      await addNote('Sub/a.md', stem: 'a');
      expect(await resolver.resolveMarkdown('/a.md'), opens(root));
      expect(
        await resolver.resolveMarkdown('/a.md', from: 'Sub/b.md'),
        opens(root),
      );
      expect(await resolver.resolveWiki('/a'), opens(root));
    });

    test('what climbs out of the library names nothing (#330)', () async {
      await addNote('xa/note.md', stem: 'note');
      const forms = ['/note', '../note', 'sub/../../note', '/../note'];
      for (final form in forms) {
        for (final from in [null, 'b.md', 'Sub/b.md']) {
          expect(
            await resolver.resolveWiki(form, from: from),
            isA<UnresolvedNote>(),
            reason: '[[$form]] from $from: the only note is at xa/',
          );
          expect(
            await resolver.resolveMarkdown('$form.md', from: from),
            isA<UnresolvedNote>(),
            reason: '[$form.md] from $from',
          );
        }
      }
      expect(
        await resolver.resolveMarkdown('../note.md', from: 'b.md'),
        isA<UnresolvedNote>(),
      );
      // The root's own `note` is not a way out of the library either.
      await addNote('note.md', stem: 'note');
      expect(
        await resolver.resolveMarkdown('../note.md', from: 'b.md'),
        isA<UnresolvedNote>(),
        reason: 'one level above the root is not the root',
      );
    });

    test('a plain path is tried beside the linking note first', () async {
      final root = await addNote('a.md', stem: 'a');
      final beside = await addNote('Sub/a.md', stem: 'a');
      await addNote('Other/a.md', stem: 'a');
      expect(
        await resolver.resolveMarkdown('a.md', from: 'Sub/b.md'),
        opens(beside),
      );
      expect(
        await resolver.resolveMarkdown('./a.md#Top', from: 'Sub/b.md'),
        isA<ResolvedNote>()
            .having((r) => r.note.id, 'note', beside.id)
            .having((r) => r.heading, 'heading', 'Top'),
      );
      // From the root the note beside is the root one.
      expect(await resolver.resolveMarkdown('a.md', from: 'b.md'), opens(root));
      // Nothing beside it: the name still finds its note, as before.
      expect(
        await resolver.resolveMarkdown('a.md', from: 'Elsewhere/b.md'),
        isA<AmbiguousNote>(),
      );
      // A wikilink is a name, not a path: it keeps the picker.
      expect(
        await resolver.resolveWiki('a', from: 'Sub/b.md'),
        isA<AmbiguousNote>(),
      );
    });

    test('a folder in the path is tried beside the note too', () async {
      await addNote('x/n.md', stem: 'n');
      final beside = await addNote('Sub/x/n.md', stem: 'n');
      expect(
        await resolver.resolveMarkdown('x/n.md', from: 'Sub/b.md'),
        opens(beside),
      );
    });

    test('the batch resolution follows the single one', () async {
      final deep = await addNote('Deep/Notes/a.md', stem: 'a');
      final rooted = await addNote('docs/c.md', stem: 'c');
      final beside = await addNote('Sub/d.md', stem: 'd');
      await addNote('d.md', stem: 'd');
      await addNote('xa/note.md', stem: 'note');
      LinkQuery q(String target, String from, {bool markdown = true}) =>
          (target: target, from: from, markdown: markdown);
      final queries = [
        q('../Notes/A.md', 'Deep/Sub/b.md'),
        q('../Notes/a', 'Deep/Sub/b.md', markdown: false),
        q('/docs/c.md', 'x/b.md'),
        q('d.md', 'Sub/b.md'),
        q('d', 'Sub/b.md', markdown: false),
        q('../note.md', 'b.md'),
        q('/note', 'b.md', markdown: false),
      ];
      final batch = await resolver.resolveQueries(queries);
      expect(batch[queries[0]], opens(deep));
      expect(batch[queries[1]], opens(deep));
      expect(batch[queries[2]], opens(rooted));
      expect(batch[queries[3]], opens(beside));
      expect(batch[queries[4]], isA<AmbiguousNote>());
      expect(batch[queries[5]], isA<UnresolvedNote>());
      expect(batch[queries[6]], isA<UnresolvedNote>());
    });

    test('the same target from two notes resolves for each', () async {
      final one = await addNote('One/a.md', stem: 'a');
      final two = await addNote('Two/a.md', stem: 'a');
      const fromOne = (target: 'a.md', from: 'One/b.md', markdown: true);
      const fromTwo = (target: 'a.md', from: 'Two/b.md', markdown: true);
      final batch = await resolver.resolveQueries([fromOne, fromTwo]);
      expect(batch[fromOne], opens(one));
      expect(batch[fromTwo], opens(two));
    });
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
      // The fragment keeps its case: the heading lookup slugs it, and a
      // place in a book names a file whose name has one (#282).
      expect((r as ResolvedNote).heading, 'Heading');
    });

    test('a path is percent-decoded, as Obsidian writes it', () async {
      await addNote('docs/Deep Note.md', stem: 'deep note');
      final r = await resolver.resolveMarkdown('docs/Deep%20Note.md');
      expect((r as ResolvedNote).note.path, 'docs/Deep Note.md');
      // Text around the escapes is kept as written, whatever it is.
      await addNote('città nota.md', stem: 'città nota');
      final plain = await resolver.resolveMarkdown('città%20nota.md');
      expect((plain as ResolvedNote).note.path, 'città nota.md');
    });

    test(
      'a file that is not a note resolves, its place along (#282)',
      () async {
        await addNote('Books/My Book.pdf', stem: 'my book.pdf');
        final r = await resolver.resolveMarkdown('Books/My%20Book.pdf#page=34');
        expect((r as ResolvedNote).note.path, 'Books/My Book.pdf');
        expect(r.heading, 'page=34');
        final epub = await resolver.resolveMarkdown(
          'Books/My%20Book.pdf#chapter=OEBPS%2FCh1.xhtml&line=4',
        );
        expect(
          (epub as ResolvedNote).heading,
          'chapter=OEBPS%2FCh1.xhtml&line=4',
        );
      },
    );

    test('a path with no extension still names no file', () async {
      await addNote('Notes.md', stem: 'notes');
      expect(await resolver.resolveMarkdown('Notes'), isA<UnresolvedNote>());
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
