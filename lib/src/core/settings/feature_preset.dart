/// The presets of the Features screen (#1109): a starting point for the
/// switches, not a mode.
///
/// A preset only writes switches; once applied, the library is just a set
/// of them, and [FeaturePreset.of] recognises the preset they happen to
/// match.
library;

import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';

/// One preset, by name, with the features it leaves on.
enum FeaturePreset {
  /// Every feature on: the default.
  everything({...LibraryFeature.values}),

  /// Notes, search, templates and the readers.
  writing({
    LibraryFeature.search,
    LibraryFeature.templates,
    LibraryFeature.readers,
  }),

  /// Notes and search: everything else off, templates and readers too.
  notesOnly({LibraryFeature.search}),

  /// Tasks, journal, calendar and Home.
  ///
  /// Search is off here, literally as the design lists it: this preset is
  /// for a library used as a planner, and one switch turns it back on.
  tasksAndJournal({
    LibraryFeature.todo,
    LibraryFeature.journal,
    LibraryFeature.calendar,
    LibraryFeature.home,
  });

  new(this.on);

  /// The features the preset leaves on; every other one is off.
  final Set<LibraryFeature> on;

  /// Whether the preset leaves [feature] on.
  bool leavesOn(LibraryFeature feature) => on.contains(feature);

  /// The preset the known switches of [features] match, or null — the
  /// screen's *Custom*. A switch this build does not know takes no part.
  static FeaturePreset? of(Features features) {
    for (final preset in FeaturePreset.values) {
      if (LibraryFeature.values.every(
        (feature) => features.own(feature) == preset.leavesOn(feature),
      )) {
        return preset;
      }
    }
    return null;
  }
}
