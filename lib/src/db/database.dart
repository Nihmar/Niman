import 'package:drift/drift.dart';

part 'database.g.dart';

/// One note file or folder in the library.
///
/// [path] is library-relative, slash-separated. Directory rows are
/// materialized (not derived on the fly) so tree queries stay cheap at
/// scale. [parent] is the parent row id; 0 means the library root.
class Notes extends Table {
  /// Primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Library-relative slash-separated path; unique.
  TextColumn get path => text().unique()();

  /// Parent row id; 0 = library root.
  IntColumn get parent => integer()();

  /// Display name (file or folder name).
  TextColumn get name => text()();

  /// Whether this row is a directory.
  BoolColumn get isDir => boolean()();

  /// Byte size; 0 for directories.
  IntColumn get size => integer()();

  /// Last modification time as seen on disk.
  DateTimeColumn get modified => dateTime()();

  /// Content sha256, hex; files only (directories are null).
  TextColumn get sha256 => text().nullable()();
}

/// Per-library local settings, keyed by the absolute library path.
///
/// Never stored inside the library folder itself.
class LibrarySettings extends Table {
  /// Absolute, normalized path of the library root; the primary key.
  TextColumn get path => text()();

  /// Whether deletes move notes into `.trash/` (true) or hard-delete them.
  BoolColumn get trashEnabled => boolean()();

  /// Number of `.history/` versions to keep (M5); default 10.
  IntColumn get historyVersions => integer()();

  @override
  Set<Column> get primaryKey => {path};
}

/// Global app settings; a single row (id 1).
class AppSettings extends Table {
  /// Row id; always 1.
  IntColumn get id => integer()();

  /// Last opened library root, used to resume the library on startup;
  /// null until a library has been opened.
  TextColumn get libraryPath => text().named('library_path').nullable()();

  /// Whether the in-app debug log buffer records events (default true).
  BoolColumn get debugLogsEnabled => boolean()
      .named('debug_logs_enabled')
      .withDefault(const Constant(true))();

  /// Whether the note editor shows the row-number column (default true).
  BoolColumn get lineNumbers => boolean()
      .named('line_numbers')
      .withDefault(const Constant(true))();

  /// Whether the note editor focuses (shows the keyboard) when a note
  /// opens (default false — the keyboard appears on the first tap).
  BoolColumn get editorAutofocus => boolean()
      .named('editor_autofocus')
      .withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// The Copist database.
///
/// Every table is rebuildable from disk: deleting the database file and
/// rescanning the library reproduces it exactly.
@DriftDatabase(tables: [Notes, LibrarySettings, AppSettings])
class CopistDatabase extends _$CopistDatabase {
  /// Creates the database on top of [e].
  CopistDatabase(super.e);

  @override
  int get schemaVersion => 4;

  /// Fresh databases get all tables; v1 databases gain the
  /// `debug_logs_enabled` column, pre-v3 databases `line_numbers`, and
  /// pre-v4 databases `editor_autofocus`.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from == 1) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN debug_logs_enabled '
          'BOOLEAN NOT NULL DEFAULT 1',
        );
      }
      if (from < 3) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN line_numbers '
          'BOOLEAN NOT NULL DEFAULT 1',
        );
      }
      if (from < 4) {
        await m.database.customStatement(
          'ALTER TABLE app_settings ADD COLUMN editor_autofocus '
          'BOOLEAN NOT NULL DEFAULT 0',
        );
      }
    },
  );
}
