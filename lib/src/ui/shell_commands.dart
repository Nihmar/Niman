import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/host_platform.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/diagram_templates.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/epub_convert_flow.dart';
import 'package:niman/src/ui/journal/journal_flow.dart';
import 'package:niman/src/ui/kinds/flashcards/review_tab.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/outside_files.dart';
import 'package:niman/src/ui/palette/command_features.dart';
import 'package:niman/src/ui/palette/command_needs.dart';
import 'package:niman/src/ui/shell_compare_tab.dart';
import 'package:niman/src/ui/shell_create_flow.dart';
import 'package:niman/src/ui/shell_dock.dart';
import 'package:niman/src/ui/shell_export_flow.dart';
import 'package:niman/src/ui/shell_journal_ui.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_note_actions.dart';
import 'package:niman/src/ui/shell_note_history.dart';
import 'package:niman/src/ui/shell_note_kind.dart';
import 'package:niman/src/ui/shell_ocr_flow.dart';
import 'package:niman/src/ui/shell_palette.dart';
import 'package:niman/src/ui/shell_quick_note.dart';
import 'package:niman/src/ui/shell_row_actions.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_settings.dart';
import 'package:niman/src/ui/shell_shown_note.dart';
import 'package:niman/src/ui/shell_tab_bodies.dart';
import 'package:niman/src/ui/shell_tab_switch.dart';
import 'package:niman/src/ui/shell_tasks.dart';
import 'package:niman/src/ui/shell_windows.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/shell_zen.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/tour/tour_host.dart';
import 'package:niman/src/ui/welcome/welcome_gate.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:path/path.dart' as p;

/// The commands (#155, #1256): what each does, which of them can run here
/// and now, and how the palette words the ones the state words better. The
/// keys, the palette, the app menu and the Mac's menu bar all ask this
/// table. A new feature reaches them all by adding its handler to [_all]
/// and, if it waits on something, its needs to `commandNeeds`, which the
/// Commands page in Settings reads too.
final class ShellCommands {
  /// The commands of the shell these collaborators make up.
  new({
    required this.controller,
    required this.selection,
    required this.workspace,
    required this.settings,
    required this.shown,
    required this.kind,
    required this.noteActions,
    required this.tabs,
    required this.bodies,
    required this.tasks,
    required this.quickNote,
    required this.createFlow,
    required this.captureFlow,
    required this.exportFlow,
    required this.epubConvert,
    required this.journalFlow,
    required this.journalUi,
    required this.immersive,
    required this.noteHistory,
    required this.rows,
    required this.windows,
    required this.dock,
    required this.compare,
    required this.reviewTab,
    required this.palette,
    required this.ocrFlow,
    required this.treeFocus,
    required this.ref,
    required this.guard,
    required this.openTodo,
    required this.recognize,
    required this.openHistory,
    required this.openPath,
    required this.revealInTree,
    required this.chipCovers,
    required this.activateTab,
    required this.reviewIn,
    required this.zenPossible,
    required this.features,
    required this.wide,
    required this.context,
    required this.mounted,
  });

  /// The open library.
  final LibrarySession controller;

  /// What is selected.
  final ShellSelection selection;

  /// The panes and their tabs.
  final ShellWorkspace workspace;

  /// The library's settings.
  final ShellSettings settings;

  /// The note on screen.
  final ShellShownNote shown;

  /// The open notes' kinds.
  final ShellNoteKind kind;

  /// What the shell does to the note on screen.
  final ShellNoteActions noteActions;

  /// The moves between destinations.
  final ShellTabSwitch tabs;

  /// The tabs' bodies: Search's hits and field.
  final ShellTabBodies bodies;

  /// The tasks.
  final ShellTasks tasks;

  /// The quick note.
  final ShellQuickNote quickNote;

  /// New notes of every kind.
  final ShellCreateFlow createFlow;

  /// Web pages captured as notes.
  final CaptureFlow captureFlow;

  /// The exports.
  final ShellExportFlow exportFlow;

  /// Books converted into notes.
  final EpubConvertFlow epubConvert;

  /// Journal entries opened and made.
  final JournalFlow journalFlow;

  /// The journal's calendar.
  final ShellJournalUi Function() journalUi;

  /// Zen and the book read in full screen.
  final ShellImmersive immersive;

  /// Back and forward through the notes shown.
  final NoteHistoryNavigator noteHistory;

  /// Rename, move and delete.
  final ShellRowActions rows;

  /// The floating windows: the libraries.
  final ShellWindows windows;

  /// The right dock.
  final ShellDock dock;

  /// A version beside the note.
  final ShellCompareTab compare;

  /// The study beside the deck.
  final ReviewTab reviewTab;

  /// The command palette, which lists these commands.
  final ShellPalette Function() palette;

