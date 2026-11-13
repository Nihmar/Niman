import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/epub_look_sheet.dart';
import 'package:niman/src/ui/epub_text_zoom.dart';
import 'package:niman/src/ui/hidden_slot.dart';
import 'package:niman/src/ui/note_services.dart';
import 'package:niman/src/ui/note_tab_bar.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/ocr/ocr_job_status.dart';
import 'package:niman/src/ui/pane_launcher.dart';
import 'package:niman/src/ui/pane_split.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/shell_annotation_flow.dart';
import 'package:niman/src/ui/shell_compare_tab.dart';
import 'package:niman/src/ui/shell_create_flow.dart';
import 'package:niman/src/ui/shell_detail_pane.dart';
import 'package:niman/src/ui/shell_journal_ui.dart';
import 'package:niman/src/ui/shell_navigation.dart';
import 'package:niman/src/ui/shell_navigation_state.dart';
import 'package:niman/src/ui/shell_note_actions.dart';
import 'package:niman/src/ui/shell_note_io.dart';
import 'package:niman/src/ui/shell_note_kind.dart';
import 'package:niman/src/ui/shell_palette.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_settings.dart';
import 'package:niman/src/ui/shell_shown_note.dart';
import 'package:niman/src/ui/shell_study.dart';
import 'package:niman/src/ui/shell_tab_rows.dart';
import 'package:niman/src/ui/shell_tab_switch.dart';
import 'package:niman/src/ui/shell_tasks.dart';
import 'package:niman/src/ui/shell_template_flow.dart';
import 'package:niman/src/ui/shell_workspace.dart';
import 'package:niman/src/ui/shell_zen.dart';
import 'package:niman/src/ui/tab_drag.dart';
import 'package:niman/src/ui/text_zoom_pinch.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/tour/tour_targets.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:path/path.dart' as p;

/// The note views the shell lays out (#1256): the phone's full-screen
/// note, and the wide window's panes — one, or two split, each a deck of
/// its own tabs with what a pinned tab, a version or a study lays over it.
/// What they show is asked of the selection, the workspace and the note
/// on screen; what they do is the note actions' and the flows'.
final class ShellNotePanes {
  /// The note views of [controller]'s library.
  new({
    required this.controller,
    required this.workspace,
    required this.selection,
    required this.settings,
    required this.shown,
    required this.kind,
    required this.noteActions,
    required this.tabs,
    required this.nav,
    required this.tabRows,
    required this.compare,
    required this.study,
    required this.reviewIn,
    required this.immersive,
    required this.journalUi,
    required this.annotations,
    required this.annotating,
    required this.annotate,
    required this.ocrActions,
    required this.convertBook,
    required this.tasks,
    required this.unsaved,
    required this.spellCheck,
    required this.window,
    required this.ocrQueue,
    required this.shellFocus,
    required this.dockToggle,
    required this.dockShown,
    required this.createFlow,
    required this.templateFlow,
    required this.palette,
    required this.openSearchNote,
    required this.openNote,
    required this.tabBodyFor,
    required this.wide,
    required this.context,
    required this.mounted,
  });

  /// The open library.
  final LibrarySession controller;

  /// The panes and their tabs.
  final ShellWorkspace workspace;

  /// What is selected, and what the note about to open is asked.
  final ShellSelection selection;

  /// The library's settings the notes are edited with.
  final ShellSettings settings;

  /// The note on screen, and the keys of the views that show notes.
  final ShellShownNote shown;

  /// The open notes' kinds, and the raw editor shown in place of one.
  final ShellNoteKind kind;

  /// What the shell does to the note on screen.
  final ShellNoteActions noteActions;

  /// The moves between destinations, and the content tab pinned in a pane.
  final ShellTabSwitch tabs;

  /// Where the shell is: the content tab pinned.
  final ShellNavigationState nav;

  /// The rows of note tabs, which a tab is dropped from.
  final ShellTabRows tabRows;

  /// A version beside the note (#712).
  final ShellCompareTab compare;

