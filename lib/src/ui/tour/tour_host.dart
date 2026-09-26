/// Starting the guided tour (#266), from wherever it is asked for: the
/// welcome's offer once a library opens, the command palette, and the
/// Settings → About row.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/welcome.dart';
import 'package:niman/src/library/library_state.dart';
import 'package:niman/src/ui/cheatsheet/cheatsheet_screen.dart';
import 'package:niman/src/ui/tour/tour_overlay.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/welcome/welcome_copy.dart';

/// Starts the tour for the window in front of us.
///
/// What the steps may point at is decided here: the source switch only
/// when the library offers both editors, the dock only on a window wide
/// enough to have one. [from] is where a resumed tour picks up.
///
/// [openCheatsheet] is how the last step hands over; the shell passes
/// its own (which can insert into the open note), and a caller without
/// one gets the cheatsheet as a page to read.
Future<void> startTour(
  BuildContext context,
  WidgetRef ref, {
  int from = 0,
  Future<void> Function(BuildContext context)? openCheatsheet,
}) async {
  final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
  final store = await welcomeStore(ref);
  final session = ref.read(librarySessionProvider);
  final editors = await session.enabledEditors;
  if (!context.mounted) return;
  final steps = tourSteps(
    const WelcomeCopy(),
    canSwitchEditor: editors.length > 1,
    hasDock: wide,
  );
  final index = from.clamp(0, steps.length - 1);
  await showTour(
    context,
    TourRun(
      steps: steps,
      copy: const WelcomeCopy(),
      initialStep: index,
      onStep: (step) => _persist(store, (s) => s.setTourStep(step)),
      onDone: () => _markDone(store),
      onAction: (action) async {
        // The step hands the tour over to what it opens; the tour is
        // done, and the cheatsheet is on screen.
        await _markDone(store);
        if (!context.mounted) return;
        switch (action) {
          case TourAction.cheatsheet:
            await (openCheatsheet ?? _openCheatsheetForReading)(context);
        }
      },
    ),
  );
}

/// Resumes the tour where it stopped, for the palette's *Take the tour*:
/// a finished tour starts over, an unfinished one picks up.
Future<void> resumeTour(BuildContext context, WidgetRef ref) async {
  final store = await welcomeStore(ref);
  final state = await store?.state();
  if (!context.mounted) return;
  final from = state != null && !state.tourSeen ? state.tourStep : 0;
  await startTour(context, ref, from: from);
}

/// Offers the tour once, when the welcome asked for it and a library is
/// open.
///
/// The offer is spent the moment it is shown: accepting and quitting
/// mid-tour must not raise it again on the next launch, and declining
/// leaves the tour to Help and the palette.
Future<void> offerTour(BuildContext context, WidgetRef ref) async {
  final store = await welcomeStore(ref);
  if (store == null) return;
  final state = await store.state();
  if (!state.tourOffer || state.tourSeen) return;
  await store.setTourOffer(offer: false);
  if (!context.mounted) return;
  const copy = WelcomeCopy();
  final show = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('tour-offer'),
      title: Text(copy.tourOfferTitle),
      content: Text(copy.tourOfferBody),
      actions: [
        TextButton(
          key: const Key('tour-offer-no'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(copy.tourOfferNo),
        ),
        FilledButton(
          key: const Key('tour-offer-yes'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(copy.tourOfferYes),
        ),
      ],
    ),
  );
  if (show != true) return;
  if (!context.mounted) return;
  await startTour(context, ref);
}

/// The tour is over (Done, or the cheatsheet hand-over): seen, and back
/// at its start for the next run.
Future<void> _markDone(WelcomeStore? store) => _persist(store, (s) async {
  await s.setTourStep(0);
  await s.setTourSeen(seen: true);
});

/// The first-run state, or null when there is none to keep it in (a test
/// bed, a database that will not open): the tour still runs, it just
/// forgets where it was.
Future<WelcomeStore?> welcomeStore(WidgetRef ref) async {
  try {
    return await ref.read(welcomeStoreProvider.future);
  } on Object {
    return null;
  }
}

/// Opens the cheatsheet with nothing to insert into: the tour's hand-over
/// from a caller that has no open note to offer (Settings → About).
Future<void> _openCheatsheetForReading(BuildContext context) =>
    showMarkdownCheatsheet(context);

Future<void> _persist(
  WelcomeStore? store,
  Future<void> Function(WelcomeStore store) write,
) async {
  if (store == null) return;
  try {
    await write(store);
  } on Object catch (error) {
    // A store that will not write is not a reason to take the tour down.
    _log.warning('the tour could not be saved ($error)');
  }
}

const AppLogger _log = AppLogger(name: 'tour');
