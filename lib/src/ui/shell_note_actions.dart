import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/editor/markdown_format.dart';
import 'package:niman/src/editor/plain_text.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/app_shortcuts.dart';
import 'package:niman/src/ui/attachment_view.dart';
import 'package:niman/src/ui/capture/paste_markdown_flow.dart';
import 'package:niman/src/ui/cheatsheet/cheatsheet_screen.dart';
import 'package:niman/src/ui/epub_text_zoom.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_menu_flow.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_review_source.dart';
import 'package:niman/src/ui/kinds/flashcards/deck_study.dart';
import 'package:niman/src/ui/kinds/flashcards/make_flashcards.dart';
import 'package:niman/src/ui/kinds/slides/slides_present.dart';
import 'package:niman/src/ui/move_to_tasks_flow.dart';
import 'package:niman/src/ui/note_menu.dart';
import 'package:niman/src/ui/note_mode_toggle.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/note_view_memento.dart';
import 'package:niman/src/ui/ocr/ocr_file_actions.dart';
import 'package:niman/src/ui/palette/command_features.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/ui/shell_editor_settings.dart';
import 'package:niman/src/ui/shell_export_flow.dart';
import 'package:niman/src/ui/shell_note_kind.dart';
import 'package:niman/src/ui/shell_palette.dart';
import 'package:niman/src/ui/shell_preview_actions.dart';
import 'package:niman/src/ui/shell_row_actions.dart';
import 'package:niman/src/ui/shell_selection.dart';
import 'package:niman/src/ui/shell_settings.dart';
import 'package:niman/src/ui/shell_shown_note.dart';
import 'package:niman/src/ui/shell_tasks.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/ui/window_controller.dart';
import 'package:niman/src/workspace/workspace.dart';
import 'package:path/path.dart' as p;

/// What the shell does to the note on screen (#1256): its ⋮ menu and the
/// bar's kind toggles and eye, the deck's and the slides' entries, the
/// tidy, the zoom, the cheatsheet, the editor's switch, and the offers the
/// editor's own menu makes — each asked of [shown], the note it is about.
final class ShellNoteActions {
  /// The actions on the note [shown] says is on screen.
  new({
    required this.controller,
    required this.shown,
    required this.kind,
    required this.settings,
    required this.selection,
    required this.tasks,
    required this.unsaved,
    required this.window,
    required this.exports,
    required this.rows,
    required this.palette,
    required this.read,
    required this.guard,
    required this.showPanel,
    required this.openHistory,
    required this.recognize,
    required this.offersOcr,
    required this.paletteByTouch,
    required this.features,
    required this.wide,
    required this.context,
    required this.update,
    required this.mounted,
  });

  /// The open library.
  final LibrarySession controller;

  /// The note on screen.
  final ShellShownNote shown;

  /// The open notes' kinds, and the raw editor shown in place of one.
  final ShellNoteKind kind;

  /// The library's settings: typewriter mode, the lint rules, the editors.
  final ShellSettings settings;

  /// What is selected, which a tidy re-reads.
  final ShellSelection selection;

  /// The tasks a note's Add task and Move to tasks write to.
  final ShellTasks tasks;

  /// The notes with unsaved edits, saved before a tidy.
  final UnsavedTracker unsaved;

  /// The window the slides present in.
  final WindowController window;

  /// The note's exports.
  final ShellExportFlow exports;

  /// Rename, move and delete.
  final ShellRowActions rows;

  /// The command palette.
  final ShellPalette Function() palette;

  /// How the actions read their providers.
  final ProviderRead read;

  /// The shell's reentrancy guard around a write.
  final Future<void> Function(Future<void> Function() action) guard;

  /// Opens a panel for the note: in the dock where it fits, else a sheet.
  final Future<void> Function(DockPane pane, {Rect? anchor}) showPanel;

  /// Opens a note's history.
  final Future<void> Function(String path) openHistory;

  /// Asks how to recognize a file's text, and queues it.
  final void Function(String path) recognize;

  /// Whether the Recognize text entries are offered.
  final bool Function() offersOcr;

