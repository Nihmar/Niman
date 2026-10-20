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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/ui/key_map.dart';
import 'package:niman/src/ui/keyboard_presence.dart';
import 'package:niman/src/ui/strings.dart';

/// A command the shell can run from the keyboard.
enum AppCommand {
  /// A new note in the tree.
  newNote,

  /// A new `type: list` note in the list folder.
  newListNote,

  /// A new `type: audio` note in the current folder.
  newAudioNote,

  /// A new `type: slides` note (#534).
  newSlides,

  /// A new `type: flashcard` note (#533).
  newFlashcards,

  /// A new todo task.
  newTodo,

  /// A web page captured as a note (#531).
  captureWebPage,

  /// The quick-note tab (its chooser when none is set).
  quickNote,

  /// Today's journal entry, made first when there is none (#7).
  journalToday,

  /// The journal entry before the one on screen.
  journalPrevious,

  /// The journal entry after the one on screen.
  journalNext,

  /// The journal's calendar: the dock's pane, or the phone's screen.
  journalCalendar,

  /// Show or hide the wide tree pane.
  toggleSidebar,

  /// Close the note showing, its tab with it (#23).
  closeTab,

  /// Show the next open note's tab.
  nextTab,

  /// Show the previous open note's tab.
  previousTab,

  /// Go back to the note shown before (#700).
  noteBack,

  /// Go forward again, after going back (#700).
  noteForward,

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

  /// The note's text a step larger (#538), in the editor and the preview.
  zoomIn,

  /// The note's text a step smaller (#538).
  zoomOut,

  /// The note's text back to its shipped size (#538).
  zoomReset,

  /// Tidy the note's Markdown (#227).
  formatNote,

  /// Insert a Mermaid diagram fence at the caret (#530).
  insertDiagram,

  /// Insert a mind map fence at the caret (#530).
  insertMindMap,

  /// Insert two columns at the caret (#729).
  insertColumns,

  /// Turn the list at the caret into a mind map (#530).
  convertListToMindMap,

  /// Paste the clipboard's HTML as Markdown at the caret (#531).
  pasteAsMarkdown,

  /// Write the note on screen out as a file (#24).
  exportNote,

  /// Recognize the text of the PDF or picture on screen (#594).
  recognizeText,

  /// Write the whole library out as one zip (#24).
  exportLibrary,

  /// The Markdown cheatsheet (#265): every construct, written and shown.
  markdownCheatsheet,

  /// The guided tour (#266), from the step where it was left.
  welcomeTour,

  /// The welcome deck again, read-only: what the app can do.
  welcomeDeck,

  /// Open a Markdown file outside the library (#77).
  openFile,

  /// The command palette (#155): commands and notes in one search.
  openPalette,

  /// The palette, on notes alone.
  goToNote,

  /// Show the note's preview, or back its editor.
  togglePreview,

  /// Present the slides note on screen (#534).
  presentSlides,

  /// The slides note's presenter view (#534).
  presenterView,

  /// Study the deck on screen (#533): the review of its due and new cards.
  studyDeck,

  /// Pick the question and answer columns of the deck on screen (#533).
  deckColumns,

  /// Forget the review of every card of the deck on screen (#533).
  deckReset,

  /// Make the plain note on screen a flashcard deck (#533).
  makeFlashcards,

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

  /// Select the Home tab (#535).
  tabHome,

  /// Select the Study tab (#533).
  tabStudy,

  /// Open the next search sidebar hit (#712).
  searchNextHit,

  /// Open the previous search sidebar hit (#712).
  searchPreviousHit,

  /// Put the cursor in the search sidebar's field (#712).
  focusSearch,

  /// Show the note on screen as the tree's row, the keyboard on the tree
  /// (#712). No key of its own by default: `Ctrl+Shift+E`, the usual one,
  /// is the editor's inline code.
  revealInTree,
}

/// One accelerator and the command it runs.
@immutable
final class AppShortcut {
  /// Creates a registry entry.
  const new(this.command, this.activation, {this.apple});

  /// What runs.
  final AppCommand command;

  /// The keys that run it.
  final ShortcutActivator activation;

  /// The keys on a Mac or an iPad, where [activation] with ⌘ for Ctrl
  /// ([hostKeys]) would take a key the system keeps or one that means
  /// something else there; null when that swap is right.
  final SingleActivator? apple;
}

