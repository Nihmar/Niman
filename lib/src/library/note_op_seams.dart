import 'package:niman/src/sync/sync_store.dart';

/// Hears what a user operation did to a library-relative path, for the
/// sync queue (docs/records/sync.md, "Queue and triggers"). A hint, not a
/// command: the reconcile decides what to do.
typedef SyncHintSink = void Function(
  String path,
  SyncOpKind kind, {
  String? fromPath,
});

/// Runs an operation serially with every other operation on the library:
/// the op chain `NoteOps` owns and hands to its collaborators, so a trash,
/// a move and a sync write never interleave on disk.
typedef Serializer = Future<T> Function<T>(Future<T> Function() fn);
