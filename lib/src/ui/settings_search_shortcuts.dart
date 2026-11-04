import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_shortcuts.dart';
import 'package:niman/src/ui/settings_areas.dart';
import 'package:niman/src/ui/settings_commands.dart';
import 'package:niman/src/ui/settings_search_entry.dart';
import 'package:niman/src/ui/settings_search_scope.dart';
import 'package:niman/src/ui/strings.dart';

/// The settings search's rows of the commands and the formatting keys
/// (#104), on Keyboard shortcuts with a [keyboardAttached] and on
/// Commands without, leaving out a command named like one of [titles] —
/// the rows already listed.
List<SettingsSearchEntry> shortcutSearchEntries(
  SettingsSearchScope scope, {
  required Set<String> titles,
  required bool keyboardAttached,
}) {
  return [
    // Every command's own row on the keyboard screen: searching "zen" lands
    // on Zen mode's keys, not only on the screen's title (0.0.8 test round).
    // Without a keyboard, where that screen does not open, on its row of
    // the Commands page instead (#207). None named like a row above
    // (Re-index now, Switch library): the setting itself is the better
    // answer, and the list shows no twins.
    for (final command in AppCommand.values)
      if (titles.contains(appCommandLabel(command)))
        ...const <SettingsSearchEntry>[]
      else if (keyboardAttached)
        SettingsSearchEntry(
          title: appCommandLabel(command),
          area: AppStrings.keyboardShortcutsTitle,
          rowKey: shortcutRowKey(command),
          areaId: SettingsAreaId.shortcuts,
          value: () async =>
              switch (AppKeyMap.current.value.bindingOf(command)) {
                final keys? => describeActivator(keys),
                null => AppStrings.shortcutNone,
              },
          open: () =>
              scope.openArea(SettingsAreaId.shortcuts, shortcutRowKey(command)),
        )
      else
        SettingsSearchEntry(
          title: appCommandLabel(command),
          area: AppStrings.commandsTitle,
          rowKey: commandRowKey(command),
          areaId: SettingsAreaId.commands,
          value: scope.noValue,
          open: () =>
              scope.openArea(SettingsAreaId.commands, commandRowKey(command)),
        ),
    // The formatting keys (#205), where there is a keyboard to press:
    // searching "bold" lands on its row rather than on nothing.
    if (keyboardAttached)
      for (final item in ToolbarItem.values)
        if (item != ToolbarItem.tools)
          SettingsSearchEntry(
            title: item.label,
            area: AppStrings.keyboardShortcutsTitle,
            rowKey: editorShortcutRowKey(item),
            areaId: SettingsAreaId.shortcuts,
            value: () async =>
                switch (AppKeyMap.current.value.editorBindingOf(item)) {
                  final keys? => describeActivator(keys),
                  null => AppStrings.shortcutNone,
                },
            open: () => scope.openArea(
              SettingsAreaId.shortcuts,
              editorShortcutRowKey(item),
            ),
          ),
  ];
}
