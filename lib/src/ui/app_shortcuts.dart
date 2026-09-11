/// The app-level keyboard accelerators, in one place (T-PP-10).
///
/// The editor has its own activator set (`editor/find_panel.dart`); these
/// are the shell's, installed once over the desktop layout and listed in
/// the in-app reference (`ui/keyboard_shortcuts.dart`) from the same
/// registry, so the keys that run and the keys that are documented cannot
/// drift. Only commands the shell actually owns are bound here: Find stays
/// the editor's own key, and edits save automatically, so there is no save
/// shortcut to fight the editor for.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/strings.dart';

/// A command the shell can run from the keyboard.
enum AppCommand {
  /// A new note in the tree.
  newNote,

  /// A new `type: list` note in the list folder.
  newListNote,

  /// A new todo task.
  newTodo,

  /// The quick-note tab (its chooser when none is set).
  quickNote,

  /// Show or hide the wide tree pane.
  toggleSidebar,

  /// Select the Files tab.
  tabFiles,

  /// Select the Todo tab.
  tabTodo,

  /// Select the Search tab.
  tabSearch,

  /// Select the Quick note tab.
  tabQuickNote,

  /// Select the Settings tab.
  tabSettings,
}

/// One accelerator and the command it runs.
@immutable
final class AppShortcut {
  /// Creates a registry entry.
  const new(this.command, this.activation);

  /// What runs.
  final AppCommand command;

  /// The keys that run it.
  final ShortcutActivator activation;
}

/// Every app accelerator, in the order the reference lists them.
///
/// Tab order matches the rail (T-PP-14), so Ctrl+1..5 select the five tabs.
final List<AppShortcut> nimanAppShortcuts = List<AppShortcut>.unmodifiable(
  const <AppShortcut>[
    AppShortcut(
      AppCommand.newNote,
      SingleActivator(LogicalKeyboardKey.keyN, control: true),
    ),
    AppShortcut(
      AppCommand.newListNote,
      SingleActivator(LogicalKeyboardKey.keyN, control: true, shift: true),
    ),
    AppShortcut(
      AppCommand.newTodo,
      SingleActivator(LogicalKeyboardKey.keyT, control: true),
    ),
    AppShortcut(
      AppCommand.quickNote,
      SingleActivator(LogicalKeyboardKey.keyQ, control: true),
    ),
    AppShortcut(
      AppCommand.toggleSidebar,
      SingleActivator(LogicalKeyboardKey.keyB, control: true),
    ),
    AppShortcut(
      AppCommand.tabFiles,
      SingleActivator(LogicalKeyboardKey.digit1, control: true),
    ),
    AppShortcut(
      AppCommand.tabTodo,
      SingleActivator(LogicalKeyboardKey.digit2, control: true),
    ),
    AppShortcut(
      AppCommand.tabSearch,
      SingleActivator(LogicalKeyboardKey.digit3, control: true),
    ),
    AppShortcut(
      AppCommand.tabQuickNote,
      SingleActivator(LogicalKeyboardKey.digit4, control: true),
    ),
    AppShortcut(
      AppCommand.tabSettings,
      SingleActivator(LogicalKeyboardKey.digit5, control: true),
    ),
  ],
);

/// The command's localized name, for the reference.
String appCommandLabel(AppCommand command) => switch (command) {
  AppCommand.newNote => AppStrings.shortcutNewNote,
  AppCommand.newListNote => AppStrings.shortcutNewList,
  AppCommand.newTodo => AppStrings.shortcutNewTodo,
  AppCommand.quickNote => AppStrings.shortcutQuickNote,
  AppCommand.toggleSidebar => AppStrings.shortcutToggleSidebar,
  AppCommand.tabFiles => AppStrings.tabFiles,
  AppCommand.tabTodo => AppStrings.todoTitle,
  AppCommand.tabSearch => AppStrings.tabSearch,
  AppCommand.tabQuickNote => AppStrings.quickNoteTitle,
  AppCommand.tabSettings => AppStrings.tabSettings,
};

/// The keys as a human reads them ("Ctrl+Shift+N").
String describeActivator(ShortcutActivator activation) {
  if (activation is! SingleActivator) return activation.toString();
  return <String>[
    if (activation.control) 'Ctrl',
    if (activation.meta) 'Meta',
    if (activation.alt) 'Alt',
    if (activation.shift) 'Shift',
    activation.trigger.keyLabel,
  ].join('+');
}

/// The `CallbackShortcuts` bindings: one activator per command with a
/// handler. A command left out of [handlers] is simply not bound, so the
/// shell installs a subset without the registry drifting.
Map<ShortcutActivator, VoidCallback> appShortcutBindings(
  Map<AppCommand, VoidCallback> handlers,
) {
  final bindings = <ShortcutActivator, VoidCallback>{};
  for (final shortcut in nimanAppShortcuts) {
    final handler = handlers[shortcut.command];
    if (handler != null) bindings[shortcut.activation] = handler;
  }
  return bindings;
}
