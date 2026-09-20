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
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/strings.dart';

/// A command the shell can run from the keyboard.
enum AppCommand {
  /// A new note in the tree.
  newNote,

  /// A new `type: list` note in the list folder.
  newListNote,

  /// A new `type: audio` note in the current folder.
  newAudioNote,

  /// A new todo task.
  newTodo,

  /// The quick-note tab (its chooser when none is set).
  quickNote,

  /// Show or hide the wide tree pane.
  toggleSidebar,

  /// Close the note showing, its tab with it (#23).
  closeTab,

  /// Show the next open note's tab.
  nextTab,

  /// Show the previous open note's tab.
  previousTab,

  /// Split the window right with the note on screen (#23).
  splitRight,

  /// Show or hide the right dock (#175).
  toggleDock,

  /// Split the window down with the note on screen (#23).
  splitDown,

  /// Enter or leave Zen mode (#69): the note, and nothing else.
  zenMode,

  /// Switch typewriter mode (#70): the line being written in the middle.
  typewriterMode,

  /// Tidy the note's Markdown (#227).
  formatNote,

  /// Open a Markdown file outside the library (#77).
  openFile,

  /// The command palette (#155): commands and notes in one search.
  openPalette,

  /// The palette, on notes alone.
  goToNote,

  /// Show the note's preview, or back its editor.
  togglePreview,

  /// Switch the note between the source editor and the WYSIWYG.
  switchEditor,

  /// Rename the note on screen.
  renameNote,

  /// Move the note on screen to another folder.
  moveNote,

  /// Delete the note on screen.
  deleteNote,

  /// The note's kept versions.
  noteHistory,

  /// Re-read the library from disk into its index.
  reindexLibrary,

  /// Switch to another library.
  switchLibrary,

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

/// Every app accelerator as shipped, in the order the reference lists
/// them. What runs is [AppKeyMap.current]: these, changed where the user
/// changed them (#159).
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
      AppCommand.newAudioNote,
      SingleActivator(LogicalKeyboardKey.keyA, control: true, shift: true),
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
      AppCommand.closeTab,
      SingleActivator(LogicalKeyboardKey.keyW, control: true),
    ),
    AppShortcut(
      AppCommand.nextTab,
      SingleActivator(LogicalKeyboardKey.tab, control: true),
    ),
    AppShortcut(
      AppCommand.previousTab,
      SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true),
    ),
    AppShortcut(
      AppCommand.splitRight,
      SingleActivator(LogicalKeyboardKey.backslash, control: true),
    ),
    AppShortcut(
      AppCommand.toggleDock,
      SingleActivator(LogicalKeyboardKey.keyB, control: true, shift: true),
    ),
    // F11, the key that means fullscreen elsewhere: the issue's
    // Ctrl+Shift+Z is redo in both editors.
    AppShortcut(AppCommand.zenMode, SingleActivator(LogicalKeyboardKey.f11)),
    AppShortcut(
      AppCommand.typewriterMode,
      SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true),
    ),
    AppShortcut(
      AppCommand.openPalette,
      SingleActivator(LogicalKeyboardKey.keyP, control: true, shift: true),
    ),
    AppShortcut(
      AppCommand.openFile,
      SingleActivator(LogicalKeyboardKey.keyO, control: true, shift: true),
    ),
    AppShortcut(
      AppCommand.goToNote,
      SingleActivator(LogicalKeyboardKey.keyO, control: true),
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
  AppCommand.newAudioNote => AppStrings.shortcutNewAudio,
  AppCommand.newTodo => AppStrings.shortcutNewTodo,
  AppCommand.quickNote => AppStrings.shortcutQuickNote,
  AppCommand.toggleSidebar => AppStrings.shortcutToggleSidebar,
  AppCommand.closeTab => AppStrings.shortcutCloseTab,
  AppCommand.nextTab => AppStrings.shortcutNextTab,
  AppCommand.previousTab => AppStrings.shortcutPreviousTab,
  AppCommand.splitRight => AppStrings.splitRight,
  AppCommand.toggleDock => AppStrings.sidePanelTooltip,
  AppCommand.splitDown => AppStrings.splitDown,
  AppCommand.zenMode => AppStrings.zenMode,
  AppCommand.typewriterMode => AppStrings.typewriterTitle,
  AppCommand.formatNote => AppStrings.formatNoteTitle,
  AppCommand.openFile => AppStrings.openFileTitle,
  AppCommand.openPalette => AppStrings.commandPaletteTitle,
  AppCommand.goToNote => AppStrings.goToNoteTitle,
  AppCommand.togglePreview => AppStrings.showPreviewTooltip,
  AppCommand.switchEditor => AppStrings.switchToWysiwygTooltip,
  AppCommand.renameNote => AppStrings.actionRename,
  AppCommand.moveNote => AppStrings.actionMove,
  AppCommand.deleteNote => AppStrings.actionDelete,
  AppCommand.noteHistory => AppStrings.noteHistoryTitle,
  AppCommand.reindexLibrary => AppStrings.reindexTitle,
  AppCommand.switchLibrary => AppStrings.switchLibraryTitle,
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
    keyName(activation.trigger),
  ].join('+');
}

/// [key] as a person reads it, in their language (#159): the modifiers
/// keep their names, and so do letters and digits; the named keys do not.
String keyName(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.space) return AppStrings.keySpace;
  if (key == LogicalKeyboardKey.enter) return AppStrings.keyEnter;
  if (key == LogicalKeyboardKey.tab) return AppStrings.keyTab;
  if (key == LogicalKeyboardKey.escape) return AppStrings.keyEscape;
  if (key == LogicalKeyboardKey.backspace) return AppStrings.keyBackspace;
  if (key == LogicalKeyboardKey.delete) return AppStrings.keyDelete;
  if (key == LogicalKeyboardKey.arrowUp) return AppStrings.keyArrowUp;
  if (key == LogicalKeyboardKey.arrowDown) return AppStrings.keyArrowDown;
  if (key == LogicalKeyboardKey.arrowLeft) return AppStrings.keyArrowLeft;
  if (key == LogicalKeyboardKey.arrowRight) return AppStrings.keyArrowRight;
  if (key == LogicalKeyboardKey.home) return AppStrings.keyHome;
  if (key == LogicalKeyboardKey.end) return AppStrings.keyEnd;
  if (key == LogicalKeyboardKey.pageUp) return AppStrings.keyPageUp;
  if (key == LogicalKeyboardKey.pageDown) return AppStrings.keyPageDown;
  if (key == LogicalKeyboardKey.insert) return AppStrings.keyInsert;
  return key.keyLabel;
}

/// The `CallbackShortcuts` bindings: one activator per command with a
/// handler. A command left out of [handlers] is simply not bound, so the
/// shell installs a subset without the registry drifting.
Map<ShortcutActivator, VoidCallback> appShortcutBindings(
  Map<AppCommand, VoidCallback> handlers,
) {
  final bindings = <ShortcutActivator, VoidCallback>{};
  // The keys in force: the shipped ones, changed where the user changed
  // them (#159).
  for (final shortcut in AppKeyMap.current.value.shortcuts) {
    final handler = handlers[shortcut.command];
    if (handler != null) bindings[shortcut.activation] = handler;
  }
  return bindings;
}
