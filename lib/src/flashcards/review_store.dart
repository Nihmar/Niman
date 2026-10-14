/// When each flashcard comes back (#533), in
/// `<library>/.niman/review.json`: one entry per deck note, by its
/// library-relative path, holding one `ReviewState` per card, by the card's
/// key (`docs/records/flashcards.md`, "Review state").
///
/// It is the library's, not the device's, and it syncs card by card: two
/// devices studying two decks never conflict, and the same card graded on
/// both keeps the later grade (`mergeReviewJson`). It is out of the notes
/// because every grade changes it; losing it loses the dates only.
///
/// Modelled on `ReadingPositions`: nothing is cached, a read opens the file
/// afresh so a copy the sync just brought is what the next read sees; the
/// writes of one library run one after the other, each reading the file
/// again, so two panes never lose each other's grade, and the encoding and
/// the write run on a background isolate. Nothing prunes on a read or a
/// write: a key the sync brought for a card whose note has not arrived yet
/// is not an orphan. Orphans go when Niman itself changes a question
/// (`pruneNote`) or the deck is reset (`resetNote`), and a note the library
/// saw leave takes its entry along (`removed`).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:path/path.dart' as p;

/// The review states of the library at [root].
final class ReviewStore {
  /// The states of the library whose absolute path is [root].
  const new(this.root);

  /// The library's absolute path.
  final String root;

  /// The file, library-relative: one of the sync's library state files.
  static const String filePath = '.niman/review.json';

  static const AppLogger _log = AppLogger(name: 'review');

  /// The writes still running, by file: each waits for the one before.
  static final Map<String, Future<void>> _queues = {};

  File get _file => File(p.join(root, filePath));

  /// The states of the cards of the note at [path], library-relative, by
  /// key. An entry that does not read is absent, as is a note that was
  /// never studied.
  Future<Map<String, ReviewState>> read(String path) async =>
      _statesOf((await _load())[path]);

  /// Every note's states, by path: what the Study view counts from. The
  /// file is read and decoded on a background isolate, being the whole
  /// library's.
  Future<Map<String, Map<String, ReviewState>>> readAll() {
    final library = root;
    return Isolate.run(() => readAllBlocking(library));
  }

