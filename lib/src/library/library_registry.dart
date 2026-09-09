import 'package:copist/src/db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

/// The libraries the app knows about (T-ML-04): what the home screen
/// lists, and what "forget this library" removes.
///
/// The registry is a list, not a definition. A folder becomes a library
/// the first time it is opened and stays one whether or not it has a row
/// here, so opening a folder the app has never seen is not an error — it
/// is how an entry appears. Forgetting one removes the row and leaves
/// everything inside the folder, `.copist/settings.json` included, so
/// opening it again lists it again with its settings intact.
final class LibraryRegistry {
  /// Creates the registry over the app database.
  new(this._db);

  final AppDatabase _db;

  /// Every known library, most recently opened first.
  Future<List<KnownLibrary>> all() {
    return (_db.select(
      _db.knownLibraries,
    )..orderBy([(t) => OrderingTerm.desc(t.lastOpened)])).get();
  }

  /// The entry for [libraryPath], or null when it is not known.
  Future<KnownLibrary?> find(String libraryPath) {
    return (_db.select(
      _db.knownLibraries,
    )..where((t) => t.path.equals(p.normalize(libraryPath)))).getSingleOrNull();
  }

  /// Records that [libraryPath] was just opened: adds it when new, moves
  /// it to the top of the list when it is not.
  ///
  /// [name] defaults to the folder's own name on the first sighting and
  /// is left alone afterwards, so a name the user chose survives every
  /// later open.
  Future<void> touch(String libraryPath, {String? name, DateTime? at}) async {
    final path = p.normalize(libraryPath);
    final when = at ?? DateTime.now();
    final existing = await find(path);
    if (existing == null) {
      await _db
          .into(_db.knownLibraries)
          .insert(
            KnownLibrariesCompanion.insert(
              path: path,
              name: name ?? _defaultName(path),
              lastOpened: when,
            ),
          );
      return;
    }
    await (_db.update(
      _db.knownLibraries,
    )..where((t) => t.path.equals(path))).write(
      KnownLibrariesCompanion(
        lastOpened: Value(when),
        name: name == null ? const Value.absent() : Value(name),
      ),
    );
  }

  /// Renames the entry for [libraryPath]; the folder is untouched.
  Future<void> rename(String libraryPath, String name) async {
    await (_db.update(_db.knownLibraries)
          ..where((t) => t.path.equals(p.normalize(libraryPath))))
        .write(KnownLibrariesCompanion(name: Value(name)));
  }

  /// Drops [libraryPath] from the list. The folder is untouched.
  Future<void> forget(String libraryPath) async {
    await (_db.delete(
      _db.knownLibraries,
    )..where((t) => t.path.equals(p.normalize(libraryPath)))).go();
  }

  /// The folder's own name, or the whole path for a root directory,
  /// which has no basename to show.
  static String _defaultName(String path) {
    final base = p.basename(path);
    return base.isEmpty ? path : base;
  }
}
