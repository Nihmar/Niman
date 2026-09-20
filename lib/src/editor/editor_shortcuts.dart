/// The formatting keys both editors answer to (#205).
///
/// The toolbar's catalogue is the catalogue of formatting actions
/// ([ToolbarItem]), and each editor already knows how to apply one —
/// the source editor writes the Markdown, the WYSIWYG sets the
/// attribute. So a formatting key is a key that applies a toolbar item,
/// and the two surfaces answer the same keys, whichever is showing.
///
/// The shipped keys follow flutter_quill's, which follow every word
/// processor's: the WYSIWYG kept them by accident of the package, and
/// the source editor had none at all. They are remappable like the app's
/// commands, and kept next to them in the device's key map.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/ui/key_map.dart';

/// The key each formatting action ships with; an item that is missing
/// here ships with none (a picker, the tools sheet).
const Map<ToolbarItem, SingleActivator> editorShortcutDefaults = {
  ToolbarItem.bold: SingleActivator(LogicalKeyboardKey.keyB, control: true),
  ToolbarItem.italic: SingleActivator(LogicalKeyboardKey.keyI, control: true),
  ToolbarItem.underline: SingleActivator(
    LogicalKeyboardKey.keyU,
    control: true,
  ),
  ToolbarItem.strikethrough: SingleActivator(
    LogicalKeyboardKey.keyS,
    control: true,
    shift: true,
  ),
  ToolbarItem.link: SingleActivator(LogicalKeyboardKey.keyK, control: true),
  ToolbarItem.code: SingleActivator(
    LogicalKeyboardKey.keyE,
    control: true,
    shift: true,
  ),
  ToolbarItem.heading: SingleActivator(
    LogicalKeyboardKey.keyH,
    control: true,
    shift: true,
  ),
  ToolbarItem.list: SingleActivator(
    LogicalKeyboardKey.keyL,
    control: true,
    shift: true,
  ),
  ToolbarItem.orderedList: SingleActivator(
    LogicalKeyboardKey.keyO,
    control: true,
    shift: true,
  ),
  ToolbarItem.quote: SingleActivator(
    LogicalKeyboardKey.keyB,
    control: true,
    shift: true,
  ),
  ToolbarItem.indent: SingleActivator(LogicalKeyboardKey.keyM, control: true),
  ToolbarItem.outdent: SingleActivator(
    LogicalKeyboardKey.keyM,
    control: true,
    shift: true,
  ),
};

/// Runs the formatting keys ahead of both editors (#205).
///
/// The same early handler the app's chosen keys use (#159), and for the
/// same reason: the key has to win over what the editor under it already
/// means by the combination — flutter_quill binds `Ctrl+B` itself, and
/// re_editor would pass it through to the text. An early handler of the
/// [FocusManager] sees the event before the focus tree and, having
/// applied the format, keeps it from the tree, so nothing happens twice.
///
/// It listens only while [active] says the editor it belongs to has the
/// focus, so a split's two editors do not both answer one key.
final class EditorFormatKeys {
  /// Applies through [actions] — the toolbar's own, for the surface
  /// showing — while [active].
  new({required this.actions, required this.active});

  /// What each formatting action does on the editor showing now.
  final Map<ToolbarItem, VoidCallback> Function() actions;

  /// Whether this editor is the one the keys belong to.
  final bool Function() active;

  /// Starts listening.
  void attach() => FocusManager.instance.addEarlyKeyEventHandler(_early);

  /// Stops listening.
  void detach() => FocusManager.instance.removeEarlyKeyEventHandler(_early);

  KeyEventResult _early(KeyEvent event) =>
      handle(event) ? KeyEventResult.handled : KeyEventResult.ignored;

  /// Applies the format [event] is the key of; true when the event is
  /// that key's and nobody else should hear it — the press that applied
  /// the format, and the repeats of it held down, which apply nothing.
  bool handle(KeyEvent event) {
    if (event is KeyUpEvent || AppKeyMap.capturing || !active()) return false;
    final keyboard = HardwareKeyboard.instance;
    final map = AppKeyMap.current.value;
    // A key the user gave a command wins, here as everywhere else
    // (#159): they moved the side panel onto Ctrl+Shift+L, which is the
    // bulleted list's, and nothing happened at all in the editor (0.0.8
    // test round). The command's own early handler takes it from here.
    for (final MapEntry(key: command, value: chosen) in map.overrides.entries) {
      if (chosen == null || !chosen.accepts(event, keyboard)) continue;
      if (map.commandOn(chosen) == command) return false;
    }
    for (final item in ToolbarItem.values) {
      final keys = map.editorBindingOf(item);
      if (keys == null || !keys.accepts(event, keyboard)) continue;
      final apply = actions()[item];
      if (apply == null) return false;
      if (event is KeyDownEvent) apply();
      return true;
    }
    // A shipped key the user moved away is swallowed rather than left to
    // the editor under it: flutter_quill binds these combinations itself,
    // so `Ctrl+B` would go on bolding in the WYSIWYG after bold was moved
    // to another key, and the two surfaces would disagree.
    for (final MapEntry(key: item, value: shipped)
        in editorShortcutDefaults.entries) {
      if (!shipped.accepts(event, keyboard)) continue;
      if (map.isEditorChanged(item) && actions().containsKey(item)) return true;
    }
    return false;
  }
}
