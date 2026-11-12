import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/capture/paste/clipboard_files.dart';
import 'package:niman/src/capture/paste/platform_clipboard_files.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/editor_shortcuts.dart';
import 'package:niman/src/editor/plain_text.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/library/attachment_store.dart';
import 'package:niman/src/links/link_preview.dart' show PreviewLimits;
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/templates/check_state.dart';
import 'package:niman/src/ui/capture/paste_markdown_flow.dart'
    show readPlainClipboard;
import 'package:niman/src/ui/dead_link_watcher.dart';
import 'package:niman/src/ui/link_preview/note_link_preview.dart';
import 'package:niman/src/ui/note_attach.dart';
import 'package:niman/src/ui/note_dead_links.dart';
import 'package:niman/src/ui/note_disk.dart';
import 'package:niman/src/ui/note_edit_commands.dart';
import 'package:niman/src/ui/note_find_keys.dart';
import 'package:niman/src/ui/note_frontmatter_panel.dart';
import 'package:niman/src/ui/note_inserts.dart';
import 'package:niman/src/ui/note_link_actions.dart';
import 'package:niman/src/ui/note_links.dart';
import 'package:niman/src/ui/note_paste.dart';
import 'package:niman/src/ui/note_place.dart';
import 'package:niman/src/ui/note_read_snapshot.dart';
import 'package:niman/src/ui/note_read_tasks.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:niman/src/ui/note_services.dart';
import 'package:niman/src/ui/note_session.dart';
import 'package:niman/src/ui/note_stats.dart';
import 'package:niman/src/ui/note_task_items.dart';
import 'package:niman/src/ui/note_text_cache.dart';
import 'package:niman/src/ui/note_todo_blocks.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:niman/src/ui/note_view_adapters.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:path/path.dart' as p;

/// The note view's collaborators (#1257): the session, the saves, the
/// panes' keys and scrolls, the find bar, the links, the commands and the
/// inserts, each wired to the others here rather than through the view's
/// `State`. The view builds one and reads it; nothing here is a widget.
final class NoteViewParts {
  /// The parts of the note view [viewOf] reads, its handle [handle].
  new({
    required this.viewOf,
    required this.handle,
    required this.context,
    required this.mounted,
    required this.update,
  });

  /// The note view as it is now built.
  final NoteView Function() viewOf;

  /// The note view as the shell holds it.
  final NoteViewHandle Function() handle;

  /// Where the view is in the tree.
  final BuildContext Function() context;

  /// Whether the view is still up.
  final bool Function() mounted;

  /// The view's `setState`.
  final void Function(VoidCallback change) update;

  /// The note view as it is now built.
  NoteView get view => viewOf();

  /// The note's own focus: the phone toolbar, the format keys, save-on-blur
  /// and the refocus when the preview goes all ask it.
  final FocusNode focus = FocusNode();

  /// The unified source pane's find & replace, over the note's surface.
  late final SourceFindController sourceFind = SourceFindController(
    surface: () => session.surface,
    onClose: focus.requestFocus,
  );

  /// The open note's lifecycle (#1257): its load, its reload, loading /
  /// ready / failed, its kind and its surface. The view follows what it
  /// says changed.
  late final NoteSession session = NoteSession(
    disk: disk,
    saves: saves,
    text: text,
    newSurface: (buffer, caret) =>
        MarkdownSurfaceController(buffer, caret: caret)
          ..onChanged = (edit) => noteChanged(
            caretLine: surfaceCaretLine ?? lastCaretLine,
            edit: edit,
          ),
    takeOver: (path) => view.services.unsavedTracker?.takeOver(path),
    alive: mounted,
  );

  /// Where the note is read: the memento it hands in as it is left, and the
  /// place it is put back at (#23).
  late final NotePlace place = NotePlace(
    path: () => view.path,
    surface: () => session.surface,
    readView: () => readViewKey.currentState,
    sourceView: () => sourceViewKey.currentState,
    reading: () => previewIn(view),
    active: () => view.active,
    ready: () => session.ready,
    mounted: mounted,
    receiver: () => view.onMemento,
    wysiwyg: () => view.showWysiwyg,
    preview: () => view.showPreview,
  );

  /// The note's word count, outline and frontmatter error (T-M2-07),
  /// refreshed a pause after the last edit; the view repaints on each
  /// refresh.
  late final NoteStatsController stats = NoteStatsController(
    surface: () => session.surface,
    loading: () => session.loading,
    sourceView: () => sourceViewKey.currentState,
    readView: () => readViewKey.currentState,
  );