  /// Recognition, where there is OCR.
  final ShellOcrFlow? Function() ocrFlow;

  /// The tree's keyboard focus.
  final FocusNode treeFocus;

  /// What the tour reads.
  final WidgetRef ref;

  /// The shell's reentrancy guard around a write.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Shows the todo list.
  final VoidCallback openTodo;

  /// Asks how to recognize a file's text, and queues it.
  final void Function(String path) recognize;

  /// Opens a note's history.
  final Future<void> Function(String path) openHistory;

  /// Opens a file by absolute path.
  final Future<void> Function(String path) openPath;

  /// Shows a note as the tree's selected row.
  final void Function(String path) revealInTree;

  /// Whether a pinned chip covers a pane's notes.
  final bool Function(int pane) chipCovers;

  /// Shows a pane's tab.
  final void Function(int pane, int index) activateTab;

  /// Whether a pane shows the study.
  final bool Function(int pane) reviewIn;

  /// Whether Zen can show.
  final bool Function() zenPossible;

  /// The library's features.
  final Features Function() features;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// Where the screens open.
  final BuildContext Function() context;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// What each command does, for the ones that can run here and now: the
  /// keys run them, and the command palette lists exactly these (#155).
  /// A new feature reaches both by adding its handler to
  /// [_all] and, if it waits on something, its needs to
  /// [commandNeeds], which the Commands page in Settings reads too.
  ///
  /// A command is available when its needs are met and its feature is on
  /// (#1109): the one question, asked here, that the keys, the palette and
  /// the app menu all answer to.
  Map<AppCommand, VoidCallback> handlers() => {
    for (final MapEntry(key: command, value: handler) in _all().entries)
      if (_available(command)) command: handler,
  };

  /// Whether [command] can run here and now: its needs are met and its
  /// feature is on.
  bool _available(AppCommand command) =>
      commandNeeds(command).every(_meets) &&
      commandFeatureOn(command, features());

  /// The commands the palette would offer but for their feature being off
  /// (#1109), each with that feature: what lets it say why a query found no
  /// command.
  Map<AppCommand, LibraryFeature> offByFeature() => {
    for (final command in AppCommand.values)
      if (featureOf(command) case final feature?
          when !features().isOn(feature) && commandNeeds(command).every(_meets))
        command: feature,
  };

  /// Whether [need] holds here and now (#207): with [commandNeeds], what
  /// decides which commands the palette offers and the keys answer to.
  bool _meets(CommandNeed need) => switch (need) {
    CommandNeed.openNote => shown.path != null,
    CommandNeed.textNote => shown.path != null && !shown.isAttachment,
    CommandNeed.wideWindow => wide(),
    CommandNeed.desktop => HostPlatform.isDesktop,
    CommandNeed.notInZen => !immersive.inZen,
    CommandNeed.zenRoom => immersive.zen.on || zenPossible(),
    CommandNeed.previewToggle => noteActions.previewToggleVisible,
    // The raw kind: an audio note's body is a clip document even with its
    // view off, and a tidy of it is refused all the same (#840).
    CommandNeed.proseNote => kind.type != 'audio',
    CommandNeed.twoEditors => settings.editor.editorsEnabled.length > 1,
    CommandNeed.journalEntry => shown.journalDay != null,
    CommandNeed.slidesNote => kind.shown == 'slides',
    CommandNeed.flashcardNote => kind.showsDeck,
    CommandNeed.plainNote => noteActions.plainNote,
    CommandNeed.ocrFile =>
      ocrFlow() != null &&
          shown.isAttachment &&
          isRecognizableFile(shown.path ?? ''),
  };

