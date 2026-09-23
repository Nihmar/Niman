/// Merge for files whose lines are records, not prose: `todo.txt` and
/// `done.txt`, where each line is one task and nothing reads across
/// lines.
///
/// The line merge of [mergeThreeWay] asks the user wherever both sides
/// touched the same place, and for a task list that is nearly always:
/// two devices that each add a task both append at the end, two that
/// each check a task both append to `done.txt`, and two neighbouring
/// tasks checked on different devices are adjacent lines. None of that
/// is a real disagreement. Here the places the line merge would ask
/// about are settled line by line instead: a line either side added is
/// in, a line either side removed from the base is out, and a line both
/// added once is in once. Nothing is left for the user, and no task is
/// lost: a task edited differently on both sides comes out as both
/// edits, which the user can see and delete.
library;

import 'package:niman/src/diff/three_way.dart';

/// Merges what [local] and [remote] each did to the record file [base]
/// (empty when there is no common version: then it is the union of both,
/// in local order with the server's new lines after).
///
/// Regions only one side changed follow [mergeThreeWay]; the line ending
/// and the trailing break come from [local].
String mergeRecords(String base, String local, String remote) {
  final merge = mergeThreeWay(base, local, remote);
  final lines = <String>[
    for (final chunk in merge.chunks)
      ...chunk.kind == MergeKind.conflict ? _records(chunk) : chunk.resolved(),
  ];
  if (lines.isEmpty) return '';
  return lines.join(merge.lineEnding) +
      (merge.trailingNewline ? merge.lineEnding : '');
}

/// One overlapping region settled record by record: this device's lines
/// minus the base lines the server removed, then the server's new lines
/// this device does not already have.
List<String> _records(MergeChunk chunk) {
  final base = chunk.base.toSet();
  final local = chunk.local.toSet();
  final remote = chunk.remote.toSet();
  return [
    for (final line in chunk.local)
      if (!base.contains(line) || remote.contains(line)) line,
    for (final line in chunk.remote)
      if (!base.contains(line) && !local.contains(line)) line,
  ];
}
