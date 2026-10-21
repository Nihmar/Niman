/// The store's generation (#1148 review): how the upkeep knows no log moved
/// while it listed them.
///
/// The upkeep names the objects the logs hold by listing the logs, then
/// reading each. A log read and gone was moved, and the listing is taken
/// again (`history_upkeep.dart`) — but a log moved from a folder the walk
/// had not reached to one it had left appears in neither listing, and no
/// read fails: its objects would be taken for unnamed and collected. So
/// every move of logs runs holding the store's move lock and ends by
/// changing the generation, a token in `.history/.generation`. The upkeep
/// reads the generation before it lists and again after it has read the
/// logs, and names nothing from a pass during which a move was running or
/// finished.
///
/// A move that began before the first read holds the lock then (the pass is
/// refused); one that begins after it changes the generation before it
/// ends, and one still running at the second read holds the lock (also
/// refused). Only a move wholly outside the pass leaves it standing, and
/// that one cannot have changed the listing.
library;

import 'dart:io';
import 'dart:math';

import 'package:niman/src/history/history_folders.dart';
import 'package:niman/src/history/history_lock.dart';
import 'package:niman/src/history/history_lock_file.dart';
import 'package:path/path.dart' as p;

final Random _random = Random();

/// The file holding the generation of the library at [root].
String historyGenerationPath(String root) =>
    p.join(root, historyFolderName, historyGenerationFileName);

/// Runs [body], which moves logs, holding the move lock, and changes the
/// generation when it ends — however it ends, since a move cut short has
/// moved some.
T trackingHistoryMove<T>(String root, T Function() body) =>
    withHistoryMoveLock(root, () {
      try {
        return body();
      } finally {
        _changeGeneration(root);
      }
    });

/// The generation of the store at [root], or null while a move of logs is
/// running (or a crash left its lock, until it is old enough to be broken).
String? historyGeneration(String root) {
  if (lockFileHeld(File(historyMoveLockPath(root)))) return null;
  try {
    return File(historyGenerationPath(root)).readAsStringSync();
  } on FileSystemException {
    return ''; // never moved: one generation, until the first move
  }
}

/// Changes the generation. A failure is raised: a move that went unrecorded
/// would let the upkeep collect what it moved.
void _changeGeneration(String root) {
  File(historyGenerationPath(root)).writeAsStringSync(
    '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}',
  );
}
