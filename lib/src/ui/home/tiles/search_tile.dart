/// The Home's saved search tile (#535): a query of its own and its first
/// results. The query is the search screen's: words, or `key = value`.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/search/query.dart';
import 'package:niman/src/ui/home/home_host.dart';
import 'package:niman/src/ui/home/home_tile_frame.dart';
import 'package:niman/src/ui/home/home_tile_loader.dart';
import 'package:niman/src/ui/home/tiles/home_note_list.dart';
import 'package:niman/src/ui/strings.dart';

/// A query's first results.
final class SearchTile extends StatelessWidget {
  /// The results of [query] in [host]'s library, reloaded on [revision].
  const new({
    required this.host,
    required this.revision,
    required this.query,
    super.key,
  });

  /// The shell's side of the Home.
  final HomeHost host;

  /// The Home's revision.
  final int revision;

  /// The tile's query.
  final String query;

  /// How many results it lists.
  static const int limit = 8;

  Future<List<HomeNoteRow>> _load() async {
    final controller = host.controller;
    if (fieldQuery(query) case (:final key, :final value)) {
      final notes = await (await controller.fieldSource)?.notesWithField(
        key,
        value,
        limit: limit,
      );
      return [
        for (final note in (notes ?? const <Note>[]).take(limit))
          homeNoteRow(note),
      ];
    }
    final source = await controller.searchSource;
    if (source == null) return const [];
    // No id: a read beside the Search tab's own, never superseding it.
    final hits = await source.search(
      buildFtsQuery(query),
      id: null,
      limit: limit,
    );
    return [
      for (final hit in hits) (path: hit.path, title: hit.title, end: null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return HomeTileEmpty(AppStrings.homeSearchNoQuery);
    }
    return HomeTileLoader<List<HomeNoteRow>>(
      revision: revision,
      load: _load,
      builder: (context, rows) => HomeNoteList(
        rows: rows,
        onOpen: host.openNote,
        empty: AppStrings.homeSearchEmpty,
      ),
    );
  }
}