  /// The template checker's state (T-TPL-09): the problems of the note when
  /// it is a template, and nothing when it is not. Owned here, handed to the
  /// surface — the same seam [NoteServices.spellCheck] keeps — so the
  /// status row can show the count the surface works out.
  final TemplateCheck templateCheck = TemplateCheck();

  /// Which of the note's links name nothing (#847): resolved against the
  /// index apart from the drawing, on load, a pause after an edit, and when
  /// the library's index moves; the editor and the read view draw the answer.
  late final DeadLinkWatcher deadLinks = openNoteDeadLinks(
    source: () => view.services.linkSource,
    buffer: () => session.loading ? null : session.surface?.buffer,
    kept: () => sourceViewKey.currentState?.references(),
    notePath: () => libraryPath,
    delay: () => stats.settleDelay,
  );

  /// The link preview (#846): the card a hovered link opens over the note.
  late final NoteLinkPreview preview = NoteLinkPreview(
    source: () => view.services.linkSource,
    notePath: () => libraryPath,
    enabled: () => view.options.linkPreview,
    unsavedText: unsavedTextOf,
    mathCache: mathCache,
    targets: links.targets,
  );

  /// The unsaved buffer text of the note at library-relative [path], when it
  /// is open with edits the disk does not have yet (in any pane).
  String? unsavedTextOf(String path) {
    final root = view.services.libraryRoot;
    if (root == null) return null;
    // One unit past the limit, so a note longer than it still reads as
    // longer: the preview is cut, and says so, as it is for the whole text.
    return view.services.unsavedTracker?.unsavedTextOf(
      p.join(root, path),
      maxChars: PreviewLimits.bytes + 1,
    );
  }

  /// The scrolls of both panes: a card closes when the note moves under it.
  late final Listenable scrolls = Listenable.merge([
    previewScroll,
    sourceScroll,
  ]);

  /// The note's path in the library, slash-separated, or null for a note
  /// opened from outside one.
  String? get libraryPath =>
      pathInLibrary(view.services.libraryRoot, view.path);

  /// Whether the note takes an insert: loaded, and not shown as its kind.
  bool get canInsert {
    if (!session.ready) return false;
    final kind = NoteKinds.forType(session.kind, features);
    return !(view.kindMode && kind != null);
  }

  /// What goes into the note from outside the editor's own keys: a paste,
  /// the links of attached files, and what the selection holds.
  late final NoteInserts inserts = NoteInserts(
    surface: () => session.surface,
    canInsert: () => canInsert,
    mounted: mounted,
    focus: focus.requestFocus,
    onInserted: () {
      stats.refresh();
      refreshPreview();
    },
  );

  /// Files pasted or dropped on the note, copied into the attachments
  /// folder and linked at the caret (#1249, #1250).
  late final NoteAttach attach = NoteAttach(
    libraryRoot: () => view.services.libraryRoot,
    notePath: () => view.path,
    linkType: () => view.options.linkType,
    // Without the suggester, the file's name: a note's without `.md`, as a
    // wikilink names it, anything else's with its extension.
    wikiTarget: (path) async =>
        await view.services.wikilinkSuggester?.targetOf(path) ??
        (p.extension(path).toLowerCase() == '.md'
            ? p.basenameWithoutExtension(path)
            : p.basename(path)),
    importFile: (root, source) =>
        view.services.importImage?.call(root, source) ??
        importImageToLibrary(
          libraryRoot: root,
          sourcePath: source,
          attachmentsFolder: view.options.attachmentsFolder,
        ),
    insert: inserts.insertAttachmentLinks,
    messenger: () => mounted() ? ScaffoldMessenger.maybeOf(context()) : null,
  );

  /// The platform's reader of the files on the clipboard (#1249).
  late final ClipboardFilesReader clipboardFiles = platformClipboardFiles();

  /// The editor's paste, before it is plain text: spreadsheet cells
  /// become a table (#1248).
  late final NotePaste paste = NotePaste(
    canInsert: () => canInsert,
    clipboardFiles: () =>
        view.services.readClipboardFiles?.call() ?? clipboardFiles.read(),
    attach: attach.attach,
    caretInCode: () => sourceViewKey.currentState?.caretInCode ?? false,
    surroundings: inserts.surroundings,
    plainText: readPlainClipboard,
    pasteText: inserts.pasteText,
    replacePasted: inserts.replacePasted,
    messenger: () => mounted() ? ScaffoldMessenger.maybeOf(context()) : null,
  );

