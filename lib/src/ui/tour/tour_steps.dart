/// The guided tour's steps (#266): one table of what each step points at,
/// what it says, and when it is left out.
library;

import 'package:niman/src/ui/strings.dart';

/// What a step can do beyond being read.
enum TourAction {
  /// Hands the tour over to the cheatsheet: the overlay closes, the
  /// cheatsheet opens, and the tour is done.
  cheatsheet,
}

/// One step of the tour.
final class TourStep {
  /// Creates a step.
  const new({
    required this.target,
    required this.title,
    required this.body,
    this.action,
  });

  /// The [TourTargets] id this step points at, or null for a card with
  /// nothing to spotlight.
  final String? target;

  /// The step's heading.
  final String title;

  /// The step's prose.
  final String body;

  /// What the step's primary button does, when it is not Next/Done.
  final TourAction? action;
}

/// The steps for this window, in order.
///
/// [canSwitchEditor] drops the modes step when the source editor is off
/// (a library that only writes live has no switch to point at);
/// [hasDock] drops the dock step on a phone, where the note's menu opens
/// the same three panes.
List<TourStep> tourSteps({
  required bool canSwitchEditor,
  required bool hasDock,
}) {
  return [
    TourStep(
      target: TourTargets.tree,
      title: AppStrings.tourTreeTitle,
      body: AppStrings.tourTreeBody,
    ),
    TourStep(
      target: TourTargets.create,
      title: AppStrings.tourCreateTitle,
      body: AppStrings.tourCreateBody,
    ),
    TourStep(
      target: TourTargets.note,
      title: AppStrings.tourNoteTitle,
      body: AppStrings.tourNoteBody,
    ),
    if (canSwitchEditor)
      TourStep(
        target: TourTargets.modeSwitch,
        title: AppStrings.tourModesTitle,
        body: AppStrings.tourModesBody,
      ),
    TourStep(
      target: TourTargets.toolbar,
      title: AppStrings.tourToolbarTitle,
      body: AppStrings.tourToolbarBody,
    ),
    TourStep(
      target: TourTargets.nav,
      title: AppStrings.tourTabsTitle,
      body: AppStrings.tourTabsBody,
    ),
    if (hasDock)
      TourStep(
        target: TourTargets.dock,
        title: AppStrings.tourDockTitle,
        body: AppStrings.tourDockBody,
      ),
    // Last: the tour hands over to the cheatsheet (#265) — the playground
    // the issue asked for, with nothing of ours left in the library.
    TourStep(
      target: TourTargets.cheatsheet,
      title: AppStrings.tourCheatsheetTitle,
      body: AppStrings.tourCheatsheetBody,
      action: TourAction.cheatsheet,
    ),
  ];
}

/// The ids the steps point at.
abstract final class TourTargets {
  /// The tree pane (either layout).
  static const String tree = 'tree';

  /// The new-note affordance: the footer's + on a desktop, the FAB on a
  /// phone.
  static const String create = 'create';

  /// The note pane.
  static const String note = 'note';

  /// The editor-kind switch in the note's chrome.
  static const String modeSwitch = 'mode-switch';

  /// The formatting toolbar.
  static const String toolbar = 'toolbar';

  /// The navigation: the rail on a wide window, the bottom bar on a
  /// phone.
  static const String nav = 'nav';

  /// The right dock.
  static const String dock = 'dock';

  /// The cheatsheet's own content, where the tour ends.
  static const String cheatsheet = 'cheatsheet';

  /// Every id a step may name, for the test that keeps a step from
  /// pointing at a target no widget registers.
  static const Set<String> all = {
    tree,
    create,
    note,
    modeSwitch,
    toolbar,
    nav,
    dock,
    cheatsheet,
  };
}
