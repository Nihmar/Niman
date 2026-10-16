import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:niman/src/workspace/workspace_store.dart';

/// Where one library's [Workspace] is kept, bound to that library (#1083).
///
/// The shell takes its slot when it is made, and reads and writes through
/// it for as long as it lives. The last writes of a library being closed or
/// switched — the notes' final places, which arrive as the views go down
/// — still reach the library they belong to, and never another one's row,
/// whatever the session has open by then.
abstract interface class WorkspaceSlot {
  /// What was left open in the library on this device; nothing open when
  /// none were.
  Future<Workspace> load();

  /// Keeps [workspace] as what is open in the library.
  Future<void> save(Workspace workspace);
}

/// The slot of the library at [root], in the app database's store.
final class StoredWorkspaceSlot implements WorkspaceSlot {
  /// A slot for the library at [root], over the app database.
  new(this._database, this.root);

  final Future<AppDatabase> _database;

  /// The library's root, as it was when the slot was made.
  final String root;

  @override
  Future<Workspace> load() async =>
      await WorkspaceStore(await _database).load(root);

  @override
  Future<void> save(Workspace workspace) async {
    await WorkspaceStore(await _database).save(root, workspace);
  }
}

/// The slot of no library: nothing is kept, nothing is read.
final class NoWorkspaceSlot implements WorkspaceSlot {
  /// The slot of no library.
  const new();

  @override
  Future<Workspace> load() async => Workspace.empty;

  @override
  Future<void> save(Workspace workspace) async {}
}