  /// The checkbox items Move to tasks (#1152) reads and takes out.
  late final NoteTaskItems taskItems = NoteTaskItems(
    surface: () => session.surface,
    sourceView: () => sourceViewKey.currentState,
    canInsert: () => canInsert,
    focus: refocus,
  );

  /// Gives the editor the keyboard back after a command — unless a window
  /// or a dialog stands over the note (#772). The cheatsheet's window
  /// inserts while it stays open; Flutter lets a route below take the focus
  /// when asked, and the window's Esc and the typing would then go to the
  /// note behind its barrier. When the window closes, its route hands the
  /// focus back to the one below.
  void refocus() {
    if (!mounted()) return;
    if (!(ModalRoute.of(context())?.isCurrent ?? true)) return;
    focus.requestFocus();
  }

  /// The note's editing commands: the toolbar's, the format keys', the
  /// context menu's, the Tools sheet's and the spelling review's.
  late final NoteEditCommands commands = NoteEditCommands(
    surface: () => session.surface,
    focus: refocus,
    context: context,
    mounted: mounted,
    canInsert: () => canInsert,
    text: () => text.text,
    sourceView: () => sourceViewKey.currentState,
    readView: () => readViewKey.currentState,
    activeFormats: activeFormats,
    linkType: () => view.options.linkType,
    indentWidth: () => view.options.indentWidth,
    toolbarLayout: () => view.options.toolbarLayout,
    pasteAsMarkdown: () => switch (view.onPasteAsMarkdown) {
      final paste? => () => paste(handle()),
      null => null,
    },
    taskItems: taskItems,
    moveToTasks: () => switch (view.onMoveToTasks) {
      final move? => () => move(handle()),
      null => null,
    },
    libraryRoot: () => view.services.libraryRoot,
    pickImage: () =>
        view.services.pickImagePath?.call() ?? NoteEditCommands.pickImageFile(),
    importImage: (root, source) =>
        view.services.importImage?.call(root, source) ??
        importImageToLibrary(
          libraryRoot: root,
          sourcePath: source,
          attachmentsFolder: view.options.attachmentsFolder,
        ),
    onInserted: () {
      stats.refresh();
      refreshPreview();
    },
    spellCheck: () => view.services.spellCheck,
    onSpellChecked: () {
      if (mounted()) update(() {});
    },
  );

  /// The note's file: reading it off the UI isolate, and what it looked like
  /// when it was last read or written — its stamp and its framing.
  late final NoteDisk disk = NoteDisk(readNote: () => view.services.readNote);

  /// The read pane's refresh (T-M2-08), after a pause in the typing.
  Timer? previewTimer;

  /// The formats on at the caret: the toolbar's pressed state.
  ///
  /// Written by the surface, which reads them off the caret's line
  /// (`MarkdownSurface.activeItems`), so the toolbar and the context menu read
  /// one notifier in every mode (T-WYS-06, #246).
  final ValueNotifier<Set<ToolbarItem>> activeFormats =
      ValueNotifier<Set<ToolbarItem>>(const <ToolbarItem>{});

  /// The read pane's scroll.
  late final ScrollController previewScroll = ScrollController();

  /// The editor surface's own scroll, so the fields panel can tell when the
  /// note has been scrolled off its head and put itself away (#157). The
  /// surface does not own it: it is handed in and the view keeps it.
  final ScrollController sourceScroll = ScrollController();

  /// The frontmatter fields panel over the note (#157): how much of it shows,
  /// in whichever pane is on stage, and the field edits it makes.
  late final NoteFrontmatterPanel frontmatter = NoteFrontmatterPanel(
    enabled: () => view.options.frontmatterPanel,
    surface: () => session.surface,
    reading: () => previewIn(view),
    typewriter: () => view.options.typewriter,
    caretLine: () => surfaceCaretLine,
    previewScroll: previewScroll,
    sourceScroll: sourceScroll,
    mounted: mounted,
    onChanged: () => update(() {}),
    onEdited: () {
      refreshPreview();
      stats.refresh();
    },
  );