  /// Every command's handler; [handlers] keeps the ones that can
  /// run now. A handler whose command needs an open note runs only with
  /// one on screen.
  Map<AppCommand, VoidCallback> _all() {
    final note = shown.path;
    return {
      AppCommand.openPalette: () => unawaited(palette().open(context())),
      AppCommand.goToNote: () =>
          unawaited(palette().open(context(), notesOnly: true)),
      AppCommand.newNote: () => unawaited(createFlow.createNote(context())),
      AppCommand.captureWebPage: () =>
          unawaited(captureFlow.capture(context())),
      AppCommand.newListNote: () =>
          unawaited(createFlow.createListNote(context())),
      AppCommand.newAudioNote: () =>
          unawaited(createFlow.createAudioNote(context())),
      AppCommand.newSlides: () =>
          unawaited(createFlow.createSlidesNote(context())),
      AppCommand.newFlashcards: () =>
          unawaited(createFlow.createFlashcards(context())),
      AppCommand.newKanban: () => unawaited(createFlow.createKanban(context())),
      AppCommand.studyDeck: () => unawaited(noteActions.studyDeck()),
      AppCommand.deckColumns: () => unawaited(noteActions.chooseDeckColumns()),
      AppCommand.deckReset: () => unawaited(noteActions.resetDeckReview()),
      AppCommand.makeFlashcards: () =>
          unawaited(noteActions.flashcardsFromNote()),
      AppCommand.presentSlides: () => unawaited(noteActions.present()),
      AppCommand.presenterView: () =>
          unawaited(noteActions.present(presenter: true)),
      AppCommand.newTodo: () {
        openTodo();
        unawaited(tasks.add());
      },
      AppCommand.newTaskForNote: () => unawaited(noteActions.newTask()),
      AppCommand.quickNote: () => unawaited(quickNote.openFromTile()),
      AppCommand.journalToday: () =>
          unawaited(journalFlow.openToday(context())),
      AppCommand.journalPrevious: () =>
          unawaited(journalFlow.openPrevious(context(), shown.journalDay!)),
      AppCommand.journalNext: () =>
          unawaited(journalFlow.openNext(context(), shown.journalDay!)),
      AppCommand.journalCalendar: () => journalUi().showCalendar(context()),
      AppCommand.zenMode: _toggleZen,
      // Not among what Zen leaves out: in Zen the status row and its
      // switch are hidden, and this is the way to it (#70).
      AppCommand.typewriterMode: settings.toggleTypewriter,
      AppCommand.zoomIn: () => unawaited(noteActions.zoom(1)),
      AppCommand.zoomOut: () => unawaited(noteActions.zoom(-1)),
      AppCommand.zoomReset: () => unawaited(noteActions.zoom(0)),
      AppCommand.formatNote: () => unawaited(noteActions.format()),
      AppCommand.insertDiagram: () =>
          shown.handle?.insertAtCaret(mermaidDiagramTemplate),
      AppCommand.insertMindMap: () =>
          shown.handle?.insertAtCaret(mermaidMindMapTemplate),
      AppCommand.insertColumns: () => shown.handle?.insertColumns(),
      AppCommand.insertEisenhower: () => shown.handle?.insertEisenhower(),
      AppCommand.convertListToMindMap: () =>
          shown.handle?.convertListToMindMap(),
      AppCommand.moveToTasks: () {
        if (shown.handle case final note?) noteActions.moveToTasks(note);
      },
      AppCommand.pasteAsMarkdown: () {
        if (shown.handle case final note?) noteActions.pasteMarkdown(note);
      },
      AppCommand.exportNote: () =>
          unawaited(exportFlow.runShownNoteExport(context())),
      AppCommand.recognizeText: () {
        if (shown.path case final path?) recognize(path);
      },
      AppCommand.convertEpub: () => unawaited(_convertEpub()),
      AppCommand.exportLibrary: () =>
          unawaited(exportFlow.runFolderExport(context(), '', library: true)),
      AppCommand.markdownCheatsheet: () =>
          unawaited(noteActions.openCheatsheet()),
      AppCommand.welcomeTour: () => unawaited(resumeTour(context(), ref)),
      AppCommand.welcomeDeck: () => unawaited(showWelcomeDeck(context())),
      AppCommand.toggleSidebar: selection.toggleSidebar,
      // The tabs are the wide layout's (#23); a phone has one note.
      AppCommand.closeTab: _closeShownTab,
      AppCommand.nextTab: () => _cycleTab(1),
      AppCommand.previousTab: () => _cycleTab(-1),
      AppCommand.noteBack: () => unawaited(noteHistory.back()),
      AppCommand.noteForward: () => unawaited(noteHistory.forward()),
      AppCommand.splitRight: () => workspace.splitActive(SplitAxis.right),
      AppCommand.splitDown: () => workspace.splitActive(SplitAxis.down),
      AppCommand.toggleDock: dock.toggleOpen,
      AppCommand.tabFiles: () => tabs.destinationSelected(ShellTab.files),
      AppCommand.tabTodo: () => tabs.destinationSelected(ShellTab.todo),
      AppCommand.tabSearch: () => tabs.destinationSelected(ShellTab.search),
      AppCommand.tabQuickNote: () =>
          tabs.destinationSelected(ShellTab.quickNote),
      AppCommand.tabSettings: () => tabs.destinationSelected(ShellTab.settings),
      AppCommand.tabHome: () => tabs.destinationSelected(ShellTab.home),
      AppCommand.tabStudy: () => tabs.destinationSelected(ShellTab.study),
      AppCommand.togglePreview: shown.togglePreview,
      AppCommand.switchEditor: () => unawaited(
        noteActions.setEditorKind(
          shown.editorKind == EditorKind.wysiwyg
              ? EditorKind.source
              : EditorKind.wysiwyg,
        ),
      ),
      // The selected row, which F2 renames (#707): on a desktop the note on
      // screen, or the folder clicked last.
      AppCommand.searchNextHit: () => bodies.stepSearchHits(1),
      AppCommand.searchPreviousHit: () => bodies.stepSearchHits(-1),
      AppCommand.focusSearch: bodies.focusSearchField,
      AppCommand.revealInTree: _revealActiveInTree,
      AppCommand.renameNote: () =>
          unawaited(rows.rename(context(), selection.path ?? note)),
      AppCommand.moveNote: () => unawaited(rows.move(context(), note)),
      AppCommand.deleteNote: () => unawaited(rows.delete(context(), note)),
      AppCommand.noteHistory: () => unawaited(openHistory(note!)),
      AppCommand.reindexLibrary: () => unawaited(_reindex()),
      // A picker for any file is a desktop thing: Android hands over a
      // copy, which could not be saved back (#77).
      AppCommand.openFile: () => unawaited(_openFile()),
      AppCommand.switchLibrary: () => windows.switchLibrary(context()),
    };
  }

