/// The Commands area of the settings (#207): every command the palette
/// can run, grouped as the palette groups them, with its keys and when
/// it shows.
///
/// The palette offers only what can run here and now, so a command that
/// needs an open note or a wide window is simply not there without one,
/// and looks missing. This page says so. The conditions come from
/// [commandNeeds], the same table the shell filters its handlers by, so
/// the page and the palette cannot disagree.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
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
  const new({this.highlight, super.key});

  /// The row to flash, or null.
  final Key? highlight;

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
        child: ValueListenableBuilder<KeyMap>(
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
                        keys: map.bindingOf(command),
                      ),
                  ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One command: its name, when it shows, and its keys if it has any.
final class _CommandRow extends StatelessWidget {
  const new({required this.command, required this.keys});

  final AppCommand command;
  final SingleActivator? keys;

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
        trailing: keys == null ? null : ShortcutKeys(describeActivator(keys)),
      ),
    );
  }
}
