// No god files (AGENTS.md, #100): a hand-written file in `lib/` holds at
// most [_ceiling] code lines — blank lines and comment-only lines do not
// count, since this repository comments by design. The rule asks for a split
// at ~300; this is the backstop that fails when nobody split.
//
// The files already over it are listed with their size as their own
// ceiling, and the ceiling only goes down: a file on the list cannot grow,
// so a change that adds to it moves something out first — a feature's flow,
// pane or commands go into a collaborator of their own, as `shell_*.dart`
// does for the shell. A split lowers the number here in the same commit; a
// file back under [_ceiling] leaves the list.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The most code lines a file may hold.
const int _ceiling = 600;

/// How far under its listed ceiling a file may fall before the number has to
/// come down to it: a split that took code out lowers the bar it set.
const int _slack = 50;

/// The files over [_ceiling] when the gate came in (2026-11-03), each held at
/// its size then or since lowered by a split.
const Map<String, int> _oversized = {
  'ui/shell.dart': 1512,
  'markdown/render/source_view.dart': 1442,
  'library/library_state.dart': 1036,
};

/// Tables that are long by nature, not by mixed responsibilities, and why:
/// splitting them would scatter one list over files without making any of
/// it easier to read.
bool _isTable(String rel) =>
    // The locale tables: one entry per string, growing with every string.
    rel == 'ui/strings.dart' ||
    rel.startsWith('ui/strings/') ||
    // The HTML5 named character references, from the WHATWG list.
    rel == 'markdown/inline/html5_entities.dart' ||
    // Tesseract's languages and their trained-data files.
    rel == 'ocr/ocr_language_catalog.dart';

/// The lines of [lines] that are neither blank nor a `//` comment.
int _codeLines(List<String> lines) {
  var count = 0;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('//')) continue;
    count++;
  }
  return count;
}

void main() {
  final sources = p.join('lib', 'src');
  final sizes = <String, int>{};
  for (final entity in Directory(sources).listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (entity.path.endsWith('.g.dart')) continue;
    final rel = p.posix.joinAll(
      p.split(p.relative(entity.path, from: sources)),
    );
    if (_isTable(rel)) continue;
    sizes[rel] = _codeLines(entity.readAsLinesSync());
  }

  test('no file grows past its ceiling', () {
    final over = [
      for (final MapEntry(key: file, value: size) in sizes.entries)
        if (size > (_oversized[file] ?? _ceiling))
          'lib/src/$file: $size, ceiling ${_oversized[file] ?? _ceiling}',
    ]..sort();
    expect(
      over,
      isEmpty,
      reason:
          'a file holds at most $_ceiling code lines, and one already over '
          'it cannot grow (#100): move a piece out into a file of its own '
          '(a flow, a pane, a command set, a value) before adding to it',
    );
  });

  test('a split lowers the ceiling it was held to', () {
    final stale = [
      for (final MapEntry(key: file, value: ceiling) in _oversized.entries)
        if (!sizes.containsKey(file))
          'lib/src/$file: gone, take it off the list'
        else if (sizes[file]! <= _ceiling)
          'lib/src/$file: ${sizes[file]}, under $_ceiling: off the list'
        else if (ceiling - sizes[file]! > _slack)
          'lib/src/$file: ${sizes[file]}, ceiling $ceiling: lower it',
    ]..sort();
    expect(stale, isEmpty, reason: 'keep _oversized at what the files hold');
  });
}
