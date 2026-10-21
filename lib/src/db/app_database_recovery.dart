import 'dart:io';

import 'package:drift/native.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/db/app_database.dart';

const AppLogger _log = AppLogger(name: 'appdb');

/// Opens the app settings database at [file], setting a damaged file aside
/// and starting a fresh one when sqlite reports it unreadable.
///
/// Unlike the library index, the settings database holds what disk cannot
/// give back (the libraries, the sync destinations and their state), so the
/// damaged file is renamed to `<name>.corrupt-<stamp>` rather than deleted:
/// whatever can still be read from it is not lost to the retry. Without
/// this a file with a few zeroed pages opened without a word and failed at
/// the first query that reached one — every minute, from the sync
/// scheduler, and the sync never ran.
///
/// The first query is a `quick_check`, which also runs the migration, so a
/// file the upgrade cannot read is caught here as well. Only sqlite's
/// `SQLITE_CORRUPT` and `SQLITE_NOTADB` count as damage; any other failure
/// (a lock, a full disk) is not a reason to discard settings and is
/// rethrown.
Future<AppDatabase> openAppDatabaseRecovering(
  File file, {
  DateTime? now,
}) async {
  final db = _open(file);
  try {
    await _verify(db);
    return db;
  } on SqliteException catch (error) {
    await _closeQuietly(db);
    if (!_isDamaged(error)) rethrow;
    _log.warning('settings database ${file.path} is damaged: $error');
    final aside = await _setAside(file, now ?? DateTime.now());
    _log.warning('settings database set aside as $aside; starting a new one');
  } on Object {
    await _closeQuietly(db);
    rethrow;
  }
  final fresh = _open(file);
  try {
    await _verify(fresh);
    return fresh;
  } on Object {
    await _closeQuietly(fresh);
    rethrow;
  }
}

AppDatabase _open(File file) =>
    AppDatabase(NativeDatabase(file, setup: appDatabaseSetup));

/// Fails with the sqlite error when the file is damaged.
///
/// `quick_check` answers with rows of problems, or the single row `ok`;
/// damage deep enough to stop the check itself arrives as an exception.
Future<void> _verify(AppDatabase db) async {
  final rows = await db.customSelect('PRAGMA quick_check(1)').get();
  final verdict = rows.single.read<String>('quick_check');
  if (verdict != 'ok') {
    throw SqliteException(
      extendedResultCode: 11,
      message: 'quick_check: $verdict',
    );
  }
}

/// sqlite's `SQLITE_CORRUPT` and `SQLITE_NOTADB` (sqlite.org/rescode.html).
bool _isDamaged(SqliteException error) =>
    error.resultCode == 11 || error.resultCode == 26;

Future<void> _closeQuietly(AppDatabase db) async {
  try {
    await db.close();
  } on Object catch (error) {
    _log.debug('damaged settings connection not closed cleanly ($error)');
  }
}

/// Renames the file and its WAL sidecars to `.corrupt-<stamp>`, and returns
/// the new name of the file itself.
Future<String> _setAside(File file, DateTime now) async {
  final stamp = _stamp(now);
  final aside = '${file.path}.corrupt-$stamp';
  for (final sidecar in const ['', '-wal', '-shm']) {
    final part = File('${file.path}$sidecar');
    if (await part.exists()) {
      await part.rename('$aside$sidecar');
    }
  }
  return aside;
}

String _stamp(DateTime t) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${t.year}${two(t.month)}${two(t.day)}-'
      '${two(t.hour)}${two(t.minute)}${two(t.second)}';
}
