import 'dart:io';

import 'package:copist/src/db/database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.current.createTemp('copist_migrate_');
    dbFile = File('${tempDir.path}/copist.db');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test(
    'v1 databases gain debug_logs_enabled on upgrade, keeping data',
    () async {
    // Build a v1-shaped file: create the database at v4, then rewind the
    // schema version and drop the columns v1 never had.
    {
      final db = CopistDatabase(NativeDatabase(dbFile));
      await db.customStatement('PRAGMA user_version = 1');
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN debug_logs_enabled',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN line_numbers',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN editor_autofocus',
      );
      await db.customStatement(
        "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
      );
      await db.close();
    }

    final db = CopistDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.appSettings).get()).single;
    expect(row.id, 1);
    expect(row.libraryPath, '/old/root');
    expect(row.debugLogsEnabled, true);
    expect(row.lineNumbers, true);
    expect(row.editorAutofocus, false);
    await db.close();
  });

  test(
    'v2 databases gain line_numbers on upgrade, persisting old rows',
    () async {
    // Build a v2-shaped file: create the database at v4, then rewind the
    // schema version and drop the columns v2 never had.
    {
      final db = CopistDatabase(NativeDatabase(dbFile));
      await db.customStatement('PRAGMA user_version = 2');
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN line_numbers',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN editor_autofocus',
      );
      await db.customStatement(
        "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
      );
      await db.close();
    }

    final db = CopistDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.appSettings).get()).single;
    expect(row.id, 1);
    expect(row.libraryPath, '/old/root');
    expect(row.lineNumbers, true);
    expect(row.editorAutofocus, false);
    expect(row.debugLogsEnabled, true);
    await db.close();
  });

  test(
    'v3 databases gain editor_autofocus on upgrade, keeping values',
    () async {
    // Build a v3-shaped file: create the database at v4, then rewind the
    // schema version and drop the column v3 never had.
    {
      final db = CopistDatabase(NativeDatabase(dbFile));
      await db.customStatement('PRAGMA user_version = 3');
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN editor_autofocus',
      );
      await db.customStatement(
        "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
      );
      await db.close();
    }

    final db = CopistDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.appSettings).get()).single;
    expect(row.id, 1);
    expect(row.libraryPath, '/old/root');
    expect(row.lineNumbers, true);
    expect(row.editorAutofocus, false);
    await db.close();
  });
}