  /// Whether the palette is reached by touch, and so has a menu entry.
  final bool Function() paletteByTouch;

  /// The library's features.
  final Features Function() features;

  /// Whether the shell is the wide one.
  final bool Function() wide;

  /// Where the dialogs and the snack bars open.
  final BuildContext Function() context;

  /// The shell's `setState`.
  final void Function(VoidCallback change) update;

  /// Whether the shell is still up.
  final bool Function() mounted;

  /// Whether the app bar shows the editor/preview eye action: hidden in
  /// kind mode (the note is a list, not a document) unless the user is
  /// in raw-edit mode, and on an attachment, which has no editor to flip
  /// from.
  bool get previewToggleVisible =>
      !shown.isAttachment && (kind.gui == null || kind.raw);

  /// The kind toggle actions (T-TK-05), for the open note.
  List<Widget> get kindActions => kind.actions(
    wide: wide(),
    onPresent: () => unawaited(present()),
    onEditRaw: editRaw,
  );

  /// The pencil: the note's raw editor, never the preview the ⋮'s
  /// Markdown preview left on for the note.
  void editRaw() {
    update(() => kind.raw = true);
    if (shown.preview) shown.togglePreview();
  }

  /// Leaves the kind's view for the note's Markdown preview (#534): the
  /// raw mode with the eye on, the preview every note has.
  void showMarkdown() {
    update(() => kind.raw = true);
    if (!shown.preview) shown.togglePreview();
  }

  /// The app-bar eye action: flips the editor/preview pane.
  Widget previewToggle({bool compact = false}) {
    // A plain-text file is read in its editor alone: the eye stays, off.
    final path = shown.path;
    final plain = path != null && isPlainTextFile(p.basename(path));
    return PreviewToggleAction(
      previewVisible: shown.preview && !plain,
      onToggle: plain ? null : shown.togglePreview,
      compact: compact,
    );
  }

  /// Switches the library's current editor from the note's status row
  /// (T-WYS-12): persisted, then the shell re-reads it. Only offered when
  /// the library enables both editors.
  Future<void> setEditorKind(EditorKind editor) async {
    // A tab switches its own editor (#23): the library's setting is only
    // the one a note opens in.
    if (wide()) {
      final name = editor == EditorKind.wysiwyg
          ? wysiwygEditorKind
          : sourceEditorKind;
      shown.updateTab((m) => m.copyWith(editorKind: name));
      return;
    }
    await settings.setEditorKind(editor);
  }

  /// Adds a task that links the note on screen (#1152): the task dialog opens
  /// with `[[Note]]` written in, after the text selected in the editor when
  /// there is some.
  Future<void> newTask() {
    final path = shown.path;
    if (path == null) return Future<void>.value();
    return tasks.notes.add(path, selection: shown.handle?.selectedText ?? '');
  }

  /// The open note's ⋮ menu (mockup H2), on the phone's note bar and in
  /// the wide layout's editor header. A choice that asks more — the
  /// outline, the export's format — grows its menu from the ⋮ button.
  Widget menu() => Builder(builder: _menuButton);

