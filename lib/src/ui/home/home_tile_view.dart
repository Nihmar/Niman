/// One Home tile (#535): its frame, and what its kind shows inside.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/home/home_tile.dart';
import 'package:niman/src/home/home_tile_feature.dart';
import 'package:niman/src/ui/feature_off.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_icons.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/home/tiles/actions_tile.dart';
import 'package:niman/src/ui/home/tiles/events_today_tile.dart';
import 'package:niman/src/ui/home/tiles/journal_calendar_tile.dart';
import 'package:niman/src/ui/home/tiles/journal_today_tile.dart';
import 'package:niman/src/ui/home/tiles/pinned_tile.dart';
import 'package:niman/src/ui/home/tiles/random_note_tile.dart';
import 'package:niman/src/ui/home/tiles/recent_tile.dart';
import 'package:niman/src/ui/home/tiles/search_tile.dart';
import 'package:niman/src/ui/home/tiles/study_tile.dart';
import 'package:niman/src/ui/home/tiles/tasks_due_tile.dart';
import 'package:niman/src/ui/home/tiles/top_tags_tile.dart';

/// [tile] in its frame.
final class HomeTileView extends StatelessWidget {
  /// Draws [tile] over [host], its loads following [revision].
  const new({
    required this.tile,
    required this.host,
    required this.revision,
    this.fit = false,
    super.key,
  });

  /// Whether the tile takes its content's height (the phone's actions).
  final bool fit;

  /// The tile; its kind is a known one.
  final HomeTile tile;

  /// The shell's side of the Home.
  final HomeHost host;

  /// The Home's revision.
  final int revision;

  @override
  Widget build(BuildContext context) {
    final kind = tile.kind!;
    return ValueListenableBuilder<Features>(
      valueListenable: host.controller.features,
      builder: (context, features, _) => HomeTileFrame(
        key: Key('home-tile-${tile.id}'),
        icon: homeTileIcon(kind),
        title: homeTileTitle(tile),
        fit: fit,
        // The Home draws no tile that is off; the editor does, in its place
        // on the grid, saying so instead of loading it (#1109).
        child: switch (featureOfTile(kind)) {
          final feature? when !features.isOn(feature) => HomeTileEmpty(
            featureOffSentence(feature),
          ),
          _ => _content(kind),
        },
      ),
    );
  }

  Widget _content(HomeTileKind kind) => switch (kind) {
    HomeTileKind.actions => ActionsTile(
      host: host,
      actions: tile.actions,
      revision: revision,
    ),
    HomeTileKind.journalToday => JournalTodayTile(
      host: host,
      revision: revision,
    ),
    HomeTileKind.tasksDue => TasksDueTile(host: host),
    HomeTileKind.eventsToday => EventsTodayTile(host: host),
    HomeTileKind.recent => RecentTile(host: host, revision: revision),
    HomeTileKind.pinned => PinnedTile(host: host, revision: revision),
    HomeTileKind.journalCalendar => JournalCalendarTile(
      host: host,
      revision: revision,
    ),
    HomeTileKind.topTags => TopTagsTile(host: host, revision: revision),
    HomeTileKind.randomNote => RandomNoteTile(host: host, revision: revision),
    HomeTileKind.search => SearchTile(
      // A new query is a new load, not the old one's results.
      key: ValueKey(tile.query),
      host: host,
      revision: revision,
      query: tile.query,
    ),
    HomeTileKind.study => StudyTile(host: host),
  };
}