/// Every app accelerator as shipped, in the order the reference lists
/// them. What runs is [AppKeyMap.current]: these, changed where the user
/// changed them (#159).
///
/// Tab order matches the rail (T-PP-14), so Ctrl+1..5 select the five tabs.
final List<AppShortcut>
nimanAppShortcuts = List<AppShortcut>.unmodifiable(const <AppShortcut>[
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
    // ⌘Q quits.
    apple: SingleActivator(LogicalKeyboardKey.keyQ, control: true),
  ),
  // Not Ctrl+Alt: Linux desktops switch workspaces on it, and on
  // Windows it is AltGr, which types letters on many layouts.
  AppShortcut(
    AppCommand.journalToday,
    SingleActivator(LogicalKeyboardKey.keyJ, control: true, shift: true),
  ),
  AppShortcut(
    AppCommand.journalPrevious,
    SingleActivator(LogicalKeyboardKey.pageUp, control: true, shift: true),
  ),
  AppShortcut(
    AppCommand.journalNext,
    SingleActivator(LogicalKeyboardKey.pageDown, control: true, shift: true),
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
    // ⌘Tab switches applications; ⌃Tab is the tabs' key on a Mac too.
    apple: SingleActivator(LogicalKeyboardKey.tab, control: true),
  ),
  AppShortcut(
    AppCommand.previousTab,
    SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true),
    apple: SingleActivator(LogicalKeyboardKey.tab, control: true, shift: true),
  ),
  // On a Mac ⌥← moves the caret by a word, and ⌘[ ⌘] are back and
  // forward in Finder and Safari.
  AppShortcut(
    AppCommand.noteBack,
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true),
    apple: SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true),
  ),
  AppShortcut(
    AppCommand.noteForward,
    SingleActivator(LogicalKeyboardKey.arrowRight, alt: true),
    apple: SingleActivator(LogicalKeyboardKey.bracketRight, meta: true),
  ),
  AppShortcut(
    AppCommand.splitRight,
    SingleActivator(LogicalKeyboardKey.backslash, control: true),
  ),
  AppShortcut(
    AppCommand.toggleDock,
    SingleActivator(LogicalKeyboardKey.keyB, control: true, shift: true),
  ),
  // W for web: the capture's own key (#531). With Shift, not Alt: see
  // the journal's keys above (#637).
  AppShortcut(
    AppCommand.captureWebPage,
    SingleActivator(LogicalKeyboardKey.keyW, control: true, shift: true),
  ),
  // Paste with Shift: the editor's own Ctrl+V pastes the plain text, and
  // binds nothing with Shift (#531).
  AppShortcut(
    AppCommand.pasteAsMarkdown,
    SingleActivator(LogicalKeyboardKey.keyV, control: true, shift: true),
  ),
  // F11, the key that means fullscreen elsewhere: the issue's
  // Ctrl+Shift+Z is redo in both editors.
  // F11 shows the desktop on a Mac; ⌃⌘F is its full screen.
  AppShortcut(
    AppCommand.zenMode,
    SingleActivator(LogicalKeyboardKey.f11),
    apple: SingleActivator(LogicalKeyboardKey.keyF, control: true, meta: true),
  ),
  // F2, the file managers' rename (#707).
  AppShortcut(AppCommand.renameNote, SingleActivator(LogicalKeyboardKey.f2)),
  // F5 is what presents in every slide app (#534).
  AppShortcut(AppCommand.presentSlides, SingleActivator(LogicalKeyboardKey.f5)),
  AppShortcut(
    AppCommand.presenterView,
    SingleActivator(LogicalKeyboardKey.f5, alt: true),
  ),
  // The same F5 studies a deck (#533): the two commands wait on different
  // notes on screen (`commandNeeds`), so at most one answers.
  AppShortcut(AppCommand.studyDeck, SingleActivator(LogicalKeyboardKey.f5)),
  AppShortcut(
    AppCommand.typewriterMode,
    SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true),
  ),
  // The browsers' keys for the page's zoom, here the note's (#538).
  AppShortcut(
    AppCommand.zoomIn,
    SingleActivator(LogicalKeyboardKey.equal, control: true),
  ),
  AppShortcut(
    AppCommand.zoomOut,
    SingleActivator(LogicalKeyboardKey.minus, control: true),
  ),
  AppShortcut(
    AppCommand.zoomReset,
    SingleActivator(LogicalKeyboardKey.digit0, control: true),
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
    // Every Mac app's settings are ⌘, (the menu bar's Niman menu).
    apple: SingleActivator(LogicalKeyboardKey.comma, meta: true),
  ),
  AppShortcut(
    AppCommand.tabHome,
    SingleActivator(LogicalKeyboardKey.digit6, control: true),
  ),
  AppShortcut(
    AppCommand.tabStudy,
    SingleActivator(LogicalKeyboardKey.digit7, control: true),
  ),
  // F4/Shift+F4, the key every editor's "find next" sits on (#712).
  AppShortcut(AppCommand.searchNextHit, SingleActivator(LogicalKeyboardKey.f4)),
  AppShortcut(
    AppCommand.searchPreviousHit,
    SingleActivator(LogicalKeyboardKey.f4, shift: true),
  ),
  // Ctrl+Shift+F, the search-everywhere chord (#712).
  AppShortcut(
    AppCommand.focusSearch,
    SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true),
  ),
]);