  Widget _menuButton(BuildContext button) => NoteMenuButton(
    typewriter: settings.editor.typewriter,
    textNote: !shown.isAttachment,
    // An audio note's body is the clip document, not prose (#840).
    tidy: kind.type != 'audio',
    recognize:
        offersOcr() &&
        shown.isAttachment &&
        isRecognizableFile(selection.path ?? ''),
    // A touch device has no key for the palette (#206), the phone's and
    // the tablet's alike (#849); a desktop window has.
    palette: paletteByTouch(),
    slides: kind.showsSlides,
    presenterView: wide(),
    deck: kind.showsDeck,
    studyEnabled: read(deckStudyStarterProvider) != null,
    makeFlashcards:
        plainNote && commandFeatureOn(AppCommand.makeFlashcards, features()),
    tasks: features().isOn(LibraryFeature.todo),
    // Shopping needs Lists and its own switch: with it off a list has no
    // second view to swap to (#1109).
    kindSwitch: switch (kind.shown) {
      'list' when features().isOn(LibraryFeature.kindShopping) =>
        NoteKindSwitch.toShoppingList,
      'shopping-list' => NoteKindSwitch.toChecklist,
      _ => null,
    },
    onSelected: (action) {
      final path = selection.path;
      if (path == null) return;
      final anchor = menuAnchorOf(button);
      unawaited(switch (action) {
        NoteMenuAction.outline => showPanel(DockPane.outline, anchor: anchor),
        NoteMenuAction.tags => showPanel(DockPane.tags),
        NoteMenuAction.links => showPanel(DockPane.links),
        NoteMenuAction.tasks => showPanel(DockPane.tasks),
        NoteMenuAction.newTask => newTask(),
        NoteMenuAction.typewriter => Future<void>.sync(
          settings.toggleTypewriter,
        ),
        NoteMenuAction.palette => palette().open(context()),
        NoteMenuAction.format => format(),
        NoteMenuAction.export => exports.runNoteExport(
          context(),
          path,
          anchor: anchor,
        ),
        NoteMenuAction.cheatsheet => openCheatsheet(),
        NoteMenuAction.history => openHistory(path),
        NoteMenuAction.recognizeText => Future<void>.sync(
          () => recognize(path),
        ),
        NoteMenuAction.kindSwitch => Future<void>.sync(switchKind),
        NoteMenuAction.studyDeck => studyDeck(),
        NoteMenuAction.makeFlashcards => flashcardsFromNote(),
        NoteMenuAction.editMarkdown => Future<void>.sync(editRaw),
        NoteMenuAction.deckColumns => chooseDeckColumns(),
        NoteMenuAction.deckReset => resetDeckReview(),
        NoteMenuAction.present => present(),
        NoteMenuAction.presenterView => present(presenter: true),
        NoteMenuAction.markdownPreview => Future<void>.sync(showMarkdown),
        NoteMenuAction.exportSlides => exports.runNoteExport(
          context(),
          path,
          slidesPdf: true,
        ),
        NoteMenuAction.rename => rows.rename(context(), path),
        NoteMenuAction.move => rows.move(context(), path),
        NoteMenuAction.delete => rows.delete(context(), path),
      });
    },
  );

  /// What the deck's ⋮ entries do beyond its view (#533).
  late final DeckMenuFlow _deckFlow = DeckMenuFlow(
    read(deckReviewSourceProvider),
  );

  /// Starts a study session of the deck on screen, through the seam the
  /// review fills (`deckStudyStarterProvider`); nothing while there is none.
  Future<void> studyDeck() async {
    final note = shown.handle;
    final starter = read(deckStudyStarterProvider);
    if (note == null || starter == null || !kind.showsDeck) return;
    await starter(context(), note.notePath);
  }

  /// Whether the note on screen is a plain one, text of no `type`: what
  /// **Make flashcards** turns into a deck (#533).
  bool get plainNote =>
      shown.path != null && !shown.isAttachment && kind.type == null;

  /// **Make flashcards** of the note on screen (#533).
  Future<void> flashcardsFromNote() async {
    final note = shown.handle;
    if (note == null || !plainNote) return;
    await makeFlashcards(context(), note: note, session: controller);
  }

  /// Chooses which of the deck's fields are its cards' sides (#533).
  Future<void> chooseDeckColumns() async {
    final note = shown.handle;
    if (note == null || !kind.showsDeck) return;
    await _deckFlow.chooseColumns(context(), note);
  }

  /// Forgets the deck's review: every card new again (#533).
  Future<void> resetDeckReview() async {
    final note = shown.handle;
    if (note == null || !kind.showsDeck) return;
    await _deckFlow.resetReview(
      context(),
      root: controller.root,
      notePath: note.notePath,
    );
  }

