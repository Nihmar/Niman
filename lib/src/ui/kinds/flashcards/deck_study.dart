import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/device_shape.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/kinds/flashcards/review_run.dart';
import 'package:niman/src/ui/kinds/flashcards/review_tab.dart';
import 'package:niman/src/ui/kinds/flashcards/review_view.dart';
import 'package:path/path.dart' as p;

/// Starts a study session of the deck at [notePath], the note's absolute
/// path (#533, phase 4).
typedef DeckStudyStarter = Future<void> Function(
  BuildContext context,
  String notePath,
);

/// What the deck's **Study** button, its ⋮ entry and `F5` start: the
/// review of the deck — beside it on a wide window, as a tab of the panes
/// ([ReviewTab]), full screen elsewhere.
///
/// The seam between the deck view and the review: a test puts its own
/// starter here, or null, and while it is null Study is shown but disabled.
final deckStudyStarterProvider = Provider<DeckStudyStarter?>(
  (ref) =>
      (context, notePath) => studyDecks(context, ref.read, [notePath]),
);

/// How a study reads its providers: a `Ref`'s or a `WidgetRef`'s `read`.
typedef ProviderRead = T Function<T>(ProviderListenable<T> provider);

/// Studies the decks at [paths], absolute, together — one deck, or the
/// decks of a category under its name [title] — beside them on a wide
/// window, full screen elsewhere. [replace] takes the place of the full
/// screen study on show: **Next deck**.
Future<void> studyDecks(
  BuildContext context,
  ProviderRead read,
  List<String> paths, {
  String? title,
  bool replace = false,
}) async {
  final run = await loadReviewRun(
    session: read(librarySessionProvider),
    reviews: read(deckReviewSourceProvider),
    paths: paths,
    title: title,
  );
  if (run == null || !context.mounted) return;
  final tab = read(reviewTabProvider);
  if (tab.hosted && isWideShell(context)) return tab.open(run);
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = MaterialPageRoute<void>(
    builder: (context) => Scaffold(
      body: SafeArea(
        child: ReviewView(
          run: run,
          onClose: () => Navigator.pop(context),
          // The next deck's study takes this one's place.
          onNextDeck: (path) => unawaited(
            studyDecks(context, read, [p.join(run.root, path)], replace: true),
          ),
        ),
      ),
    ),
  );
  await (replace ? navigator.pushReplacement(route) : navigator.push(route));
}
