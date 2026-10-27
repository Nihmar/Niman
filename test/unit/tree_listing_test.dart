// #1200 phase 4: the rows of the note tree by index — the model, the pages
// held, a text recognition sidecar nested within its page and the row being
// made as a virtual one — and what asks the index for a name or reads a range
// of them. The session is the in-memory fake.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/tree_listing.dart';
import 'package:niman/src/ui/tree_name_search.dart';
import 'package:niman/src/ui/tree_pages.dart';
import 'package:niman/src/ui/tree_range_reader.dart';
import 'package:niman/src/ui/visible_tree.dart';

import '../fakes/fake_library_session.dart';

const _pageSize = 10;

void main() {
  late FakeLibrarySession session;
  late TreePages pages;

  setUp(() async {
    session = FakeLibrarySession();
    pages = TreePages(pageSize: _pageSize);
    addTearDown(() async {
      await session.close();
      await session.dispose();
    });
    await session.open('/lib', create: false);
  });

  /// The listing of the rows [expanded] shows, with the pages in [loaded]
  /// held: `(folder path, page)`.
  Future<TreeListing> listing(
    Set<String> expanded, {
    Iterable<(String, int)> loaded = const [],
  }) async {
    final model = await pages.visible(session, expanded, TreeSort.nameAsc);
    for (final (path, page) in loaded) {
      final id = path.isEmpty ? 0 : (await session.find(path))!.id;
      await pages.load(session, id, page, TreeSort.nameAsc);
    }
    return TreeListing(
      session: session,
      model: model,
      pages: pages,
      sort: TreeSort.nameAsc,
    );
  }

  /// The tree flattened the way it was drawn before: each child, then the
  /// rows of an expanded folder.
  Future<List<Note>> flatten(Set<String> expanded, [int parent = 0]) async {
    final out = <Note>[];
    for (final note in await session.children(parent)) {
      out.add(note);
      if (note.isDir && expanded.contains(note.path)) {
        out.addAll(await flatten(expanded, note.id));
      }
    }
    return out;
  }

  /// A root of two folders and notes, the folders holding 25 and 12.
  Future<void> seed() async {
    await session.createFolder(parentPath: '', name: 'alpha');
    await session.createFolder(parentPath: '', name: 'beta');
    for (var i = 0; i < 25; i++) {
      await session.createNote(
        parentPath: 'alpha',
        name: 'a${i.toString().padLeft(2, '0')}',
      );
    }
    for (var i = 0; i < 12; i++) {
      await session.createNote(
        parentPath: 'beta',
        name: 'b${i.toString().padLeft(2, '0')}',
      );
    }
    for (final name in ['mango', 'nectar', 'olive']) {
      await session.createNote(parentPath: '', name: name);
    }
  }

  group('entries', () {
    test(
      'a row is drawn from its page, an unloaded one waits for it',
      () async {
        await seed();
        final rows = await listing({'alpha'}, loaded: [('', 0), ('alpha', 1)]);
        expect(rows.length, 2 + 25 + 3);
        expect(rows.entryAt(0).note?.path, 'alpha');
        expect(rows.entryAt(0).depth, 0);
        // alpha's first page (positions 0 to 9) is not held.
        final waiting = rows.entryAt(1);
        expect(waiting.note, isNull);
        expect(waiting.page, ((await session.find('alpha'))!.id, 0));
        // Its second is: position 10 is the eleventh row under alpha.
        expect(rows.entryAt(11).note?.path, 'alpha/a10.md');
        expect(rows.entryAt(11).depth, 1);
        expect(rows.entryAt(26).note?.path, 'beta');
        expect(rows.entryAt(27).note?.path, 'mango.md');
      },
    );

    test(
      'says where a path is, from the pages held and from the index',
      () async {
        await seed();
        final rows = await listing({'alpha'}, loaded: [('', 0), ('alpha', 1)]);
        expect(rows.modelIndexOfLoaded('alpha/a10.md'), 11);
        expect(rows.modelIndexOfLoaded('alpha/a03.md'), isNull);
        expect(await rows.modelIndexOfPath('alpha/a03.md'), 4);
        expect(
          await rows.modelIndexOfPath('beta/b00.md'),
          isNull,
          reason: 'shut',
        );
        expect(await rows.modelIndexOfPath('nowhere.md'), isNull);
        expect(rows.modelIndexOfLoaded('alpha/a03.md'), 4, reason: 'now held');
      },
    );

    test('a sidecar is drawn under its file within the page', () async {
      await session.seedFile('a.md');
      await session.seedFile('scan.pdf');
      await session.seedFile('scan.ocr.md');
      await session.seedFile('z.md');
      final rows = await listing({}, loaded: [('', 0)]);
      expect(
        [
          for (var i = 0; i < 4; i++)
            (rows.entryAt(i).note?.name, rows.entryAt(i).sidecar),
        ],
        [
          ('a.md', false),
          ('scan.pdf', false),
          ('scan.ocr.md', true),
          ('z.md', false),
        ],
      );
      expect(rows.entryAt(2).depth, 1);
      expect(rows.modelIndexOfLoaded('scan.ocr.md'), 2);
      expect(await rows.modelIndexOfPath('scan.ocr.md'), 2);
    });

    test('a frozen listing keeps the rows its pages had', () async {
      await seed();
      final rows = await listing({}, loaded: [('', 0)]);
      expect(rows.entryAt(0).note, isNotNull);
      rows.freeze();
      pages.forget([VisibleTree.rootId]);
      expect(rows.isFrozen, isTrue);
      expect(rows.entryAt(0).note?.path, 'alpha');
      expect(rows.modelIndexOfLoaded('mango.md'), 2);
    });
  });

  group('the row being made', () {
    test('is one more row, right under its folder', () async {
      await seed();
      final rows = await listing({'alpha'}, loaded: [('', 0)]);
      rows.placeCreating(0, depth: 1);
      expect(rows.length, rows.modelLength + 1);
      expect(rows.entryAt(0).note?.path, 'alpha');
      expect(rows.entryAt(1).creating, isTrue);
      expect(rows.entryAt(1).depth, 1);
      expect(rows.entryAt(1).note, isNull);
      // The rows after it are the model's, one further down the list.
      expect(rows.entryAt(rows.length - 3).note?.path, 'mango.md');
      expect(rows.listIndexOf(0), 0);
      expect(rows.listIndexOf(1), 2);
      expect(rows.modelIndexOf(1), isNull);
      expect(rows.modelIndexOf(2), 1);
      expect(rows.modelIndexOf(0), 0);
      rows.placeCreating(null);
      expect(rows.length, rows.modelLength);
      expect(rows.entryAt(1).creating, isFalse);
    });
  });

  group('a name asked of the index', () {
    test('finds what the visible order puts first, in every range', () async {
      await seed();
      const expanded = {'alpha', 'beta'};
      final rows = await listing(expanded);
      final flat = await flatten(expanded);
      final search = TreeNameSearch(rows);
      for (final prefix in ['a', 'a1', 'b0', 'b1', 'm', 'o', 'q', 'alpha']) {
        for (var start = 0; start < flat.length; start += 7) {
          for (var end = start + 1; end <= flat.length; end += 11) {
            Note? expected;
            for (var i = start; i < end; i++) {
              if (foldName(flat[i].name).startsWith(prefix)) {
                expected = flat[i];
                break;
              }
            }
            final found = await search.firstIn(prefix, start, end);
            expect(
              found?.path,
              expected?.path,
              reason: '"$prefix" in [$start, $end)',
            );
          }
        }
      }
    });
  });

  group('a range read', () {
    test('is the rows between, a page at a time', () async {
      await seed();
      const expanded = {'alpha', 'beta'};
      final rows = await listing(expanded);
      final flat = await flatten(expanded);
      final reader = TreeRangeReader(rows);
      expect(reader.heldPaths(0, flat.length - 1), isNull);
      expect(await reader.paths(0, flat.length - 1), [
        for (final note in flat) note.path,
      ]);
      expect(await reader.paths(13, 40), [
        for (final note in flat.sublist(13, 41)) note.path,
      ]);
      // Reading holds nothing in the pages: they are the screen's alone.
      expect(pages.pageCount, 0);
    });

    test('is read from the pages when they are held', () async {
      await seed();
      final rows = await listing({'beta'}, loaded: [('', 0), ('beta', 0)]);
      final reader = TreeRangeReader(rows);
      expect(reader.heldPaths(0, 3), [
        'alpha',
        'beta',
        'beta/b00.md',
        'beta/b01.md',
      ]);
      expect(reader.heldPaths(0, 13), isNull, reason: 'beta/b10 is page 1');
      expect(await reader.paths(0, 13), hasLength(14));
    });
  });
}
