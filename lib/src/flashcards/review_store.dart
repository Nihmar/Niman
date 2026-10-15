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
/// A `LibraryStateFile`, as `ReadingPositions` is: nothing is cached, a read
/// opens the file afresh so a copy the sync just brought is what the next
/// read sees; the writes of one library run one after the other, each
/// reading the file again, so two panes never lose each other's grade, and
/// the read, the change and the write run on a background isolate. Nothing
/// prunes on a read or a write: a key the sync brought for a card whose note
/// has not arrived yet is not an orphan, and a card edit does not prune
/// either. Orphans go when the deck is reset (`resetNote`), and a note the
/// library saw leave takes its entry along (`removed`).
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/library_state_file.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:path/path.dart' as p;

/// What tells one version of `review.json` from another: its modification
/// time, in microseconds, and its size.
typedef ReviewFileStamp = ({int modified, int size});

/// The review states of the library at [root].
final class ReviewStore {
  /// The states of the library whose absolute path is [root].
  const new(this.root);

  /// The library's absolute path.
  final String root;

  /// The file, library-relative: one of the sync's library state files.
  static const String filePath = '.niman/review.json';

  LibraryStateFile get _state => LibraryStateFile(root, filePath);

  /// The states of the cards of the note at [path], library-relative, by
  /// key. An entry that does not read is absent, as is a note that was
  /// never studied.
  Future<Map<String, ReviewState>> read(String path) async =>
      _statesOf((await _state.read([path]))[path]);

