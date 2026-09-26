/// The first-run gate (#266): the deck in front of the app until it has
/// been finished or skipped, and the app otherwise.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/welcome/welcome_screen.dart';

/// The first run's state as the gate reads it, or null when there is no
/// store to read — a test bed with no application-support folder, or a
/// database that will not open — in which case there is no deck and the
/// app opens exactly as it did before #266.
final welcomeStateProvider = FutureProvider<WelcomeState?>((ref) async {
  try {
    final store = await ref.watch(welcomeStoreProvider.future);
    return await store.state();
  } on Object catch (error) {
    // A test bed without an application-support folder, a database that
    // will not open: the app opens as before #266, and the log says why.
    _log.warning('the first run could not be read ($error)');
    return null;
  }
});

/// [child], with the welcome deck in front of it on a first run.
final class WelcomeGate extends ConsumerWidget {
  /// Creates the gate over [child] (the library home).
  const new({required this.child, super.key});

  /// What the app shows when this is not a first run.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(welcomeStateProvider);
    final welcome = state.value;
    // Loading, no store, or already welcomed: the app, unchanged. The
    // deck never flashes in front of a library that was resumed.
    //
    // A first run makes the state resolve in the first frames and the
    // deck covers the app then; while it is still unknown the app stays
    // usable rather than frozen, which is also the only shape that
    // survives a test bed whose store never answers.
    if (welcome == null || welcome.deckSeen) return child;
    return WelcomeScreen(
      initialAnswer: welcome.experience,
      initialTourOffer: welcome.tourOffer,
      onAnswer: (answer) => unawaited(_answer(ref, answer)),
      onFinish: ({required experience, required tourOffer}) =>
          unawaited(_finish(ref, experience: experience, tourOffer: tourOffer)),
    );
  }
}

/// Keeps the answer as soon as it is tapped: a deck left halfway, or an
/// app killed behind it, does not lose what the user said.
Future<void> _answer(WidgetRef ref, MarkdownExperience answer) async {
  try {
    final store = await ref.read(welcomeStoreProvider.future);
    await store.setExperience(answer);
  } on Object catch (error) {
    _log.warning('the welcome answer was not kept ($error)');
  }
}

/// Leaves the deck: the answer (when one was given), the tour offer, and
/// the flag that this install has been welcomed.
Future<void> _finish(
  WidgetRef ref, {
  required MarkdownExperience? experience,
  required bool tourOffer,
}) async {
  try {
    final store = await ref.read(welcomeStoreProvider.future);
    if (experience != null) await store.setExperience(experience);
    await store.setTourOffer(offer: tourOffer);
    await store.setDeckSeen(seen: true);
  } on Object catch (error) {
    _log.warning('the welcome could not be closed ($error)');
  }
  ref.invalidate(welcomeStateProvider);
}

/// Opens the deck again, read-only: the pages, no question, no second
/// answer to store — Settings → About, and the palette's *What Niman can
/// do*.
Future<void> showWelcomeDeck(BuildContext context) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => WelcomeScreen(
        readOnly: true,
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
  );
}

const AppLogger _log = AppLogger(name: 'welcome');