  /// The study beside the deck (#533).
  final ShellStudy Function() study;

  /// Whether a pane shows the study now.
  final bool Function(int pane) reviewIn;

  /// Zen and the book read in full screen.
  final ShellImmersive immersive;

  /// The journal's header over an entry.
  final ShellJournalUi journalUi;

  /// The marks a book or a PDF draws, and the annotating of them (#284).
  final ShellAnnotationFlow annotations;

  /// Whether the readers annotate (#1109).
  final bool Function() annotating;

  /// Annotates a place of a book or a PDF.
  final void Function(Annotation annotation) annotate;

  /// The file views' Recognize text, or null without OCR.
  final OcrFileActions? Function() ocrActions;

  /// Converts a book into notes (#1138).
  final void Function(String path) convertBook;

  /// The tasks a note's task list reads.
  final ShellTasks tasks;

  /// The notes with unsaved edits.
  final UnsavedTracker unsaved;

  /// The editor's spelling.
  final EditorSpellCheck spellCheck;

  /// The window, whose title bar may be the app's own.
  final WindowController window;

  /// The recognitions under way, shown over the phone's note.
  final OcrQueue? ocrQueue;

  /// The focus the app accelerators are bound on.
  final FocusNode shellFocus;

  /// The dock's button, at the end of the note's row.
  final Widget Function() dockToggle;

  /// Whether the dock shows.
  final bool Function() dockShown;

  /// New notes, from an empty pane's launcher.
  final ShellCreateFlow createFlow;

  /// New notes from templates, from the launcher.
  final ShellTemplateFlow templateFlow;

  /// The palette, the launcher's Go to note.
  final ShellPalette palette;

  /// Opens a note the way a search result opens.
  final void Function(String path) openSearchNote;

  /// Opens a note by library-relative path, at a heading when there is one.
  final void Function(String path, String? anchor) openNote;

  /// The body of a tab, which a pinned content tab shows in a pane.
  final Widget Function(ShellTab tab, LibrarySession controller) tabBodyFor;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// Where the sheets open.
  final BuildContext Function() context;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// The phone full-screen note body.
  Widget fullNote(LibrarySession controller, String selectedPath) {
    final view = _phoneNote(controller, selectedPath);
    final above = immersive.inZen
        ? null
        : journalUi.header(context(), selectedPath, compact: true);
    final queue = ocrQueue;
    if (above == null && queue == null) return view;
    return Column(
      children: [
        // A recognition under way, wherever the reader went meanwhile.
        if (queue != null) OcrJobStatus(queue: queue, except: selectedPath),
        ?above,
        Expanded(child: view),
      ],
    );
  }