/// The command's localized name, for the reference.
String appCommandLabel(AppCommand command) => switch (command) {
  AppCommand.newNote => AppStrings.shortcutNewNote,
  AppCommand.newListNote => AppStrings.shortcutNewList,
  AppCommand.newAudioNote => AppStrings.shortcutNewAudio,
  AppCommand.newSlides => AppStrings.newSlidesTitle,
  AppCommand.newFlashcards => AppStrings.newFlashcardsTitle,
  AppCommand.studyDeck => AppStrings.flashcardsStudyDeck,
  AppCommand.deckColumns => AppStrings.flashcardsColumnsTitle,
  AppCommand.deckReset => AppStrings.flashcardsResetAction,
  AppCommand.makeFlashcards => AppStrings.makeFlashcardsTitle,
  AppCommand.presentSlides => AppStrings.slidesPresent,
  AppCommand.presenterView => AppStrings.slidesPresenterView,
  AppCommand.newTodo => AppStrings.shortcutNewTodo,
  AppCommand.captureWebPage => AppStrings.captureWebPage,
  AppCommand.quickNote => AppStrings.shortcutQuickNote,
  AppCommand.journalToday => AppStrings.journalToday,
  AppCommand.journalPrevious => AppStrings.journalPrevious,
  AppCommand.journalNext => AppStrings.journalNext,
  AppCommand.journalCalendar => AppStrings.journalShowCalendar,
  AppCommand.toggleSidebar => AppStrings.shortcutToggleSidebar,
  AppCommand.closeTab => AppStrings.shortcutCloseTab,
  AppCommand.nextTab => AppStrings.shortcutNextTab,
  AppCommand.previousTab => AppStrings.shortcutPreviousTab,
  AppCommand.noteBack => AppStrings.shortcutNoteBack,
  AppCommand.noteForward => AppStrings.shortcutNoteForward,
  AppCommand.splitRight => AppStrings.splitRight,
  AppCommand.toggleDock => AppStrings.sidePanelTooltip,
  AppCommand.splitDown => AppStrings.splitDown,
  AppCommand.zenMode => AppStrings.zenMode,
  AppCommand.typewriterMode => AppStrings.typewriterTitle,
  AppCommand.zoomIn => AppStrings.zoomIn,
  AppCommand.zoomOut => AppStrings.zoomOut,
  AppCommand.zoomReset => AppStrings.zoomReset,
  AppCommand.formatNote => AppStrings.formatNoteTitle,
  AppCommand.insertDiagram => AppStrings.commandInsertDiagram,
  AppCommand.insertMindMap => AppStrings.commandInsertMindMap,
  AppCommand.insertColumns => AppStrings.commandInsertColumns,
  AppCommand.convertListToMindMap => AppStrings.commandConvertListToMindMap,
  AppCommand.pasteAsMarkdown => AppStrings.pasteAsMarkdown,
  AppCommand.exportNote => AppStrings.exportTitle,
  AppCommand.recognizeText => AppStrings.ocrRecognizeAction,
  AppCommand.exportLibrary => AppStrings.exportLibraryTitle,
  AppCommand.markdownCheatsheet => AppStrings.cheatsheetTitle,
  AppCommand.welcomeTour => AppStrings.welcomeTourCommand,
  AppCommand.welcomeDeck => AppStrings.welcomeDeckCommand,
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
  AppCommand.tabHome => AppStrings.tabHome,
  AppCommand.tabStudy => AppStrings.tabStudy,
  // The find bar's own words: the same step, through the hits.
  AppCommand.searchNextHit => AppStrings.editorFindNextTooltip,
  AppCommand.searchPreviousHit => AppStrings.editorFindPreviousTooltip,
  AppCommand.focusSearch => AppStrings.searchHint,
  AppCommand.revealInTree => AppStrings.revealInTree,
};

