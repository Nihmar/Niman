/// A study session (#533, `docs/records/flashcards.md`, "Scheduling" and
/// the decisions on sessions): the queue of one deck, or of a category's
/// decks, and the grades given to it.
///
/// Pure. A grade, or an undo, returns the [StateWrite]s the caller makes
/// to `ReviewStore`; the session does no I/O and keeps its own picture of
/// every card's state, so it needs no read in between.
library;

import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/flashcards/queue_kind.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:niman/src/flashcards/session_card.dart';
import 'package:niman/src/flashcards/session_deck.dart';
import 'package:niman/src/flashcards/session_summary.dart';
import 'package:niman/src/flashcards/sm2.dart';
import 'package:niman/src/flashcards/state_write.dart';

/// One grade given, kept to take it back.
final class _Entry {
  new({
    required this.card,
    required this.kind,
    required this.before,
    required this.grade,
    required this.requeued,
    required this.at,
  });

  final SessionCard card;
  final QueueKind kind;
  final ReviewState? before;
  final Grade grade;
  final bool requeued;
  final DateTime at;
}

/// The cards of a study and the grades given them.
final class StudySession {
  /// A session over [decks] on the study day [today], with at most
  /// [newPerDay] new cards per deck per day, [clock] telling the time.
  ///
  /// The queue is the cards due, oldest due first (the decks' order, then
  /// note order, breaking ties), then each deck's new cards in note order up
  /// to the deck's share of the day's limit: [newPerDay] less the cards of
  /// the deck first graded today.
  factory start({
    required List<SessionDeck> decks,
    required DateTime today,
    required int newPerDay,
    DateTime Function()? clock,
  }) {
    final states = <({String deck, String key}), ReviewState>{};
    final due = <(SessionCard, ReviewState)>[];
    final fresh = <SessionCard>[];
    for (final deck in decks) {
      var introduced = 0;
      final unseen = <SessionCard>[];
      for (final card in deck.cards) {
        final session = SessionCard(deck.path, card);
        final state = deck.states[card.key];
        if (state == null) {
          unseen.add(session);
          continue;
        }
        states[session.id] = state;
        if (state.isDue(today)) due.add((session, state));
        if (state.first == today) introduced++;
      }
      final room = newPerDay - introduced;
      fresh.addAll(unseen.take(room < 0 ? 0 : room));
    }
    // A stable sort: the cards of one day stay in deck and note order.
    final ordered = _stableSortedBy(due, (entry) => entry.$2.due);
    return StudySession._(
      decks: decks,
      today: DateTime(today.year, today.month, today.day),
      clock: clock ?? DateTime.now,
      states: states,
      queue: [
        for (final (card, _) in ordered) (card, QueueKind.due),
        for (final card in fresh) (card, QueueKind.fresh),
      ],
    );
  }

  new _({
    required this.decks,
    required this.today,
    required DateTime Function() clock,
    required this._states,
    required this._queue,
  }) : _clock = clock,
       startedAt = clock();

  /// The decks studied.
  final List<SessionDeck> decks;

  /// The study day, a date at midnight.
  final DateTime today;

  /// When the session began.
  final DateTime startedAt;

  final DateTime Function() _clock;
  final Map<({String deck, String key}), ReviewState> _states;
  final List<(SessionCard, QueueKind)> _queue;
  final List<_Entry> _history = [];
  bool _shown = false;

  /// The card to ask, or null when the queue is empty.
  SessionCard? get current => _queue.isEmpty ? null : _queue.first.$1;

  /// Why [current] is in the queue; null when there is none.
  QueueKind? get currentKind => _queue.isEmpty ? null : _queue.first.$2;

  /// [current]'s review state, null for a new card or when there is none.
  ReviewState? get currentState {
    final card = current;
    return card == null ? null : _states[card.id];
  }

  /// Whether the queue is empty: the session is over.
  bool get isDone => _queue.isEmpty;

  /// Whether the answer to [current] is on show.
  bool get answerShown => _shown;

  /// How many cards the queue holds, [current] included.
  int get remaining => _queue.length;

  /// How many of them are due (reviewed before).
  int get remainingDue => _count(QueueKind.due);

  /// How many of them are new.
  int get remainingNew => _count(QueueKind.fresh);

  /// How many of them were graded Again in this session and are back.
  int get remainingAgain => _count(QueueKind.again);

  /// How many grades can be taken back.
  int get undoable => _history.length;

  /// What each grade would schedule [current] for, in days; empty when the
  /// session is over. For the four buttons.
  Map<Grade, int> get previews =>
      current == null ? const {} : intervalPreviews(currentState);

  /// Shows the answer to [current].
  void show() {
    if (current != null) _shown = true;
  }

  /// Grades [current], whether or not the answer was shown, and returns the
  /// write to make. An Again card goes back at the end of the queue and
  /// comes back until it is graded another way; any other grade is its
  /// last for the session.
  List<StateWrite> grade(Grade grade) {
    final (card, kind) = _queue.first;
    final before = _states[card.id];
    final now = _clock();
    final after = gradeCard(before, grade, today, now: now);
    _queue.removeAt(0);
    final again = grade == Grade.again;
    if (again) _queue.add((card, QueueKind.again));
    _states[card.id] = after;
    _history.add(
      _Entry(
        card: card,
        kind: kind,
        before: before,
        grade: grade,
        requeued: again,
        at: now,
      ),
    );
    _shown = false;
    return [StateWrite(card.deckPath, card.card.key, after)];
  }

  /// Takes the last grade back: the card is [current] again with the state
  /// it had, and the write that restores it is returned. Empty when there is
  /// nothing to take back.
  List<StateWrite> undo() {
    if (_history.isEmpty) return const [];
    final entry = _history.removeLast();
    // Every later grade is already undone, so the card's Again copy, when
    // it has one, is the last of the queue.
    if (entry.requeued) _queue.removeLast();
    _queue.insert(0, (entry.card, entry.kind));
    final before = entry.before;
    if (before == null) {
      _states.remove(entry.card.id);
    } else {
      _states[entry.card.id] = before;
    }
    _shown = false;
    return [StateWrite(entry.card.deckPath, entry.card.card.key, before)];
  }

  /// What the session came to so far; the end screen's numbers.
  SessionSummary get summary {
    final grades = {for (final grade in Grade.values) grade: 0};
    for (final entry in _history) {
      grades[entry.grade] = grades[entry.grade]! + 1;
    }
    final end = isDone && _history.isNotEmpty ? _history.last.at : _clock();
    DateTime? next;
    var nextCount = 0;
    for (final deck in decks) {
      for (final card in deck.cards) {
        final due = _states[(deck: deck.path, key: card.key)]?.due;
        if (due == null || !due.isAfter(today)) continue;
        if (next == null || due.isBefore(next)) {
          next = due;
          nextCount = 1;
        } else if (due == next) {
          nextCount++;
        }
      }
    }
    return SessionSummary(
      reviewed: {for (final entry in _history) entry.card.id}.length,
      grades: Map.unmodifiable(grades),
      elapsed: end.difference(startedAt),
      nextDue: next,
      nextCount: nextCount,
    );
  }

  int _count(QueueKind kind) =>
      _queue.where((entry) => entry.$2 == kind).length;
}

List<T> _stableSortedBy<T, K extends Comparable<K>>(
  List<T> items,
  K Function(T) key,
) {
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])]
    ..sort((a, b) {
      final byKey = key(a.$2).compareTo(key(b.$2));
      return byKey != 0 ? byKey : a.$1.compareTo(b.$1);
    });
  return [for (final (_, item) in indexed) item];
}
