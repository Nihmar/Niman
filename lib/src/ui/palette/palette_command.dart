/// The command palette's commands (#155): the app's own [AppCommand]s,
/// named the way Obsidian and VS Code both name theirs — `Group: Verb`,
/// so an alphabetical list groups itself — and ending in `…` when they
/// ask something before they act.
///
/// A new feature is reached by adding an [AppCommand] and its handler;
/// the palette lists it with no chrome of its own.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/strings.dart';

/// The group a command's name starts with.
enum PaletteGroup {
  /// The note: new ones, and the one on screen.
  note,

  /// How the note is edited and shown.
  editor,

  /// The window: panes, tabs, panels.
  view,

  /// The library as a whole.
  library,

  /// The app's places.
  goTo,
}

/// The group [command] belongs to; null for the ones named on their own
/// (the palette and Go to note, whose names say it already).
PaletteGroup? paletteGroup(AppCommand command) => switch (command) {
  AppCommand.newNote ||
  AppCommand.newListNote ||
  AppCommand.newAudioNote ||
  AppCommand.newTodo ||
  AppCommand.quickNote ||
  AppCommand.renameNote ||
  AppCommand.moveNote ||
  AppCommand.deleteNote ||
  AppCommand.noteHistory ||
  AppCommand.openFile ||
  AppCommand.closeTab => PaletteGroup.note,
  AppCommand.togglePreview ||
  AppCommand.switchEditor ||
  AppCommand.typewriterMode => PaletteGroup.editor,
  AppCommand.toggleSidebar ||
  AppCommand.toggleDock ||
  AppCommand.splitRight ||
  AppCommand.splitDown ||
  AppCommand.zenMode ||
  AppCommand.nextTab ||
  AppCommand.previousTab => PaletteGroup.view,
  AppCommand.reindexLibrary || AppCommand.switchLibrary => PaletteGroup.library,
  AppCommand.tabFiles ||
  AppCommand.tabTodo ||
  AppCommand.tabSearch ||
  AppCommand.tabQuickNote ||
  AppCommand.tabSettings => PaletteGroup.goTo,
  AppCommand.openPalette || AppCommand.goToNote => null,
};

/// Whether [command] asks something before it acts: its name ends in
/// `…`, a different promise from one that just runs.
bool paletteAsks(AppCommand command) => switch (command) {
  AppCommand.newNote ||
  AppCommand.newListNote ||
  AppCommand.newTodo ||
  AppCommand.renameNote ||
  AppCommand.moveNote ||
  AppCommand.deleteNote ||
  AppCommand.openFile ||
  AppCommand.switchLibrary => true,
  _ => false,
};

String _groupName(PaletteGroup group) => switch (group) {
  PaletteGroup.note => AppStrings.paletteGroupNote,
  PaletteGroup.editor => AppStrings.paletteGroupEditor,
  PaletteGroup.view => AppStrings.paletteGroupView,
  PaletteGroup.library => AppStrings.paletteGroupLibrary,
  PaletteGroup.goTo => AppStrings.paletteGroupGoTo,
};

/// One command as the palette lists it.
@immutable
final class PaletteCommand {
  /// [command], called [name], bound to [binding] when it has a key.
  const new({required this.command, required this.name, this.binding});

  /// [command] with its palette name; [label] replaces the registry's
  /// own where the state words it better ("Show editor" while the
  /// preview is up).
  factory of(AppCommand command, {String? label}) {
    final group = paletteGroup(command);
    final verb = label ?? appCommandLabel(command);
    final name = group == null ? verb : '${_groupName(group)}: $verb';
    final binding = AppKeyMap.current.value.bindingOf(command);
    return PaletteCommand(
      command: command,
      name: paletteAsks(command) ? '$name…' : name,
      binding: binding,
    );
  }

  /// What runs.
  final AppCommand command;

  /// What the palette calls it.
  final String name;

  /// Its key, shown beside it; null when it has none.
  final ShortcutActivator? binding;
}
