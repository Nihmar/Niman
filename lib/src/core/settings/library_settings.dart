import 'package:drift/drift.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/theme.dart';
import 'package:niman/src/db/app_database.dart';

/// The preview layout mode (settings, T-M2-08): follow the width, or
/// keep one pane at any width.
///
/// A third value used to force the split at any width. Once a narrow
/// screen stopped honouring it (T-CL-05) it did the same as [auto]
/// everywhere, so T-CL-07 dropped it; a stored `split` reads back as
/// [auto], which is what it now means.
enum PreviewLayoutMode {
  /// Side by side at >= 600 dp, one pane below it.
  auto,

  /// One pane with the top switch, at any width.
  fullScreen,
}

/// Which editor a library writes in (T-WYS-03, default source).
enum EditorKind {
  /// The Markdown source editor (re_editor).
  source,

  /// The WYSIWYG surface (flutter_quill).
  wysiwyg,
}

/// The library tree sort order (T-UI-03).
enum TreeSort {
  /// Name ascending (default).
  nameAsc,

  /// Name descending.
  nameDesc,
}

/// The link format the editor's link button inserts.
enum LinkType {
  /// A wikilink `[[…]]` (the default).
  wikilink,

  /// A markdown link `[…](…)`.
  markdown,
}

/// Below this width the shell is single-pane (spec: phones are
/// full-screen tree or editor, the split lands at 600 dp and up).
const double splitBreakpoint = 600;

/// Whether the editor and the preview actually sit side by side.
///
/// A narrow screen never splits, whatever the mode says: two panes of a
/// Markdown editor at phone width are two unusable panes, and the spec
/// puts the split at 600 dp for that reason. Above it, the mode decides.
///
/// It lives here rather than in the shell because the settings screen
/// asks the same question: neither the layout row nor the split-ratio row
/// means anything where the panes cannot share a screen (T-CL-05).
bool previewSplits(
  PreviewLayoutMode mode, {
  required bool narrow,
  EditorKind editor = EditorKind.source,
  bool previewEnabled = true,
}) =>
    previewEnabled &&
    editor == EditorKind.source &&
    !narrow &&
    mode == PreviewLayoutMode.auto;

/// The default editor share of the split.
const double defaultSplitRatio = 0.55;

/// The default folder (library-relative) of the list notes (T-TK-06).
const String defaultListFolder = 'Lists';

/// The default folder (library-relative) holding the note templates
/// (T-M4-05).
const String defaultTemplateFolder = 'Templates';

/// The lower bound of the allowed split range.
const double minSplitRatio = 0.2;

/// The upper bound of the allowed split range.
const double maxSplitRatio = 0.8;

/// Global app settings, a single row (id 1).
final class AppSettingsRepo {
  /// Creates the repo over the given [AppDatabase].
  new(this._db);

  final AppDatabase _db;

  /// The last opened library root, or null.
  Future<String?> lastLibraryPath() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty ? null : rows.first.libraryPath;
  }

  /// Persists `path` as the last opened library root.
  Future<void> setLastLibraryPath(String? path) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(libraryPath: Value(path)),
    );
  }

  /// Whether the debug log buffer records events (default true).
  Future<bool> debugLogsEnabled() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty || rows.first.debugLogsEnabled;
  }

  /// Persists the debug log recording toggle.
  Future<void> setDebugLogsEnabled({required bool enabled}) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(debugLogsEnabled: Value(enabled)),
    );
  }

  /// The preview layout mode (default [PreviewLayoutMode.auto]).
  Future<PreviewLayoutMode> previewMode() async {
    final rows = await _db.select(_db.appSettings).get();
    if (rows.isEmpty) return PreviewLayoutMode.auto;
    return switch (rows.first.previewMode) {
      'switch' || 'fullScreen' => PreviewLayoutMode.fullScreen,
      // 'split' included: it is what auto already does (T-CL-07).
      _ => PreviewLayoutMode.auto,
    };
  }

  /// Persists the preview layout mode.
  Future<void> setPreviewMode(PreviewLayoutMode mode) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(previewMode: Value(mode.name)),
    );
  }

  /// The editor|preview split ratio (0..1; default [defaultSplitRatio]).
  Future<double> splitRatio() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty ? defaultSplitRatio : rows.first.splitRatio;
  }

  /// Persists the split ratio (clamped to the allowed range).
  Future<void> setSplitRatio(double ratio) async {
    await _ensureRow();
    final clamped = ratio < minSplitRatio
        ? minSplitRatio
        : ratio > maxSplitRatio
        ? maxSplitRatio
        : ratio;
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(splitRatio: Value(clamped)),
    );
  }

  /// The stored UI language id (`system`, `en` or `it`).
  Future<AppLanguage> language() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty
        ? AppLanguage.system
        : AppLanguage.fromId(rows.first.language);
  }

  /// Persists the UI language.
  Future<void> setLanguage(AppLanguage language) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(language: Value(language.id)),
    );
  }

  /// The stored brightness choice (T-M6-05).
  Future<AppBrightness> themeBrightness() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty
        ? AppBrightness.system
        : AppBrightness.fromId(rows.first.themeBrightness);
  }

  /// Persists the brightness choice.
  Future<void> setThemeBrightness(AppBrightness brightness) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(themeBrightness: Value(brightness.id)),
    );
  }

  /// The stored palette (T-M6-05); a fresh install wears [AppPalette.niman].
  Future<AppPalette> themePalette() async {
    final rows = await _db.select(_db.appSettings).get();
    return rows.isEmpty
        ? AppPalette.niman
        : AppPalette.fromId(rows.first.themePalette);
  }

  /// Persists the palette.
  Future<void> setThemePalette(AppPalette palette) async {
    await _ensureRow();
    await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(themePalette: Value(palette.id)),
    );
  }

  Future<void> _ensureRow() async {
    final rows = await _db.select(_db.appSettings).get();
    if (rows.isNotEmpty) {
      return;
    }
    await _db
        .into(_db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: const Value(1),
            libraryPath: const Value(null),
          ),
        );
  }
}
