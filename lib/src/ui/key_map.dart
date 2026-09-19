/// The keys the user chose (#159, #205): which command — or which
/// formatting action — each combination runs, over the ones Niman ships.
///
/// Only the differences are kept — a key moved, a key cleared — so a
/// command that ships a key later still gets it on a map that never
/// touched it. A cleared command is a valid state: the command palette
/// (#155) still reaches it.
///
/// The map is the device's, not a library's: a shortcut belongs to the
/// keyboard in front of the person, and a library synced to another
/// machine must not carry this machine's keys into it.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/editor_shortcuts.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/ui/app_shortcuts.dart';

/// The shipped keys, changed where the user changed them.
@immutable
final class KeyMap {
  /// A map with [overrides] for the app's commands and [editorOverrides]
  /// for the editors' formatting (#205): a key, or null for none.
  const new([this.overrides = const {}, this.editorOverrides = const {}]);

  /// Reads a stored form; anything unreadable is left out, so a key map
  /// written by a newer build loses only what this one cannot read.
  factory fromJson(String? json) {
    if (json == null || json.isEmpty) return KeyMap.defaults;
    Object? raw;
    try {
      raw = jsonDecode(json);
    } on FormatException {
      return KeyMap.defaults;
    }
    if (raw is! Map) return KeyMap.defaults;
    final overrides = <AppCommand, SingleActivator?>{};
    final editorOverrides = <ToolbarItem, SingleActivator?>{};
    for (final MapEntry(:key, :value) in raw.entries) {
      if (value != null && value is! String) continue;
      final keys = value is String ? decodeKeys(value) : null;
      if (value is String && keys == null) continue;
      // The formatting keys live in the same object under a prefix
      // (#205), so an older build reading this map simply skips them.
      if (key is String && key.startsWith(_editorPrefix)) {
        final id = key.substring(_editorPrefix.length);
        final item = ToolbarItem.values.where((i) => i.id == id).firstOrNull;
        if (item != null) editorOverrides[item] = keys;
        continue;
      }
      final command = AppCommand.values.where((c) => c.name == key).firstOrNull;
      if (command == null) continue;
      overrides[command] = keys;
    }
    return KeyMap(
      Map.unmodifiable(overrides),
      Map.unmodifiable(editorOverrides),
    );
  }

  /// Nothing changed: the keys as shipped.
  static const KeyMap defaults = KeyMap();

  /// What the user changed, command by command.
  final Map<AppCommand, SingleActivator?> overrides;

  /// What the user changed among the editors' formatting keys (#205).
  final Map<ToolbarItem, SingleActivator?> editorOverrides;

  /// How the formatting keys are named in the stored form.
  static const String _editorPrefix = 'editor:';

  /// The key [command] ships with, or null.
  static SingleActivator? defaultOf(AppCommand command) {
    for (final shortcut in nimanAppShortcuts) {
      if (shortcut.command == command) {
        return shortcut.activation as SingleActivator;
      }
    }
    return null;
  }

  /// The key [command] runs on now, or null for none.
  SingleActivator? bindingOf(AppCommand command) =>
      overrides.containsKey(command) ? overrides[command] : defaultOf(command);

  /// Whether [command]'s key is the user's rather than the shipped one.
  bool isChanged(AppCommand command) => overrides.containsKey(command);

  /// The key [item]'s formatting ships with, or null.
  static SingleActivator? editorDefaultOf(ToolbarItem item) =>
      editorShortcutDefaults[item];

  /// The key [item] runs on now, or null for none.
  SingleActivator? editorBindingOf(ToolbarItem item) =>
      editorOverrides.containsKey(item)
      ? editorOverrides[item]
      : editorDefaultOf(item);

  /// Whether [item]'s key is the user's rather than the shipped one.
  bool isEditorChanged(ToolbarItem item) => editorOverrides.containsKey(item);

  /// The formatting [keys] apply now, or null.
  ToolbarItem? editorItemOn(SingleActivator keys) {
    for (final item in ToolbarItem.values) {
      final binding = editorBindingOf(item);
      if (binding != null && sameKeys(binding, keys)) return item;
    }
    return null;
  }

  /// [item] on [keys] (null clears it); a change back to the shipped key
  /// is no change at all.
  KeyMap withEditorBinding(ToolbarItem item, SingleActivator? keys) {
    final next = {...editorOverrides};
    final shipped = editorDefaultOf(item);
    final same = keys == null
        ? shipped == null
        : shipped != null && sameKeys(keys, shipped);
    if (same) {
      next.remove(item);
    } else {
      next[item] = keys;
    }
    return KeyMap(overrides, Map.unmodifiable(next));
  }

  /// [item] back on its shipped key.
  KeyMap editorReverted(ToolbarItem item) =>
      KeyMap(overrides, Map.unmodifiable({...editorOverrides}..remove(item)));

  /// The command [keys] runs now, or null.
  AppCommand? commandOn(SingleActivator keys) {
    for (final command in AppCommand.values) {
      final binding = bindingOf(command);
      if (binding != null && sameKeys(binding, keys)) return command;
    }
    return null;
  }