  Widget _phoneNote(LibrarySession controller, String selectedPath) {
    // A picture, a PDF or a book, shown rather than read as a note.
    if (isShownAttachment(
      selectedPath,
      controller.librarySettings.features.value,
    )) {
      return TourTarget(
        id: TourTargets.note,
        child: AttachmentView(
          key: shown.phoneKey,
          path: p.join(controller.root ?? '', selectedPath),
          column: settings.editor.noteColumn,
          onEditEpubLook: (anchor) => _editEpubLook(controller, anchor),
          onEpubTextScale: (scale) =>
              unawaited(keepEpubTextScale(controller, scale)),
          positions: switch (controller.root) {
            final root? => ReadingPositions(root),
            null => null,
          },
          anchor: selection.request.anchor,
          reloadToken: selection.linksFollowed,
          linkType: settings.editor.linkType,
          onAnnotate: annotating() ? annotate : null,
          onConvertBook: convertBook,
          marks: annotating() ? annotations : null,
          ocr: ocrActions(),
          fullScreen: immersive.fullScreen,
        ),
      );
    }
    return TourTarget(
      id: TourTargets.note,
      child: _pinchToZoom(
        NoteView(
          key: shown.phoneKey,
          path: p.join(controller.root ?? '', selectedPath),
          // One editor on the phone: switching notes hands the one going in
          // its memento, and the one going out hands in its own (#23).
          initialMemento: workspace.value.tabs
              .where((tab) => tab.path == selectedPath)
              .firstOrNull
              ?.memento,
          onMemento: (path, memento) {
            final root = controller.root;
            if (root != null) workspace.remember(relPath(path, root), memento);
          },
          onEditedNoteClosed: noteActions.tidyClosed,
          // No typewriter switch in the phone's status row: it has no room
          // left for one. Settings and the Search tab's commands reach it.
          options: settings.editor.noteOptions,
          // The Files pane opened this note (#727): the caret goes in it.
          caretRequest: selectedPath == selection.caretPath
              ? selection.caretRequest
              : 0,
          showPreview: shown.preview,
          showWysiwyg: settings.editor.editorKind == EditorKind.wysiwyg,
          // A single enabled editor has nowhere to switch to: the note hides
          // its switch instead of offering a dead toggle.
          onEditorKindChanged: settings.editor.editorsEnabled.length > 1
              ? noteActions.setEditorKind
              : null,
          services: _services(controller),
          initialAnchor: selection.request.anchor,
          anchorRequests: selection.linksFollowed,
          initialCaretOffset: selection.request.caret,
          initialFind: selection.request.find,
          kindMode: !kind.raw,
          onNoteKindChanged: kind.reported,
          onKindMarkdown: noteActions.showMarkdown,
          onPasteAsMarkdown: noteActions.pasteAsMarkdownOffer,
          onMoveToTasks: noteActions.moveToTasksOffer,
          reloadToken: selection.reloadToken,
        ),
      ),
    );
  }

  /// What the open library lends every note view (#1257): the phone's and
  /// each pane's alike.
  NoteServices _services(LibrarySession controller) => NoteServices(
    libraryRoot: controller.root,
    linkSource: settings.linkSource,
    wikilinkSuggester: settings.wikilinkSuggester,
    tasks: tasks.notes,
    onOpenNote: openNote,
    features: controller.librarySettings.features,
    unsavedTracker: unsaved,
    spellCheck: spellCheck,
    saveNote: noteSaverFor(controller),
    saveNoteStream: noteStreamSaverFor(controller),
    createMissingNote: missingNoteCreatorFor(controller),
  );

  /// [note] with its text zoomed by a pinch (#538): each step shown at
  /// once, and the size kept for the library when the fingers lift. Off
  /// while [enabled] is false: over a book, which zooms its own text.
  Widget _pinchToZoom(Widget note, {bool enabled = true}) => TextZoomPinch(
    enabled: enabled,
    scale: () => AppTextScales.note,
    onZoom: (scale, {required done}) {
      if (done) {
        unawaited(controller.librarySettings.setNoteTextScale(scale));
      } else {
        AppTextScales.note = scale;
      }
    },
    child: note,
  );

  /// The panes of the wide layout (#23): one, or two split right or
  /// down, each a deck of its own tabs. A click anywhere in a pane gives
  /// it the focus, so the tree's next note opens there.
  Widget panes(LibrarySession controller) {
    final w = workspace.value;
    if (!w.isSplit) return _pane(controller, 0);
    final down = w.axis == SplitAxis.down;
    return PaneSplit(
      axis: w.axis,
      fraction: w.fraction,
      onFraction: workspace.setFraction,
      first: _pane(controller, 0),
      // Split down, the lower pane's tabs head the pane itself: the title
      // bar has no x to divide at.
      second: down
          ? Column(
              children: [
                SizedBox(
                  height: NoteTabBar.rowHeight(
                    touch: thumbDense(Theme.of(context())),
                  ),
                  child: tabRows.pane(1, const SizedBox.shrink()),
                ),
                const Divider(height: 1),
                Expanded(child: _pane(controller, 1)),
              ],
            )
          : _pane(controller, 1),
    );
  }

