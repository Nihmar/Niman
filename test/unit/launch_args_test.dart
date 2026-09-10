// T-PP-05: the CLI is the desktop floor for the four quick actions. Each
// flag must map to the same ShortcutAction its launcher and tray twins
// use, and the hand-off must stay one-shot like the platform's.
import 'package:copist/src/core/launch_args.dart';
import 'package:copist/src/core/shortcuts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each flag maps to its launcher action', () {
    expect(parseLaunchArgs(['--quick-note']).action, ShortcutAction.quickNote);
    expect(parseLaunchArgs(['--new-note']).action, ShortcutAction.newNote);
    expect(parseLaunchArgs(['--new-todo']).action, ShortcutAction.newTodo);
    expect(parseLaunchArgs(['--new-list']).action, ShortcutAction.newList);
  });

  test('an ordinary start asks for nothing', () {
    final launch = parseLaunchArgs(const []);
    expect(launch.action, isNull);
    expect(launch.openPath, isNull);
  });

  test('unknown flags are ignored, the first action wins', () {
    final launch = parseLaunchArgs([
      '--ozone-platform=wayland',
      '--new-note',
      '--new-todo',
    ]);
    expect(launch.action, ShortcutAction.newNote);
  });

  test('a bare path is captured for the P3 file-open slice', () {
    final launch = parseLaunchArgs(['/tmp/notes/a.md']);
    expect(launch.action, isNull);
    expect(launch.openPath, '/tmp/notes/a.md');
  });

  test(
    'the CLI hand-off is one-shot, like the platform launch action',
    () async {
      final service = CliShortcutService(ShortcutAction.quickNote);
      expect(service.actions, emitsDone);
      expect(await service.consumeLaunchAction(), ShortcutAction.quickNote);
      expect(await service.consumeLaunchAction(), isNull);
      await service.publish(const <ShortcutAction, String>{});
      await service.dispose();
    },
  );
}
