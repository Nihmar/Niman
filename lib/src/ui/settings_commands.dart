/// The Commands area of the settings (#207): every command the palette
/// can run, grouped as the palette groups them, with its keys and when
/// it shows.
///
/// The palette offers only what can run here and now, so a command that
/// needs an open note or a wide window is simply not there without one,
/// and looks missing. This page says so. The conditions come from
/// [commandNeeds], the same table the shell filters its handlers by, so
/// the page and the palette cannot disagree.
///
/// It is a reference, and nothing is changed here (#264): it looks enough
/// like Keyboard shortcuts to pass for a second place to set keys. So it
/// says where its keys come from, with a way there, and each keycap leads
/// to that command's row in it.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_presence.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/palette/command_needs.dart';
import 'package:niman/src/ui/palette/palette_command.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/strings.dart';

/// The key of [command]'s row on the Commands page.
Key commandRowKey(AppCommand command) => Key('command-${command.name}');

/// The screen.
final class SettingsCommandsScreen extends StatelessWidget {
  /// The page; [highlight] is the row the settings search landed on.
  /// [openShortcuts] opens Keyboard shortcuts at a command's row (or at
  /// the top, for null); without it the keys are only shown.
  const new({this.highlight, this.openShortcuts, super.key});

  /// The row to flash, or null.
  final Key? highlight;

  /// Opens Keyboard shortcuts, at [AppCommand]'s row when given.
  final void Function(AppCommand? command)? openShortcuts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final groups = <PaletteGroup?, List<AppCommand>>{};
    for (final command in AppCommand.values) {
      (groups[paletteGroup(command)] ??= []).add(command);
    }
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.commandsTitle)),
      body: SettingsHighlight(
        target: highlight,
        child: ListenableBuilder(
          listenable: KeyboardPresence.shared,
          builder: (context, _) => ValueListenableBuilder<KeyMap>(
            valueListenable: AppKeyMap.current,
            // Every row built, not a lazy list: the search lands on a row
            // that has to exist to scroll itself into view.
            builder: (context, map, _) => SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(AppStrings.commandsIntro, style: muted),
                  ),
                  // Keys only mean something with a keyboard, and so does
                  // the page that changes them.
                  if (KeyboardPresence.shared.attached)
                    _KeysNote(openShortcuts: openShortcuts),
                  for (final group in [null, ...PaletteGroup.values])
                    if (groups[group] case final commands?) ...[
                      SettingsListHeading(
                        group == null
                            ? AppStrings.paletteCommands
                            : paletteGroupName(group),
                      ),
                      for (final command in commands)
                        _CommandRow(
                          command: command,
                          // No keyboard, no keys to name (#230): what a
                          // command needs is the point of this page, and
                          // that stays.
                          keys: KeyboardPresence.shared.attached
                              ? map.bindingOf(command)
                              : null,
                          onKeys: switch (openShortcuts) {
                            final open? => () => open(command),
                            null => null,
                          },
                        ),
                    ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Where the keys come from, and the way to change them.
final class _KeysNote extends StatelessWidget {
  const new({required this.openShortcuts});

  final void Function(AppCommand? command)? openShortcuts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final open = openShortcuts;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.commandsKeysNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (open != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                key: const Key('commands-open-shortcuts'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => open(null),
                icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                label: Text(AppStrings.commandsOpenShortcuts),
              ),
            ),
        ],
      ),
    );
  }
}

/// One command: its name, when it shows, and its keys if it has any —
/// a keycap that, given [onKeys], leads to where they are changed.
final class _CommandRow extends StatelessWidget {
  const new({required this.command, required this.keys, this.onKeys});

  final AppCommand command;
  final SingleActivator? keys;
  final VoidCallback? onKeys;

  @override
  Widget build(BuildContext context) {
    final needs = commandNeeds(command);
    final keys = this.keys;
    final name = appCommandLabel(command);
    return HighlightRow(
      key: commandRowKey(command),
      child: ListTile(
        dense: true,
        title: Text(paletteAsks(command) ? '$name…' : name),
        subtitle: Text(
          needs.isEmpty
              ? AppStrings.commandNeedNone
              : [for (final need in needs) commandNeedLabel(need)].join(' · '),
        ),
        trailing: keys == null
            ? null
            : onKeys == null
            ? ShortcutKeys(describeActivator(keys))
            : Tooltip(
                message: AppStrings.commandsChangeKeyTooltip,
                child: InkWell(
                  key: Key('command-keys-${command.name}'),
                  borderRadius: BorderRadius.circular(5),
                  onTap: onKeys,
                  child: ShortcutKeys(describeActivator(keys)),
                ),
              ),
      ),
    );
  }
}