  /// The source pane's state, for its headings: the outline is read off the
  /// blocks the colours are already drawn from.
  final GlobalKey<MarkdownSourceViewState> sourceViewKey =
      GlobalKey<MarkdownSourceViewState>();

  /// The read mode's own state, so an anchor jump can ask it for a line: the
  /// read view knows which block a line belongs to and where that block starts,
  /// which is what a jump needs and what a line *fraction* of the note cannot
  /// say (#256).
  final GlobalKey<MarkdownReadViewState> readViewKey =
      GlobalKey<MarkdownReadViewState>();

  /// The typeset formulas, shared by the read pane, the live editor and the
  /// link preview.
  late final MathCache mathCache = MathCache();

  /// The unified engine's parser: one for the view's life, so its per-block
  /// cache survives a rebuild and invalidates itself when the text changes.
  final ReadParser unifiedParser = ReadParser();

  /// What the read pane draws of the note: a snapshot of the editor's
  /// buffer, taken once per revision shown.
  final NoteReadSnapshot readSnapshot = NoteReadSnapshot();

  /// The note's text as the unified source surface has it (see
  /// [NoteTextCache]): where saving, the preview and the statistics all get
  /// their text from.
  late final NoteTextCache text = NoteTextCache(() => unifiedSurfaceBuffer);

  /// The buffer the unified source surface edits. Its own, not the read pane's:
  /// the read pane's is rebuilt from the preview text on a debounce, and a pane
  /// cannot edit an object that another part of the shell replaces underneath
  /// it.
  SourceBuffer? get unifiedSurfaceBuffer => session.surface?.buffer;

  /// The mode the unified surface is built in: the WYSIWYG pane is `live`, the
  /// source pane is `source` (`docs/records/unified-surface.md` §8.6.3).
  MarkdownSurfaceMode get unifiedMode =>
      wysiwygIn(view) ? MarkdownSurfaceMode.live : MarkdownSurfaceMode.source;

  /// The app-level unsaved registry this editor reports into (T-PP-11),
  /// or null when the owner does not track.
  late final UnsavedTracker? unsaved;

  /// The [UnsavedNote] view handed to [unsaved]; it reads this state's
  /// revision pair live, so it cannot hold stale text.
  late final UnsavedNoteAdapter unsavedNote = UnsavedNoteAdapter(
    notePath: () => view.path,
    loading: () => session.loading,
    revision: () => saves.revision,
    lastSavedRevision: () => saves.lastSavedRevision,
    saveForClose: saves.saveForClose,
    bufferText: () => text.text,
    bufferHead: text.head,
  );

  /// How the note reaches the disk: its revisions, the debounce after an
  /// edit and the saves themselves.
  late final NoteSavePipeline saves = NoteSavePipeline(
    notePath: () => view.path,
    ready: () => session.ready,
    text: () => text.text,
    buffer: () => unifiedSurfaceBuffer,
    references: () => sourceViewKey.currentState?.references(),
    framing: () => disk.framing,
    saveNote: () => view.services.saveNote,
    writeNote: () => view.services.writeNote,
    saveNoteStream: () => view.services.saveNoteStream,
    onSaved: (path, stamp) {
      disk.stamp = stamp;
      unsaved?.noteChanged();
    },
    onSettled: () {
      if (mounted()) update(() {});
    },
    hold: view.services.unsavedTracker?.hold,
    diskStamp: () => disk.stamp,
    onExternalKept: (_) {
      if (!mounted()) return;
      ScaffoldMessenger.maybeOf(context())
          ?.showSnackBar(SnackBar(content: Text(AppStrings.noteChangedOnDisk)));
    },
  );

  /// The first failure of a run of saves is said once, with a snack bar; the
  /// status row keeps saying it, and offers the retry (#1054).
  void onSaveFailureChanged() {
    if (!mounted()) return;
    final failure = saves.failure.value;
    update(() {});
    if (failure == null || failure.attempts != 1) return;
    ScaffoldMessenger.maybeOf(context())
        ?.showSnackBar(SnackBar(content: Text(AppStrings.noteSaveFailedSnack)));
  }

  /// The library's features, or every one on with no library.
  Features get features => view.services.features?.value ?? const Features();

