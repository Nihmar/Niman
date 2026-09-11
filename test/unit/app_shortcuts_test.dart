// T-PP-10: the accelerator registry is the single source for what runs and
// what the in-app reference documents.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';

void main() {
  test('every command has exactly one accelerator', () {
    final commands = nimanAppShortcuts.map((s) => s.command).toList();
    expect(commands.toSet().length, commands.length);
    expect(commands.toSet(), AppCommand.values.toSet());
  });

  test('no two commands share a key combination', () {
    final keys = nimanAppShortcuts
        .map((s) => describeActivator(s.activation))
        .toList();
    expect(keys.toSet().length, keys.length);
  });

  test('every command has a non-empty label', () {
    for (final command in AppCommand.values) {
      expect(appCommandLabel(command), isNotEmpty, reason: command.name);
    }
  });

  test('an activator reads the way a user types it', () {
    expect(
      describeActivator(
        const SingleActivator(LogicalKeyboardKey.keyN, control: true),
      ),
      'Ctrl+N',
    );
    expect(
      describeActivator(
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
          shift: true,
        ),
      ),
      'Ctrl+Shift+N',
    );
    expect(
      describeActivator(
        const SingleActivator(LogicalKeyboardKey.digit5, control: true),
      ),
      'Ctrl+5',
    );
  });

  test('bindings carry exactly the commands with a handler', () {
    var ran = 0;
    final bindings = appShortcutBindings({AppCommand.newNote: () => ran++});
    expect(bindings, hasLength(1));
    bindings.values.single();
    expect(ran, 1);
    expect(
      bindings.keys.single,
      isA<SingleActivator>().having(
        (a) => a.trigger,
        'trigger',
        LogicalKeyboardKey.keyN,
      ),
    );
  });
}
