// T-PP-05: the CLI is the desktop floor for the quick actions. Each
// flag must map to the same ShortcutAction its launcher and tray twins
// use, and the hand-off must stay one-shot like the platform's.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/core/launch_args.dart';
import 'package:niman/src/core/shortcuts.dart';

void main() {
  test('each flag maps to its launcher action', () {
    expect(parseLaunchArgs(['--quick-note']).action, ShortcutAction.quickNote);
    expect(parseLaunchArgs(['--new-note']).action, ShortcutAction.newNote);
    expect(parseLaunchArgs(['--new-todo']).action, ShortcutAction.newTodo);
    expect(parseLaunchArgs(['--new-list']).action, ShortcutAction.newList);
    expect(parseLaunchArgs(['--new-voice']).action, ShortcutAction.newVoice);
    expect(
      parseLaunchArgs(['--journal-today']).action,
      ShortcutAction.journalToday,
    );
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

  test('a bare path is the file to open (#41)', () {
    final launch = parseLaunchArgs(['/tmp/notes/a.md']);
    expect(launch.action, isNull);
    expect(launch.openPath, '/tmp/notes/a.md');
  });

  test('a relative path is made absolute against where it was typed', () {
    // The first instance started somewhere else: `niman ../a.md` must
    // reach it as the file the user meant.
    final launch = parseLaunchArgs(['../notes/a.md'], cwd: '/home/u/work');
    expect(launch.openPath, '/home/u/notes/a.md');
  });

  test('a file URI, as some file managers pass it, is its path', () {
    expect(
      parseLaunchArgs(['file:///home/u/My%20notes/a.md']).openPath,
      '/home/u/My notes/a.md',
    );
    // Not a file this process can open.
    expect(parseLaunchArgs(['file://server/share/a.md']).openPath, isNull);
  });

  test('a launch survives the hand-over to the first instance', () {
    const launch = LaunchArgs(
      action: ShortcutAction.newTodo,
      openPath: '/home/u/a.md',
    );
    final back = LaunchArgs.fromJson(launch.toJson());
    expect(back.action, ShortcutAction.newTodo);
    expect(back.openPath, '/home/u/a.md');
    // What cannot be read is left out, a relative path included.
    final odd = LaunchArgs.fromJson({'action': 'nope', 'open': 'a.md'});
    expect(odd.action, isNull);
    expect(odd.openPath, isNull);
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

  test('later launches’ actions arrive as the service’s actions', () async {
    final service = CliShortcutService(
      null,
      later: Stream.fromIterable([ShortcutAction.quickNote]),
    );
    expect(await service.consumeLaunchAction(), isNull);
    expect(await service.actions.toList(), [ShortcutAction.quickNote]);
  });
}
