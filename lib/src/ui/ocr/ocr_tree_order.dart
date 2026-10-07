import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:path/path.dart' as p;

/// [siblings] (one folder's rows, in the tree's order) with each text
/// recognition sidecar moved right under the file it reads, marked true
/// (#595): the tree shows it there, indented and dimmed, so a folder of
/// scans does not fill with a second row per file.
///
/// A sidecar is told by its name alone — `scan.ocr.md` under `scan.pdf`,
/// or `scan.pdf.ocr.md` when another file of that stem took the first
/// name — which costs the tree no read. One whose file is not among its
/// siblings stays where it sorts, as a plain note.
List<(T, bool)> nestOcrSidecars<T>(
  List<T> siblings,
  String Function(T row) nameOf,
) {
  const suffix = '.ocr.md';
  final byName = {for (final row in siblings) nameOf(row): row};
  final under = <T, T>{};
  for (final row in siblings) {
    final name = nameOf(row);
    if (!name.endsWith(suffix)) continue;
    final base = name.substring(0, name.length - suffix.length);
    final exact = byName[base];
    final owner = exact != null && isRecognizableFile(base)
        ? exact
        : _stemOwner(siblings, nameOf, base);
    if (owner != null) under[row] = owner;
  }
  if (under.isEmpty) return [for (final row in siblings) (row, false)];
  final sidecarsOf = <T, List<T>>{};
  for (final MapEntry(key: sidecar, value: owner) in under.entries) {
    sidecarsOf.putIfAbsent(owner, () => []).add(sidecar);
  }
  return [
    for (final row in siblings)
      if (!under.containsKey(row)) ...[
        (row, false),
        for (final sidecar in sidecarsOf[row] ?? <T>[]) (sidecar, true),
      ],
  ];
}

T? _stemOwner<T>(List<T> siblings, String Function(T) nameOf, String stem) {
  for (final row in siblings) {
    final name = nameOf(row);
    if (p.basenameWithoutExtension(name) == stem && isRecognizableFile(name)) {
      return row;
    }
  }
  return null;
}