  /// The note changed, from either source pane: the text, and where the caret
  /// is
  /// in it (a line, which is what the preview's sync speaks in).
  ///
  /// The surface reports the pair through `onChanged` and `onSelection`, and
  /// everything downstream — the save debounce, the unsaved marker, the
  /// statistics, the preview text — is one code path for every mode.
  void noteChanged({required int caretLine, SourceEdit? edit}) {
    session.markEdited();
    if (edit != null) {
      // Before the revision moves: the count follows the edit's own lines,
      // which is the whole point of keeping it per line.
      session.surface?.words.edited(edit, session.surface!.buffer);
    }
    saves.edited();
    unsaved?.noteChanged();
    lastCaretLine = caretLine;
    stats.schedule();
    deadLinks.edited();
    preview.close();
    previewTimer?.cancel();
    previewTimer = Timer(const Duration(milliseconds: 500), refreshPreview);
  }

  /// Where the caret is, in the preview's own terms.
  int lastCaretLine = 0;

  /// Brings the read pane up to the editor, when it is the pane on stage.
  void refreshPreview() {
    if (!mounted() || session.loading) return;
    if (!previewIn(view)) {
      // The read pane is off stage behind the source pane, and bringing it up
      // to date means re-reading and re-parsing the whole note: done when it
      // is shown, not every time the writer pauses.
      readSnapshot.stale = true;
      return;
    }
    final live = session.surface?.buffer;
    if (live == null) return;
    // The editor's own lines, by revision: no text joined, no text compared.
    if (readSnapshot.shows(live)) return;
    update(() => readSnapshot.show(live));
  }

  /// Flips between the source editor and the WYSIWYG surface (T-WYS-12);
  /// the owner persists it and refreshes the shell.
  void toggleEditorKind() {
    final next = view.showWysiwyg ? EditorKind.source : EditorKind.wysiwyg;
    view.onEditorKindChanged?.call(next);
  }

  /// Whether only the preview is on screen (the editor hidden): the IME
  /// has no editable target, so it must go.
  bool get previewOnly => previewIn(view);

  /// Whether [view] shows its preview. In Zen (#69) too: a note read
  /// rather than written is read there in its preview (0.0.8 test round).
  static bool previewIn(NoteView view) =>
      view.showPreview && !plainTextIn(view);

  /// Whether [view] holds a file of a syntax of its own rather than
  /// Markdown — the Todo tab's todo.txt and done.txt, and calendar.txt
  /// (#730) — drawn in the source pane with its own colours and nowhere
  /// else: the preview and `live` read Markdown, and would run its lines
  /// together into paragraphs.
  static bool plainTextIn(NoteView view) =>
      isPlainTextFile(p.basename(view.path));

  /// Whether [view] holds a template: a note of the library's template
  /// folder, whose `{{…}}` commands the source colours.
  static bool templateIn(NoteView view) {
    final root = view.services.libraryRoot;
    final folder = view.options.templateFolder;
    if (root == null || folder == null || folder.isEmpty) return false;
    if (!p.isWithin(root, view.path)) return false;
    return isUnder(folder, relPath(view.path, root));
  }

  /// Whether [view] shows its note in the WYSIWYG pane.
  static bool wysiwygIn(NoteView view) =>
      view.showWysiwyg && !plainTextIn(view);

