import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/flashcards/deck.dart';
import 'package:niman/src/flashcards/grade.dart';
import 'package:niman/src/flashcards/library_decks.dart';
import 'package:niman/src/flashcards/study_day.dart';
import 'package:niman/src/flashcards/study_session.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/markdown/note_bytes.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:path/path.dart' as p;

/// A study on screen (#533): the session, what it is called, and the
/// review states each grade and undo writes.
///
/// The writes are handed to [reviews] in the order they are made, and the
/// store runs a library's writes one after the other: nothing is awaited
/// between two grades.
final class ReviewRun extends ChangeNotifier {
  /// A run of [session] over the decks of the library at [root].
  new({
    required this.session,
    required this.title,
    required this.root,
    required this.reviews,
    this.nextDeck,
  });

  /// The cards and the grades.
  final StudySession session;

  /// The deck's name, or the category's.
  final String title;

  /// The library's absolute path.
  final String root;

  /// Where the grades are written.
  final DeckReviewSource reviews;

  /// Finds a deck still to study today, other than these, by its
  /// library-relative path; null when there is none to look for.
  final Future<String?> Function()? nextDeck;

  /// Shows the answer.
  void show() {
    if (session.isDone || session.answerShown) return;
    session.show();
    notifyListeners();
  }

  /// Grades the card on show; nothing before its answer is.
  void grade(Grade grade) {
    if (session.isDone || !session.answerShown) return;
    _write(session.grade(grade));
  }

  /// Takes the last grade back.
  void undo() {
    if (session.undoable == 0) return;
    _write(session.undo());
  }

  void _write(List<StateWrite> writes) {
    for (final write in writes) {
      unawaited(reviews.write(root, write.path, write.key, write.state));
    }
    notifyListeners();
  }
}

/// A run over the deck notes at [paths], absolute, of the library [session]
/// has open: the notes read off the UI isolate, the states from [reviews],
/// today and the day's new cards from the library's settings. Null outside
/// a library; a note that does not read is left out.
Future<ReviewRun?> loadReviewRun({
  required LibrarySession session,
  required DeckReviewSource reviews,
  required List<String> paths,
}) async {
  final root = session.root;
  if (root == null) return null;
  final rel = [for (final path in paths) ?pathInLibrary(root, path)];
  final decks = await _readAll(root, rel);
  final read = [
    for (var i = 0; i < rel.length; i++)
      if (decks[i] case final deck?) (path: rel[i], deck: deck),
  ];
  if (read.isEmpty) return null;
  final newPerDay = await session.newCardsPerDay;
  final dayStart = (await session.ops?.journal)?.dayStartHour ?? 0;
  final first = read.first;
  final studied = {for (final deck in read) deck.path};
  return ReviewRun(
    session: StudySession.start(
      decks: [
        for (final (:path, :deck) in read)
          SessionDeck(
            path: path,
            cards: deck.cards,
            states: await reviews.read(root, path),
          ),
      ],
      today: studyToday(DateTime.now(), dayStart),
      newPerDay: newPerDay,
    ),
    title:
        first.deck.meta.title ?? p.posix.basenameWithoutExtension(first.path),
    root: root,
    reviews: reviews,
    nextDeck: () => _nextDeck(session, studied),
  );
}

/// The decks at [paths], library-relative, read on a background isolate:
/// a function of its own, so the closure carries the paths and nothing of
/// the caller's.
Future<List<Deck?>> _readAll(String root, List<String> paths) =>
    Isolate.run(() => [for (final path in paths) _read(root, path)]);

Deck? _read(String root, String path) {
  try {
    return Deck.read(
      decodeNoteText(File(p.join(root, path)).readAsBytesSync()),
    );
  } on FileSystemException {
    return null;
  }
}

/// The first deck of the library, in path order, with cards to study today
/// and not in [studied].
Future<String?> _nextDeck(LibrarySession session, Set<String> studied) async {
  final catalog = deckCatalogOf(session);
  if (catalog == null) return null;
  try {
    await catalog.refresh();
    for (final deck in catalog.summaries) {
      if (deck.toStudy > 0 && !studied.contains(deck.path)) return deck.path;
    }
    return null;
  } finally {
    catalog.dispose();
  }
}
