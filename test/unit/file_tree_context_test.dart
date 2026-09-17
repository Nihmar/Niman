// Issue #76: the tree row's "show in file manager" / "open in default
// app" entries. The launcher is faked — the real one opens a window on
// the host — so what is covered here is the policy around it: the
// existence check, which call each action makes, and the outcomes the
// shell turns into a snackbar.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:path/path.dart' as p;

/// Records what it was asked to do, and answers [answer].
final class _FakeLauncher extends OsLauncher {
  new({this.answer = true});

  final bool answer;
  final List<String> opened = [];
  final List<String> revealed = [];

  @override
  Future<bool> openFile(String path) async {
    opened.add(path);
    return answer;
  }

  @override
  Future<bool> revealFile(String path) async {
    revealed.add(path);
    return answer;
  }
}

void main() {
  late Directory dir;
  late String note;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('niman_tree_ctx_');
    note = p.join(dir.path, 'Note.md');
    await File(note).writeAsString('# Note\n');
  });

  tearDown(() async {
    if (dir.existsSync()) await dir.delete(recursive: true);
  });

  test('open in default app hands the file to the launcher', () async {
    final launcher = _FakeLauncher();

    final outcome = await runTreeContextAction(
      note,
      TreeContextAction.openInDefaultApp,
      launcher: launcher,
    );

    expect(outcome, TreeContextOutcome.opened);
    expect(launcher.opened, [note]);
    expect(launcher.revealed, isEmpty);
  });

  test('open in file manager reveals the file instead', () async {
    final launcher = _FakeLauncher();

    final outcome = await runTreeContextAction(
      note,
      TreeContextAction.openInFileManager,
      launcher: launcher,
    );

    expect(outcome, TreeContextOutcome.opened);
    expect(launcher.revealed, [note]);
    expect(launcher.opened, isEmpty);
  });

  test(
    'a note whose file is gone reports missing, launcher untouched',
    () async {
      final launcher = _FakeLauncher();
      await File(note).delete();

      final outcome = await runTreeContextAction(
        note,
        TreeContextAction.openInDefaultApp,
        launcher: launcher,
      );

      expect(outcome, TreeContextOutcome.missing);
      expect(launcher.opened, isEmpty);
      expect(launcher.revealed, isEmpty);
    },
  );

  test('a launcher that refuses the file reports failed', () async {
    final launcher = _FakeLauncher(answer: false);

    final outcome = await runTreeContextAction(
      note,
      TreeContextAction.openInFileManager,
      launcher: launcher,
    );

    expect(outcome, TreeContextOutcome.failed);
    expect(launcher.revealed, [note]);
  });

  test('the actions are offered on the desktop, where the test runs', () {
    expect(supportsTreeContextActions, isTrue);
  });
}
