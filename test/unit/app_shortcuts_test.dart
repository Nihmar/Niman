// T-PP-10: the accelerator registry is the single source for what runs and
// what the in-app reference documents.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/editor_shortcuts.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/palette/palette_command.dart';

void main() {
  // Since the command palette (#155) a command may have no key at all:
  // the palette reaches it. What must hold is that none has two.
  test('no command has more than one accelerator', () {
    final commands = nimanAppShortcuts.map((s) => s.command).toList();
    expect(commands.toSet().length, commands.length);
  });

  test('the palette and Go to note have their keys', () {
    final bound = nimanAppShortcuts.map((s) => s.command).toSet();
    expect(bound, containsAll([AppCommand.openPalette, AppCommand.goToNote]));
  });

  test('every command has a palette name, grouped or on its own', () {
    for (final command in AppCommand.values) {
      final name = PaletteCommand.of(command).name;
      expect(name, isNotEmpty, reason: command.name);
      if (paletteGroup(command) != null) {
        expect(name, contains(': '), reason: command.name);
      }
      expect(name.endsWith('…'), paletteAsks(command), reason: command.name);
    }
  });

  test('no two commands share a key combination', () {
    final keys = nimanAppShortcuts
        .map((s) => describeActivator(s.activation))
        .toList();
    expect(keys.toSet().length, keys.length);
  });

  // #370: the editor's formatting keys and the shell's commands must not
  // answer the same chord. The editor's early handler takes a key while it
  // has the focus, so a command that shares one never runs there — the two
  // formatting keys that sat on *Open file* and *Toggle side panel* did
  // nothing for it. Ctrl+B is the one the editor has always shared with
  // the shell (bold inside it, the side panel outside; see
  // `ui/keyboard_shortcuts.dart`), and the fault was the two, not it.
  test('no formatting key is also an app command key', () {
    final appKeys = {
      for (final shortcut in nimanAppShortcuts)
        describeActivator(shortcut.activation),
    };
    final shared = [
      for (final MapEntry(key: item, value: keys)
          in editorShortcutDefaults.entries)
        if (item != ToolbarItem.bold &&
            appKeys.contains(describeActivator(keys)))
          '${describeActivator(keys)} (${item.name})',
    ];
    expect(shared, isEmpty);
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

  test('zoom in on the + of every layout, and the numpad (#577)', () {
    /// The keys bound to zoom in and out, as `trigger/shift`.
    Set<String> zoomKeys() {
      final bindings = appShortcutBindings({
        AppCommand.zoomIn: () {},
        AppCommand.zoomOut: () {},
      });
      return {
        for (final keys in bindings.keys.cast<SingleActivator>())
          '${keys.trigger.keyLabel}${keys.shift ? '+shift' : ''}',
      };
    }

    expect(zoomKeys(), {
      // Its listed key, the `+` key of Italian and German keyboards, the
      // US Ctrl++, the numpad's.
      '=', '+', '=+shift', 'Numpad Add',
      '-', 'Numpad Subtract',
    });
    // A key the user chose is the only one.
    addTearDown(() => AppKeyMap.current.value = KeyMap.defaults);
    AppKeyMap.current.value = const KeyMap({
      AppCommand.zoomIn: SingleActivator(
        LogicalKeyboardKey.keyZ,
        control: true,
      ),
    });
    expect(zoomKeys(), {'Z', '-', 'Numpad Subtract'});
  });
}
