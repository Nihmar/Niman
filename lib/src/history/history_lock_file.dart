/// One lock file, taken and released safely (#1148 review): the primitive
/// under the history's locks (`history_lock.dart`).
///
/// A lock is a file created exclusively — an operation the file system
/// answers once, whichever isolate or process asks — holding the token of
/// whoever created it. What makes it safe:
///
/// - **Release deletes only what is still ours.** A lock broken as stale
///   while its holder stalled may since be another writer's; deleting it by
///   path would free that writer's lock.
/// - **Breaking a stale lock is exclusive too.** Two waiters that both saw
///   a lock stale must not both delete it, the second deleting what the
///   first just created in its place: a stale lock is broken only holding a
///   `.break` guard created exclusively, and looked at again once the guard
///   is held.
/// - **Only "already there" is waiting.** Any other failure to create the
///   lock — a read-only store, a full disk, a folder that cannot be made —
///   is raised at once, rather than waited out and reported as a lock held.
///   The one exception is Windows' delete-pending window, where creating
///   over a lock just deleted is refused for a few milliseconds.
///
/// Synchronous, like the store: it runs on background isolates, where a
/// short sleep blocks nothing a user waits on.
library;

import 'dart:io';
import 'dart:isolate';
import 'dart:math';

/// How old a lock must be to be taken for a crash's leftover.
const Duration historyLockStale = Duration(seconds: 30);

/// How long a writer waits for a lock before it gives up.
const Duration historyLockPatience = Duration(seconds: 10);

/// How long Windows may refuse a create over a just-deleted lock before the
/// refusal is taken for a permission problem.
const Duration _deletePending = Duration(milliseconds: 500);

/// Windows' ERROR_ACCESS_DENIED and ERROR_SHARING_VIOLATION: what creating
/// over a file whose delete is pending answers.
const Set<int> _pendingCodes = {5, 32};

final Random _random = Random();

/// A token no other holder shares: this process, this isolate, this moment.
String newLockToken() =>
    '$pid-${Isolate.current.hashCode}-'
    '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

/// Takes the lock file [lock], waiting up to [patience]; answers the token
/// that proves it is held, or null when it stayed held past the patience.
///
/// A lock older than [stale] is broken. Throws a [FileSystemException] when
/// the lock cannot be created for any reason but being held.
String? acquireLockFile(
  File lock, {
  Duration stale = historyLockStale,
  Duration patience = historyLockPatience,
}) {
  final clock = Stopwatch()..start();
  final token = newLockToken();
  Stopwatch? denied;
  var pause = 1;
  lock.parent.createSync(recursive: true);
  while (true) {
    try {
      lock.createSync(exclusive: true);
      try {
        lock.writeAsStringSync(token);
      } on Object {
        _delete(lock);
        rethrow;
      }
      return token;
    } on PathNotFoundException {
      // The folder went between its creation and the lock's.
      lock.parent.createSync(recursive: true);
      continue;
    } on FileSystemException catch (e) {
      if (!_isHeld(e, lock, denied ??= Stopwatch()..start())) rethrow;
    }
    if (_isStale(lock, stale)) _breakStale(lock, stale);
    if (clock.elapsed > patience) return null;
    sleep(Duration(milliseconds: pause));
    pause = pause < 32 ? pause * 2 : 32;
  }
}

/// Releases the lock file [lock] taken with [token]: deleted only when it
/// still holds that token.
void releaseLockFile(File lock, String token) {
  try {
    if (lock.readAsStringSync() == token) lock.deleteSync();
  } on FileSystemException {
    // Broken as stale, or gone: nothing of ours left to release.
  }
}

/// Whether [e], the failure to create [lock], means it is held.
bool _isHeld(FileSystemException e, File lock, Stopwatch deniedFor) {
  if (e is PathExistsException || lock.existsSync()) return true;
  final code = e.osError?.errorCode;
  return Platform.isWindows &&
      code != null &&
      _pendingCodes.contains(code) &&
      deniedFor.elapsed < _deletePending;
}

/// Whether [lock] is taken: there, and not older than [stale] (one that old
/// is a crash's leftover, which the next writer breaks).
bool lockFileHeld(File lock, {Duration stale = historyLockStale}) {
  final stat = lock.statSync();
  return stat.type == FileSystemEntityType.file &&
      DateTime.now().difference(stat.modified) <= stale;
}

/// Whether [lock] is there and older than [stale]. A lock that is not there
/// is not stale: a stat of nothing answers the epoch, which is.
bool _isStale(File lock, Duration stale) {
  final stat = lock.statSync();
  if (stat.type != FileSystemEntityType.file) return false;
  return DateTime.now().difference(stat.modified) > stale;
}

/// Deletes the stale [lock], holding the guard beside it so that two
/// breakers do not take turns deleting each other's fresh lock.
void _breakStale(File lock, Duration stale) {
  final guard = File('${lock.path}.break');
  try {
    guard.createSync(exclusive: true);
  } on FileSystemException {
    // Another waiter is breaking it. A guard itself left by a crash goes.
    if (_isStale(guard, stale)) _delete(guard);
    return;
  }
  try {
    // Looked at again now that nobody else is breaking: the lock may have
    // been replaced since the caller saw it stale.
    if (_isStale(lock, stale)) _delete(lock);
  } finally {
    _delete(guard);
  }
}

void _delete(File file) {
  try {
    file.deleteSync();
  } on FileSystemException {
    // Gone already.
  }
}
