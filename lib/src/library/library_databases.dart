import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:niman/src/core/app_channel.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/db/app_database_recovery.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/library/container_path.dart';
import 'package:path/path.dart' as p;

/// The app settings database FILE in the platform application-support
/// directory.
///
/// It has held that name since M1, when it was the index too; T-ML-03
/// moved the index into [libraryIndexFile] and left the settings here.
Future<File> defaultAppDbFile() async {
  final dir = await appSupportDirectory();
  return File(p.join(dir.path, 'niman.db'));
}

/// The index FILE for the library at [libraryPath].
///
/// One per library, named by a digest of the absolute path: two libraries
/// never share a file, and a library that moves simply rebuilds under its
/// new name. The digest is truncated — it names a file in the app's own
/// folder, so a collision would need two libraries whose paths collide in
/// 64 bits, and the registry keeps the mapping readable (T-ML-04).
///
/// It lives OUTSIDE the library folder: the index is a cache, the files
/// on disk are the source of truth, and `.niman/` is for what the user
/// would want to keep.
Future<File> libraryIndexFile(String libraryPath) async {
  final dir = Directory(p.join((await appSupportDirectory()).path, 'indexes'));
  await dir.create(recursive: true);
  // On iOS the key is the path inside the app's Documents, which outlives
  // the container's own path (container_path.dart).
  final digest = sha256.convert(utf8.encode(libraryIndexKey(libraryPath)));
  return File(p.join(dir.path, '${digest.toString().substring(0, 16)}.db'));
}

/// The one connection to the app settings database, shared by everything
/// that reads it (#312).
///
/// Not one per caller: the welcome gate, the update notice and the session
/// each opened their own, and on the first launch after an update all of
/// them upgraded the same file at once — two migrations interleaved, and
/// the one that lost came out of its `ALTER` with `duplicate column name`
/// (the crash in #312). One connection, one migrator; the migration itself
/// takes the file's write lock as well (see [AppDatabase.migration]).
Future<AppDatabase>? _appDatabase;

/// The app settings database in the application-support directory.
///
/// Every caller shares the connection this hands out, so nobody opens a
/// second one; [forgetDefaultAppDatabase] drops it once it is closed.
Future<AppDatabase> defaultAppDatabase() =>
    _appDatabase ??= _openDefaultAppDatabase();

Future<AppDatabase> _openDefaultAppDatabase() async {
  final file = await defaultAppDbFile();
  return await openAppDatabaseRecovering(file);
}

/// Forgets the connection [defaultAppDatabase] handed out, when [db] is
/// that connection, so the next call opens a fresh one: a closed drift
/// database cannot be reopened.
Future<void> forgetDefaultAppDatabase(AppDatabase db) async {
  final open = _appDatabase;
  if (open != null && identical(await open, db)) {
    _appDatabase = null;
  }
}

/// Opens the index of the library at [libraryPath], on drift's background
/// isolate.
///
/// Every write of the index — a saved note's text into the full-text table,
/// its tags, stems and links — ran on the UI isolate: sqlite is synchronous,
/// and a 100 MB note held the frame for seconds while its body went in, the
/// tree's menu waiting behind it (0.0.9 stress test). The search connection
/// was moved off first (T-M3-09); the index follows it.
Future<IndexDatabase> defaultIndexDatabase(String libraryPath) async {
  return IndexDatabase(
    NativeDatabase.createInBackground(
      await libraryIndexFile(libraryPath),
      setup: indexDatabaseSetup,
    ),
  );
}

/// The search connection over the same library's index file, with drift's
/// background-isolate executor: `MATCH` over large result sets runs off the
/// UI isolate (T-M3-09 fix: many results with novel-length bodies stalled
/// every frame).
Future<IndexDatabase> defaultSearchDatabase(String libraryPath) async {
  return IndexDatabase(
    NativeDatabase.createInBackground(
      await libraryIndexFile(libraryPath),
      setup: indexDatabaseSetup,
    ),
  );
}