  /// The states of the cards of each note of [paths], library-relative: one
  /// read of the file for all of them, where a study of a category of decks
  /// would otherwise decode it once per deck. Every path is a key, with no
  /// states for a note never studied.
  Future<Map<String, Map<String, ReviewState>>> readMany(
    Iterable<String> paths,
  ) async {
    final wanted = paths.toList(growable: false);
    final entries = await _state.read(wanted);
    return {for (final path in wanted) path: _statesOf(entries[path])};
  }

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
    final (:entries, problem: _) = LibraryStateFile.readBlocking(
      root,
      filePath,
    );
    return {
      for (final MapEntry(:key, :value) in entries.entries)
        if (_statesOf(value) case final states when states.isNotEmpty)
          key: states,
    };
  }

  /// The states of [readAllBlocking], decoded only if the file is no longer
  /// the version [known] (#967): `states` is null when it still is, and the
  /// caller keeps what it decoded then. The stamp is taken before the file
  /// is read, so a write that lands in between shows as a different stamp
  /// at the next call and is read again, never missed.
  ///
  /// For code already on a background isolate. A file that is missing has no
  /// stamp and is always read, which costs a failed open.
  static ({
    ReviewFileStamp? stamp,
    Map<String, Map<String, ReviewState>>? states,
  })
  readAllUnless(String root, ReviewFileStamp? known) {
    final stamp = _stampOf(FileStat.statSync(p.join(root, filePath)));
    if (stamp != null && stamp == known) return (stamp: stamp, states: null);
    return (stamp: stamp, states: readAllBlocking(root));
  }

  /// [readAllUnless] on a background isolate.
  Future<
    ({ReviewFileStamp? stamp, Map<String, Map<String, ReviewState>>? states})
  >
  readAllIfChanged(ReviewFileStamp? known) {
    final library = root;
    return Isolate.run(() => readAllUnless(library, known));
  }

  /// Fires with the library root after this app wrote the file: the Study
  /// view counts again. A copy the sync brings is told by the sync.
  static Stream<String> get changes => _changes.stream;

  static final StreamController<String> _changes =
      StreamController<String>.broadcast();

  /// Records that the card [key] of the note at [path] is now in [state];
  /// null takes it back to a card never reviewed (an undone first grade).
  Future<void> write(String path, String key, ReviewState? state) {
    final json = state?.toJson();
    return _told(
      _state.update((entries) {
        final cards = _cardsOf(entries[path]);
        if (json == null) {
          if (cards.remove(key) == null) return false;
          if (cards.isEmpty) {
            entries.remove(path);
          } else {
            entries[path] = cards;
          }
          return true;
        }
        cards[key] = json;
        entries[path] = cards;
        return true;
      }),
    );
  }

  /// Carries the entries of [from] to [to], both library-relative: a note
  /// renamed or moved, or a folder and every note under it.
  ///
  /// Most moves have nothing to carry, and a library moves a thousand notes
  /// as readily as one: the file is read and rewritten on a background
  /// isolate, so a move that has no entry to carry must not go there (#968).
  /// A library with no review file is told by a stat; one with a file, by
  /// the paths it holds, which are read once per version of the file and
  /// kept ([ReviewFileStamp]) for the next move.
  Future<void> moved(String from, String to) async {
    // A write of this app still in the file's queue is not on disk yet, so
    // neither the stat nor the kept paths can see it: a first grade of a
    // deck, then the deck renamed, must carry the entry the grade is about
    // to make. With one in flight the move takes its place in the queue.
    if (!_writing && !await _mayHold(from) && !_writing) return;
    await _told(_state.moved(from, to));
  }

  /// Drops the entries of [paths], library-relative, and of the notes under
  /// them: the files the library saw leave.
  ///
  /// Only a deletion the library observed comes through here; see the
  /// library comment.
  Future<void> removed(Iterable<String> paths) => _told(_state.removed(paths));

  /// Forgets every card of the note at [path]: **Reset the review of this
  /// deck**.
  Future<void> resetNote(String path) =>
      _told(_state.update((entries) => entries.remove(path) != null));

  /// Forgets every card of every deck: **Reset all reviews**. The notes
  /// are not touched.
  Future<void> resetAll() => _told(
    _state.update((entries) {
      if (entries.isEmpty) return false;
      entries.clear();
      return true;
    }),
  );

  /// Whether the file holds an entry for [path] or for a note under it.
  Future<bool> _mayHold(String path) async {
    final stamp = _stampOf(await FileStat.stat(p.join(root, filePath)));
    if (stamp == null) {
      _heldPaths.remove(root);
      return false;
    }
    final kept = _heldPaths[root];
    final library = root;
    final held = kept != null && kept.stamp == stamp
        ? kept
        : await Isolate.run(() => _pathsOf(library));
    _heldPaths[root] = held;
    return held.paths.contains(path) ||
        held.paths.any((other) => isUnder(path, other));
  }

  /// The paths each library's file held when it was last looked at, by the
  /// version of the file they came from.
  static final Map<String, ({ReviewFileStamp? stamp, Set<String> paths})>
  _heldPaths = {};

  /// The stamp and the note paths of the library [root]'s file, read here
  /// and now: for a background isolate. The stamp comes before the read,
  /// as in [readAllUnless].
  static ({ReviewFileStamp? stamp, Set<String> paths}) _pathsOf(String root) {
    final stamp = _stampOf(FileStat.statSync(p.join(root, filePath)));
    final (:entries, problem: _) = LibraryStateFile.readBlocking(
      root,
      filePath,
    );
    return (stamp: stamp, paths: entries.keys.toSet());
  }

  /// The version of a file whose stat is [stat]; null if there is no file.
  static ReviewFileStamp? _stampOf(FileStat stat) =>
      stat.type == FileSystemEntityType.file
      ? (modified: stat.modified.microsecondsSinceEpoch, size: stat.size)
      : null;

  /// Tells [changes] that the file was written, once [wrote] says it was.
  ///
  /// Every write of the file comes through here, called as the write is
  /// started, so the count of those in flight is exact.
  Future<void> _told(Future<bool> wrote) async {
    _inFlight[root] = (_inFlight[root] ?? 0) + 1;
    try {
      if (await wrote && _changes.hasListener) _changes.add(root);
    } finally {
      final left = _inFlight[root]! - 1;
      if (left == 0) {
        _inFlight.remove(root);
      } else {
        _inFlight[root] = left;
      }
    }
  }

  /// How many writes of this app are started and not finished, by library.
  static final Map<String, int> _inFlight = {};

  bool get _writing => _inFlight.containsKey(root);

  /// A note's raw cards, copied so an update can change them: none for an
  /// entry that is not an object.
  static Map<String, Object?> _cardsOf(Object? entry) => entry is Map
      ? {for (final card in entry.entries) card.key.toString(): card.value}
      : <String, Object?>{};

  static Map<String, ReviewState> _statesOf(Object? entry) => {
    for (final MapEntry(:key, :value) in _cardsOf(entry).entries)
      key: ?ReviewState.fromJson(value),
  };
}
