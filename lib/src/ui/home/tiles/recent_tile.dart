/// The Home's recently modified tile (#535): the notes changed last,
/// newest first, the templates left out.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/templates/engine.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_loader.dart';
import 'package:niman/src/ui/home/tiles/home_note_list.dart';
import 'package:niman/src/ui/strings.dart';

/// The notes modified last.
final class RecentTile extends StatelessWidget {
  /// The tile over [host]'s library, reloaded on [revision].
  const new({required this.host, required this.revision, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// The Home's revision.
  final int revision;

  /// How many notes it lists: the tallest tile's rows.
  static const int limit = 12;

  Future<List<Note>> _load() async {
    final ops = host.controller.ops;
    if (ops == null) return const [];
    return await ops.recentlyModified(
      limit: limit,
      excludeFolder: await ops.templateFolder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return HomeTileLoader<List<Note>>(
      revision: revision,
      load: _load,
      builder: (context, notes) => HomeNoteList(
        rows: [
          for (final note in notes)
            homeNoteRow(note, end: _when(note.modified, now)),
        ],
        onOpen: host.openNote,
        empty: AppStrings.homeNotesEmpty,
      ),
    );
  }

  /// The time for today, the day otherwise: how a list of recent things
  /// is read at a glance.
  static String _when(DateTime at, DateTime now) {
    final today =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return formatDateTime(at, today ? 'HH:mm' : 'D MMM');
  }
}
