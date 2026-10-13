import 'dart:async' show unawaited;

import 'package:niman/src/core/lru_cache.dart';
import 'package:niman/src/db/index_database.dart';

/// What a panel kept of a note's list, by the note and its revision: a run of
/// keystrokes names the same target each time and the panel filters the list
/// locally, so one read answers them all, and a read still under way answers
/// every ask that comes before it lands.
final class RevisionCache<T> {
  /// A cache that keeps the lists of the [notes] most recently asked for:
  /// more than the run of keystrokes needs, so moving between a few targets
  /// does not re-read; bounded, so a long session cannot keep a novel's
  /// outline per note it ever named.
  new({int notes = 8})
    : _kept = LruCache<(int, DateTime, int), Future<List<T>?>>(notes);

  final LruCache<(int, DateTime, int), Future<List<T>?>> _kept;

  /// The list of [note] at its revision (its mtime and size, as the index
  /// records it), read by [read] when it is not kept. An empty list when the
  /// note is gone, which is not kept: it may come back.
  Future<List<T>> of(Note note, Future<List<T>?> Function() read) async {
    final key = (note.id, note.modified, note.size);
    final kept = _kept[key];
    if (kept != null) return await kept ?? List<T>.empty();
    final reading = read();
    _kept[key] = reading;
    try {
      final rows = await reading;
      if (rows == null) unawaited(_kept.remove(key));
      return rows ?? List<T>.empty();
    } on Object {
      // A read that failed is not kept.
      unawaited(_kept.remove(key));
      rethrow;
    }
  }
}
