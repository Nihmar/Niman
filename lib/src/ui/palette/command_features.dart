/// Which feature a command belongs to (#1109), said once.
///
/// A command whose feature is off is not offered anywhere: not in the
/// palette, not on its key, not in a menu. The shell asks one question,
/// "needs met and feature on", and the answers come from `commandNeeds`
/// and from here — an exhaustive `switch`, so a command added without a
/// feature (or an explicit null) does not compile.
library;

import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/app_shortcuts.dart';

/// The feature [command] belongs to, or null for one that is core: the
/// files, the editor, export, trash and history, settings, the palette and
/// the keys — and sync, which is not a feature.
LibraryFeature? featureOf(AppCommand command) => switch (command) {
  AppCommand.searchNextHit ||
  AppCommand.searchPreviousHit ||
  AppCommand.focusSearch ||
  AppCommand.tabSearch => LibraryFeature.search,
  AppCommand.quickNote || AppCommand.tabQuickNote => LibraryFeature.quickNote,
  AppCommand.captureWebPage ||
  AppCommand.pasteAsMarkdown => LibraryFeature.capture,
  AppCommand.newTodo || AppCommand.tabTodo => LibraryFeature.todo,
  AppCommand.journalToday ||
  AppCommand.journalPrevious ||
  AppCommand.journalNext ||
  AppCommand.journalCalendar => LibraryFeature.journal,
  AppCommand.newListNote => LibraryFeature.kindList,
  AppCommand.newAudioNote => LibraryFeature.kindAudio,
  AppCommand.newSlides ||
  AppCommand.presentSlides ||
  AppCommand.presenterView => LibraryFeature.kindSlides,
  AppCommand.newFlashcards ||
  AppCommand.studyDeck ||
  AppCommand.deckColumns ||
  AppCommand.deckReset ||
  AppCommand.makeFlashcards ||
  AppCommand.tabStudy => LibraryFeature.kindFlashcards,
  AppCommand.recognizeText => LibraryFeature.ocr,
  AppCommand.tabHome => LibraryFeature.home,
  AppCommand.newNote ||
  AppCommand.toggleSidebar ||
  AppCommand.closeTab ||
  AppCommand.nextTab ||
  AppCommand.previousTab ||
  AppCommand.noteBack ||
  AppCommand.noteForward ||
  AppCommand.splitRight ||
  AppCommand.toggleDock ||
  AppCommand.splitDown ||
  AppCommand.zenMode ||
  AppCommand.typewriterMode ||
  AppCommand.zoomIn ||
  AppCommand.zoomOut ||
  AppCommand.zoomReset ||
  AppCommand.formatNote ||
  AppCommand.insertDiagram ||
  AppCommand.insertMindMap ||
  AppCommand.insertColumns ||
  AppCommand.convertListToMindMap ||
  AppCommand.exportNote ||
  AppCommand.exportLibrary ||
  AppCommand.convertEpub ||
  AppCommand.markdownCheatsheet ||
  AppCommand.welcomeTour ||
  AppCommand.welcomeDeck ||
  AppCommand.openFile ||
  AppCommand.openPalette ||
  AppCommand.goToNote ||
  AppCommand.togglePreview ||
  AppCommand.switchEditor ||
  AppCommand.renameNote ||
  AppCommand.moveNote ||
  AppCommand.deleteNote ||
  AppCommand.noteHistory ||
  AppCommand.reindexLibrary ||
  AppCommand.switchLibrary ||
  AppCommand.tabFiles ||
  AppCommand.tabSettings ||
  AppCommand.revealInTree => null,
};

/// Whether [command]'s feature is on in [features]: always, for a core
/// command. This is the half of "available" that `commandNeeds` does not
/// say.
bool commandFeatureOn(AppCommand command, Features features) =>
    switch (featureOf(command)) {
      final feature? => features.isOn(feature),
      null => true,
    };
