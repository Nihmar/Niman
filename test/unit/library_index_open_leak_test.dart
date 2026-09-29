import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' show SqliteException;

/// An index connection whose first query fails with an injected error, and
/// which records its own close so a leak is observable.
class _FailingIndex extends IndexDatabase {
  _FailingIndex(super.e);

  late Object failWith;
  bool closed = false;

  @override
  Selectable<QueryRow> customSelect(
    String query, {
    List<Variable> variables = const [],
    Set<ResultSetImplementation> readsFrom = const {},
  }) {
    throw failWith;
  }

  @override
  Future<void> close() async {
    closed = true;
    await super.close();
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tmp;
  late Directory root;

  setUp(() async {
    tmp = await Directory.current.createTemp('niman_index_leak_');
    root = Directory(p.join(tmp.path, 'library'))..createSync();
    File(p.join(root.path, 'a.md')).writeAsStringSync('a');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<AppDatabase> appDb() async =>
      AppDatabase(NativeDatabase(File(p.join(tmp.path, 'niman.db'))));

  test(
    'a failed open that is not damage closes its index connection',
    () async {
      // #492: `_openIndex` rethrew before `_indexDb` was set, so `_teardown`
      // found nothing to close. A locked file or a full disk left the
      // connection — and its isolate — open.
      final opened = <_FailingIndex>[];
      final controller = LibraryController(
        appDb,
        indexDbFactory: (libraryPath) async {
          final db = _FailingIndex(
            NativeDatabase(File(p.join(tmp.path, 'index.db'))),
          )..failWith = const FileSystemException('no space left on device');
          opened.add(db);
          return db;
        },
        rescanInterval: const Duration(hours: 1),
      );

      await controller.open(root.path, create: false);

      expect(controller.lastError, isNotNull);
      expect(controller.phase, LibraryPhase.none);
      expect(opened, hasLength(1));
      expect(opened.single.closed, isTrue);
      await controller.dispose();
    },
  );

  test('a rebuild whose fresh connection fails closes it too', () async {
    // The damaged path already closed the first connection; the rebuilt one
    // that fails for another reason was left open.
    final opened = <_FailingIndex>[];
    final controller = LibraryController(
      appDb,
      indexDbFactory: (libraryPath) async {
        final db = _FailingIndex(
          NativeDatabase(File(p.join(tmp.path, 'index.db'))),
        );
        db.failWith = opened.isEmpty
            ? SqliteException(message: 'damaged', extendedResultCode: 11)
            : const FileSystemException('no space left on device');
        opened.add(db);
        return db;
      },
      indexFileOf: (libraryPath) async => File(p.join(tmp.path, 'index.db')),
      rescanInterval: const Duration(hours: 1),
    );

    await controller.open(root.path, create: false);

    expect(controller.lastError, isNotNull);
    expect(opened, hasLength(2));
    expect(opened[0].closed, isTrue);
    expect(opened[1].closed, isTrue);
    await controller.dispose();
  });
}
