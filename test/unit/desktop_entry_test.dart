// T-PP-06: the Linux desktop entry is the right-click surface for the four
// quick actions. It must stay the CLI's twin: each Desktop Action's Exec is
// fed back through the same parser the app runs, so an entry that points at
// a flag `parseLaunchArgs` does not understand fails here instead of
// silently opening the app with no action.
import 'dart:io';

import 'package:copist/src/core/launch_args.dart';
import 'package:copist/src/core/shortcuts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _expected = <String, ShortcutAction>{
  'quick-note': ShortcutAction.quickNote,
  'new-todo': ShortcutAction.newTodo,
  'new-note': ShortcutAction.newNote,
  'new-list': ShortcutAction.newList,
};

void main() {
  late List<String> lines;

  setUpAll(() {
    lines = File(p.join('linux', 'dev.copist.copist.desktop'))
        .readAsLinesSync();
  });

  /// The value of the first `key=` line at or after [from], or null.
  String? valueOf(String key, {int from = 0}) {
    for (var i = from; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('[') && i > from) return null;
      if (line.startsWith('$key=')) return line.substring(key.length + 1);
    }
    return null;
  }

  test('the four actions are declared in the main entry', () {
    final declared = valueOf('Actions')!
        .split(';')
        .where((action) => action.isNotEmpty)
        .toList();
    expect(
      declared,
      _expected.keys,
      reason: 'the right-click menu must list all four, in tray order',
    );
  });

  test('each Desktop Action runs one flag parseLaunchArgs knows', () {
    for (final entry in _expected.entries) {
      final header = '[Desktop Action ${entry.key}]';
      final at = lines.indexOf(header);
      expect(at, isNonNegative, reason: 'missing $header');

      final exec = valueOf('Exec', from: at);
      expect(exec, isNotNull, reason: 'missing Exec in $header');
      final tokens = exec!.split(' ').skip(1).toList();
      expect(
        parseLaunchArgs(tokens).action,
        entry.value,
        reason: '$header runs $exec',
      );
    }
  });
}
