// Issue #159: the key map keeps only what the user changed, reads back
// what it wrote, and never pretends a shipped key is a change.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';

const _ctrlAltN = SingleActivator(
  LogicalKeyboardKey.keyN,
  control: true,
  alt: true,
);

void main() {
  test('untouched, every command has its shipped key', () {
    for (final shortcut in nimanAppShortcuts) {
      expect(KeyMap.defaults.bindingOf(shortcut.command), shortcut.activation);
    }
    expect(KeyMap.defaults.bindingOf(AppCommand.renameNote), isNull);
  });

  test('a key moved, a key cleared, and the way back', () {
    final map = KeyMap.defaults
        .withBinding(AppCommand.newNote, _ctrlAltN)
        .withBinding(AppCommand.toggleSidebar, null);
    expect(map.bindingOf(AppCommand.newNote), _ctrlAltN);
    expect(map.isChanged(AppCommand.newNote), isTrue);
    expect(map.bindingOf(AppCommand.toggleSidebar), isNull);
    expect(map.commandOn(_ctrlAltN), AppCommand.newNote);
    // Reverting, or choosing the shipped key again, is no change.
    expect(
      map.reverted(AppCommand.newNote).isChanged(AppCommand.newNote),
      isFalse,
    );
    final back = map.withBinding(
      AppCommand.newNote,
      KeyMap.defaultOf(AppCommand.newNote),
    );
    expect(back.isChanged(AppCommand.newNote), isFalse);
  });

  test('the stored form reads back what it wrote', () {
    final map = KeyMap.defaults
        .withBinding(AppCommand.newNote, _ctrlAltN)
        .withBinding(AppCommand.toggleSidebar, null)
        .withBinding(
          AppCommand.renameNote,
          const SingleActivator(LogicalKeyboardKey.f2),
        );
    expect(KeyMap.fromJson(map.toJson()), map);
  });

  test('what cannot be read is left out, not guessed', () {
    expect(KeyMap.fromJson(null), KeyMap.defaults);
    expect(KeyMap.fromJson('not json'), KeyMap.defaults);
    final map = KeyMap.fromJson(
      '{"noSuchCommand": "ctrl+1", "newNote": "ctrl+nonsense", '
      '"toggleSidebar": null}',
    );
    expect(map.overrides.keys, [AppCommand.toggleSidebar]);
  });
}
