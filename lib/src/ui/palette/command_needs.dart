/// When each command can run (#207): what the palette offers and the
/// keys answer to, said once.
///
/// The shell builds a handler for every command and keeps the ones whose
/// needs are met here and now; the Commands page in Settings lists the
/// same needs in words. One table read by both, so the page cannot say a
/// command is there when the palette leaves it out.
library;

import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/strings.dart';

/// One condition a command waits on.
enum CommandNeed {
  /// A note is on screen.
  openNote,

  /// The window is wide enough for tabs and panes.
  wideWindow,

  /// The window is wide enough for the right dock.
  dockRoom,

  /// Linux or Windows: a picker for any file, a window to make Zen of.
  desktop,

  /// Zen mode is off: what Zen hides it also leaves alone.
  notInZen,

  /// Zen can start: the desktop's window, wide, with a note in a tab —
  /// or Zen is on already, to leave it.
  zenRoom,

  /// The note has a preview to switch to: the preview is on, and the
  /// note is text, not a list or a voice note in its own view.
  previewToggle,

  /// Both editors are enabled, so there is another to switch to.
  twoEditors,
}

/// What [command] waits on; empty for one that can always run.
Set<CommandNeed> commandNeeds(AppCommand command) => switch (command) {
  AppCommand.togglePreview => const {
    CommandNeed.openNote,
    CommandNeed.previewToggle,
  },
  AppCommand.switchEditor => const {
    CommandNeed.openNote,
    CommandNeed.twoEditors,
  },
  AppCommand.renameNote ||
  AppCommand.moveNote ||
  AppCommand.deleteNote ||
  AppCommand.noteHistory => const {CommandNeed.openNote},
  AppCommand.closeTab ||
  AppCommand.nextTab ||
  AppCommand.previousTab => const {CommandNeed.wideWindow},
  AppCommand.splitRight ||
  AppCommand.splitDown => const {CommandNeed.wideWindow, CommandNeed.notInZen},
  AppCommand.toggleDock => const {CommandNeed.dockRoom, CommandNeed.notInZen},
  AppCommand.toggleSidebar => const {CommandNeed.notInZen},
  AppCommand.zenMode => const {CommandNeed.zenRoom},
  AppCommand.openFile => const {CommandNeed.desktop},
  AppCommand.openPalette ||
  AppCommand.goToNote ||
  AppCommand.newNote ||
  AppCommand.newListNote ||
  AppCommand.newAudioNote ||
  AppCommand.newTodo ||
  AppCommand.quickNote ||
  AppCommand.typewriterMode ||
  AppCommand.reindexLibrary ||
  AppCommand.switchLibrary ||
  AppCommand.tabFiles ||
  AppCommand.tabTodo ||
  AppCommand.tabSearch ||
  AppCommand.tabQuickNote ||
  AppCommand.tabSettings => const {},
};

/// [need] in words, for the Commands page.
String commandNeedLabel(CommandNeed need) => switch (need) {
  CommandNeed.openNote => AppStrings.commandNeedOpenNote,
  CommandNeed.wideWindow => AppStrings.commandNeedWideWindow,
  CommandNeed.dockRoom => AppStrings.commandNeedDockRoom,
  CommandNeed.desktop => AppStrings.commandNeedDesktop,
  CommandNeed.notInZen => AppStrings.commandNeedNotInZen,
  CommandNeed.zenRoom => AppStrings.commandNeedZenRoom,
  CommandNeed.previewToggle => AppStrings.commandNeedPreview,
  CommandNeed.twoEditors => AppStrings.commandNeedTwoEditors,
};
