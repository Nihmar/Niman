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
/// has not arrived yet is not an orphan. Orphans go when Niman itself changes
/// a question (`pruneNote`) or the deck is reset (`resetNote`), and a note
/// the library saw leave takes its entry along (`removed`).
library;

import 'dart:async';
import 'dart:isolate';

import 'package:niman/src/core/library_state_file.dart';
import 'package:niman/src/flashcards/review_state.dart';

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
  Future<void> moved(String from, String to) => _told(_state.moved(from, to));

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

  /// Drops the cards of the note at [path] whose key is not in [keepKeys]:
  /// the orphans a question changed in Niman leaves behind.
  Future<void> pruneNote(String path, Set<String> keepKeys) {
    final keep = Set<String>.of(keepKeys);
    return _told(
      _state.update((entries) {
        if (!entries.containsKey(path)) return false;
        final cards = _cardsOf(entries[path]);
        final before = cards.length;
        cards.removeWhere((key, _) => !keep.contains(key));
        if (cards.isEmpty) {
          entries.remove(path);
          return true;
        }
        if (cards.length == before) return false;
        entries[path] = cards;
        return true;
      }),
    );
  }

  /// Tells [changes] that the file was written, once [wrote] says it was.
  Future<void> _told(Future<bool> wrote) async {
    if (await wrote && _changes.hasListener) _changes.add(root);
  }

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
