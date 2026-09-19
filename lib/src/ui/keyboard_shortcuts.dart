/// The keyboard shortcuts (T-PP-10, #159): where the keys live.
///
/// Every command is listed, with its key or with none. A tap records new
/// keys; ↺ puts the shipped key back, × takes the key away — a command
/// without one is still reached from the command palette (#155). A
/// combination another command holds is never taken silently: the screen
/// names that command and asks. A combination the text fields and the
/// editor use (copy, undo, find) may be taken, after a plain warning.
///
/// The map is the device's: kept in its settings, never in a library.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_capture_dialog.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/strings.dart';

/// The combinations the text fields and the editors already mean, with
/// what they mean there: taking one is allowed, with a warning.
///
/// The formatting keys (#205) are among them. They are a space of their
/// own — they apply while an editor has the focus, where an app command
/// on the same keys does not run — so they do not collide with a command,
/// as `Ctrl+B` has not collided with the side panel since flutter_quill
/// bound it. What the warning does is say so instead of leaving it to be
/// discovered.
Map<String, String> _editorKeys(BuildContext context) {
  final words = MaterialLocalizations.of(context);
  String keys(LogicalKeyboardKey key, {bool shift = false}) =>
      KeyMap.encodeKeys(SingleActivator(key, control: true, shift: shift));
  return {
    keys(LogicalKeyboardKey.keyC): words.copyButtonLabel,
    keys(LogicalKeyboardKey.keyV): words.pasteButtonLabel,
    keys(LogicalKeyboardKey.keyX): words.cutButtonLabel,
    keys(LogicalKeyboardKey.keyA): words.selectAllButtonLabel,
    keys(LogicalKeyboardKey.keyZ): AppStrings.shortcutUndo,
    keys(LogicalKeyboardKey.keyY): AppStrings.shortcutRedo,
    keys(LogicalKeyboardKey.keyZ, shift: true): AppStrings.shortcutRedo,
    keys(LogicalKeyboardKey.keyF): AppStrings.shortcutFind,
    keys(LogicalKeyboardKey.keyH): AppStrings.shortcutReplace,
    for (final item in ToolbarItem.values)
      if (AppKeyMap.current.value.editorBindingOf(item) case final format?)
        KeyMap.encodeKeys(format): item.label,
  };
}

/// Records new keys for [command] and, after whatever it collides with
/// has been settled, keeps them through [session].
Future<void> changeShortcut(
  BuildContext context,
  AppCommand command,
  LibrarySession session,
) async {
  final keys = await showKeyCaptureDialog(context, appCommandLabel(command));
  if (keys == null || !context.mounted) return;
  final map = await _cleared(context, keys, command: command);
  if (map == null) return;
  await _keep(session, map.withBinding(command, keys));
}

/// Records new keys for the formatting [item] (#205) and keeps them.
Future<void> changeEditorShortcut(
  BuildContext context,
  ToolbarItem item,
  LibrarySession session,
) async {
  final keys = await showKeyCaptureDialog(context, item.label);
  if (keys == null || !context.mounted) return;
  final map = await _cleared(context, keys, item: item);
  if (map == null) return;
  await _keep(session, map.withEditorBinding(item, keys));
}

/// The map with whatever else holds [keys] settled — the other command,
/// the other formatting action, or a key the text fields and the editors
/// already mean — or null if the user backed out.
///
/// Commands collide with commands and formatting with formatting: the
/// two are separate spaces (see [_editorKeys]). The one being given the
/// keys is left out, so re-recording its own keys asks nothing.
Future<KeyMap?> _cleared(
  BuildContext context,
  SingleActivator keys, {
  AppCommand? command,
  ToolbarItem? item,
}) async {
  var map = AppKeyMap.current.value;
  final described = describeActivator(keys);
  final other = command == null ? null : map.commandOn(keys);
  if (other != null && other != command) {
    final move = await _ask(
      context,
      AppStrings.shortcutConflict(described, appCommandLabel(other)),
      AppStrings.shortcutMove,
      key: const Key('shortcut-conflict'),
    );
    if (!move || !context.mounted) return null;
    map = map.withBinding(other, null);
  }
  final otherItem = item == null ? null : map.editorItemOn(keys);
  if (otherItem != null && otherItem != item) {
    final move = await _ask(
      context,
      AppStrings.shortcutConflict(described, otherItem.label),
      AppStrings.shortcutMove,
      key: const Key('shortcut-conflict'),
    );
    if (!move || !context.mounted) return null;
    map = map.withEditorBinding(otherItem, null);
  }
  // A formatting row is not warned about the formatting keys: its own
  // space was settled above.
  final editor = item != null
      ? null
      : _editorKeys(context)[KeyMap.encodeKeys(keys)];
  if (editor != null) {
    final take = await _ask(
      context,
      AppStrings.shortcutTakesEditorKey(described, editor),
      AppStrings.shortcutUseAnyway,
      key: const Key('shortcut-editor-key'),
    );
    if (!take) return null;
  }
  return map;
}

Future<void> _keep(LibrarySession session, KeyMap map) async {
  AppKeyMap.current.value = map;
  await session.setKeyMap(map.toJson());
}

Future<bool> _ask(
  BuildContext context,
  String question,
  String yes, {
  required Key key,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: key,
        content: Text(question),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: Key('${(key as ValueKey<String>).value}-yes'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(yes),
          ),
        ],
      ),
    ) ??
    false;

/// The screen.
final class KeyboardShortcutsScreen extends StatelessWidget {
  /// The shortcuts of this device, kept through [controller]; [highlight]
  /// is the row the settings search landed on.
  const new({required this.controller, this.highlight, super.key});

