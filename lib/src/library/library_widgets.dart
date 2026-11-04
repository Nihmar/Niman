import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/library/library_registry.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_libraries.dart';

/// The home-screen widgets' records in the app database (issue 6): which
/// placed instance reads which library or note, and the mirror of the
/// known libraries the native config activity reads (round 2, R1).
final class LibraryWidgets {
  /// Records kept in [appDatabase]; the mirror names each library's index
  /// file through [locateIndex].
  new({required this.appDatabase, required this.locateIndex});

  /// The app's settings database, opened once per session.
  final Future<AppDatabase> Function() appDatabase;

  /// Locates a library's index file, for the mirror.
  final Future<File> Function(String libraryPath) locateIndex;

  final AppLogger _log = const AppLogger(name: 'session');

  /// The home-screen widget instances reading [libraryPath] (issue 6).
  Future<List<WidgetConfig>> configsFor(String libraryPath) async {
    return await WidgetConfigStore(await appDatabase()).forLibrary(libraryPath);
  }

  /// Records a placed [provider] widget for [libraryPath] (issue 6).
  Future<void> adoptLibraryWidget(
    int androidWidgetId,
    String libraryPath,
    WidgetProvider provider,
  ) async {
    final store = WidgetConfigStore(await appDatabase());
    if (await store.find(androidWidgetId) != null) return;
    await store.upsert(
      androidWidgetId: androidWidgetId,
      provider: provider,
      libraryPath: libraryPath,
    );
  }

  /// Records a placed note widget for [notePath] (issue 6).
  Future<void> adoptNoteWidget(
    int androidWidgetId,
    String libraryPath,
    String notePath,
  ) async {
    final store = WidgetConfigStore(await appDatabase());
    if (await store.find(androidWidgetId) != null) return;
    await store.upsert(
      androidWidgetId: androidWidgetId,
      provider: WidgetProvider.note,
      libraryPath: libraryPath,
      notePath: notePath,
    );
  }

  /// Drops [libraryPath]'s [provider] widget configurations whose
  /// instance is no longer placed (issue 6); the refresh calls this,
  /// since the native `onDeleted` cannot reach the database.
  Future<void> prune({
    required String libraryPath,
    required WidgetProvider provider,
    required Set<int> placedIds,
  }) async {
    final store = WidgetConfigStore(await appDatabase());
    final stale = {
      for (final config in await store.forLibrary(libraryPath))
        if (config.provider == provider.name &&
            !placedIds.contains(config.androidWidgetId))
          config.androidWidgetId,
    };
    for (final id in stale) {
      await store.remove(id);
    }
  }

  /// Mirrors the known libraries for the native widget config activity
  /// (round 2, R1): path, display name and index file per library.
  ///
  /// Best effort and Android-only: the activity treats the mirror as a
  /// cache, and a failure here must never break an open or a forget.
  Future<void> saveLibraryMirror(AppDatabase appDb) async {
    if (!Platform.isAndroid) return;
    try {
      final libraries = await LibraryRegistry(appDb).all();
      final indexByPath = <String, String>{};
      for (final lib in libraries) {
        indexByPath[lib.path] = (await locateIndex(lib.path)).path;
      }
      await HomeWidget.saveWidgetData<String>(
        widgetLibrariesKey,
        encodeLibraryMirror(libraries, indexByPath),
      );
    } on MissingPluginException {
      // No host handler (tests, desktops).
    } on PlatformException catch (error) {
      _log.warning('widget library mirror not saved ($error)');
    }
  }
}
