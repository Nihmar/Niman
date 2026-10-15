/// Where the decks come from (#533, `docs/records/flashcards.md`, "Where
/// the decks come from"): the notes whose frontmatter says
/// `type: flashcard`, found with one query on the index, read off the UI
/// isolate in one batch together with `review.json`.
///
/// Nothing new is indexed. The read decks are kept per note by its
/// modification time, so a refresh of a library of a million notes and forty
/// decks reads the decks that changed, and a change of `review.json` alone
/// counts again without reading a note. The decoded `review.json` is kept
/// too, by the file's modification time and size, so a refresh that finds
/// the file as it was decodes nothing (#967).
library;

import 'dart:io';
import 'dart:isolate';

import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/deck_summary.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/review_store.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:path/path.dart' as p;

/// The paths of the deck notes of the library [fields] indexes, in path
/// order: one seek on the `type` field of `frontmatter_fields`.
Future<List<String>> findDeckPaths(FieldSource fields) async => [
  for (final note in await fields.notesWithField('type', 'flashcard'))
    if (!note.isDir) note.path,
];

/// The decks of a library and their review states, as of one load.
@immutable
final class DeckSnapshot {
  /// A snapshot of [decks] and [states].
  const new({required this.decks, required this.states});

  /// No deck.
  static const DeckSnapshot empty = DeckSnapshot(
    decks: <DeckInfo>[],
    states: <String, Map<String, ReviewState>>{},
  );

  /// The deck notes, in path order.
  final List<DeckInfo> decks;

  /// The review states of the whole library, by note path and card key.
  final Map<String, Map<String, ReviewState>> states;

  /// The decks counted on the study day [today] with the library's limit of
  /// [newPerDay] new cards per deck per day. Pure: no read.
  List<DeckSummary> summaries(DateTime today, int newPerDay) => [
    for (final deck in decks)
      deck.summary(states[deck.path] ?? const {}, today, newPerDay),
  ];

  /// This snapshot over other [states].
  DeckSnapshot withStates(Map<String, Map<String, ReviewState>> states) =>
      DeckSnapshot(decks: decks, states: states);
}

/// Reads the decks of one library, keeping what it read.
final class DeckCatalog {
  /// A catalog of the library at [root] whose deck notes [find] lists.
  new({required this.root, required this.find});

  /// The library's absolute path.
  final String root;

  /// The library-relative paths of the deck notes (see [findDeckPaths]).
  final Future<List<String>> Function() find;

  final Map<String, DeckInfo> _cache = {};

  /// The decoded `review.json` and the version of the file it came from.
  ReviewFileStamp? _stamp;
  Map<String, Map<String, ReviewState>> _states = const {};
  DeckSnapshot _last = DeckSnapshot.empty;

  /// The last snapshot loaded; empty before the first.
  DeckSnapshot get snapshot => _last;

  /// How many notes the last [load] read, for the tests and the bench: the
  /// point of the cache is that this stays at the decks that changed.
  int notesRead = 0;

  /// Finds the decks and reads those that changed since the last load,
  /// with `review.json`, on one background isolate.
  Future<DeckSnapshot> load() async {
    final paths = await find();
    final known = {
      for (final path in paths)
        if (_cache[path] case final deck?) path: deck.modified,
    };
    final library = root;
    final stamp = _stamp;
    final read = await Isolate.run(() => _read(library, paths, known, stamp));
    notesRead = read.decks.length;
    _keep(read.stamp, read.states);
    for (final deck in read.decks) {
      _cache[deck.path] = deck;
    }
    // A deck no longer found, or whose note cannot be read, is dropped.
    final present = {...read.decks.map((d) => d.path), ...read.unchanged};
    _cache.removeWhere((path, _) => !present.contains(path));
    return _last = DeckSnapshot(
      decks: [for (final path in paths) ?_cache[path]],
      states: _states,
    );
  }

  /// Reads `review.json` again and keeps the decks: what a grade, a reset
  /// or a sync of the file asks, since no note changed.
  Future<DeckSnapshot> reloadStates() async {
    final read = await ReviewStore(root).readAllIfChanged(_stamp);
    _keep(read.stamp, read.states);
    notesRead = 0;
    return _last = _last.withStates(_states);
  }

  /// Keeps the states a read decoded, or leaves the ones kept when the file
  /// was still the version they came from ([states] null).
  void _keep(
    ReviewFileStamp? stamp,
    Map<String, Map<String, ReviewState>>? states,
  ) {
    _stamp = stamp;
    if (states != null) _states = states;
  }
}

typedef _Read = ({
  List<DeckInfo> decks,
  List<String> unchanged,
  ReviewFileStamp? stamp,
  Map<String, Map<String, ReviewState>>? states,
});

/// Reads, on a background isolate, the notes of [paths] whose modification
/// time is not the one in [known], and the review states unless the file is
/// still the version [stamp].
_Read _read(
  String root,
  List<String> paths,
  Map<String, DateTime> known,
  ReviewFileStamp? stamp,
) {
  final decks = <DeckInfo>[];
  final unchanged = <String>[];
  for (final path in paths) {
    final file = File(p.join(root, path));
    try {
      final modified = file.statSync().modified;
      if (known[path] == modified) {
        unchanged.add(path);
        continue;
      }
      final deck = Deck.read(decodeNoteText(file.readAsBytesSync()));
      decks.add(
        DeckInfo(
          path: path,
          modified: modified,
          meta: deck.meta,
          keys: [for (final card in deck.cards) card.key],
        ),
      );
    } on FileSystemException {
      // Gone since the index looked, or unreadable: not a deck for now.
    }
  }
  final reviews = ReviewStore.readAllUnless(root, stamp);
  return (
    decks: decks,
    unchanged: unchanged,
    stamp: reviews.stamp,
    states: reviews.states,
  );
}
