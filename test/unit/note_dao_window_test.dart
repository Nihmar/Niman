// #1200: the reads the windowed tree stands on — a row's rank among its
// siblings, a page before a row, a page at an offset, a count and the first
// name that starts with something — all agree with the folder read whole,
// in every sort.
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/name_sort_key.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/db/dao.dart';
import 'package:niman/src/db/index_database.dart';

import '../fakes/fake_library_session.dart';

/// Names that make every tie a cursor has to break: case, marks, numbers,
/// a name that folds to two letters.
final _names = <String>[
  'Alpha',
  'alpha',
  'alpha2',
  'alpha10',
  'alpha010',
  'Beta',
  'beta',
  'Émile',
  'emile',
  'Emilia',
  'Straße',
  'strasse',
  'zed',
  'Zed',
  'n1',
  'n2',
  'n10',
  'n11',
  'n100',
  'a1b',
  'a10b',
  for (var i = 0; i < 29; i++) 'note$i',
];

/// The prefixes the type-ahead is asked for, as `foldName` folds them.
const _prefixes = <String>[
  '',
  'a',
  'alpha',
  'alpha1',
  'alpha2',
  'alpha0',
  'e',
  'emi',
  'emile',
  'n',
  'n1',
  'n10',
  'note',
  'note2',
  'strass',
  'z',
  'a1',
  'nothing',
  '9',
];

/// The reads under test, from whichever source answers them.
final class _Reads {
  new({
    required this.children,
    required this.count,
    required this.rank,
    required this.page,
    required this.at,
    required this.starting,
  });

  final Future<List<Note>> Function(TreeSort sort) children;
  final Future<int> Function() count;
  final Future<int> Function(Note note, TreeSort sort) rank;
  final Future<List<Note>> Function(
    TreeSort sort, {
    required int limit,
    Note? after,
    Note? before,
  })
  page;
  final Future<List<Note>> Function(
    TreeSort sort, {
    required int offset,
    required int limit,
  })
  at;
  final Future<Note?> Function(TreeSort sort, String prefix, Note? after)
  starting;
}

List<String> _paths(Iterable<Note> notes) => [for (final n in notes) n.path];

/// Holds every read in [sorts] to the order [_Reads.children] gives.
void _agreeWithTheWholeFolder(_Reads reads, Iterable<TreeSort> sorts) {
  for (final sort in sorts) {
    test(
      'every read in ${sort.name} agrees with the folder read whole',
      () async {
        final all = await reads.children(sort);
        expect(all.length, greaterThan(40));
        expect(await reads.count(), all.length);

        for (var i = 0; i < all.length; i++) {
          final here = 'row $i (${all[i].path})';
          expect(await reads.rank(all[i], sort), i, reason: 'rank of $here');
          expect(
            _paths(await reads.page(sort, limit: 7, after: all[i])),
            _paths(all.sublist(i + 1, math.min(all.length, i + 8))),
            reason: 'seven after $here',
          );
          expect(
            _paths(await reads.page(sort, limit: 7, before: all[i])),
            _paths(all.sublist(math.max(0, i - 7), i)),
            reason: 'seven before $here',
          );
          expect(
            _paths(await reads.at(sort, offset: i, limit: 7)),
            _paths(all.sublist(i, math.min(all.length, i + 7))),
            reason: 'seven at $here',
          );
        }
        expect(await reads.at(sort, offset: all.length, limit: 7), isEmpty);
      },
    );

    test('the first name starting with a prefix in ${sort.name} is the '
        'first of the folder read whole', () async {
      final all = await reads.children(sort);
      for (final prefix in _prefixes) {
        Note? firstFrom(int start) {
          for (var i = start; i < all.length; i++) {
            if (foldName(all[i].name).startsWith(prefix)) return all[i];
          }
          return null;
        }

        expect(
          (await reads.starting(sort, prefix, null))?.path,
          firstFrom(0)?.path,
          reason: '"$prefix" from the top',
        );
        for (var i = 0; i < all.length; i++) {
          expect(
            (await reads.starting(sort, prefix, all[i]))?.path,
            firstFrom(i + 1)?.path,
            reason: '"$prefix" after ${all[i].path}',
          );
        }
      }
    });
  }
}