  /// Zen's panes: the focused one alone. The other stays mounted behind
  /// it, so its notes keep their undo and their place for the way back.
  Widget zenPanes(LibrarySession controller) {
    final w = workspace.value;
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var pane = 0; pane < w.panes.length; pane++)
          HiddenSlot(
            hidden: pane != w.focused,
            child: TickerMode(
              enabled: pane == w.focused,
              child: _pane(controller, pane),
            ),
          ),
      ],
    );
  }

  /// [pane]'s deck, focusing the pane on any press inside it.
  ///
  /// A pane showing a note claims the tour's note target; an empty pane
  /// claims nothing, so the step is skipped rather than pointing at a
  /// blank.
  Widget _pane(LibrarySession controller, int pane) {
    final review = reviewIn(pane);
    final comparing = compare.shownIn(pane) && !review;
    final content =
        tabs.contentTabShows &&
            pane == tabs.contentPaneShown &&
            !comparing &&
            !review
        ? nav.contentTab
        : null;
    final listener = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => workspace.focus(pane),
      child: TabDropZone(
        pane: pane,
        isSplit: workspace.value.isSplit,
        onDrop: (drag, kind) => tabRows.dropOnPane(drag, pane, kind),
        child: _pinchToZoom(
          enabled: !isBook(workspace.value.panes[pane].activeTab?.path ?? ''),
          // A pinned content tab (#712) paints over the deck, which stays
          // mounted and laid out behind it: the notes keep their undo and
          // their place for the way back.
          Stack(
            fit: StackFit.expand,
            children: [
              HiddenSlot(
                hidden: content != null || comparing || review,
                child: TickerMode(
                  enabled: content == null && !comparing && !review,
                  child: ShellDetailPane(
                    shellFocus: shellFocus,
                    root: controller.root,
                    tabs: _deck(pane),
                    launcher: _launcher(pane),
                    onMemento: workspace.remember,
                    zen: immersive.inZen,
                    // The panel holds the note's outline and spelling
                    // wherever the wide layout can show it — docked beside
                    // the note, or over it on a window without room for
                    // both — so the status row leaves both its buttons
                    // out (#1002). A phone keeps them: there they open
                    // their sheets.
                    outlineInDock: wide() && !immersive.inZen,
                    spellCheckInDock: wide() && !immersive.inZen,
                    relatedInDock: wide() && !immersive.inZen && dockShown(),
                    options: settings.editor.noteOptions,
                    onToggleTypewriter: settings.toggleTypewriter,
                    onLoaded: workspace.noteLoaded,
                    onEditedNoteClosed: noteActions.tidyClosed,
                    // The kind toggles and ⋮ sit at the end of the note's
                    // one row of chrome (#173); there is no header above.
                    // Where the panes head their own tab row, the dock's
                    // toggle ends that row instead (#1134).
                    barActions: [
                      ...noteActions.kindActions,
                      // A tablet's Edit | Read, where the status row's
                      // eye was (#1266).
                      ...noteActions.modeToggleFor(pane),
                      if (window.customTitleBar) dockToggle(),
                      noteActions.menu(),
                    ],
                    // The Files pane opened a note (#727): that tab's own
                    // view is asked for the caret, and no other.
                    caretPath: selection.caretPath,
                    caretRequest: selection.caretRequest,
                    // A single enabled editor has nowhere to switch to:
                    // the note hides its switch instead of offering a
                    // dead toggle.
                    onEditorKindChanged:
                        settings.editor.editorsEnabled.length > 1
                        ? noteActions.setEditorKind
                        : null,
                    services: _services(controller),
                    kindMode: !kind.raw,
                    onNoteKindChanged: kind.reported,
                    onTabKind: kind.tabReported,
                    onPasteAsMarkdown: noteActions.pasteAsMarkdownOffer,
                    onMoveToTasks: noteActions.moveToTasksOffer,
                    reloadToken: selection.reloadToken,
                    linksFollowed: selection.linksFollowed,
                    onAnnotate: annotating() ? annotate : null,
                    onConvertBook: convertBook,
                    ocr: ocrActions(),
                    marks: annotating() ? annotations : null,
                    statusActions: noteActions.statusActionsFor(pane),
                    header: (path) => journalUi.header(context(), path),
                    onEditEpubLook: (anchor) =>
                        _editEpubLook(controller, anchor),
                    onEpubTextScale: (scale) =>
                        unawaited(keepEpubTextScale(controller, scale)),
                    epubFullScreen: immersive.fullScreen,
                  ),
                ),
              ),
              // The content tab stays mounted while a note shows: its
              // filter, its scroll and its place are kept, as a note
              // tab's are.
              if (nav.contentTab case final tab?
                  when pane == tabs.contentPaneShown)
                HiddenSlot(
                  key: Key('content-pane-${tab.name}'),
                  hidden: content == null || review,
                  child: TickerMode(
                    enabled: content != null,
                    child: tabBodyFor(tab, controller),
                  ),
                ),
              // A version beside the note (#712): over the deck, which
              // keeps its notes as they were.
              if (comparing)
                compare.page(
                  context(),
                  controller,
                  onRestored: () {
                    if (mounted()) selection.reload();
                  },
                ),
              // A study beside the deck (#533): over the pane's notes too.
              if (review) study().page(),
            ],
          ),
        ),
      ),
    );
    return workspace.value.panes[pane].activeTab == null
        ? listener
        : TourTarget(id: TourTargets.note, child: listener);
  }

  /// Opens the sheet that sets how the books look (#280); a pointer's menu
  /// grows from [anchor], the book's Aa button.
  void _editEpubLook(LibrarySession controller, Rect? anchor) => unawaited(
    showEpubLookSheet(context(), session: controller, anchor: anchor),
  );

  /// The notes whose editor is mounted (#23): the showing tab and the
  /// ones kept alive behind it, each shown its own way.
  List<DetailTab> _deck(int pane) {
    final w = workspace.value;
    final kept = workspace.mounted();
    final showing = w.panes[pane].activeTab?.path;
    final focused = pane == w.focused;
    shown.keys.keepOnly(kept);
    kind.keepOnly(kept);
    return [
      for (final tab in w.panes[pane].tabs)
        if (kept.contains(tab.path))
          () {
            final editor = shown.editorOf(tab.memento);
            return DetailTab(
              key: shown.keys.keyOf(tab.path),
              path: tab.path,
              movedFrom: shown.keys.movedFrom(tab.path),
              active: tab.path == showing,
              focused: focused,
              memento: tab.memento,
              showWysiwyg: editor == EditorKind.wysiwyg,
              showPreview: tab.memento.preview ?? false,
              // A tab opened behind (#1268) lands on its own anchor when it
              // first shows.
              anchor: focused && tab.path == showing
                  ? workspace.anchorBehind(tab.path) ?? selection.request.anchor
                  : null,
              // The wide deck's own door for it: the phone's single note
              // view took it, and the tabs never did, so a template's
              // `{{cursor}}` landed nowhere on the desktop.
              caret: focused && tab.path == showing
                  ? selection.request.caret
                  : null,
              find: focused && tab.path == showing
                  ? selection.request.find
                  : null,
            );
          }(),
    ];
  }

  /// [pane]'s launcher (#1134), while it shows no note: each way in takes
  /// the pane's focus first, so the note it makes or picks lands there.
  Widget _launcher(int pane) {
    void inPane(VoidCallback action) {
      workspace.focus(pane);
      action();
    }

    return PaneLauncher(
      onNewNote: () =>
          inPane(() => unawaited(createFlow.createNote(context()))),
      onNewFromTemplate: () =>
          inPane(() => unawaited(templateFlow.createFromTemplate(context()))),
      onGoToNote: () =>
          inPane(() => unawaited(palette.open(context(), notesOnly: true))),
      recent: workspace.history.recent(5),
      onOpen: (path) => inPane(() => openSearchNote(path)),
    );
  }
}