  /// [readAll] for code already on a background isolate: reads the file
  /// synchronously. Nothing for a file that is missing or does not read.
  static Map<String, Map<String, ReviewState>> readAllBlocking(String root) {
    final Object? decoded;
    try {
      decoded = jsonDecode(File(p.join(root, filePath)).readAsStringSync());
    } on FileSystemException {
      return const {};
    } on FormatException {
      return const {};
    }
    if (decoded is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in decoded.entries)
        if (_statesOf(value) case final states when states.isNotEmpty)
          key.toString(): states,
    };
  }

  /// Fires with the library root after this app wrote the file: the Study
  /// view counts again. A copy the sync brings is told by the sync.
  static Stream<String> get changes => _changes.stream;

  static final StreamController<String> _changes =
      StreamController<String>.broadcast();

  /// Records that the card [key] of the note at [path] is now in [state];
  /// null takes it back to a card never reviewed (an undone first grade).
  Future<void> write(String path, String key, ReviewState? state) =>
      _update((entries) {
        final cards = _cardsOf(entries[path]);
        if (state == null) {
          if (cards.remove(key) == null) return false;
          if (cards.isEmpty) {
            entries.remove(path);
          } else {
            entries[path] = cards;
          }
          return true;
        }
        cards[key] = state.toJson();
        entries[path] = cards;
        return true;
      });

  /// Carries the entries of [from] to [to], both library-relative: a note
  /// renamed or moved, or a folder and every note under it.
  Future<void> moved(String from, String to) => _update((entries) {
    final carried = {
      for (final key in entries.keys)
        if (key == from || isUnder(from, key))
          key: to + key.substring(from.length),
    };
    if (carried.isEmpty) return false;
    for (final MapEntry(key: old, value: moved) in carried.entries) {
      entries[moved] = entries.remove(old);
    }
    return true;
  });

  /// Drops the entries of [paths], library-relative, and of the notes under
  /// them: the files the library saw leave.
  ///
  /// Only a deletion the library observed comes through here; see the
  /// library comment.
  Future<void> removed(Iterable<String> paths) {
    final gone = paths.toList(growable: false);
    if (gone.isEmpty) return Future<void>.value();
    return _update((entries) {
      final leaving =
          entries.keys
              .where(
                (key) => gone.any((path) => key == path || isUnder(path, key)),
              )
              .toList(growable: false)
            ..forEach(entries.remove);
      return leaving.isNotEmpty;
    });
  }

  /// Forgets every card of the note at [path]: **Reset the review of this
  /// deck**.
  Future<void> resetNote(String path) =>
      _update((entries) => entries.remove(path) != null);

  /// Forgets every card of every deck: **Reset all reviews**. The notes
  /// are not touched.
  Future<void> resetAll() => _update((entries) {
    if (entries.isEmpty) return false;
    entries.clear();
    return true;
  });

  /// Drops the cards of the note at [path] whose key is not in [keepKeys]:
  /// the orphans a question changed in Niman leaves behind.
  Future<void> pruneNote(String path, Set<String> keepKeys) =>
      _update((entries) {
        if (!entries.containsKey(path)) return false;
        final cards = _cardsOf(entries[path]);
        final before = cards.length;
        cards.removeWhere((key, _) => !keepKeys.contains(key));
        if (cards.isEmpty) {
          entries.remove(path);
          return true;
        }
        if (cards.length == before) return false;
        entries[path] = cards;
        return true;
      });

  /// Runs [change] over the entries, after every earlier write of this
  /// library, and writes them back when it says it changed them.
  ///
  /// The encoding and the write run on a background isolate: the file is
  /// one of the sync's library state files, rewritten whole on every rest
  /// (AGENTS.md).
  Future<void> _update(
    bool Function(Map<String, Object?> entries) change,
  ) async {
    final key = _file.path;
    final before = _queues[key];
    final done = Completer<void>();
    _queues[key] = done.future;
    try {
      if (before != null) await before;
      final entries = await _load();
      if (!change(entries)) return;
      await Isolate.run(() => _writeEntries(root, entries));
      if (_changes.hasListener) _changes.add(root);
    } on Object catch (error) {
      _log.warning('could not write $filePath: $error');
    } finally {
      done.complete();
      if (identical(_queues[key], done.future)) unawaited(_queues.remove(key));
    }
  }

  /// The entries on disk: none when the file is missing or is not a JSON
  /// object.
  Future<Map<String, Object?>> _load() async {
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map) {
        return {
          for (final entry in decoded.entries)
            entry.key.toString(): entry.value,
        };
      }
    } on FileSystemException {
      // No file yet: nothing was studied in this library.
    } on FormatException catch (error) {
      _log.warning('$filePath does not read: $error');
    }
    return {};
  }

  /// A note's raw cards, copied so [_update] can change them: none for an
  /// entry that is not an object.
  static Map<String, Object?> _cardsOf(Object? entry) => entry is Map
      ? {for (final card in entry.entries) card.key.toString(): card.value}
      : <String, Object?>{};

  static Map<String, ReviewState> _statesOf(Object? entry) => {
    for (final MapEntry(:key, :value) in _cardsOf(entry).entries)
      key: ?ReviewState.fromJson(value),
  };
}

/// Encodes [entries] and writes them whole to `.niman/review.json`.
///
/// Top level for `Isolate.run`: the closure carries only [root] and
/// [entries], both plain values, so the re-encode and the write stay off the
/// UI isolate.
Future<void> _writeEntries(String root, Map<String, Object?> entries) async {
  final file = File(p.join(root, ReviewStore.filePath));
  await file.parent.create(recursive: true);
  final text = const JsonEncoder.withIndent('  ').convert(entries);
  await writeFileAtomically(file, utf8.encode('$text\n'));
}