  /// Presents the slides note on screen (#534), from the slide its view
  /// shows; [presenter] opens on the presenter view.
  Future<void> present({bool presenter = false}) async {
    final note = shown.handle;
    if (note == null || kind.shown != 'slides') return;
    await presentSlides(
      context(),
      text: note.currentText,
      notePath: note.notePath,
      resolveEmbed: note.resolveEmbed,
      window: window,
      presenter: presenter,
    );
  }

  /// Turns the open note between `list` and `shopping-list` (#309).
  ///
  /// The note's own buffer rewrites the frontmatter (unsaved changes
  /// included) through its handle, one undoable edit, saved at once; the
  /// body swaps as the shell hears the new kind. Nothing else moves: the
  /// name, the folder and the lines stay.
  void switchKind() {
    final note = shown.handle;
    if (note == null) return;
    note.setNoteKind(kind.shown == 'list' ? 'shopping-list' : 'list');
  }

  /// The open note's actions on the phone's note bar: the kind toggles,
  /// the editor/preview eye, and the ⋮ menu.
  List<Widget> barActions(Widget openNotes) {
    return [
      ...kindActions,
      if (previewToggleVisible) previewToggle(),
      openNotes,
      menu(),
    ];
  }

  /// The Markdown cheatsheet (#265); its examples go into the note on
  /// screen when there is one to take them.
  Future<void> openCheatsheet() {
    final note = shown.handle;
    return showMarkdownCheatsheet(
      context(),
      onInsert: note == null || !note.canInsert ? null : note.insertAtCaret,
    );
  }

  /// The note's text [steps] zoom steps larger (smaller when negative), or
  /// back to its shipped size at zero (#538): the library's note text size,
  /// as the settings' slider sets it, in the editor and the preview alike.
  /// A book on screen zooms its own text instead, the books' text size.
  Future<void> zoom(int steps) async {
    if (isBook(shown.path ?? '')) {
      EpubTextZoom((scale) => unawaited(keepEpubTextScale(controller, scale)))
          .zoom(steps);
      return;
    }
    await controller.librarySettings.setNoteTextScale(
      AppTextScales.zoomed(AppTextScales.note, steps),
    );
  }

  /// Paste as Markdown for the editor's menu, or null when the library has
  /// web capture off (#1109): the entry goes with the command.
  ValueChanged<NoteViewHandle>? get pasteAsMarkdownOffer =>
      commandFeatureOn(AppCommand.pasteAsMarkdown, features())
      ? pasteMarkdown
      : null;

  /// Move to tasks for the editor's menu and Tools sheet (#1152), or null when
  /// the library has the Todo feature off: the entry goes with the command.
  ValueChanged<NoteViewHandle>? get moveToTasksOffer =>
      commandFeatureOn(AppCommand.moveToTasks, features()) ? moveToTasks : null;

  /// Moves the checkbox items under [note]'s selection to the tasks (#1152).
  void moveToTasks(NoteViewHandle note) =>
      unawaited(MoveToTasksFlow(tasks.notes).run(context(), note));

  /// Attaches files dropped on the window to the note on screen (#1250):
  /// false when there is none that takes text — no note open, a kind's view
  /// in front of it, a note outside the library.
  Future<bool> attachDropped(List<String> paths) async {
    final note = shown.handle;
    if (note == null || !note.canInsert) return false;
    return await note.attachFiles(paths);
  }

  /// Pastes the clipboard's HTML into [note] as Markdown (#531).
  void pasteMarkdown(NoteViewHandle note) =>
      unawaited(pasteAsMarkdown(context(), note, read(pasteServicesProvider)));