  /// A command's name where the state words it better than the
  /// registry: what it would switch to, not a fixed verb.
  String? labelOf(AppCommand command) => switch (command) {
    AppCommand.togglePreview =>
      shown.preview
          ? AppStrings.showEditorTooltip
          : AppStrings.showPreviewTooltip,
    AppCommand.switchEditor =>
      shown.editorKind == EditorKind.wysiwyg
          ? AppStrings.switchToSourceTooltip
          : AppStrings.switchToWysiwygTooltip,
    AppCommand.zenMode =>
      immersive.zen.on ? AppStrings.zenModeLeave : AppStrings.zenModeEnter,
    AppCommand.typewriterMode =>
      settings.editor.typewriter
          ? AppStrings.typewriterOff
          : AppStrings.typewriterOn,
    _ => null,
  };

  /// Shows/hides the wide tree pane; the rail stays (T-PP-22).
  /// The app accelerators (T-PP-10), built from the shared registry so the
  /// installed keys and the in-app reference cannot drift.
  Map<ShortcutActivator, VoidCallback> shortcutBindings() =>
      appShortcutBindings(handlers());

  /// Ctrl+W: closes the tab the focused pane shows (#1078) — the pinned chip
  /// when it covers the notes, else the note's tab.
  void _closeShownTab() {
    final pane = workspace.value.focused;
    if (reviewIn(pane)) {
      reviewTab.close();
    } else if (compare.shownIn(pane)) {
      compare.close();
    } else if (tabs.contentTabShows && pane == tabs.contentPaneShown) {
      tabs.closeContentTab();
    } else {
      workspace.closeActive();
    }
  }

  /// Ctrl+Tab and Ctrl+Shift+Tab (#1078): the next or the previous note tab.
  /// From a chip over the pane, the row goes on from its far end: the first
  /// note tab forward, the last backward, shown as a click on it shows it.
  void _cycleTab(int step) {
    final w = workspace.value;
    final pane = w.focused;
    if (!chipCovers(pane)) {
      workspace.cycle(step);
      return;
    }
    final tabs = w.panes[pane].tabs;
    if (tabs.isEmpty) return;
    activateTab(pane, step > 0 ? 0 : tabs.length - 1);
  }

  /// The palette's conversion: the book on screen, else the book selected
  /// in the tree, else one picked.
  Future<void> _convertEpub() async {
    final root = controller.root;
    final book = [
      shown.path,
      selection.path,
    ].nonNulls.where(isBook).firstOrNull;
    if (root != null && book != null) {
      return await epubConvert.run(context(), p.join(root, book));
    }
    await epubConvert.pickAndRun(context());
  }

  /// Opens a Markdown file from anywhere (#77). One inside this library
  /// is one of its notes, and opens as one — editing it on its own would
  /// skip its history and put two editors on one file. Anything else
  /// opens outside the library, over it.
  Future<void> _openFile() async {
    final path = await pickOutsideFile();
    if (path == null || !mounted()) return;
    await openPath(path);
  }

  /// Re-reads the library into its index, saying when it is done.
  Future<void> _reindex() => guard(() async {
    await controller.rescanNow();
    if (!mounted()) return;
    ScaffoldMessenger.of(context())
        .showSnackBar(SnackBar(content: Text(AppStrings.reindexDone)));
  });

  /// Shows the note on screen as the tree's row and gives the tree the
  /// keyboard (#712): the arrows go on from there.
  void _revealActiveInTree() {
    final path = workspace.value.activePath;
    if (path == null) return;
    revealInTree(path);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted()) treeFocus.requestFocus();
    });
  }

  void _toggleZen() => unawaited(immersive.toggleZen());
}
