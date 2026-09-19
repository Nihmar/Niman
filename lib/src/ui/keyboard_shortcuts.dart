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
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_capture_dialog.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/strings.dart';

/// The combinations the text fields and the editor already mean, with
/// what they mean there: taking one is allowed, with a warning.
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
  };
}

/// Records new keys for [command] and, after whatever it collides with
/// has been settled, keeps them through [session].
Future<void> changeShortcut(
  BuildContext context,
  AppCommand command,
  LibrarySession session,
) async {
  final keys = await showKeyCaptureDialog(context, command);
  if (keys == null || !context.mounted) return;
  var map = AppKeyMap.current.value;
  final described = describeActivator(keys);
  final other = map.commandOn(keys);
  if (other != null && other != command) {
    final move = await _ask(
      context,
      AppStrings.shortcutConflict(described, appCommandLabel(other)),
      AppStrings.shortcutMove,
      key: const Key('shortcut-conflict'),
    );
    if (!move || !context.mounted) return;
    map = map.withBinding(other, null);
  }
  final editor = _editorKeys(context)[KeyMap.encodeKeys(keys)];
  if (editor != null) {
    final take = await _ask(
      context,
      AppStrings.shortcutTakesEditorKey(described, editor),
      AppStrings.shortcutUseAnyway,
      key: const Key('shortcut-editor-key'),
    );
    if (!take) return;
  }
  await _keep(session, map.withBinding(command, keys));
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
  /// The shortcuts of this device, kept through [controller].
  const new({required this.controller, super.key});

  /// Where the key map is kept.
  final LibrarySession controller;

  static String _groupName(PaletteGroup? group) => switch (group) {
    PaletteGroup.note => AppStrings.paletteGroupNote,
    PaletteGroup.editor => AppStrings.paletteGroupEditor,
    PaletteGroup.view => AppStrings.paletteGroupView,
    PaletteGroup.library => AppStrings.paletteGroupLibrary,
    PaletteGroup.goTo => AppStrings.paletteGroupGoTo,
    null => AppStrings.paletteCommands,
  };

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
      body: ValueListenableBuilder<KeyMap>(
        valueListenable: AppKeyMap.current,
        builder: (context, map, _) {
          final groups = <PaletteGroup?, List<AppCommand>>{};
          for (final command in AppCommand.values) {
            (groups[paletteGroup(command)] ??= []).add(command);
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              for (final group in [null, ...PaletteGroup.values])
                if (groups[group] case final commands?) ...[
                  _Heading(_groupName(group)),
                  for (final command in commands)
                    _ShortcutRow(
                      command: command,
                      keys: map.bindingOf(command),
                      changed: map.isChanged(command),
                      onChange: () => unawaited(
                        changeShortcut(context, command, controller),
                      ),
                      onClear: () => unawaited(
                        _keep(controller, map.withBinding(command, null)),
                      ),
                      onRevert: () =>
                          unawaited(_keep(controller, map.reverted(command))),
                    ),
                ],
              _Heading(AppStrings.shortcutEditorSection),
              ListTile(
                dense: true,
                title: Text(AppStrings.shortcutFind),
                trailing: const _Keys('Ctrl+F'),
              ),
              ListTile(
                dense: true,
                title: Text(AppStrings.shortcutReplace),
                trailing: const _Keys('Ctrl+H'),
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
          );
        },
      ),
    );
  }
}

final class _Heading extends StatelessWidget {
  const new(this.text);

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

/// One command: its name, its keys (or none), and the ways to change
/// them.
final class _ShortcutRow extends StatelessWidget {
  const new({
    required this.command,
    required this.keys,
    required this.changed,
    required this.onChange,
    required this.onClear,
    required this.onRevert,
  });

  final AppCommand command;
  final SingleActivator? keys;
  final bool changed;
  final VoidCallback onChange;
  final VoidCallback onClear;
  final VoidCallback onRevert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keys = this.keys;
    return ListTile(
      key: Key('shortcut-${command.name}'),
      dense: true,
      title: Text(appCommandLabel(command)),
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
            _Keys(describeActivator(keys)),
          // Always the same two slots, so the keys never shift under the
          // pointer as they come and go.
          SizedBox.square(
            dimension: 36,
            child: changed
                ? IconButton(
                    key: Key('shortcut-revert-${command.name}'),
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
                    key: Key('shortcut-clear-${command.name}'),
                    tooltip: AppStrings.shortcutClear,
                    iconSize: 18,
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

final class _Keys extends StatelessWidget {
  const new(this.text);

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