  /// Tidies the open note's Markdown (#227).
  ///
  /// Through the file rather than through the editor's buffer: the note
  /// is saved first, tidied on disk and read back the way an edit from
  /// another program is read back, so both editors show the result and
  /// neither has to know how to rewrite its own document.
  Future<void> format() async {
    final path = shown.path;
    final ops = controller.ops;
    if (path == null || ops == null) return;
    // An audio note's body is the clip document (#840): the menu does not
    // offer the tidy, and the palette and the key never reach here (the
    // proseNote need keeps them off it). This remains for a direct call,
    // and the frontmatter check below for a kind the bar still lags on:
    // no write, and nothing to say about a tidy that never was one.
    if (kind.type == 'audio') return;
    await guard(() async {
      // The buffer's own edits land first: what is tidied is the note as
      // it stands, not the note as it was last written.
      await unsaved.saveAll();
      // The shell's paths are the library's own, relative to its root.
      final text = await ops.readNote(path);
      // The shell's kind as the bar last heard it can lag the file; the
      // note's own frontmatter is the authority.
      if (frontmatterTypeOf(text) == 'audio') return;
      final tidied = formatMarkdown(text, rules: settings.editor.lintRules);
      if (!mounted()) return;
      if (tidied == text) {
        ScaffoldMessenger.of(context()).showSnackBar(
          SnackBar(content: Text(AppStrings.formatNoteAlreadyTidy)),
        );
        return;
      }
      await ops.saveNote(path, tidied);
      if (!mounted()) return;
      selection.reload();
      ScaffoldMessenger.of(context())
          .showSnackBar(SnackBar(content: Text(AppStrings.formatNoteDone)));
    });
  }

  /// Tidies the note at absolute [path], edited and now closed, when the
  /// library asks for it ([ShellEditorSettings.tidyOnClose]).
  ///
  /// Quiet, unlike the command: the note has left the screen, and a
  /// snackbar about it would be about a note nobody is looking at. The
  /// tidy runs in the note's own turn among its saves (`NoteWriter.tidy`),
  /// so it tidies what the last save wrote and a note opened again and
  /// typed in meanwhile keeps what was typed. A note back on screen by the
  /// time the tidy lands re-reads it, when it has nothing unsaved.
  void tidyClosed(String path) {
    final root = controller.root;
    final ops = controller.ops;
    if (root == null || ops == null || !settings.editor.tidyOnClose) return;
    final rel = relPath(path, root);
    unawaited(
      ops
          .tidyNote(rel, rules: settings.editor.lintRules)
          .then(
            (changed) {
              if (changed && mounted()) selection.reload();
            },
            onError: (Object error) {
              const AppLogger(name: 'shell').warning('tidy of $rel: $error');
            },
          ),
    );
  }

  /// The view controls in [pane]'s status row (T-PP-22): for the note
  /// that pane shows, so each pane's eye says what its own tab does. A
  /// tablet has them at the note's top instead ([modeToggleFor], #1266).
  List<Widget> statusActionsFor(int pane) {
    if (thumbDense(Theme.of(context()))) return const [];
    final mode = _modeOf(pane);
    if (mode == null) return const [];
    return [
      PreviewToggleAction(
        previewVisible: mode.preview,
        onToggle: mode.toggle,
        compact: true,
      ),
    ];
  }

  /// [pane]'s **Edit | Read** pair at the top of its note, on a tablet
  /// (#1266): the status row's eye, named.
  List<Widget> modeToggleFor(int pane) {
    if (!thumbDense(Theme.of(context()))) return const [];
    final mode = _modeOf(pane);
    if (mode == null) return const [];
    return [
      NoteModeToggle(previewVisible: mode.preview, onToggle: mode.toggle),
    ];
  }

  /// Whether [pane]'s note shows its preview and what flips it, or null
  /// when its note has no such switch.
  ({bool preview, VoidCallback? toggle})? _modeOf(int pane) {
    final tab = shown.workspace.value.panes[pane].activeTab;
    if (tab == null) return null;
    // The focused pane's note is the one the shell's kind and raw mode
    // speak of; another pane's is told by its own kind (#1081).
    final offered = pane == shown.workspace.value.focused
        ? previewToggleVisible
        : previewToggleOffered(
            path: tab.path,
            kindGui: kind.guiOf(tab.path),
            features: controller.librarySettings.features.value,
          );
    if (!offered) return null;
    final plain = isPlainTextFile(p.basename(tab.path));
    return (
      preview: !plain && (tab.memento.preview ?? false),
      toggle: plain ? null : () => shown.togglePreviewOf(tab.path),
    );
  }
}
