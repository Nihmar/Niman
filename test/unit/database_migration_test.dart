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
      // Build a v1-shaped file: create the database at v5, then rewind the
      // schema version and drop the columns v1 never had.
      {
        final db = CopistDatabase(NativeDatabase(dbFile));
        await db.customStatement('PRAGMA user_version = 1');
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN language',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
        );
        await db.customStatement(
          'ALTER TABLE library_settings DROP COLUMN list_note_folder',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN link_type',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN indent_width',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN debug_logs_enabled',
        );
        await db.customStatement(
          'ALTER TABLE library_settings DROP COLUMN quick_note_path',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN line_numbers',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN editor_autofocus',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN preview_mode',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN split_ratio',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN tree_sort',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN reminder_show_tokens',
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
      expect(row.previewMode, 'auto');
      expect(row.splitRatio, 0.55);
      await db.close();
    },
  );

  test(
    'v2 databases gain line_numbers on upgrade, persisting old rows',
    () async {
      // Build a v2-shaped file: create the database at v5, then rewind the
      // schema version and drop the columns v2 never had.
      {
        final db = CopistDatabase(NativeDatabase(dbFile));
        await db.customStatement('PRAGMA user_version = 2');
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN language',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
        );
        await db.customStatement(
          'ALTER TABLE library_settings DROP COLUMN list_note_folder',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN link_type',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN indent_width',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN line_numbers',
        );
        await db.customStatement(
          'ALTER TABLE library_settings DROP COLUMN quick_note_path',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN editor_autofocus',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN preview_mode',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN split_ratio',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN tree_sort',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN reminder_show_tokens',
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
    },
  );

  test(
    'v3 databases gain editor_autofocus on upgrade, keeping values',
    () async {
      // Build a v3-shaped file: create the database at v5, then rewind the
      // schema version and drop the columns v3 never had.
      {
        final db = CopistDatabase(NativeDatabase(dbFile));
        await db.customStatement('PRAGMA user_version = 3');
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN language',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
        );
        await db.customStatement(
          'ALTER TABLE library_settings DROP COLUMN list_note_folder',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN link_type',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN indent_width',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN editor_autofocus',
        );
        await db.customStatement(
          'ALTER TABLE library_settings DROP COLUMN quick_note_path',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN preview_mode',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN split_ratio',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN tree_sort',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN reminder_show_tokens',
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
      expect(row.previewMode, 'auto');
      expect(row.splitRatio, 0.55);
      await db.close();
    },
  );

  test('v4 databases gain preview_mode and split_ratio on upgrade, keeping '
      'values', () async {
    // Build a v4-shaped file: create the database at v5, then rewind the
    // schema version and drop the columns v4 never had.
    {
      final db = CopistDatabase(NativeDatabase(dbFile));
      await db.customStatement('PRAGMA user_version = 4');
      await db.customStatement('ALTER TABLE app_settings DROP COLUMN language');
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
      );
      await db.customStatement(
        'ALTER TABLE library_settings DROP COLUMN list_note_folder',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN link_type',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN indent_width',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN preview_mode',
      );
      await db.customStatement(
        'ALTER TABLE library_settings DROP COLUMN quick_note_path',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN split_ratio',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN tree_sort',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN reminder_show_tokens',
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
    expect(row.previewMode, 'auto');
    expect(row.splitRatio, 0.55);
    await db.close();
  });

  test('v5 databases gain quick_note_path on upgrade, keeping library '
      'settings', () async {
    // Build a v5-shaped file: create the database at v6, rewind the schema
    // version, and drop the column v5 never had.
    {
      final db = CopistDatabase(NativeDatabase(dbFile));
      await db.customStatement('PRAGMA user_version = 5');
      await db.customStatement('ALTER TABLE app_settings DROP COLUMN language');
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
      );
      await db.customStatement(
        'ALTER TABLE library_settings DROP COLUMN list_note_folder',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN link_type',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN indent_width',
      );
      await db.customStatement(
        'ALTER TABLE library_settings DROP COLUMN quick_note_path',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN tree_sort',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN reminder_show_tokens',
      );
      await db.customStatement(
        'INSERT INTO library_settings (path, trash_enabled, '
        "history_versions) VALUES ('/lib', 1, 10)",
      );
      await db.close();
    }

    final db = CopistDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.librarySettings).get()).single;
    expect(row.path, '/lib');
    expect(row.trashEnabled, true);
    expect(row.historyVersions, 10);
    expect(row.quickNotePath, isNull);
    await db.close();
  });

  test('v6 databases gain tree_sort on upgrade, keeping values', () async {
    // Build a v6-shaped file: create the database at v7, rewind the schema
    // version, and drop the column v6 never had.
    {
      final db = CopistDatabase(NativeDatabase(dbFile));
      await db.customStatement('PRAGMA user_version = 6');
      await db.customStatement('ALTER TABLE app_settings DROP COLUMN language');
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
      );
      await db.customStatement(
        'ALTER TABLE library_settings DROP COLUMN list_note_folder',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN link_type',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN indent_width',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN tree_sort',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN reminder_show_tokens',
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
    expect(row.treeSort, 'nameAsc');
    await db.close();
  });

  test('v7 databases gain the M3 tables and notes_fts on upgrade, keeping '
      'app_settings', () async {
    // Build a v7-shaped file: create the database at v8, rewind the schema
    // version, and drop the tables v7 never had.
    {
      final db = CopistDatabase(NativeDatabase(dbFile));
      await db.customStatement('PRAGMA user_version = 7');
      await db.customStatement('ALTER TABLE app_settings DROP COLUMN language');
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
      );
      await db.customStatement(
        'ALTER TABLE library_settings DROP COLUMN list_note_folder',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN link_type',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN indent_width',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN reminder_show_tokens',
      );
      await db.customStatement('DROP TABLE IF EXISTS notes_fts');
      await db.customStatement('DROP TABLE IF EXISTS note_links');
      await db.customStatement('DROP TABLE IF EXISTS note_tags');
      await db.customStatement('DROP TABLE IF EXISTS note_stems');
      await db.customStatement('DROP TABLE IF EXISTS tags');
      await db.customStatement(
        "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
      );
      await db.close();
    }

    final db = CopistDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.appSettings).get()).single;
    expect(row.id, 1);
    expect(row.libraryPath, '/old/root');

    // The M3 tables exist and are writable.
    final id = await db
        .into(db.noteStems)
        .insert(
          NoteStemsCompanion.insert(
            stem: 'migrated',
            noteId: 1,
            source: 'file',
          ),
        );
    expect(id, isPositive);
    await db.into(db.tags).insert(TagsCompanion.insert(name: 'migrated'));
    await db
        .into(db.noteTags)
        .insert(
          NoteTagsCompanion.insert(
            tag: 'migrated',
            noteId: 1,
            isFrontmatter: true,
          ),
        );
    await db
        .into(db.noteLinks)
        .insert(
          NoteLinksCompanion.insert(fromNote: 1, toNote: 2, kind: 'wiki'),
        );

    // The FTS index exists and accepts a note row (rowid = notes.id).
    final count = await db
        .customSelect('SELECT count(*) FROM notes_fts WHERE rowid = 1')
        .getSingle();
    expect(count.read<int>('count(*)'), 0);
    await db.customStatement(
      'INSERT INTO notes_fts (rowid, title, body) VALUES (1, ?1, ?2)',
      ['Title', 'Body'],
    );
    await db.close();
  });

  test(
    'v8 databases gain reminder_show_tokens on upgrade, keeping values',
    () async {
      // Build a v8-shaped file: create at v9, rewind, drop the new column.
      {
        final db = CopistDatabase(NativeDatabase(dbFile));
        await db.customStatement('PRAGMA user_version = 8');
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN language',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
        );
        await db.customStatement(
          'ALTER TABLE library_settings DROP COLUMN list_note_folder',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN link_type',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN indent_width',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN reminder_show_tokens',
        );
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, tree_sort) '
          "VALUES (1, '/old/root', 'nameDesc')",
        );
        await db.close();
      }

      final db = CopistDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.libraryPath, '/old/root');
      expect(row.treeSort, 'nameDesc');
      // Off by default: an upgrade must not start putting +project and
      // @context into notifications that never had them.
      expect(row.reminderShowTokens, false);
      await db.close();
    },
  );

  test('v9 databases gain link_type and indent_width on upgrade, keeping '
      'values', () async {
    // Build a v9-shaped file: create at v10, rewind, drop the new columns.
    {
      final db = CopistDatabase(NativeDatabase(dbFile));
      await db.customStatement('PRAGMA user_version = 9');
      await db.customStatement('ALTER TABLE app_settings DROP COLUMN language');
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
      );
      await db.customStatement(
        'ALTER TABLE library_settings DROP COLUMN list_note_folder',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN link_type',
      );
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN indent_width',
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
    // Wikilink by default; a 2-space indent (the pre-M5 default).
    expect(row.linkType, 'wikilink');
    expect(row.indentWidth, 2);
    await db.close();
  });

  test('v10 databases gain list_note_folder on upgrade, keeping library '
      'settings', () async {
    // Build a v10-shaped file: create the database at v11, rewind the
    // schema version, and drop the column v10 never had.
    {
      final db = CopistDatabase(NativeDatabase(dbFile));
      await db.customStatement('PRAGMA user_version = 10');
      await db.customStatement('ALTER TABLE app_settings DROP COLUMN language');
      await db.customStatement(
        'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
      );
      await db.customStatement(
        'ALTER TABLE library_settings DROP COLUMN list_note_folder',
      );
      await db.customStatement(
        'INSERT INTO library_settings (path, trash_enabled, '
        "history_versions) VALUES ('/lib', 1, 10)",
      );
      await db.close();
    }

    final db = CopistDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.librarySettings).get()).single;
    expect(row.path, '/lib');
    expect(row.trashEnabled, true);
    expect(row.historyVersions, 10);
    // The default list folder appears on upgrade.
    expect(row.listNoteFolder, 'Lists');
    await db.close();
  });

  test(
    'v11 databases gain editor_toolbar on upgrade, keeping the settings',
    () async {
      // Build a v11-shaped file: the current schema minus the one column
      // v12 adds.
      {
        final db = CopistDatabase(NativeDatabase(dbFile));
        await db.customStatement('PRAGMA user_version = 11');
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN language',
        );
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN editor_toolbar',
        );
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, indent_width) '
          "VALUES (1, '/old/root', 4)",
        );
        await db.close();
      }

      final db = CopistDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.libraryPath, '/old/root');
      expect(row.indentWidth, 4);
      // Empty is "the shipped toolbar"; nothing to migrate into it.
      expect(row.editorToolbar, '');
      await db.close();
    },
  );

  test(
    'v12 databases gain language on upgrade, keeping the settings',
    () async {
      // Build a v12-shaped file: the current schema minus the one column
      // v13 adds.
      {
        final db = CopistDatabase(NativeDatabase(dbFile));
        await db.customStatement('PRAGMA user_version = 12');
        await db.customStatement(
          'ALTER TABLE app_settings DROP COLUMN language',
        );
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, editor_toolbar) '
          "VALUES (1, '/old/root', 'link,-bold')",
        );
        await db.close();
      }

      final db = CopistDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.libraryPath, '/old/root');
      expect(row.editorToolbar, 'link,-bold');
      // An existing library follows the OS, as it did before the setting
      // existed.
      expect(row.language, 'system');
      await db.close();
    },
  );
}
