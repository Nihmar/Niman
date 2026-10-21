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

  /// The note on screen is text: not a picture, a PDF or a book, which
  /// the pane shows rather than edits.
  textNote,

  /// The window is wide enough for tabs and panes.
  wideWindow,

  /// Linux or Windows: a picker for any file, a window to make Zen of.
  desktop,

  /// Zen mode is off: what Zen hides it also leaves alone.
  notInZen,

  /// Zen can start: the desktop's window, wide, with a note in a tab —
  /// or Zen is on already, to leave it.
  zenRoom,

  /// The note can be read as well as written: it is text, not a list or
  /// a voice note in its own view.
  previewToggle,

  /// The note on screen is prose: not a voice note, whose body is its
  /// clip document and which the tidy rules would rewrite (#840).
  proseNote,

  /// Both editors are enabled, so there is another to switch to.
  twoEditors,

  /// The note on screen is a journal entry (#7).
  journalEntry,

  /// A PDF or a picture is on screen, and text recognition is there to
  /// read it (#594).
  ocrFile,

  /// A slides note is on screen (#534).
  slidesNote,

  /// A flashcard deck is on screen, shown as its cards (#533).
  flashcardNote,

  /// The note on screen is plain text of no `type`: it can become a deck
  /// (#533).
  plainNote,
}

/// What [command] waits on; empty for one that can always run.
Set<CommandNeed> commandNeeds(AppCommand command) => switch (command) {
  AppCommand.togglePreview => const {
    CommandNeed.textNote,
    CommandNeed.previewToggle,
  },
  AppCommand.switchEditor => const {
    CommandNeed.textNote,
    CommandNeed.twoEditors,
  },
  AppCommand.renameNote ||
  AppCommand.moveNote ||
  AppCommand.deleteNote => const {CommandNeed.openNote},
  AppCommand.formatNote => const {CommandNeed.textNote, CommandNeed.proseNote},
  AppCommand.insertDiagram ||
  AppCommand.insertMindMap ||
  AppCommand.insertColumns ||
  AppCommand.convertListToMindMap ||
  AppCommand.pasteAsMarkdown ||
  AppCommand.exportNote ||
  AppCommand.noteHistory => const {CommandNeed.textNote},
  AppCommand.closeTab ||
  AppCommand.nextTab ||
  AppCommand.previousTab => const {CommandNeed.wideWindow},
  AppCommand.revealInTree => const {
    CommandNeed.openNote,
    CommandNeed.wideWindow,
  },
  AppCommand.splitRight ||
  AppCommand.splitDown => const {CommandNeed.wideWindow, CommandNeed.notInZen},
  AppCommand.toggleDock => const {CommandNeed.wideWindow, CommandNeed.notInZen},
  AppCommand.toggleSidebar => const {CommandNeed.notInZen},
  AppCommand.journalPrevious ||
  AppCommand.journalNext => const {CommandNeed.journalEntry},
  AppCommand.zenMode => const {CommandNeed.zenRoom},
  AppCommand.recognizeText => const {CommandNeed.ocrFile},
  AppCommand.presentSlides => const {CommandNeed.slidesNote},
  AppCommand.presenterView => const {
    CommandNeed.slidesNote,
    CommandNeed.desktop,
  },
  AppCommand.studyDeck ||
  AppCommand.deckColumns ||
  AppCommand.deckReset => const {CommandNeed.flashcardNote},
  AppCommand.makeFlashcards => const {
    CommandNeed.textNote,
    CommandNeed.plainNote,
  },
  AppCommand.openFile => const {CommandNeed.desktop},
  AppCommand.openPalette ||
  AppCommand.goToNote ||
  AppCommand.newNote ||
  AppCommand.newListNote ||
  AppCommand.newAudioNote ||
  AppCommand.newSlides ||
  AppCommand.newFlashcards ||
  AppCommand.newTodo ||
  AppCommand.captureWebPage ||
  AppCommand.quickNote ||
  AppCommand.journalToday ||
  AppCommand.journalCalendar ||
  AppCommand.typewriterMode ||
  AppCommand.zoomIn ||
  AppCommand.zoomOut ||
  AppCommand.zoomReset ||
  AppCommand.markdownCheatsheet ||
  AppCommand.welcomeTour ||
  AppCommand.welcomeDeck ||
  AppCommand.reindexLibrary ||
  AppCommand.exportLibrary ||
  AppCommand.convertEpub ||
  AppCommand.switchLibrary ||
  AppCommand.tabFiles ||
  AppCommand.tabTodo ||
  AppCommand.tabSearch ||
  AppCommand.tabQuickNote ||
  AppCommand.tabSettings ||
  AppCommand.tabHome ||
  AppCommand.tabStudy ||
  AppCommand.noteBack ||
  AppCommand.noteForward ||
  // The step and the focus no-op when there is no search on screen; the
  // palette offering them is cheaper than a need that says so.
  AppCommand.searchNextHit ||
  AppCommand.searchPreviousHit ||
  AppCommand.focusSearch => const {},
};

/// [need] in words, for the Commands page.
String commandNeedLabel(CommandNeed need) => switch (need) {
  CommandNeed.openNote => AppStrings.commandNeedOpenNote,
  CommandNeed.textNote => AppStrings.commandNeedTextNote,
  CommandNeed.wideWindow => AppStrings.commandNeedWideWindow,
  CommandNeed.desktop => AppStrings.commandNeedDesktop,
  CommandNeed.notInZen => AppStrings.commandNeedNotInZen,
  CommandNeed.zenRoom => AppStrings.commandNeedZenRoom,
  CommandNeed.previewToggle => AppStrings.commandNeedPreview,
  CommandNeed.proseNote => AppStrings.commandNeedProseNote,
  CommandNeed.twoEditors => AppStrings.commandNeedTwoEditors,
  CommandNeed.journalEntry => AppStrings.commandNeedJournalEntry,
  CommandNeed.ocrFile => AppStrings.commandNeedOcrFile,
  CommandNeed.slidesNote => AppStrings.commandNeedSlidesNote,
  CommandNeed.flashcardNote => AppStrings.commandNeedFlashcardNote,
  CommandNeed.plainNote => AppStrings.commandNeedPlainNote,
};