void main() {
  group('NoteDao', () {
    late IndexDatabase db;
    late NoteDao dao;

    setUp(() async {
      db = IndexDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      dao = NoteDao(db);
      // Folders among the files, and times and sizes that repeat.
      for (var i = 0; i < _names.length; i++) {
        await db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                path: _names[i],
                parent: 0,
                name: _names[i],
                nameKey: nameSortKey(_names[i]),
                isDir: i % 4 == 0,
                size: i % 3,
                modified: DateTime(2026, 1, 1 + i % 4),
                created: DateTime(2026, 2, 1 + i % 5),
              ),
            );
      }
      // Rows of another folder must not leak into a read.
      for (var i = 0; i < 5; i++) {
        await db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                path: 'other/alpha$i',
                parent: 99,
                name: 'alpha$i',
                nameKey: nameSortKey('alpha$i'),
                isDir: false,
                size: 0,
                modified: DateTime(2026),
                created: DateTime(2026),
              ),
            );
      }
    });

    final reads = _Reads(
      children: (sort) => dao.children(0, sort: sort),
      count: () => dao.childCount(0),
      rank: (note, sort) => dao.rankOf(note, sort: sort),
      page: (sort, {required limit, after, before}) => dao.childrenPage(
        0,
        limit: limit,
        sort: sort,
        after: after,
        before: before,
      ),
      at: (sort, {required offset, required limit}) =>
          dao.childrenAt(0, offset: offset, limit: limit, sort: sort),
      starting: (sort, prefix, after) =>
          dao.firstChildStartingWith(0, prefix, sort: sort, after: after),
    );
    _agreeWithTheWholeFolder(reads, TreeSort.values);

    test('a folder with no child counts none and has nothing around', () async {
      expect(await dao.childCount(1234), 0);
      expect(await dao.childrenAt(1234, offset: 0, limit: 5), isEmpty);
      expect(await dao.firstChildStartingWith(1234, 'a'), isNull);
    });

    test('a page after and a page before together is an error', () async {
      final first = (await dao.children(0)).first;
      expect(
        () => dao.childrenPage(0, limit: 3, after: first, before: first),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the type-ahead folds case and marks as the tree does', () async {
      // `Émile`, `emile` and `Emilia` all start with `emi`, whatever the
      // case or the accent they were written with.
      final hit = await dao.firstChildStartingWith(0, foldName('ÉMI'));
      expect(hit?.name, anyOf('Émile', 'emile', 'Emilia'));
      expect(foldName(hit!.name), startsWith('emi'));
      // `ß` is two letters: `strass` finds `Straße`.
      final sharp = await dao.firstChildStartingWith(0, foldName('STRASS'));
      expect(sharp?.name, anyOf('Straße', 'strasse'));
    });

    test('a prefix ending in digits finds the numbers it starts', () async {
      // `alpha1` starts `alpha10` and `alpha010`? No: `alpha010` is the
      // number 10 written with a zero, and folds to `alpha010`.
      final names = [
        for (final n in await dao.children(0))
          if (foldName(n.name).startsWith('alpha1')) n.name,
      ];
      expect(names, ['alpha10']);
      final hit = await dao.firstChildStartingWith(0, 'alpha1');
      expect(hit?.name, 'alpha10');
    });
  });

  group('FakeLibrarySession', () {
    late FakeLibrarySession session;

    setUp(() async {
      session = FakeLibrarySession();
      addTearDown(() async {
        await session.close();
        await session.dispose();
      });
      await session.open('/lib', create: false);
      for (var i = 0; i < _names.length; i++) {
        if (i % 4 == 0) {
          await session.createFolder(parentPath: '', name: _names[i]);
        } else {
          await session.createNote(parentPath: '', name: _names[i]);
          session.setNoteMetrics(
            '${_names[i]}.md',
            size: i % 3,
            modified: DateTime(2026, 1, 1 + i % 4),
            created: DateTime(2026, 2, 1 + i % 5),
          );
        }
      }
    });

    _agreeWithTheWholeFolder(
      _Reads(
        children: (sort) => session.children(0, sort: sort),
        count: () => session.childCount(0),
        rank: (note, sort) => session.rankOf(note, sort: sort),
        page: (sort, {required limit, after, before}) => session.childrenPage(
          0,
          limit: limit,
          sort: sort,
          after: after,
          before: before,
        ),
        at: (sort, {required offset, required limit}) =>
            session.childrenAt(0, offset: offset, limit: limit, sort: sort),
        starting: (sort, prefix, after) =>
            session.firstChildStartingWith(0, prefix, sort: sort, after: after),
      ),
      [TreeSort.nameAsc, TreeSort.nameDesc, TreeSort.modifiedDesc],
    );
  });
}
