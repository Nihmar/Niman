/// The decks of the open library as the Study screens read them (#533): a
/// [ChangeNotifier] holding the catalog's last snapshot, counted, and kept
/// current by what changes it.
///
/// Three things move it: the index (a deck note saved, added, removed or
/// retyped: debounced, then every deck whose modification time moved is
/// read again), `review.json` (a grade of this app, or a copy the sync
/// brought: the counts again, no note read) and the library's own settings
/// (the day's limit of new cards, the hour a day starts), which are asked at
/// every refresh.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/flashcards/deck_catalog.dart';
import 'package:niman/src/flashcards/deck_summary.dart';
import 'package:niman/src/flashcards/deck_tree.dart';
import 'package:niman/src/flashcards/review_store.dart';
import 'package:niman/src/flashcards/study_day.dart';

/// What the counts depend on in the library's settings.
typedef StudySettings = ({int newPerDay, int dayStartHour});

/// The decks of the library, counted for today, as a tree.
final class DeckCatalogController extends ChangeNotifier {
  /// A controller over [catalog], [settings] read at each refresh.
  ///
  /// [indexEvents] is the session's stream of index changes and
  /// [syncChanges] the paths a sync wrote locally; either may be null.
  /// [now] is the clock and [settle] how long a burst of index changes
  /// waits before the decks are looked at.
  new({
    required this.catalog,
    required this.settings,
    Stream<Object?>? indexEvents,
    Stream<Set<String>>? syncChanges,
    DateTime Function()? now,
    this.settle = const Duration(milliseconds: 400),
  }) : _now = now ?? DateTime.now {
    _subscriptions = [
      ?indexEvents?.listen((_) => _later(full: true)),
      ReviewStore.changes.listen((root) {
        if (root == catalog.root) _later(full: false);
      }),
      ?syncChanges?.listen((paths) {
        if (paths.contains(ReviewStore.filePath)) _later(full: false);
        if (paths.any((path) => path.endsWith('.md'))) _later(full: true);
      }),
    ];
  }

  static const AppLogger _log = AppLogger(name: 'flashcards');

  /// What reads the decks.
  final DeckCatalog catalog;

  /// The library settings the counts depend on.
  final Future<StudySettings> Function() settings;

  /// How long a burst of changes waits before the refresh.
  final Duration settle;

  final DateTime Function() _now;
  late final List<StreamSubscription<Object?>> _subscriptions;
  Timer? _timer;
  bool _fullPending = false;
  Future<void>? _running;
  bool _rerun = false;
  bool _rerunFull = false;
  bool _disposed = false;

  DeckSnapshot _snapshot = DeckSnapshot.empty;
  StudySettings _settings = (newPerDay: 20, dayStartHour: 0);
  DateTime _today = DateTime(1970);
  List<DeckSummary> _summaries = const [];
  Set<String> _selected = const {};
  DeckTree _tree = const DeckTree([]);
  bool _loaded = false;

  /// Whether the decks were read at least once.
  bool get loaded => _loaded;

  /// The study day the counts are for, a date at midnight.
  DateTime get today => _today;

  /// The limit of new cards per deck per day the counts used.
  int get newPerDay => _settings.newPerDay;

  /// Every deck, counted, in path order.
  List<DeckSummary> get summaries => _summaries;

  /// The tags the decks carry, alphabetically: the chips.
  List<String> get tags => DeckTree.tagsOf(_summaries);

  /// The tags the tree is filtered by: only the decks carrying all of them.
  Set<String> get selectedTags => _selected;

  /// The Study tree of the decks carrying every selected tag.
  DeckTree get tree => _tree;

  /// The last snapshot, with the review states of the whole library by
  /// note path and card key: what a session of the decks starts from.
  DeckSnapshot get snapshot => _snapshot;

  /// Filters the tree by [tags], keeping those that are still on a deck.
  void selectTags(Set<String> tags) {
    final present = tags.intersection(this.tags.toSet());
    if (setEquals(present, _selected)) return;
    _selected = present;
    _rebuildTree();
    notifyListeners();
  }

  /// Adds [tag] to the filter, or takes it off.
  void toggleTag(String tag) => selectTags(
    _selected.contains(tag)
        ? ({..._selected}..remove(tag))
        : {..._selected, tag},
  );

  /// Finds the decks, reads those that changed, and counts. Calls that
  /// overlap queue behind the one running.
  Future<void> refresh() => _load(full: true);

  /// Reads `review.json` again and counts, with no note read.
  Future<void> refreshStates() => _load(full: false);

  void _later({required bool full}) {
    if (_disposed) return;
    _fullPending = _fullPending || full;
    _timer?.cancel();
    _timer = Timer(settle, () {
      final wantsFull = _fullPending;
      _fullPending = false;
      unawaited(_load(full: wantsFull));
    });
  }

  /// One load at a time: a request that comes while one runs makes it run
  /// once more when it ends (a full one if any request was), so no answer
  /// is lost to a newer, narrower one.
  Future<void> _load({required bool full}) {
    final running = _running;
    if (running != null) {
      _rerun = true;
      _rerunFull = _rerunFull || full;
      return running;
    }
    return _running = _drain(full);
  }

  Future<void> _drain(bool first) async {
    var full = first;
    try {
      do {
        _rerun = false;
        _rerunFull = false;
        await _once(full: full);
        full = _rerunFull;
      } while (_rerun && !_disposed);
    } finally {
      _running = null;
    }
  }

  Future<void> _once({required bool full}) async {
    try {
      final settings = await this.settings();
      final snapshot = full || !_loaded
          ? await catalog.load()
          : await catalog.reloadStates();
      if (_disposed) return;
      // The snapshot is always the latest, for a session to start from, but
      // what the screens show is told only when it moved: a note saved
      // elsewhere in the library reloads the decks and, the counts being
      // the same, notifies nobody (#947).
      _snapshot = snapshot;
      final today = studyToday(_now(), settings.dayStartHour);
      final summaries = snapshot.summaries(today, settings.newPerDay);
      final moved =
          !_loaded ||
          today != _today ||
          settings != _settings ||
          !listEquals(summaries, _summaries);
      _loaded = true;
      if (!moved) return;
      _settings = settings;
      _today = today;
      _summaries = summaries;
      _selected = _selected.intersection(tags.toSet());
      _rebuildTree();
      notifyListeners();
    } on Object catch (error) {
      _log.warning('could not read the decks: $error');
    }
  }

  void _rebuildTree() {
    _tree = DeckTree.build(_summaries, tags: _selected);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}
