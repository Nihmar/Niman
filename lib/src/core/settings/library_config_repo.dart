import 'package:copist/src/core/settings/library_config.dart';

/// The open library's settings, read once from
/// `<library>/.copist/settings.json` and written back on every change
/// (T-ML-02).
///
/// The file replaced a database row, and a row was cheap to read: the
/// trash toggle is consulted on every delete, the list folder and the
/// quick note on UI paths. Re-reading and re-parsing the file each time
/// would put disk I/O on those paths, so the value is cached for the life
/// of the session — which is also the life of the open library, so an
/// external edit of the file is picked up the next time it is opened.
///
/// Writes are read-modify-write over a shared file, so they run one at a
/// time, and the cache is replaced only once the write has landed.
final class LibraryConfigRepo {
  /// Creates the repo for the library at its absolute path.
  new(String libraryPath) : _store = LibraryConfigStore(libraryPath);

  final LibraryConfigStore _store;

  Future<LibraryConfig>? _config;
  Future<void> _chain = Future<void>.value();

  /// The library's settings; the first call reads the file, later ones
  /// return the cached value.
  Future<LibraryConfig> get config => _config ??= _store.read();

  /// Applies [change] to the current settings and persists the result.
  ///
  /// A change that produces an equal config writes nothing.
  Future<void> update(LibraryConfig Function(LibraryConfig) change) {
    final next = _chain.then((_) async {
      final current = await config;
      final updated = change(current);
      if (updated == current) return;
      await _store.write(updated);
      _config = Future<LibraryConfig>.value(updated);
    });
    _chain = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}
