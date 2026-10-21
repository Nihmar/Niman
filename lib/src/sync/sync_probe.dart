import 'dart:io';
import 'dart:isolate';

/// Which of [paths] exist, in the order given.
///
/// What the sync asks about a watcher batch (`LibrarySyncService.watched`):
/// a file there is queued as changed, a file gone as deleted.
typedef ExistenceProbe = Future<List<bool>> Function(List<String> paths);

/// The [ExistenceProbe] the app runs: all the paths in one background
/// isolate, so a batch naming hundreds of files costs the UI isolate one
/// message instead of a FUSE round trip apiece (#1143).
Future<List<bool>> probeExistence(List<String> paths) => Isolate.run(
  () => [
    for (final path in paths)
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound,
  ],
);
