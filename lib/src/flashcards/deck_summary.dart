/// What the Study view shows of a deck (#533): its place, its name and its
/// counts, computed from the deck's card keys and the review states, with
/// no read of the note.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/deck_meta.dart';
import 'package:niman/src/flashcards/review_state.dart';
import 'package:path/path.dart' as p;

/// A deck note as read once: its metadata and its cards' keys. What the
/// catalog keeps per note, by modification time, so a refresh reads again
/// only the decks that changed.
@immutable
final class DeckInfo {
  /// A deck at [path] last modified [modified].
  const new({
    required this.path,
    required this.modified,
    required this.meta,
    required this.keys,
  });

  /// The note's library-relative path.
  final String path;

  /// The note's modification time when it was read.
  final DateTime modified;

  /// The frontmatter's say on the deck.
  final DeckMeta meta;

  /// The keys of its cards, in note order, each unique.
  final List<String> keys;

  /// The deck's name: the note's `title:`, else its file name.
  String get name => meta.title ?? p.posix.basenameWithoutExtension(path);

  /// The deck's counts on the study day [today] — a date at midnight —
  /// with [states] its cards' review states and [newPerDay] the library's
  /// limit of new cards per deck per day.
  DeckSummary summary(
    Map<String, ReviewState> states,
    DateTime today,
    int newPerDay,
  ) {
    var due = 0;
    var fresh = 0;
    var introduced = 0;
    for (final key in keys) {
      final state = states[key];
      if (state == null) {
        fresh++;
        continue;
      }
      if (state.isDue(today)) due++;
      if (state.first == today) introduced++;
    }
    final room = newPerDay - introduced;
    return DeckSummary(
      path: path,
      name: name,
      category: meta.category,
      tags: meta.tags,
      total: keys.length,
      due: due,
      fresh: fresh,
      newAvailable: room <= 0 ? 0 : (fresh < room ? fresh : room),
    );
  }
}

/// A deck, counted.
@immutable
final class DeckSummary {
  /// A deck of [total] cards.
  const new({
    required this.path,
    required this.name,
    required this.category,
    required this.tags,
    required this.total,
    required this.due,
    required this.fresh,
    required this.newAvailable,
  });

  /// The note's library-relative path.
  final String path;

  /// The deck's name.
  final String name;

  /// Its place in the Study tree, the categories from the root down; empty
  /// for **No category**.
  final List<String> category;

  /// The note's tags.
  final List<String> tags;

  /// All its cards.
  final int total;

  /// The cards reviewed before whose day has come: due today or earlier.
  final int due;

  /// The cards never reviewed.
  final int fresh;

  /// The new cards a study of today shows: [fresh], but no more than the
  /// day's limit leaves after the new cards already shown today.
  final int newAvailable;

  /// What a study of the deck shows today.
  int get toStudy => due + newAvailable;
}
