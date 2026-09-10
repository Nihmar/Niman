import 'dart:convert';
import 'dart:io';

import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/core/theme.dart';
import 'package:copist/src/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `library_settings` table as it stood through v13, before T-ML-02
/// dropped it. A rewound database has to bring it back itself: the
/// current schema no longer creates it, so `onCreate` leaves nothing to
/// drop columns from.
const _createLibrarySettings =
    'CREATE TABLE library_settings ( '
    'path TEXT NOT NULL PRIMARY KEY, '
    'trash_enabled INTEGER NOT NULL, '
    'history_versions INTEGER NOT NULL, '
    'quick_note_path TEXT, '
    "list_note_folder TEXT NOT NULL DEFAULT 'Lists')";

// The note index as it stood through v14, before T-ML-03 gave every
// library its own file. Column shapes do not matter here — the v15
// migration only drops these tables — but their presence does.
const _createNotes =
    'CREATE TABLE notes ( '
    'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
    'path TEXT NOT NULL UNIQUE, parent INTEGER NOT NULL, '
    'name TEXT NOT NULL, is_dir INTEGER NOT NULL, '
    'size INTEGER NOT NULL, modified INTEGER NOT NULL, sha256 TEXT)';
const _createNoteStems =
    'CREATE TABLE note_stems ( '
    'stem TEXT NOT NULL, note_id INTEGER NOT NULL, source TEXT NOT NULL)';
const _createTags = 'CREATE TABLE tags (name TEXT NOT NULL PRIMARY KEY)';
const _createNoteTags =
    'CREATE TABLE note_tags ( '
    'tag TEXT NOT NULL, note_id INTEGER NOT NULL, '
    'is_frontmatter INTEGER NOT NULL)';
const _createNoteLinks =
    'CREATE TABLE note_links ( '
    'from_note INTEGER NOT NULL, to_note INTEGER NOT NULL, '
    'kind TEXT NOT NULL)';
const _createNotesFts =
    'CREATE VIRTUAL TABLE notes_fts USING fts5(title, body)';

const List<String> _createIndexTables = [
  _createNotes,
  _createNoteStems,
  _createTags,
  _createNoteTags,
  _createNoteLinks,
  _createNotesFts,
];

/// The seven editor settings as `app_settings` columns, before T-ML-10
/// moved them into each library's own file.
const List<String> _editorSettingColumns = [
  'line_numbers BOOLEAN NOT NULL DEFAULT 1',
  'editor_autofocus BOOLEAN NOT NULL DEFAULT 0',
  'reminder_show_tokens BOOLEAN NOT NULL DEFAULT 0',
  "tree_sort TEXT NOT NULL DEFAULT 'nameAsc'",
  "link_type TEXT NOT NULL DEFAULT 'wikilink'",
  'indent_width INTEGER NOT NULL DEFAULT 2',
  "editor_toolbar TEXT NOT NULL DEFAULT ''",
];

/// The names of those tables, for asserting they are gone.
const List<String> _indexTableNames = [
  'notes',
  'note_stems',
  'tags',
  'note_tags',
  'note_links',
  'notes_fts',
];