  /// Dismisses the keyboard when the preview is the only pane: a note
  /// opening in preview, or the switch flipping to it, must not leave
  /// the IME up over a pane with nothing editable.
  void dismissKeyboardForPreview() {
    if (!previewOnly) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // The read pane takes the keyboard instead, for the keys a page is read
    // with (the arrows, the page keys, Home and End); a tab behind another
    // leaves it where it is.
    if (!view.active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted() && previewOnly && view.active) {
        readViewKey.currentState?.focus();
      }
    });
  }

  /// The find keys, for the note and its bar ([NoteFindKeys]).
  late final NoteFindKeys findKeys = NoteFindKeys(
    find: sourceFind,
    openFind: openFind,
  );

  /// Opens the find bar (with replace when [replace]) over the source pane;
  /// the read pane and a note not loaded yet have nothing to find in.
  void openFind({bool replace = false}) {
    if (previewOnly || !session.ready) return;
    sourceFind.open(replace: replace);
  }

  /// The line the unified surface's caret is on (1-based), or null before it
  /// has
  /// reported one.
  int? surfaceCaretLine;

  /// What draws the note's `todo` fences as lists of tasks (#1152), or null
  /// where there is no list to draw them from: the Todo feature is off, or the
  /// note is outside a library. The fence is the code it is on disk then.
  TodoBlockBuilder? get todoBlocks {
    final tasks = view.services.tasks;
    final path = libraryPath;
    if (tasks == null || path == null || !features.isOn(LibraryFeature.todo)) {
      return null;
    }
    return NoteTodoBlocks(host: tasks, notePath: path);
  }

  /// The read pane's task items, ticked through the editor's own door.
  late final NoteReadTasks readTasks = NoteReadTasks(
    surface: () => session.surface,
    snapshot: readSnapshot,
    // The pane on screen has the note scanned.
    blocks: () =>
        sourceViewKey.currentState?.blocks ?? readViewKey.currentState?.blocks,
    cascade: () => view.options.cascadeChecklist,
    onEdited: refreshPreview,
  );

  /// The blocks and definitions of [buffer] as the source pane already holds
  /// them (see [NoteReadSnapshot.editorScanOf]), or null.
  DocumentScan? editorScanOf(SourceBuffer buffer) =>
      readSnapshot.editorScanOf(buffer, sourceViewKey.currentState);

  /// [editorScanOf], once the editor's reading of the note under way has
  /// landed: the read pane of a note opened in it waits for the scan the
  /// editor mounted behind it is making, rather than making a second one
  /// (#1199). Null when there is no editor, or the note moved on meanwhile.
  Future<DocumentScan?> editorScanLater(SourceBuffer buffer) async {
    final editor = sourceViewKey.currentState;
    if (editor == null) return null;
    await editor.readingLanded;
    if (!mounted()) return null;
    return editorScanOf(buffer);
  }

  /// The note's links: following them from either pane, the embeds they
  /// name, a link dropped from the tree, and the jumps to a heading.
  late final NoteLinkActions links = NoteLinkActions(
    notePath: () => view.path,
    notePathInLibrary: () => libraryPath,
    libraryRoot: () => view.services.libraryRoot,
    linkSource: () => view.services.linkSource,
    linkType: () => view.options.linkType,
    newItemLocation: () => view.options.newItemLocation,
    wikilinkSuggester: () => view.services.wikilinkSuggester,
    onOpenNote: () => view.services.onOpenNote,
    createMissingNote: () => view.services.createMissingNote,
    outline: () => stats.outline.value,
    surface: () => session.surface,
    readView: () => readViewKey.currentState,
    reading: () => previewIn(view),
    context: context,
    mounted: mounted,
    onDropped: () {
      focus.requestFocus();
      stats.refresh();
      refreshPreview();
    },
  );

  /// The status row's word on the note: loading, saving, unsaved, saved.
  String get status {
    if (session.error != null) return AppStrings.noteStatusError;
    if (session.loading) return AppStrings.noteStatusLoading;
    if (saves.failure.value != null && !saves.saving) {
      return AppStrings.noteStatusSaveFailed;
    }
    if (saves.saving) return AppStrings.noteStatusSaving;
    if (saves.dirty) return AppStrings.noteStatusUnsaved;
    return AppStrings.noteStatusSaved;
  }

  /// A kind GUI's byte-stable edit: the buffer takes the new text (the
  /// highlighter, stats and preview follow it as with any edit) and the
  /// note is saved immediately.
  void applyKindEdit(String newText) {
    final surface = session.surface;
    if (surface != null && newText != text.text) {
      // The kind GUI stands in front of the surface, so there may be no view:
      // the controller edits the buffer itself, and it is that buffer the save
      // below writes.
      surface.applyEdit(
        newText,
        TextSelection.collapsed(
          offset: surface.selection.extent.clamp(0, newText.length),
        ),
      );
    }
    // An edit that changes the note's `type` (Make flashcards, #533) turns
    // the view to the kind it names, as a note opened with it would be.
    session.kindEdited(newText);
    saves.saveInBackground();
  }

  /// The formatting keys (#205), applied through the toolbar's own
  /// actions for whichever surface is showing.
  late final EditorFormatKeys formatKeys = EditorFormatKeys(
    actions: commands.toolbarActions,
    active: () => mounted() && keyboardUp,
  );

  /// Whether the editor on screen holds the focus — the phone's proxy for
  /// "the keyboard is up": the formatting toolbar shows only while the
  /// keyboard is up (it is the keyboard's row, and in preview there is
  /// nothing to format), so it rides this focus.
  bool get keyboardUp => focus.hasFocus;

  /// The editor's log.
  static const AppLogger log = AppLogger(name: 'editor');

  /// Whether the Files pane asked for the caret in this note and it has not
  /// been given yet (#727): the editor is not up until the note has loaded,
  /// and a focus asked for before that goes nowhere.
  bool caretPending = false;

  /// When the load in flight started: what the log says it cost.
  final Stopwatch loadClock = Stopwatch();

  /// The session moved: the view follows what it says changed.
  void onSession() {
    switch (session.event) {
      case NoteEvent.loading:
        // The links and the card of the note that went are not this
        // one's, nor is the read pane's copy of its text (#1202).
        deadLinks.clear();
        preview.close();
        readSnapshot.clear();
        update(() {});
      case NoteEvent.surfaced:
        // What the bar found was in the note that went.
        sourceFind.close(refocus: false);
        surfaceCaretLine = null;
        // A template `{{cursor}}` landing (#53): the surface was given the
        // caret with its buffer, and a memento must not take it back (a note
        // created at a path that had one lost its `{{cursor}}`).
        if (view.initialCaretOffset == null && view.initialAnchor == null) {
          place.restore(view.initialMemento, inWysiwyg: wysiwygIn(view));
        }
        // The spell cache is keyed by line index + text; a different note
        // can reuse the same indices, so forget the previous file's answers.
        view.services.spellCheck?.reset();
        unsaved?.noteChanged();
      case NoteEvent.opened:
        opened();
      case NoteEvent.failed:
        update(() {});
      case NoteEvent.reread:
        view.services.spellCheck?.reset();
        unsaved?.noteChanged();
        view.onNoteKindChanged?.call(session.kind);
        stats.refresh();
        deadLinks.refresh();
        refreshPreview();
        if (mounted()) update(() {});
      case NoteEvent.kindChanged:
        update(() {});
        view.onNoteKindChanged?.call(session.kind);
      case null:
        update(() {});
    }
  }

  /// The note landed on screen: the keyboard, the caret, the shell's word
  /// of its kind, its statistics, its links, its preview and the place
  /// asked for.
  void opened() {
    final path = view.path;
    final length = text.text.length;
    update(() {});
    // Opened straight into the preview: the IME has no target here.
    dismissKeyboardForPreview();
    // A template `{{cursor}}` landing takes the keyboard (#53), and so
    // does a note the Files pane opened (#727), and asks for it: the
    // surface's `autofocus` gives way to whatever its scope already
    // focused — the tree, the button the template was picked from — and
    // the caret was drawn where no key went. Once the frame has put the
    // surface under its focus node.
    if (view.initialCaretOffset != null || caretPending) {
      caretPending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted() && view.path == path) focus.requestFocus();
      });
    }
    view.onNoteKindChanged?.call(session.kind);
    // Word count + outline: asked for only now, with the note already on
    // screen, because computing them costs an order of magnitude more
    // than reading the note (see PreviewWork's `read`). Small notes
    // answer synchronously inside this call; big ones go to an isolate
    // and land a moment later.
    stats.refresh();
    // The links that name nothing, resolved against the index with the
    // note already on screen, and drawn muted when they arrive (#847).
    deadLinks.refresh();
    // The editor gets this frame: the preview's parse and first layout
    // start right after the text is on screen, so a large note shows it
    // before the preview works (T-PP-22). The outline is asked for again
    // then too: a big note's comes off a pane's scan, and the panes drew
    // the note before this one until this frame built them for it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted()) return;
      refreshPreview();
      if (view.path == path) stats.refresh();
    });
    if (view.initialFind case final terms? when terms.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted() && view.path == path) {
          sourceFind.openFinding(terms);
        }
      });
    }
    landOnAnchor();
    view.onLoaded?.call(path, length);
    log.info(
      'note loaded: $path ($length chars, '
      '${loadClock.elapsedMilliseconds} ms)',
    );
    // The read time above is what the disk/isolate cost; this is what the
    // user waited for — load plus the frame that paints the loaded note.
    logNextFrame('editor', 'note open first frame ($length chars)');
  }

  /// Lands on the anchor the note was opened at, once it is open: the
  /// view's own opening jump, and a link followed to the note while it was
  /// already on screen (#1268), which opens nothing to jump after.
  void landOnAnchor() {
    final anchor = view.initialAnchor;
    if (anchor == null || !mounted() || !session.ready) return;
    unawaited(jumpToAnchor(context(), anchor, links.targets()));
  }
}
