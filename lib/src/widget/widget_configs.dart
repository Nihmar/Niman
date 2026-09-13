/// Per-instance home-screen widget configuration (issue 6).
///
/// Each placed widget (one Android `appWidgetId`) owns a row: which widget
/// it is, which library it reads, and — for note widgets — which note it
/// shows. A widget never assumes the last-opened library, so the same
/// widget can sit twice on the home screen for two libraries.
///
/// Pure database access, no widgets: the Android configuration activity
/// writes through [WidgetConfigStore.upsert], the provider cleanup calls
/// [WidgetConfigStore.remove], and "forget this library" calls
/// [WidgetConfigStore.removeForLibrary].
library;

import 'package:drift/drift.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:path/path.dart' as p;

/// Which home-screen widget a configured instance is.
enum WidgetProvider {
  /// The open-todos list, due-soonest first.
  todo,

  /// The pinned note (preview, or checklist for `type: list`).
  note,
}

/// The widget configurations of this install (issue 6).
final class WidgetConfigStore {
  /// Creates the store over the app database.
  new(this._db);

  final AppDatabase _db;

  /// Every configured instance, most recently configured first.
  Future<List<WidgetConfig>> all() {
    return (_db.select(
      _db.widgetConfigs,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  /// The configuration of [androidWidgetId], or null when the instance
  /// was never configured (or was removed).
  Future<WidgetConfig?> find(int androidWidgetId) {
    return (_db.select(_db.widgetConfigs)
          ..where((t) => t.androidWidgetId.equals(androidWidgetId)))
        .getSingleOrNull();
  }

  /// Every instance reading [libraryPath].
  Future<List<WidgetConfig>> forLibrary(String libraryPath) {
    final path = p.normalize(libraryPath);
    return (_db.select(
      _db.widgetConfigs,
    )..where((t) => t.libraryPath.equals(path))).get();
  }

  /// Records the configuration of [androidWidgetId], replacing the
  /// previous one on reconfigure.
  ///
  /// [libraryPath] is the absolute library root; [notePath] the
  /// library-relative note path (`note` widgets only, null for `todo`).
  /// Throws [ArgumentError] when a note widget has no note.
  Future<void> upsert({
    required int androidWidgetId,
    required WidgetProvider provider,
    required String libraryPath,
    String? notePath,
    DateTime? at,
  }) async {
    if (provider == WidgetProvider.note &&
        (notePath == null || notePath.isEmpty)) {
      throw ArgumentError('A note widget needs a note path');
    }
    await _db
        .into(_db.widgetConfigs)
        .insertOnConflictUpdate(
          WidgetConfigsCompanion.insert(
            // Client-assigned (Android owns the id): the generated insert
            // takes it as an explicit value, not an autoincrement.
            androidWidgetId: Value(androidWidgetId),
            provider: provider.name,
            libraryPath: p.normalize(libraryPath),
            notePath: Value(notePath),
            updatedAt: at ?? DateTime.now(),
          ),
        );
  }

  /// Drops the configuration of [androidWidgetId] (called from the
  /// provider's `onDeleted`, so removed widgets leave no rows behind).
  Future<void> remove(int androidWidgetId) async {
    await (_db.delete(
      _db.widgetConfigs,
    )..where((t) => t.androidWidgetId.equals(androidWidgetId))).go();
  }

  /// Drops every instance reading [libraryPath] (called when the library
  /// is forgotten; the folder is untouched).
  Future<void> removeForLibrary(String libraryPath) async {
    await (_db.delete(
      _db.widgetConfigs,
    )..where((t) => t.libraryPath.equals(p.normalize(libraryPath)))).go();
  }
}