/// Turns a freshly created (current-schema) database into one shaped like
/// [version], by undoing every schema change made after it.
///
/// One list rather than one per test: a test that forgets an entry does
/// not fail on the migration it is about, it fails on a duplicate-column
/// error somewhere else, and the next schema bump would have to be
/// repeated in every test in the file.
Future<void> _rewindTo(AppDatabase db, int version) async {
  Future<void> drop(String table, String column) =>
      db.customStatement('ALTER TABLE $table DROP COLUMN $column');

  if (version < 18) {
    await drop('app_settings', 'theme_brightness');
    await drop('app_settings', 'theme_palette');
  }
  if (version < 17) {
    // The seven settings v17 hands to the libraries were columns here.
    for (final column in _editorSettingColumns) {
      await db.customStatement('ALTER TABLE app_settings ADD COLUMN $column');
    }
  }
  if (version < 16) await db.customStatement('DROP TABLE known_libraries');
  if (version < 15) {
    for (final statement in _createIndexTables) {
      await db.customStatement(statement);
    }
  }
  if (version < 14) {
    await drop('app_settings', 'legacy_library_settings');
    await db.customStatement(_createLibrarySettings);
  }
  if (version < 13) await drop('app_settings', 'language');
  if (version < 12) await drop('app_settings', 'editor_toolbar');
  if (version < 11) await drop('library_settings', 'list_note_folder');
  if (version < 10) {
    await drop('app_settings', 'link_type');
    await drop('app_settings', 'indent_width');
  }
  if (version < 9) await drop('app_settings', 'reminder_show_tokens');
  if (version < 8) {
    await db.customStatement('DROP TABLE IF EXISTS notes_fts');
    await db.customStatement('DROP TABLE IF EXISTS note_links');
    await db.customStatement('DROP TABLE IF EXISTS note_tags');
    await db.customStatement('DROP TABLE IF EXISTS note_stems');
    await db.customStatement('DROP TABLE IF EXISTS tags');
  }
  if (version < 7) await drop('app_settings', 'tree_sort');
  if (version < 6) await drop('library_settings', 'quick_note_path');
  if (version < 5) {
    await drop('app_settings', 'preview_mode');
    await drop('app_settings', 'split_ratio');
  }
  if (version < 4) await drop('app_settings', 'editor_autofocus');
  if (version < 3) await drop('app_settings', 'line_numbers');
  if (version < 2) await drop('app_settings', 'debug_logs_enabled');
  await db.customStatement('PRAGMA user_version = $version');
}

