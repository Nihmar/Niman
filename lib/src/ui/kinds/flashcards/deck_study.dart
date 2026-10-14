import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      (context, notePath) => _study(context, ref, notePath),
);

Future<void> _study(
  BuildContext context,
  Ref ref,
  String notePath, {
  bool replace = false,
}) async {
  final run = await loadReviewRun(
    session: ref.read(librarySessionProvider),
    reviews: ref.read(deckReviewSourceProvider),
    paths: [notePath],
  );
  if (run == null || !context.mounted) return;
  final tab = ref.read(reviewTabProvider);
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
            _study(context, ref, p.join(run.root, path), replace: true),
          ),
        ),
      ),
    ),
  );
  await (replace ? navigator.pushReplacement(route) : navigator.push(route));
}
