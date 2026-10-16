/// How the `note_stems` rows a typed name finds are ranked (#475, #1035):
/// shared by the `[[` panel and Go to note, so the two put the same note
/// first for the same text.
library;

import 'dart:math' show min;

import 'package:niman/src/links/stem_row.dart';
import 'package:niman/src/links/suggestion.dart';
import 'package:path/path.dart' as p;

/// A ranked note: the suggestion with its bare target, and the note's path,
/// which qualifies the target when the name is shared.
typedef RankedStem = ({NoteSuggestion note, String path});

/// [rows] grouped by note and ranked for the lowercased text [q]: the name
/// (or an alias) typed in full first, then the names it starts, then those
/// that hold it; each tier by how much more the name says, then by folder
/// and name. A note found only through an alias carries it. With an empty
/// [q] every note is one tier, by folder and name.
List<RankedStem> rankStems(List<StemRow> rows, String q) {
  final byNote = <int, List<StemRow>>{};
  for (final row in rows) {
    (byNote[row.id] ??= <StemRow>[]).add(row);
  }
  final ranked = <({RankedStem row, int tier, int length})>[];
  for (final group in byNote.values) {
    final first = group.first;
    final named = group.where((r) => r.source == 'file').firstOrNull;
    final name = displayName(first.path);
    // The best way the note answers to [q]: its name or an alias typed
    // in full, one that starts with it, or one that only holds it.
    final exact = q.isNotEmpty && group.any((r) => r.stem == q);
    final prefix = q.isNotEmpty && group.any((r) => r.stem.startsWith(q));
    final matching = [
      for (final r in group)
        if (q.isEmpty || (prefix ? r.stem.startsWith(q) : r.stem.contains(q)))
          r.stem.length,
    ];
    final nameMatched = q.isEmpty || (named != null && named.stem.contains(q));
    ranked.add((
      row: (
        note: NoteSuggestion(
          name: name,
          folder: folderOf(first.path),
          target: name,
          alias: q.isNotEmpty && !nameMatched ? first.stem : null,
        ),
        path: first.path,
      ),
      tier: exact ? 0 : (prefix ? 1 : 2),
      // The shorter name is the closer one (`proj` before `proj notes`).
      length: q.isEmpty || matching.isEmpty ? 0 : matching.reduce(min),
    ));
  }
  ranked.sort((a, b) {
    if (a.tier != b.tier) return a.tier - b.tier;
    if (a.length != b.length) return a.length - b.length;
    final byFolder = a.row.note.folder.compareTo(b.row.note.folder);
    return byFolder != 0
        ? byFolder
        : a.row.note.name.compareTo(b.row.note.name);
  });
  return [for (final r in ranked) r.row];
}

/// The name shown for [path]: the file's base name, `.md` dropped.
String displayName(String path) {
  final name = p.basename(path);
  return name.toLowerCase().endsWith('.md')
      ? name.substring(0, name.length - 3)
      : name;
}

/// The folder of [path] relative to the library; empty at the root.
String folderOf(String path) {
  final dir = p.dirname(path);
  return dir == '.' ? '' : dir;
}