/// The settings v14 parked on its way out of `library_settings`, keyed by
/// library path.
Future<Map<String, Map<String, Object?>>> _parked(AppDatabase db) async {
  final row = (await db.select(db.appSettings).get()).single;
  if (row.legacyLibrarySettings.isEmpty) return {};
  final decoded = jsonDecode(row.legacyLibrarySettings) as Map<String, Object?>;
  return {
    for (final entry in decoded.entries)
      entry.key: entry.value! as Map<String, Object?>,
  };
}

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
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 1);
        await db.customStatement(
          "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.id, 1);
      expect(row.libraryPath, '/old/root');
      expect(row.debugLogsEnabled, true);
      expect(row.previewMode, 'auto');
      expect(row.splitRatio, 0.55);
      await db.close();
    },
  );

  test(
    'v2 databases gain line_numbers on upgrade, persisting old rows',
    () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 2);
        await db.customStatement(
          "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.id, 1);
      expect(row.libraryPath, '/old/root');
      expect(row.debugLogsEnabled, true);
      await db.close();
    },
  );

  test(
    'v3 databases gain editor_autofocus on upgrade, keeping values',
    () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 3);
        await db.customStatement(
          "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.id, 1);
      expect(row.libraryPath, '/old/root');
      expect(row.previewMode, 'auto');
      expect(row.splitRatio, 0.55);
      await db.close();
    },
  );

  test('v4 databases gain preview_mode and split_ratio on upgrade, keeping '
      'values', () async {
    {
      final db = AppDatabase(NativeDatabase(dbFile));
      await _rewindTo(db, 4);
      await db.customStatement(
        "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
      );
      await db.close();
    }

    final db = AppDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.appSettings).get()).single;
    expect(row.id, 1);
    expect(row.libraryPath, '/old/root');
    expect(row.previewMode, 'auto');
    expect(row.splitRatio, 0.55);
    await db.close();
  });

  test('v5 databases gain quick_note_path on upgrade, keeping library '
      'settings', () async {
    {
      final db = AppDatabase(NativeDatabase(dbFile));
      await _rewindTo(db, 5);
      await db.customStatement(
        'INSERT INTO library_settings (path, trash_enabled, '
        "history_versions) VALUES ('/lib', 1, 10)",
      );
      await db.close();
    }

    // v6 adds the column and v14 carries the row out of the table; the
    // settings themselves survive both.
    final db = AppDatabase(NativeDatabase(dbFile));
    final lib = (await _parked(db))['/lib']!;
    expect(lib['trashEnabled'], true);
    expect(lib['historyVersions'], 10);
    // A row that never chose a quick note parks without the key.
    expect(lib.containsKey('quickNotePath'), isFalse);
    await db.close();
  });

  test('v6 databases gain tree_sort on upgrade, keeping values', () async {
    {
      final db = AppDatabase(NativeDatabase(dbFile));
      await _rewindTo(db, 6);
      await db.customStatement(
        "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
      );
      await db.close();
    }

    final db = AppDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.appSettings).get()).single;
    expect(row.id, 1);
    expect(row.libraryPath, '/old/root');
    await db.close();
  });

  test('v7 databases keep their app_settings across the whole chain', () async {
    // v8 used to create the M3 index tables here. They are the index's
    // business now (T-ML-03), so what this version has to prove is that
    // a database old enough to predate them still arrives with its
    // settings — the only rows in the file that cannot be rebuilt.
    {
      final db = AppDatabase(NativeDatabase(dbFile));
      await _rewindTo(db, 7);
      await db.customStatement(
        "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
      );
      await db.close();
    }

    final db = AppDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.appSettings).get()).single;
    expect(row.id, 1);
    expect(row.libraryPath, '/old/root');
    expect(row.language, 'system');
    await db.close();
  });

  test(
    'v8 databases gain reminder_show_tokens on upgrade, keeping values',
    () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 8);
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, tree_sort) '
          "VALUES (1, '/old/root', 'nameDesc')",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.libraryPath, '/old/root');
      // Off by default: an upgrade must not start putting +project and
      // @context into notifications that never had them.
      await db.close();
    },
  );

  test('v9 databases gain link_type and indent_width on upgrade, keeping '
      'values', () async {
    {
      final db = AppDatabase(NativeDatabase(dbFile));
      await _rewindTo(db, 9);
      await db.customStatement(
        "INSERT INTO app_settings (id, library_path) VALUES (1, '/old/root')",
      );
      await db.close();
    }

    final db = AppDatabase(NativeDatabase(dbFile));
    final row = (await db.select(db.appSettings).get()).single;
    expect(row.id, 1);
    expect(row.libraryPath, '/old/root');
    // Wikilink by default; a 2-space indent (the pre-M5 default).
    await db.close();
  });

  test('v10 databases gain list_note_folder on upgrade, keeping library '
      'settings', () async {
    {
      final db = AppDatabase(NativeDatabase(dbFile));
      await _rewindTo(db, 10);
      await db.customStatement(
        'INSERT INTO library_settings (path, trash_enabled, '
        "history_versions) VALUES ('/lib', 1, 10)",
      );
      await db.close();
    }

    final db = AppDatabase(NativeDatabase(dbFile));
    final lib = (await _parked(db))['/lib']!;
    expect(lib['trashEnabled'], true);
    expect(lib['historyVersions'], 10);
    // The default list folder appears on upgrade, and travels with the
    // rest when v14 empties the table.
    expect(lib['listNoteFolder'], 'Lists');
    await db.close();
  });

  test(
    'v11 databases gain editor_toolbar on upgrade, keeping the settings',
    () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 11);
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, indent_width) '
          "VALUES (1, '/old/root', 4)",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.libraryPath, '/old/root');
      // Empty is "the shipped toolbar"; nothing to migrate into it.
      await db.close();
    },
  );

  test(
    'v12 databases gain language on upgrade, keeping the settings',
    () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 12);
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, editor_toolbar) '
          "VALUES (1, '/old/root', 'link,-bold')",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.libraryPath, '/old/root');
      // An existing library follows the OS, as it did before the setting
      // existed.
      await db.close();
    },
  );

  group('v13 → v14: library_settings is dropped, its rows parked', () {
    test('every row is carried out of the table before it goes', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 13);
        await db.customStatement(
          'INSERT INTO library_settings (path, trash_enabled, '
          'history_versions, quick_note_path, list_note_folder) '
          "VALUES ('/work', 0, 25, 'Inbox/Scratch.md', 'Checklists')",
        );
        await db.customStatement(
          'INSERT INTO library_settings (path, trash_enabled, '
          "history_versions) VALUES ('/personal', 1, 10)",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final parked = await _parked(db);
      expect(parked.keys, unorderedEquals(['/work', '/personal']));
      expect(parked['/work'], {
        'trashEnabled': false,
        'historyVersions': 25,
        'quickNotePath': 'Inbox/Scratch.md',
        'listNoteFolder': 'Checklists',
      });
      expect(parked['/personal'], {
        'trashEnabled': true,
        'historyVersions': 10,
        'listNoteFolder': 'Lists',
      });

      // The table itself is gone.
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name = 'library_settings'",
          )
          .get();
      expect(tables, isEmpty);
      await db.close();
    });

    test('an empty table parks nothing and leaves no app_settings row '
        'behind', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 13);
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      // Nothing to carry: the upgrade must not invent a settings row.
      expect(await db.select(db.appSettings).get(), isEmpty);
      await db.close();
    });

    test('the app settings survive the drop', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 13);
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, language) '
          "VALUES (1, '/old/root', 'it')",
        );
        await db.customStatement(
          'INSERT INTO library_settings (path, trash_enabled, '
          "history_versions) VALUES ('/old/root', 0, 3)",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.libraryPath, '/old/root');
      expect(row.language, 'it');
      expect((await _parked(db))['/old/root']!['historyVersions'], 3);
      await db.close();
    });
  });

  group('v14 → v15: the index leaves the app database', () {
    /// The tables still in [db], of those the index used to own.
    Future<List<String>> indexTables(AppDatabase db) async {
      final rows = await db
          .customSelect('SELECT name FROM sqlite_master')
          .get();
      return rows
          .map((r) => r.read<String>('name'))
          .where(_indexTableNames.contains)
          .toList();
    }

    test('every index table is dropped', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 14);
        expect(await indexTables(db), hasLength(6));
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      // The index is rebuildable, and each library now keeps its own
      // (T-ML-03): these rows are re-derived by the first scan.
      expect(await indexTables(db), isEmpty);
      await db.close();
    });

    test('the settings, which are not rebuildable, survive', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 14);
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, language, '
          "editor_toolbar) VALUES (1, '/old/root', 'it', 'link,-bold')",
        );
        await db.customStatement(
          'INSERT INTO notes (path, parent, name, is_dir, size, modified) '
          "VALUES ('a.md', 0, 'a.md', 0, 1, 0)",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final row = (await db.select(db.appSettings).get()).single;
      expect(row.libraryPath, '/old/root');
      expect(row.language, 'it');
      await db.close();
    });

    test('a database with no index tables upgrades anyway', () async {
      // An install that never got as far as v8 has none of them; the
      // drop must not care.
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        // Rewinding past v8 already removes the M3 tables; `notes` is the
        // one that goes back to v1, so drop that too and leave nothing.
        await _rewindTo(db, 7);
        await db.customStatement('DROP TABLE notes');
        await db.customStatement(
          "INSERT INTO app_settings (id, library_path) VALUES (1, '/old')",
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      expect(
        (await db.select(db.appSettings).get()).single.libraryPath,
        '/old',
      );
      expect(await indexTables(db), isEmpty);
      await db.close();
    });
  });

  group('v15 → v16: the known-library registry appears', () {
    test('the library being resumed is seeded into it', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 15);
        await db.customStatement(
          "INSERT INTO app_settings (id, library_path) VALUES (1, '/lib/Work')",
        );
        await db.close();
      }

      // An upgrade must not land on an empty home screen while a library
      // is open (T-ML-04).
      final db = AppDatabase(NativeDatabase(dbFile));
      final entry = (await db.select(db.knownLibraries).get()).single;
      expect(entry.path, '/lib/Work');
      expect(entry.name, 'Work');
      await db.close();
    });

    test('an install with no library resumes with an empty list', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 15);
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path) VALUES (1, NULL)',
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      expect(await db.select(db.knownLibraries).get(), isEmpty);
      await db.close();
    });
  });

  group('v16 → v17: the editor settings go to the libraries', () {
    test('every known library is handed the current values', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 16);
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, line_numbers, '
          'indent_width, link_type, editor_toolbar) '
          "VALUES (1, '/lib/Work', 0, 6, 'markdown', 'link,-bold')",
        );
        for (final path in ['/lib/Work', '/lib/Personal']) {
          await db.customStatement(
            'INSERT INTO known_libraries (path, name, last_opened) '
            "VALUES ('$path', 'x', 0)",
          );
        }
        await db.close();
      }

      // They were one value for every library; each one now gets its own
      // copy, so nobody's configuration is lost by the move.
      final db = AppDatabase(NativeDatabase(dbFile));
      final parked = await _parked(db);
      expect(parked.keys, unorderedEquals(['/lib/Work', '/lib/Personal']));
      for (final entry in parked.values) {
        expect(entry['lineNumbers'], false);
        expect(entry['indentWidth'], 6);
        expect(entry['linkType'], 'markdown');
        expect(entry['editorToolbar'], 'link,-bold');
      }
      await db.close();
    });

    test('the columns are gone from the table', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 16);
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      final columns = await db
          .customSelect("SELECT name FROM pragma_table_info('app_settings')")
          .get();
      final names = columns.map((r) => r.read<String>('name'));
      expect(names, isNot(contains('line_numbers')));
      expect(names, isNot(contains('editor_toolbar')));
      // The two that follow the screen rather than the library stay.
      expect(names, contains('preview_mode'));
      expect(names, contains('split_ratio'));
      await db.close();
    });

    test('an install with no library parks nothing', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 16);
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path) VALUES (1, NULL)',
        );
        await db.close();
      }

      final db = AppDatabase(NativeDatabase(dbFile));
      expect(await _parked(db), isEmpty);
      await db.close();
    });

    test('what an earlier migration parked is kept', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 13);
        await db.customStatement(
          'INSERT INTO library_settings (path, trash_enabled, '
          "history_versions) VALUES ('/lib/Work', 0, 3)",
        );
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, indent_width) '
          "VALUES (1, '/lib/Work', 6)",
        );
        await db.close();
      }

      // v14 parks the trash toggle, v16 registers the library, v17 adds
      // the editor settings to the same entry rather than replacing it.
      final db = AppDatabase(NativeDatabase(dbFile));
      final entry = (await _parked(db))['/lib/Work']!;
      expect(entry['trashEnabled'], false);
      expect(entry['historyVersions'], 3);
      expect(entry['indentWidth'], 6);
      await db.close();
    });
  });

  group('v17 → v18: the theme appears', () {
    test('an existing install keeps the look it had', () async {
      {
        final db = AppDatabase(NativeDatabase(dbFile));
        await _rewindTo(db, 17);
        await db.customStatement(
          'INSERT INTO app_settings (id, library_path, language) '
          "VALUES (1, '/old/root', 'it')",
        );
        await db.close();
      }

      // The device's brightness and the device's colors: what the app
      // wore before there was anything to choose (T-M6-05).
      final db = AppDatabase(NativeDatabase(dbFile));
      final repo = AppSettingsRepo(db);
      expect(await repo.themeBrightness(), AppBrightness.system);
      expect(await repo.themePalette(), AppPalette.system);
      expect((await db.select(db.appSettings).get()).single.language, 'it');
      await db.close();
    });

    test('a chosen theme survives the round trip', () async {
      final db = AppDatabase(NativeDatabase(dbFile));
      final repo = AppSettingsRepo(db);
      await repo.setThemeBrightness(AppBrightness.night);
      await repo.setThemePalette(AppPalette.gruvbox);

      expect(await repo.themeBrightness(), AppBrightness.night);
      expect(await repo.themePalette(), AppPalette.gruvbox);
      await db.close();
    });

    test('a palette this build never heard of reads as the default', () async {
      // A settings row written by a later build, or edited by hand.
      final db = AppDatabase(NativeDatabase(dbFile));
      await db.customStatement(
        'INSERT INTO app_settings (id, theme_palette) '
        "VALUES (1, 'dracula')",
      );
      expect(await AppSettingsRepo(db).themePalette(), AppPalette.system);
      await db.close();
    });
  });

  test('a stored "split" layout reads back as side by side', () async {
    // T-CL-07 dropped the third mode; what it did is what auto does.
    final db = AppDatabase(NativeDatabase(dbFile));
    await db.customStatement(
      "INSERT INTO app_settings (id, preview_mode) VALUES (1, 'split')",
    );
    expect(await AppSettingsRepo(db).previewMode(), PreviewLayoutMode.auto);
    await db.close();
  });

  test('a fresh database holds the settings and the registry alone', () async {
    final db = AppDatabase(NativeDatabase(dbFile));
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    expect(
      tables.map((r) => r.read<String>('name')),
      unorderedEquals(['app_settings', 'known_libraries']),
    );
    expect(await db.select(db.appSettings).get(), isEmpty);
    expect(await db.select(db.knownLibraries).get(), isEmpty);
    await db.close();
  });
}
