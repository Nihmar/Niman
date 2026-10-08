/// The Home's pinned tile (#535): the notes whose frontmatter pins them,
/// as the tree's pinned section lists them.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_loader.dart';
import 'package:niman/src/ui/home/tiles/home_note_list.dart';
import 'package:niman/src/ui/strings.dart';

/// The pinned notes.
final class PinnedTile extends StatelessWidget {
  /// The tile over [host]'s library, reloaded on [revision].
  const new({required this.host, required this.revision, super.key});

  /// The shell's side of the Home.
  final HomeHost host;

  /// The Home's revision.
  final int revision;

  Future<List<Note>> _load() async =>
      await (await host.controller.fieldSource)?.pinnedNotes() ?? const [];

  @override
  Widget build(BuildContext context) => HomeTileLoader<List<Note>>(
    revision: revision,
    load: _load,
    builder: (context, notes) => HomeNoteList(
      rows: [for (final note in notes) homeNoteRow(note)],
      onOpen: host.openNote,
      empty: AppStrings.homePinnedEmpty,
      icon: Icons.push_pin_outlined,
    ),
  );
}