/// The keys as a human reads them: "Ctrl+Shift+N", or on a Mac or an
/// iPad the system's glyphs in its order, "⌃⌥⇧⌘N".
String describeActivator(ShortcutActivator activation, {bool? apple}) {
  if (activation is! SingleActivator) return activation.toString();
  if (apple ?? platformModifierIsMeta) {
    return <String>[
      if (activation.control) '⌃',
      if (activation.alt) '⌥',
      if (activation.shift) '⇧',
      if (activation.meta) '⌘',
      keyName(activation.trigger),
    ].join();
  }
  return <String>[
    if (activation.control) 'Ctrl',
    if (activation.meta) 'Meta',
    if (activation.alt) 'Alt',
    if (activation.shift) 'Shift',
    keyName(activation.trigger),
  ].join('+');
}

/// [label], with the key that runs it when [keys] names one and a
/// keyboard is there to press it (#712): a tooltip that only repeats the
/// icon teaches nothing.
String tooltipWithKeys(String label, SingleActivator? keys) {
  if (keys == null || !KeyboardPresence.shared.attached) return label;
  return '$label (${describeActivator(keys)})';
}

/// Whether the platform's own shortcut modifier is Meta rather than
/// Control: macOS, and an iPad's keyboard (⌘).
bool get platformModifierIsMeta =>
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Shipped [keys] as this host presses them (docs/records/apple-platforms.md).
///
/// The tables are written with Ctrl, the modifier Linux, Windows and
/// Android press; a Mac or an iPad presses ⌘ in its place — or [apple],
/// where that swap would take a key the system keeps. Only shipped keys go
/// through here: a key the user chose is the key they pressed.
SingleActivator hostKeys(SingleActivator keys, {SingleActivator? apple}) {
  if (!platformModifierIsMeta) return keys;
  if (apple != null) return apple;
  if (!keys.control) return keys;
  return SingleActivator(
    keys.trigger,
    meta: true,
    shift: keys.shift,
    alt: keys.alt,
    includeRepeats: keys.includeRepeats,
  );
}

/// The key the editors' find bar opens on (issue #381): `Ctrl+F`, or
/// `Meta+F` on macOS, which binds no `Ctrl+F` at all.
///
/// One source for the binding and for the reference row, so the key that
/// runs and the key the shortcut screen names cannot drift.
SingleActivator findInNoteKey({bool? mac}) {
  final meta = mac ?? platformModifierIsMeta;
  return SingleActivator(LogicalKeyboardKey.keyF, control: !meta, meta: meta);
}

/// The key the editors' replace opens on: the find key with Alt.
SingleActivator replaceInNoteKey({bool? mac}) {
  final meta = mac ?? platformModifierIsMeta;
  return SingleActivator(
    LogicalKeyboardKey.keyF,
    control: !meta,
    meta: meta,
    alt: true,
  );
}

/// The second key the editors' replace answers to, where the platform
/// has one: `Ctrl+H`. Null on macOS, whose chord is [replaceInNoteKey].
SingleActivator? ctrlHReplaceKey({bool? mac}) => (mac ?? platformModifierIsMeta)
    ? null
    : const SingleActivator(LogicalKeyboardKey.keyH, control: true);

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

/// The keys a command runs on besides its listed one, while that one is
/// the shipped key (#577): the zoom's `+` as each layout types it — its
/// own key on Italian and German keyboards, Shift and `=` on a US one —
/// and the numpad's `+` and `-`.
const Map<AppCommand, List<SingleActivator>> _alsoShipped = {
  AppCommand.zoomIn: [
    SingleActivator(LogicalKeyboardKey.add, control: true),
    SingleActivator(LogicalKeyboardKey.equal, control: true, shift: true),
    SingleActivator(LogicalKeyboardKey.numpadAdd, control: true),
  ],
  AppCommand.zoomOut: [
    SingleActivator(LogicalKeyboardKey.numpadSubtract, control: true),
  ],
};

/// The `CallbackShortcuts` bindings: one activator per command with a
/// handler. A command left out of [handlers] is simply not bound, so the
/// shell installs a subset without the registry drifting.
Map<ShortcutActivator, VoidCallback> appShortcutBindings(
  Map<AppCommand, VoidCallback> handlers,
) {
  final bindings = <ShortcutActivator, VoidCallback>{};
  final map = AppKeyMap.current.value;
  // The keys in force: the shipped ones, changed where the user changed
  // them (#159).
  for (final shortcut in map.shortcuts) {
    final handler = handlers[shortcut.command];
    if (handler == null) continue;
    bindings[shortcut.activation] = handler;
    if (map.isChanged(shortcut.command)) continue;
    for (final keys
        in _alsoShipped[shortcut.command] ?? const <SingleActivator>[]) {
      bindings[hostKeys(keys)] = handler;
    }
  }
  return bindings;
}