  /// Every command with a key, in the registry's order.
  List<AppShortcut> get shortcuts => [
    for (final command in AppCommand.values)
      if (bindingOf(command) case final keys?) AppShortcut(command, keys),
  ];

  /// [command] on [keys] (null clears it); a change back to the shipped
  /// key is no change at all.
  KeyMap withBinding(AppCommand command, SingleActivator? keys) {
    final next = {...overrides};
    final shipped = defaultOf(command);
    final same = keys == null
        ? shipped == null
        : shipped != null && sameKeys(keys, shipped);
    if (same) {
      next.remove(command);
    } else {
      next[command] = keys;
    }
    return KeyMap(Map.unmodifiable(next), editorOverrides);
  }

  /// [command] back on its shipped key.
  KeyMap reverted(AppCommand command) => KeyMap(
    Map.unmodifiable({...overrides}..remove(command)),
    editorOverrides,
  );

  /// Whether two combinations are the same keys.
  static bool sameKeys(SingleActivator a, SingleActivator b) =>
      a.trigger == b.trigger &&
      a.control == b.control &&
      a.shift == b.shift &&
      a.alt == b.alt &&
      a.meta == b.meta;

  /// The stored form: a JSON object of command name to keys, `null` for
  /// a cleared one.
  String toJson() => jsonEncode({
    for (final MapEntry(:key, :value) in overrides.entries)
      key.name: value == null ? null : encodeKeys(value),
    for (final MapEntry(:key, :value) in editorOverrides.entries)
      '$_editorPrefix${key.id}': value == null ? null : encodeKeys(value),
  });

  /// `ctrl+shift+<key id>`: modifiers by name, the key by its id, which
  /// no keyboard layout or language renames.
  static String encodeKeys(SingleActivator keys) => [
    if (keys.control) 'ctrl',
    if (keys.meta) 'meta',
    if (keys.alt) 'alt',
    if (keys.shift) 'shift',
    '${keys.trigger.keyId}',
  ].join('+');

  /// Reads [encodeKeys]' form; null when it does not name a key.
  static SingleActivator? decodeKeys(String text) {
    final parts = text.split('+');
    final id = int.tryParse(parts.last);
    final key = id == null ? null : LogicalKeyboardKey.findKeyByKeyId(id);
    if (key == null) return null;
    return SingleActivator(
      key,
      control: parts.contains('ctrl'),
      meta: parts.contains('meta'),
      alt: parts.contains('alt'),
      shift: parts.contains('shift'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeyMap && other.toJson() == toJson();

  @override
  int get hashCode => toJson().hashCode;
}

/// The key map in force, for every place that shows or installs keys.
///
/// Read at start from the device's settings and replaced whenever the
/// keyboard screen changes it; the shell rebuilds its bindings on it.
final class AppKeyMap {
  const new _();

  /// The map in force.
  static final ValueNotifier<KeyMap> current = ValueNotifier(KeyMap.defaults);

  /// Set while a combination is being captured: nothing may run on it.
  static bool capturing = false;
}

/// Runs the keys the user chose (#159), ahead of everything else.
///
/// The shipped keys are bound through the focus tree, where an editor
/// that means something else by a combination hears it first — and the
/// shipped keys are picked not to collide. A key the user chose is the
/// user's word, so it wins everywhere, in both editors too: it is an
/// early handler of the [FocusManager], which sees the event before the
/// focus tree and, having run the command, keeps it from the tree.
///
/// A [HardwareKeyboard] handler looked right and was not: returning true
/// there does not stop the focus tree, so a chosen key ran twice — once
/// here, once through the shell's own bindings. A toggle (the side
/// panel) undid itself, and the editors heard the key as well.
final class ChosenKeys {
  /// Runs through [handlers] while [active] says so.
  new({required this.handlers, required this.active});

  /// What each command does, where it can run now.
  final Map<AppCommand, VoidCallback> Function() handlers;

  /// Whether the keys may run now (not under a dialog, say).
  final bool Function() active;

  /// Starts listening.
  void attach() => FocusManager.instance.addEarlyKeyEventHandler(_early);

  /// Stops listening.
  void detach() => FocusManager.instance.removeEarlyKeyEventHandler(_early);

  KeyEventResult _early(KeyEvent event) =>
      handle(event) ? KeyEventResult.handled : KeyEventResult.ignored;

  /// Runs the command [event] is the chosen key of; true when the event is
  /// the chosen key's and nobody else should hear it — the press that ran
  /// the command, and the repeats of it held down, which run nothing.
  bool handle(KeyEvent event) {
    if (event is KeyUpEvent || AppKeyMap.capturing || !active()) {
      return false;
    }
    final map = AppKeyMap.current.value;
    for (final MapEntry(key: command, value: keys) in map.overrides.entries) {
      if (keys == null) continue;
      if (!keys.accepts(event, HardwareKeyboard.instance)) continue;
      final run = handlers()[command];
      if (run == null) return false;
      if (event is KeyDownEvent) run();
      return true;
    }
    return false;
  }
}
