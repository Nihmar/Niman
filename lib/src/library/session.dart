import 'package:copist/src/db/database.dart';
import 'package:copist/src/library/library_state.dart';
import 'package:copist/src/library/note_ops.dart';

/// Operations the UI layer performs on an open library.
///
/// Implemented by [NoteOps] (real disk + index, production) and by an
/// in-memory fake in widget tests: `testWidgets` runs on a fake async
/// zone where real filesystem/sqlite I/O never completes, so the UI is
/// exercised against the fake while the real implementation is covered
/// by unit tests.
abstract interface class NoteOperations {
  /// Creates an empty `<name>.md` note in [parentPath].
  Future<Note> createNote({
    required String parentPath,
    required String name,
  });

  /// Creates a folder in [parentPath].
  Future<Note> createFolder({
    required String parentPath,
    required String name,
  });

  /// Renames the note or folder at [path] to [newName].
  Future<Note> rename(String path, String newName);

  /// Moves the note or folder at [path] into [targetParent].
  Future<Note> move(String path, String targetParent);

  /// Deletes [path] (into `.trash/` while the trash toggle is on).
  Future<void> delete(String path);

  /// Whether deletes move notes into `.trash/` (default true).
  Future<bool> get trashEnabled;

  /// Sets the trash toggle: `true` = deletes move into `.trash/`.
  Future<void> setTrashEnabled({required bool enabled});

  /// Lists the managed trash items, in deletion order.
  Future<List<TrashItem>> trashItems();

  /// Restores the trash item [trashName] to its original location.
  Future<Note> restoreTrash(String trashName);

  /// Permanently deletes the trash item [trashName].
  Future<void> deleteTrashPermanently(String trashName);

  /// Permanently deletes every managed trash item.
  Future<void> emptyTrash();
}

/// What the UI layer needs from a library session (open/resume/lifecycle,
/// change events, tree reads, and the operation surface).
///
/// Implemented by [LibraryController] (production) and by an in-memory
/// fake in widget tests.
abstract interface class LibrarySession {
  /// Coarse lifecycle of the session.
  LibraryPhase get phase;

  /// Absolute root path while [phase] is opening or ready.
  String? get root;

  /// Last failure message, or null.
  String? get lastError;

  /// Bumped after every index change.
  int get revision;

  /// Fires with the new [revision] after every index change.
  Stream<int> get events;

  /// CRUD ops for the open library, or null while closed.
  NoteOperations? get ops;

  /// Resumes the last opened library (if it still exists).
  ///
  /// Non-blocking: the library becomes ready immediately from the last
  /// index, and a background reconciliation scan converges it with the
  /// disk, so a relaunch does not wait on a full disk walk.
  Future<void> resume();

  /// Opens the library at [path]; with [create] true it is created first
  /// when missing.
  ///
  /// With [blockingScan] true (the default) the full index scan completes
  /// before the library becomes ready. With [blockingScan] false (used by
  /// [resume]) the scan is deferred to a background reconciliation.
  Future<void> open(
    String path, {
    required bool create,
    bool blockingScan = true,
  });

  /// Closes the current library (stops watching; keeps the index).
  Future<void> close();

  /// Triggers a full rescan immediately (explicit re-index).
  Future<void> rescanNow();

  /// Notifies listeners that state changed without an index mutation.
  void notify();

  /// Closes the session and releases resources; call exactly once.
  Future<void> dispose();

  /// Children of the row with id [parentId] (0 = library root),
  /// directories first, then by name.
  Future<List<Note>> children(int parentId);

  /// Every indexed folder, path-ordered (for move-target pickers).
  Future<List<Note>> folders();
}