  /// Where the key map is kept.
  final LibrarySession controller;

  /// The row to flash, or null.
  final Key? highlight;

  static String _groupName(PaletteGroup? group) =>
      group == null ? AppStrings.paletteCommands : paletteGroupName(group);

  Future<void> _restoreDefaults(BuildContext context) async {
    final yes = await _ask(
      context,
      AppStrings.shortcutRestoreDefaultsConfirm,
      AppStrings.shortcutRestoreDefaults,
      key: const Key('shortcut-restore-defaults'),
    );
    if (yes) await _keep(controller, KeyMap.defaults);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.keyboardShortcutsTitle),
        actions: [
          TextButton(
            key: const Key('shortcuts-restore-defaults'),
            onPressed: () => unawaited(_restoreDefaults(context)),
            child: Text(AppStrings.shortcutRestoreDefaults),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SettingsHighlight(
        target: highlight,
        child: ValueListenableBuilder<KeyMap>(
          valueListenable: AppKeyMap.current,
          builder: (context, map, _) {
            final groups = <PaletteGroup?, List<AppCommand>>{};
            for (final command in AppCommand.values) {
              (groups[paletteGroup(command)] ??= []).add(command);
            }
            // Every row built, not a lazy list: the settings search lands
            // on a row that has to exist to scroll itself into view, and
            // there are only a few dozen of them.
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in [null, ...PaletteGroup.values])
                    if (groups[group] case final commands?) ...[
                      SettingsListHeading(_groupName(group)),
                      for (final command in commands)
                        _KeysRow(
                          rowKey: shortcutRowKey(command),
                          name: appCommandLabel(command),
                          id: command.name,
                          keys: map.bindingOf(command),
                          changed: map.isChanged(command),
                          onChange: () => unawaited(
                            changeShortcut(context, command, controller),
                          ),
                          onClear: () => unawaited(
                            _keep(controller, map.withBinding(command, null)),
                          ),
                          onRevert: () => unawaited(
                            _keep(controller, map.reverted(command)),
                          ),
                        ),
                    ],
                  SettingsListHeading(AppStrings.shortcutFormatSection),
                  for (final item in ToolbarItem.values)
                    if (item != ToolbarItem.tools)
                      _KeysRow(
                        rowKey: editorShortcutRowKey(item),
                        name: item.label,
                        id: item.id,
                        keys: map.editorBindingOf(item),
                        changed: map.isEditorChanged(item),
                        onChange: () => unawaited(
                          changeEditorShortcut(context, item, controller),
                        ),
                        onClear: () => unawaited(
                          _keep(controller, map.withEditorBinding(item, null)),
                        ),
                        onRevert: () => unawaited(
                          _keep(controller, map.editorReverted(item)),
                        ),
                      ),
                  SettingsListHeading(AppStrings.shortcutEditorSection),
                  ListTile(
                    dense: true,
                    title: Text(AppStrings.shortcutFind),
                    trailing: const ShortcutKeys('Ctrl+F'),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(AppStrings.shortcutReplace),
                    trailing: const ShortcutKeys('Ctrl+H'),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      AppStrings.shortcutSavingNote,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A list's group heading, in small capitals: the keyboard and the
/// Commands pages head their groups with it.
final class SettingsListHeading extends StatelessWidget {
  /// A heading reading [text].
  const new(this.text, {super.key});

  /// The group's name.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// The key of [command]'s row on the keyboard screen: the settings
/// search lands on it.
Key shortcutRowKey(AppCommand command) => Key('shortcut-${command.name}');

/// The key of the formatting [item]'s row (#205).
Key editorShortcutRowKey(ToolbarItem item) => Key('shortcut-format-${item.id}');

/// One row: a name, its keys (or none), and the ways to change them —
/// a command, or a formatting action (#205).
final class _KeysRow extends StatelessWidget {
  const new({
    required this.rowKey,
    required this.name,
    required this.id,
    required this.keys,
    required this.changed,
    required this.onChange,
    required this.onClear,
    required this.onRevert,
  });

  final Key rowKey;
  final String name;

  /// What the clear and revert buttons' keys are built from.
  final String id;
  final SingleActivator? keys;
  final bool changed;
  final VoidCallback onChange;
  final VoidCallback onClear;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = this.keys;
    return HighlightRow(
      key: rowKey,
      child: ListTile(
        dense: true,
        title: Text(name),
        onTap: onChange,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (keys == null)
              Text(
                AppStrings.shortcutNone,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ShortcutKeys(describeActivator(keys)),
            // Always the same two slots, so the keys never shift under the
            // pointer as they come and go.
            SizedBox.square(
              dimension: 36,
              child: changed
                  ? IconButton(
                      key: Key('shortcut-revert-$id'),
                      tooltip: AppStrings.shortcutRevert,
                      iconSize: 18,
                      icon: const Icon(Icons.undo),
                      onPressed: onRevert,
                    )
                  : null,
            ),
            SizedBox.square(
              dimension: 36,
              child: keys != null
                  ? IconButton(
                      key: Key('shortcut-clear-$id'),
                      tooltip: AppStrings.shortcutClear,
                      iconSize: 18,
                      icon: const Icon(Icons.close),
                      onPressed: onClear,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// A key combination drawn as a keycap.
final class ShortcutKeys extends StatelessWidget {
  /// A keycap reading [text].
  const new(this.text, {super.key});

  /// The keys, as `describeActivator` writes them.
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}
