import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts a study session of the deck at [notePath], the note's absolute
/// path (#533, phase 4).
typedef DeckStudyStarter = Future<void> Function(
  BuildContext context,
  String notePath,
);

/// What the deck's **Study** button, its ⋮ entry and `F5` start.
///
/// The seam between the deck view and the review: null until the review
/// exists, and while it is null Study is shown but disabled. The review
/// replaces the provider's body with its starter; nothing else in the deck
/// view changes.
final deckStudyStarterProvider = Provider<DeckStudyStarter?>((ref) => null);
