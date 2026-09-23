/// Merge of two copies with no version in common: a note created on two
/// devices, or one whose sync base rotated out of history.
///
/// Without a base nothing says which side changed what, so nothing is
/// taken on its own: the lines both copies share stand, and every place
/// they differ becomes a choice, the same Mine / Theirs / Both the three-
/// way merge offers where edits overlap. It turns "keep one whole copy"
/// into a choice per difference.
library;

import 'package:niman/src/diff/line_diff.dart';
import 'package:niman/src/diff/three_way.dart';

/// [local] and [remote] as one [MergeResult]: runs both share are
/// [MergeKind.unchanged], and each place they differ is a
/// [MergeKind.conflict] with an empty base. The line ending and the
/// trailing break come from [local].
MergeResult mergeTwoWay(String local, String remote) {
  final chunks = <MergeChunk>[];
  final same = <String>[];
  final mine = <String>[];
  final theirs = <String>[];
  void flushSame() {
    if (same.isEmpty) return;
    final lines = List<String>.unmodifiable(same);
    chunks.add(
      MergeChunk(
        kind: MergeKind.unchanged,
        base: lines,
        local: lines,
        remote: lines,
      ),
    );
    same.clear();
  }

  void flushDifference() {
    if (mine.isEmpty && theirs.isEmpty) return;
    chunks.add(
      MergeChunk(
        kind: MergeKind.conflict,
        base: const [],
        local: List.unmodifiable(mine),
        remote: List.unmodifiable(theirs),
      ),
    );
    mine.clear();
    theirs.clear();
  }

  for (final line in diffLines(local, remote)) {
    switch (line.kind) {
      case DiffKind.same:
        flushDifference();
        same.add(line.text);
      case DiffKind.removed:
        flushSame();
        mine.add(line.text);
      case DiffKind.added:
        flushSame();
        theirs.add(line.text);
    }
  }
  flushDifference();
  flushSame();
  return MergeResult(
    chunks: chunks,
    lineEnding: local.contains('\r\n') ? '\r\n' : '\n',
    trailingNewline: local.isEmpty || local.endsWith('\n'),
  );
}
