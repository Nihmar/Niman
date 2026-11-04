import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/device_settings_store.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/library/container_path.dart';
import 'package:niman/src/library/library_registry.dart';
import 'package:niman/src/sync/sync_secrets.dart';
import 'package:niman/src/sync/sync_store.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/workspace/workspace_store.dart';

/// The libraries this device knows (T-ML-04), and what it keeps about each
/// one outside the library folder: the registry row, the widgets reading
/// it, its sync state and password, its workspace and its device settings.
final class LibraryRecords {
  /// The records in [appDatabase], the sync passwords in [syncSecrets].
  new({required this.appDatabase, required this.syncSecrets});

  /// The app's settings database, opened once per session.
  final Future<AppDatabase> Function() appDatabase;

  /// Where each library's WebDAV password lives (M5).
  final SyncSecretStore syncSecrets;

  final AppLogger _log = const AppLogger(name: 'session');

  /// The libraries the app knows about, most recently opened first.
  Future<List<KnownLibrary>> all() async {
    final known = await LibraryRegistry(await appDatabase()).all();
    final documents = await containerDocuments();
    if (documents == null) return known;
    // On iPhone a library remembered before the container moved is the one
    // at the same place in today's Documents; listed once, by its newest.
    final seen = <String>{};
    return [
      for (final library in known)
        if (seen.add(rebaseContainerPath(library.path, documents)))
          library.copyWith(path: rebaseContainerPath(library.path, documents)),
    ];
  }

  /// Drops every record [db] and the secret store keep of [libraryPath];
  /// the folder is untouched.
  Future<void> forget(AppDatabase db, String libraryPath) async {
    await LibraryRegistry(db).forget(libraryPath);
    // Widgets pointing at it would open a library the home screen no
    // longer lists; their rows go with the entry (issue 6).
    await WidgetConfigStore(db).removeForLibrary(libraryPath);
    // Its sync state describes a library the app no longer knows; opened
    // again, it starts unconfigured (docs/records/sync.md, "Configuration").
    await SyncStore(db).removeLibrary(libraryPath);
    // What was left open in it goes too (#23): opened again, it starts
    // with nothing open, like a library the app has never seen.
    await WorkspaceStore(db).remove(libraryPath);
    // So do the settings it kept on this device: opened again, it takes
    // them from its settings file, like a library opened for the first time.
    await DbDeviceSettingsStore(db).remove(libraryPath);
    try {
      await syncSecrets.delete(libraryPath);
    } on Exception catch (e) {
      // A missing keychain must not block forgetting; the entry is inert
      // without its destination row.
      _log.warning('forget library: sync password not deleted: $e');
    }
  }
}
