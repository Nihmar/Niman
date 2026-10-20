/// Which feature a Home tile or action belongs to (#1109).
///
/// A tile or an action whose feature is off is not built, and the editor
/// does not offer to add it. The Home's file is never written for it: the
/// layout the user made stays as it is, and turning the feature on brings
/// the tile back where it was.
///
/// Both are exhaustive `switch`es, so a tile kind or an action kind cannot
/// ship without saying which feature it belongs to, or that it is core.
library;

import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/home/home_action.dart';
import 'package:niman/src/home/home_layout.dart';
import 'package:niman/src/home/home_tile.dart';

/// The feature a tile of [kind] shows, or null for a tile of core: the
/// notes, the tags and the actions tile (each of its buttons has its own,
/// see [featureOfAction]).
LibraryFeature? featureOfTile(HomeTileKind kind) => switch (kind) {
  HomeTileKind.actions => null,
  HomeTileKind.journalToday => LibraryFeature.journal,
  HomeTileKind.tasksDue => LibraryFeature.todo,
  HomeTileKind.eventsToday => LibraryFeature.calendar,
  HomeTileKind.recent => null,
  HomeTileKind.pinned => null,
  HomeTileKind.journalCalendar => LibraryFeature.journal,
  HomeTileKind.topTags => null,
  HomeTileKind.randomNote => null,
  HomeTileKind.search => LibraryFeature.search,
  HomeTileKind.study => LibraryFeature.kindFlashcards,
};

/// The feature an action of [kind] runs, or null for core.
LibraryFeature? featureOfAction(HomeActionKind kind) => switch (kind) {
  HomeActionKind.newNote => null,
  HomeActionKind.addTask => LibraryFeature.todo,
  HomeActionKind.openNote => null,
  HomeActionKind.journal => LibraryFeature.journal,
  HomeActionKind.capture => LibraryFeature.capture,
};

/// Whether a tile of [kind] is on under [features]; a kind this build does
/// not know (null) is never drawn, so it counts as on.
bool tileKindIsOn(HomeTileKind? kind, Features features) =>
    switch (kind == null ? null : featureOfTile(kind)) {
      final feature? => features.isOn(feature),
      null => true,
    };

/// Whether an action of [kind] is on under [features].
bool actionKindIsOn(HomeActionKind? kind, Features features) =>
    switch (kind == null ? null : featureOfAction(kind)) {
      final feature? => features.isOn(feature),
      null => true,
    };

/// [layout] as the Home draws it: a tile whose feature is off is hidden.
///
/// For drawing only — it is never written, so the file keeps the tile.
HomeLayout homeLayoutUnder(HomeLayout layout, Features features) => HomeLayout([
  for (final t in layout.tiles)
    if (tileKindIsOn(t.kind, features)) t else t.copyWith(hidden: true),
]);
