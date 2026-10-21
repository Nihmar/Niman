import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database_recovery.dart';
import 'package:path/path.dart' as p;

// The settings database of a machine that lost pages of niman.db opened
// without a word and failed at the first query that reached one: the sync
// scheduler's, every minute, so the sync never ran. The open now checks the
// file and starts a new one when sqlite calls it unreadable.
void main() {
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_appdb_recovery_');
    addTearDown(() => dir.delete(recursive: true));
    file = File(p.join(dir.path, 'niman.db'));
  });

  Future<void> seed() async {
    final db = await openAppDatabaseRecovering(file);
    await db.customStatement(
      "INSERT INTO app_settings (id, library_path) VALUES (1, 'kept')",
    );
    await db.close();
  }

  List<File> asides() => dir
      .listSync()
      .whereType<File>()
      .where((f) => p.basename(f.path).contains('.corrupt-'))
      .toList();

  Future<String?> libraryPathOf(File f) async {
    final db = await openAppDatabaseRecovering(f);
    try {
      final rows = await db.select(db.appSettings).get();
      return rows.isEmpty ? null : rows.single.libraryPath;
    } finally {
      await db.close();
    }
  }

  test('a healthy file is opened as it is and nothing is set aside', () async {
    await seed();

    expect(await libraryPathOf(file), 'kept');
    expect(asides(), isEmpty);
  });

  test('a file with zeroed pages is set aside and a new one started', () async {
    await seed();
    final bytes = await file.readAsBytes();
    // Everything after the first page, as the lost pages of the report.
    await file.writeAsBytes([
      ...bytes.sublist(0, 4096),
      ...List<int>.filled(bytes.length - 4096, 0),
    ]);

    final db = await openAppDatabaseRecovering(
      file,
      now: DateTime(2026, 10, 21, 12, 30, 5),
    );
    // The sync scheduler's own query.
    expect(await db.select(db.syncItems).get(), isEmpty);
    await db.close();

    final aside = asides();
    expect(aside, hasLength(1));
    expect(p.basename(aside.single.path), 'niman.db.corrupt-20261021-123005');
    expect(await aside.single.length(), bytes.length);
    expect(await libraryPathOf(file), isNull);
  });

  test('a file that is not a database is set aside', () async {
    await file.writeAsString('this is not a sqlite file, ' * 400);

    final db = await openAppDatabaseRecovering(file);
    expect(await db.select(db.appSettings).get(), isEmpty);
    await db.close();

    expect(asides(), hasLength(1));
  });
}
