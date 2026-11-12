import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/task_items.dart';
import 'package:niman/src/editor/task_items_edit.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/frontmatter/edit.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/ui/hidden_slot.dart';
import 'package:niman/src/ui/note_editor_options.dart';
import 'package:niman/src/ui/note_footer.dart';
import 'package:niman/src/ui/note_links.dart';
import 'package:niman/src/ui/note_load_error.dart';
import 'package:niman/src/ui/note_place.dart';
import 'package:niman/src/ui/note_read_pane.dart';
import 'package:niman/src/ui/note_services.dart';
import 'package:niman/src/ui/note_session.dart';
import 'package:niman/src/ui/note_source_pane.dart';
import 'package:niman/src/ui/note_stats.dart';
import 'package:niman/src/ui/note_tags.dart';
import 'package:niman/src/ui/note_top_bar.dart';
import 'package:niman/src/ui/note_view_adapters.dart';
import 'package:niman/src/ui/note_view_chrome.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/note_view_parts.dart';
import 'package:niman/src/ui/pointer_density.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:path/path.dart' as p;

export 'package:niman/src/ui/note_save_pipeline.dart'
    show NoteSaver, NoteStreamSaver;
export 'package:niman/src/ui/note_source_pane.dart' show zenCaretWidth;

/// Opens a note file in the source editor and keeps disk in sync.
///
/// The file is the source of truth (design.md): the initial read happens
/// off the UI isolate (a full-file read is a FUSE round trip on Android),
/// and saves are atomic. Edits persist ~500 ms after the last keystroke,
/// on focus loss, and when the app is hidden.
///
/// Line endings: the buffer uses LF; `\r` is stripped on load, the file's
/// dominant ending is remembered with the note, and every save writes the
/// text back with it (#1056) — a CRLF note stays CRLF.
///
/// [options] are the settings toggles,
/// passed through to the editor. The note is one pane: [showPreview] says
/// which of the two it holds — the editor or the read surface.
final class NoteView extends StatefulWidget {
  /// Opens the note at [path].
  const new({
    required this.path,
    required this.options,
    this.barActions = const [],
    this.showPreview = false,
    this.showWysiwyg = false,
    this.onWysiwygChanged,
    this.onEditorKindChanged,
    this.services = const NoteServices(),
    this.initialAnchor,
    this.initialCaretOffset,
    this.initialFind,
    this.active = true,
    this.initialMemento,
    this.movedFrom,
    this.onMemento,
    this.onEditedNoteClosed,
    this.onLoaded,
    this.kindMode = true,
    this.outlineInDock = false,
    this.spellCheckInDock = false,
    this.relatedInDock = false,
    this.onNoteKindChanged,
    this.onKindMarkdown,
    this.onPasteAsMarkdown,
    this.onMoveToTasks,
    this.toolbarTop = false,
    this.zen = false,
    this.onToggleTypewriter,
    this.statusActions = const <Widget>[],
    this.reloadToken = 0,
    this.caretRequest = 0,
    super.key,
  });

  /// Absolute path of the note file.
  final String path;

  /// How the library's settings say the note is edited (#1257).
  final NoteEditorOptions options;

  /// A counter the shell bumps when the note was opened from the Files pane
  /// — a click on a row or a tile, or the pane's `Enter` — and the caret
  /// should be in it (#727).
  ///
  /// The editor is the same widget across notes, so opening one does not
  /// remount it and `autofocusEditor` — a fresh mount's — says nothing
  /// here. A click on a note is an invitation to write in it, so the shell
  /// asks for the caret; 0 is "nobody asked".
  final int caretRequest;

  /// How long a note waits after the last edit before its word count and
  /// outline are refreshed, or null to wait for nothing.
  ///
  /// A test sets it to zero so the count is on screen by the frame after a
  /// keystroke; nothing in the app sets it.
  @visibleForTesting
  static Duration? get statsDelayOverride => NoteStatsController.delayOverride;
  @visibleForTesting
  static set statsDelayOverride(Duration? delay) =>
      NoteStatsController.delayOverride = delay;

  /// The note's own controls at the right end of the desktop's top row
  /// (#173): the kind toggles and the ⋮ menu the shell builds.
  final List<Widget> barActions;

  /// Preview visibility (T-UI-06): the shared app bar owns the switch
  /// and passes the state down; NoteView just follows it.
  final bool showPreview;

  /// Whether this note opens in the WYSIWYG surface instead of the source
  /// editor (T-WYS-05).
  final bool showWysiwyg;

  /// Reports a WYSIWYG edit as Markdown (the owner saves it).
  final ValueChanged<String>? onWysiwygChanged;

  /// Switches the library's editor kind (the status row's toggle,
  /// T-WYS-12); null hides the toggle, which is what a library with a
  /// single enabled editor passes.
  final ValueChanged<EditorKind>? onEditorKindChanged;

  /// What the open library lends the note (#1257).
  final NoteServices services;

  /// A heading anchor to land on after the note loads (T-M3-07).
  final String? initialAnchor;

  /// A template `{{cursor}}` offset to land the caret on after the note
  /// loads (#53), measured in the created text. Clamped into the text.
  final int? initialCaretOffset;

  /// The words a search result matched (#1045): the note shows the first
  /// of them it holds, selected, with the find bar marking every one.
  final List<String>? initialFind;

  /// Whether this is the tab on screen (#23). A tab kept alive behind it
  /// keeps its buffer, undo and view, and hands in a memento as it goes.
  final bool active;

  /// Where the note was left, put back once it loads (#23): its
  /// selection when it was left in the editor that shows now, and its
  /// scroll. A caret landing or an anchor wins over it.
  final NoteMemento? initialMemento;

  /// The path this note was at a moment ago, when its file was renamed or
  /// moved (#1076): [path] changing from this one is the same note under
  /// another name, so the view keeps its text, undo and place instead of
  /// loading another note.
  final String? movedFrom;

  /// Receives where the note is left: when its tab goes behind another,
  /// and when the view goes away.
  final void Function(String path, NoteMemento memento)? onMemento;

  /// Told the path of a note that was edited while it was open, once it is
  /// closed — another note taking its place, or the view going away — and
  /// its last edit is on disk: where the library tidies it
  /// (`LibraryConfig.tidyOnClose`). A note only read is never reported.
  final void Function(String path)? onEditedNoteClosed;

  /// Told the note's length once it is loaded: the tabs keep a note this
  /// large alive behind others only up to a point (#23).
  final void Function(String path, int length)? onLoaded;

  /// Whether the note-kind GUIs are shown (T-TK-02): a note whose
  /// frontmatter declares a known `type` opens in its kind GUI instead of
  /// the editor. False = always the raw editor.
  final bool kindMode;

  /// Whether the window's panel has the outline (#1002): the status row's
  /// own outline button would then be a second way to the same list, and is
  /// left out. True wherever the wide layout shows the panel — docked
  /// beside the note, or over it on a window without room for both. Off
  /// where nothing else has it — a phone, a window too narrow for the wide
  /// layout.
  final bool outlineInDock;

  /// Whether the window's panel has the spelling review (#1002), on the
  /// same rule as [outlineInDock]: the status row's own spelling button
  /// would then be a second way to the same pane, and is left out. A phone
  /// keeps its button — the sheet is its way to the review.
  final bool spellCheckInDock;

  /// Whether the window's panel is open on a wide layout: it has the notes
  /// and tasks that link this one, so the rows under the note are left out.
  final bool relatedInDock;

  /// Reports the loaded note's kind (the frontmatter `type` value, null =
  /// plain note); the shell shows the kind toggle for known kinds.
  final void Function(String? type)? onNoteKindChanged;

  /// Leaves the kind's view for the note's Markdown preview: the phone's
  /// button under a slides note (#534). Null where the screen offers no
  /// such button.
  final VoidCallback? onKindMarkdown;

  /// Paste as Markdown from the editor's menu (#531), run by the shell on
  /// this note; null leaves the entry out.
  final ValueChanged<NoteViewHandle>? onPasteAsMarkdown;

  /// Move to tasks from the editor's menu and Tools sheet (#1152), run by
  /// the shell on this note; null leaves the entry out.
  final ValueChanged<NoteViewHandle>? onMoveToTasks;

  /// Whether the note has its row of chrome above it (the wide layout),
  /// the formatting toolbar in it on a desktop; a phone's toolbar, and a
  /// tablet's (#1266), is below the editor, extending the keyboard.
  final bool toolbarTop;

  /// Zen mode (#69): the note alone. Its row above, its status row and
  /// its row numbers go, and the caret thickens a little, since the
  /// chrome that framed it has gone.
  final bool zen;

  /// The status row's typewriter switch; null leaves it out.
  final VoidCallback? onToggleTypewriter;

  /// Extra controls at the right of the status row (T-PP-22): the desktop
  /// puts the layout/preview actions here, next to the note's own status;
  /// the phone keeps them in its note app bar (empty by default).
  final List<Widget> statusActions;

  /// External-change reload requests (home-screen widget toggles): the
  /// shell bumps this when the already-open note may have changed on
  /// disk (a same-note reopen, an app resume). A change triggers a
  /// clean-only re-read — unsaved edits always win over the disk.
  final int reloadToken;

  @override
  State<NoteView> createState() => _NoteViewState();
}

final class _NoteViewState extends State<NoteView>
    with WidgetsBindingObserver
    implements NoteViewHandle {
  /// The note view's collaborators and how they are wired (#1257).
  late final NoteViewParts _parts = NoteViewParts(
    viewOf: () => widget,
    handle: () => this,
    context: () => context,
    mounted: () => mounted,
    update: setState,
  );

  @override
  bool get canInsert => _parts.canInsert;

  static const AppLogger _log = AppLogger(name: 'editor');

  @override
  ValueListenable<List<OutlineEntry>> get outline => _parts.stats.outline;

  @override
  String get currentText => _parts.text.text;

  @override
  Future<List<String>> currentTags() {
    final buffer = _parts.unifiedSurfaceBuffer;
    if (buffer == null) return Future.value(noteTagsOf(_parts.text.text));
    // A long note's scan keeps its tags block by block for the save to
    // hand the index: the same answer, with nothing of the note read again.
    return noteTagsOfBuffer(
      buffer,
      references: _parts.sourceViewKey.currentState?.references(),
    );
  }

  @override
  String get selectedText => _parts.inserts.selectedText;

  @override
  String get notePath => widget.path;

  @override
  String? get notePathInLibrary => _parts.libraryPath;

  @override
  Future<String?> resolveEmbed(String target) =>
      _parts.links.resolveEmbed(target);

  @override
  void jumpToHeading(int line) => _parts.links.jumpToHeading(line);

  @override
  void setNoteKind(String? type) {
    // Once: a long note's text is joined for each ask (see [NoteTextCache]).
    final current = _parts.text.text;
    final text = type == null
        ? removeFrontmatterKey(current, 'type')
        : setFrontmatterKey(current, 'type', type);
    if (text == current) return;
    _parts.applyKindEdit(text);
  }

  @override
  void applyKindEdit(String newText) => _parts.applyKindEdit(newText);

  @override
  void insertAtCaret(String markdown) {
    if (!canInsert) return;
    _parts.commands.run(
      (text, selection) =>
          insertSnippet(text: text, selection: selection, snippet: markdown),
      // A block keeps a blank line from the lines either side.
      context: 1,
    );
  }

  @override
  void insertColumns() {
    if (!canInsert) return;
    _parts.commands.insertColumnsAtCaret();
  }

  @override
  void insertEisenhower() {
    if (!canInsert) return;
    _parts.commands.insertEisenhowerMatrixAtCaret();
  }

  @override
  Future<bool> attachFiles(List<String> paths) =>
      canInsert ? _parts.attach.attach(paths) : Future.value(false);

  @override
  PastedText? pasteText(String text) => _parts.inserts.pasteText(text);

  @override
  void replacePasted(PastedText pasted, String text) =>
      _parts.inserts.replacePasted(pasted, text);

  @override
  void convertListToMindMap() => _parts.commands.convertListToMindMap();

  @override
  List<TaskItem> get taskItems => _parts.taskItems.selected();

  @override
  TakenTaskItems? takeOutTaskItems(List<TaskItem> items) =>
      mounted ? _parts.taskItems.takeOut(items) : null;

  @override
  bool putBackTaskItems(TakenTaskItems taken) =>
      mounted && _parts.taskItems.putBack(taken);

  @override
  void takeFocus() {
    if (!mounted) return;
    if (!_parts.session.ready) {
      // The load puts the caret in once the editor is up.
      _parts.caretPending = true;
      return;
    }
    if (_parts.previewOnly) {
      _parts.readViewKey.currentState?.focus();
      return;
    }
    _parts.refocus();
  }

  @override
  SpellReview? get spellReview =>
      _parts.commands.spellReview(edited: _parts.stats);

  /// Keeps the note where it was read when it moves between `source`,
  /// `live` and the read view ([NotePlace.keepAcrossModes]).
  void _keepPlaceAcrossModes(NoteView oldWidget) {
    if (!_parts.session.ready) return;
    if (oldWidget.path != widget.path) return;
    _parts.place.keepAcrossModes(
      wasRead: NoteViewParts.previewIn(oldWidget),
      read: NoteViewParts.previewIn(widget),
      modeChanged:
          NoteViewParts.wysiwygIn(oldWidget) != NoteViewParts.wysiwygIn(widget),
    );
  }

  /// Files changed on disk under the open notes (#1042): the tracker's word.
  StreamSubscription<Set<String>>? _diskChanges;

  /// A switch was flipped, or a sync brought another device's: the kind the
  /// note shows follows it, and the note's text is not touched (#1109).
  void _featuresChanged() {
    if (mounted) setState(() {});
  }

  /// The kind GUIs' window onto the note (T-TK-02).
  late final NoteKindHostAdapter _kindHost;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _parts.session.addListener(_parts.onSession);
    _parts.focus.addListener(_onFocusChanged);
    widget.services.features?.addListener(_featuresChanged);
    _parts.deadLinks.sourceChanged();
    // The pane opened the note before this editor was mounted (#727): the
    // surface is built this frame, so the caret is asked for after it.
    _parts.caretPending = widget.caretRequest != 0;
    // The fields panel rides the note's head (#157), in whichever pane is on
    // stage: both scrolls are watched, and the panel reads the one that is.
    _parts.previewScroll.addListener(_parts.frontmatter.scrolled);
    _parts.sourceScroll.addListener(_parts.frontmatter.scrolled);
    // The formatting keys, while this editor is the focused one (#205).
    _parts.formatKeys.attach();
    _kindHost = NoteKindHostAdapter(
      noteText: () => _parts.text.text,
      applyNoteEdit: _parts.applyKindEdit,
      noteFilePath: () => widget.path,
      rootDirectory: () => widget.services.libraryRoot,
      attachmentsFolderOf: () => widget.options.attachmentsFolder,
      linkTypeOf: () => widget.options.linkType,
      embedResolver: _parts.links.resolveEmbed,
      linkOpener: (context, href) =>
          unawaited(openHref(context, href, _parts.links.targets())),
      wikiLinkOpener: (context, inner) => unawaited(
        openWiki(context, parseWikiRef(inner), _parts.links.targets()),
      ),
      markdownShower: () => widget.onKindMarkdown,
    );
    _parts.unsaved = widget.services.unsavedTracker;
    _parts.unsaved?.register(_parts.unsavedNote);
    widget.services.spellCheck?.addListener(_onSpellCheckChanged);
    // The WYSIWYG publishes the formats at its caret on every selection
    // change: the same moment its memento moves.
    _parts.activeFormats.addListener(_parts.place.schedule);
    // And the scroll of either pane: where the note is read is where it is
    // left (#1077).
    _parts.previewScroll.addListener(_parts.place.schedule);
    _parts.sourceScroll.addListener(_parts.place.schedule);
    _parts.stats.addListener(_onStatsChanged);
    _parts.saves.failure.addListener(_parts.onSaveFailureChanged);
    _diskChanges = _parts.unsaved?.diskChanges.listen((paths) {
      if (paths.isEmpty || paths.any((it) => p.equals(it, widget.path))) {
        unawaited(_reloadIfChanged());
      }
    });
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant NoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.services.features != widget.services.features) {
      oldWidget.services.features?.removeListener(_featuresChanged);
      widget.services.features?.addListener(_featuresChanged);
    }
    final moved = _followsMove(oldWidget);
    _keepPlaceAcrossModes(oldWidget);
    if (!identical(oldWidget.services.linkSource, widget.services.linkSource)) {
      // The library opened under a note that was already on screen: its
      // links are resolved against it now.
      _parts.deadLinks
        ..sourceChanged()
        ..refresh();
    }
    if (oldWidget.path != widget.path && !moved) {
      // Another note's head is not this one's (#157): the panel opens closed
      // again, and the note on screen is taken at its head until it scrolls.
      _parts.frontmatter.reset();
    }
    if (oldWidget.showPreview != widget.showPreview) {
      if (widget.showPreview && _parts.readSnapshot.stale) {
        _parts.readSnapshot
          ..stale = false
          ..show(_parts.session.surface?.buffer);
      }
      if (widget.showPreview) {
        // What the flip costs to reach the pixels, and what the frames after
        // it cost. The line above says when it started; without these two,
        // "the preview was slow to open" (device report, 2026-09-21: about a
        // second on the geometry note) could be neither confirmed nor
        // attributed — the read pane had no trace of its own at all.
        logNextFrame('preview', 'read pane first frame');
        // The frame window is for a run whose log can be handed over; it is
        // also a 2.5-second timer, which a widget test would report as a
        // pending one (`AppLog.file` is attached in `main` and null there).
        if (AppLog.file != null) FrameProbe.watch('preview', 'read pane open');
      }
    }
    if (oldWidget.active && !widget.active) _parts.place.hand(oldWidget.path);
    if (!oldWidget.active && widget.active && _parts.place.landing) {
      _parts.place.scheduleLanding();
    }
    if (!oldWidget.active && widget.active && _parts.session.ready) {
      // Back on screen: the shell asks the showing note what kind it is.
      widget.onNoteKindChanged?.call(_parts.session.kind);
      _parts.dismissKeyboardForPreview();
    }
    if (moved) {
      _followMove();
    } else if (oldWidget.path != widget.path) {
      _parts.place.hand(oldWidget.path);
      // Persist the outgoing note under its own path before the buffer is
      // replaced by the incoming one: the _load below resets it.
      _closed(oldWidget.path, _parts.saves.saveOutgoing(oldWidget.path));
      // The tracker now sees the incoming path (the adapter reads it
      // live) — re-read the dirty set so the guard does not act on the
      // outgoing note.
      _parts.unsaved?.noteChanged();
      unawaited(_load());
    }
    // An external change may have landed while the note stayed open (a
    // home-screen widget toggle edits the file in a background isolate):
    // re-read when the buffer is clean, keep unsaved edits otherwise.
    if (widget.reloadToken != oldWidget.reloadToken) {
      unawaited(_reloadIfChanged());
    }
    // Coming back to the editor no longer remounts it (both panes stay
    // mounted below), so the source editor's autofocus no longer fires on
    // its own — request it like a fresh mount did.
    if (NoteViewParts.previewIn(oldWidget) &&
        !NoteViewParts.previewIn(widget)) {
      if (widget.options.autofocusEditor) _parts.focus.requestFocus();
    }
    // The preview has no editable: a note opening in it, or the switch
    // flipping to it, dismisses the keyboard instead of leaving it up.
    final wasPreviewOnly = NoteViewParts.previewIn(oldWidget);
    if (_parts.previewOnly &&
        (widget.path != oldWidget.path || !wasPreviewOnly)) {
      _parts.dismissKeyboardForPreview();
    }
    // The pane opened the note (#727): the caret goes in it, whatever the
    // editor was showing before. Last, so a note opening in the preview is
    // not dismissed right after being asked for. The editor may still be
    // loading, so the ask is remembered for when it is up. A drop to 0 is
    // the ask going to another note — another pane's, another tab's — and
    // asks this one for nothing.
    if (widget.caretRequest != 0 &&
        widget.caretRequest != oldWidget.caretRequest) {
      _parts.caretPending = true;
      _parts.refocus();
    }
  }

  /// Whether [oldWidget] to this one is the same loaded note renamed or
  /// moved (#1076), not another note: its buffer is still the note.
  bool _followsMove(NoteView oldWidget) =>
      oldWidget.path != widget.path &&
      widget.movedFrom == oldWidget.path &&
      _parts.session.holdsNote;

  /// The note's file is at a new path and its editor stays as it is: the
  /// text, the undo, the place. What was keyed on the old path starts over.
  void _followMove() {
    _log.debug('moved: ${widget.movedFrom} -> ${widget.path}');
    // The edits from here on are saved under the new name, as a new
    // session. The disk stamp is the old file's, which the move kept, so a
    // rewrite of this note's links by the move still reads as a change.
    _parts.session.moved(widget.path);
    _parts.unsaved?.noteChanged();
    // Its links resolve from where it is now.
    _parts.deadLinks
      ..sourceChanged()
      ..refresh();
  }

  @override
  void dispose() {
    widget.services.features?.removeListener(_featuresChanged);
    _parts.place
      ..hand(widget.path)
      ..dispose();
    _parts.activeFormats.removeListener(_parts.place.schedule);
    _parts.previewScroll.removeListener(_parts.place.schedule);
    _parts.sourceScroll.removeListener(_parts.place.schedule);
    _parts.templateCheck.dispose();
    _parts.saves.cancel();
    _parts.previewTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _closed(widget.path, _parts.saves.close());
    _parts.session
      ..removeListener(_parts.onSession)
      ..dispose();
    _parts.unsaved?.unregister(_parts.unsavedNote);
    widget.services.spellCheck?.removeListener(_onSpellCheckChanged);
    _parts.sourceFind.dispose();
    _parts.saves.failure.removeListener(_parts.onSaveFailureChanged);
    unawaited(_diskChanges?.cancel());
    _parts.stats
      ..removeListener(_onStatsChanged)
      ..dispose();
    _parts.deadLinks.dispose();
    _parts.preview.dispose();
    _parts.activeFormats.dispose();
    _parts.formatKeys.detach();
    _parts.focus.dispose();
    _parts.previewScroll.removeListener(_parts.frontmatter.scrolled);
    _parts.sourceScroll.removeListener(_parts.frontmatter.scrolled);
    _parts.sourceScroll.dispose();
    _parts.previewScroll.dispose();
    _parts.mathCache.dispose();
    super.dispose();
  }

  /// The note at [path] is closed: once [saved] — its last save — is on
  /// disk, [NoteView.onEditedNoteClosed] hears of it, if it was edited
  /// while it was open.
  void _closed(String path, Future<void> saved) {
    final edited = _parts.session.takeEdited();
    final report = widget.onEditedNoteClosed;
    if (!edited || report == null) return;
    unawaited(
      saved.then(
        (_) => report(path),
        // A save that failed left the note as it was; there is nothing
        // of this session's to tidy on disk.
        onError: (Object error) =>
            _log.warning('closed unsaved: $path ($error)'),
      ),
    );
  }

  @override
  void deactivate() {
    _parts.place.leaving();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _parts.place.back();
  }

  /// Opens the note on screen: the session reads it, and the view follows.
  Future<void> _load() {
    _parts.loadClock
      ..reset()
      ..start();
    return _parts.session.open(
      widget.path,
      caret: widget.initialCaretOffset ?? 0,
    );
  }

  /// Opens the note again after a load that failed (#1059).
  void _retryLoad() => _parts.session.retry(widget.path);

  /// Adopts the disk text when it changed under a clean note
  /// ([NoteSession.reload]). The test seam reads nothing, so it has no
  /// stamp to check and reads on.
  Future<void> _reloadIfChanged() => _parts.session.reload(
    widget.path,
    checkStamp: widget.services.readNote == null,
  );

  @override
  void openFind({bool replace = false}) => _parts.openFind(replace: replace);

  void _onFocusChanged() {
    if (!_parts.focus.hasFocus) _parts.saves.saveInBackground();
    _onToolbarFocusChanged();
  }

  /// The phone's formatting toolbar shows only while the keyboard is up,
  /// so a focus change repaints it; the desktop's top toolbar never rides
  /// the keyboard and does not repaint for it.
  void _onToolbarFocusChanged() {
    if (mounted && !_formatAbove) setState(() {});
  }

  /// Whether the formatting toolbar sits above the note: a desktop's. A
  /// tablet keeps the row above for the note's own controls and has the
  /// toolbar ride the keyboard, as a phone does (#1266).
  bool get _formatAbove => widget.toolbarTop && !thumbDense(Theme.of(context));

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.info('lifecycle: ${state.name}');
    // `paused` is a phone's; a desktop window that is minimised or covered
    // goes `hidden` and never `paused` (#1057).
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _parts.saves.saveInBackground();
    }
    // Leaving the foreground may be the last thing this process does.
    if (state != AppLifecycleState.resumed && widget.active) {
      _parts.place.handNow();
    }
  }

  /// The statistics were refreshed: the status row and the fields panel are
  /// drawn again.
  void _onStatsChanged() {
    if (mounted) setState(() {});
  }

  /// Spelling results changed (the note loaded, or a settings toggle): the
  /// pane is drawn again with the new ranges.
  void _onSpellCheckChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final error = _parts.session.error;
    final showPreview = NoteViewParts.previewIn(widget);
    // The head the fields panel follows, measured for the pane about to be
    // built (#157): the panel reads it on every scroll tick, and building a
    // theme there would cost a frame's worth on each one.
    _parts.frontmatter.measure(context, showPreview: showPreview);
    // The toolbar formats the editor: it hides while the preview holds
    // the pane, which has nothing to format. On the phone it also rides
    // the keyboard (it shows only while the keyboard is up); on desktop
    // it never does.
    // Hiding every button hides the toolbar itself; the editor keeps its
    // keyboard shortcuts.
    // A todo.txt has no Markdown to format.
    final showToolbar =
        !showPreview &&
        !NoteViewParts.plainTextIn(widget) &&
        (_formatAbove || _parts.keyboardUp) &&
        widget.options.toolbarLayout.visible.isNotEmpty;
    // Kind mode (T-TK-02): a known `type` swaps the body for the kind GUI
    // and hides the editor chrome (outline, status row, toolbar) — the
    // note is a list, not a document, on screen.
    final kindGui = NoteKinds.forType(_parts.session.kind, _parts.features);
    final kindBody = widget.kindMode && kindGui != null;
    // A list or a voice note keeps to the note column like text does
    // (0.0.8 test round): the column is the app's shape, not the editor's.
    final kindChild = kindBody
        ? NoteColumnPadding(
            column: widget.options.noteColumn,
            child: kindGui.buildBody(context, _kindHost),
          )
        : null;
    return Column(
      children: [
        // Desktop: one row above the note (#173) — the formatting on the
        // left, the note's own controls and ⋮ on the right, both keeping
        // to the note's column. The row stays when there is nothing to
        // format (preview, a list note, a file that did not open), so
        // the ⋮ never moves. Phone: the toolbar extends the keyboard,
        // below (see the bottom slot).
        if (widget.toolbarTop && !widget.zen)
          NoteTopBar(
            column: widget.options.noteColumn,
            toolbar:
                showToolbar &&
                    _formatAbove &&
                    !kindBody &&
                    !_parts.session.loading &&
                    error == null
                ? _toolbar(context, dense: true)
                : null,
            actions: widget.barActions,
          ),
        Expanded(
          child: Listener(
            onPointerDown: (event) =>
                _parts.links.pointerDownAt = event.position,
            // The preview card of a hovered link goes over the note (#846).
            child: _parts.preview.host(
              closeOn: _parts.scrolls,
              child: error == null
                  ? (!_parts.session.ready || _parts.session.loading
                        ? const Center(child: CircularProgressIndicator())
                        : kindBody
                        ? kindChild!
                        // Both panes stay mounted and only one is on stage:
                        // coming back to the preview finds its parse, scroll
                        // offset, typeset math and images where they were
                        // (device report, 2026-09-11: every return re-parsed
                        // the note and restarted from the top). Hidden
                        // children skip layout, hit testing, painting and the
                        // default finders (#1079); the panes never show
                        // together.
                        : Stack(
                            children: [
                              HiddenSlot(
                                hidden: showPreview,
                                child: KeyedSubtree(
                                  key: ValueKey(
                                    NoteViewParts.wysiwygIn(widget)
                                        ? 'pane-wysiwyg'
                                        : 'pane-editor',
                                  ),
                                  child: NoteSourcePane(parts: _parts),
                                ),
                              ),
                              HiddenSlot(
                                hidden: !showPreview,
                                child: KeyedSubtree(
                                  key: const ValueKey('pane-preview'),
                                  child: NoteReadPane(parts: _parts),
                                ),
                              ),
                            ],
                          ))
                  : NoteLoadError(
                      message: error,
                      path: widget.path,
                      offerDefaultApp: _parts.session.notText,
                      onRetry: _parts.session.notText ? null : _retryLoad,
                    ),
            ),
          ),
        ),
        if (!kindBody && !widget.zen)
          NoteFooter(
            column: widget.options.noteColumn,
            loading: _parts.session.loading,
            ready: _parts.session.ready,
            frontmatterError: _parts.stats.frontmatterError,
            showRelated: !widget.relatedInDock,
            linkSource: widget.services.linkSource,
            notePath: _parts.libraryPath,
            onOpenNote: (path) => widget.services.onOpenNote?.call(path, null),
            showTasks: _parts.features.isOn(LibraryFeature.todo),
            tasks: widget.services.tasks,
            statusRow: ListenableBuilder(
              listenable: _parts.templateCheck,
              builder: (context, _) => NoteStatusRow(
                loading: _parts.session.loading,
                showOutline: !widget.outlineInDock,
                showPreview: showPreview,
                showWysiwyg: NoteViewParts.wysiwygIn(widget),
                showSpellCheck:
                    !widget.spellCheckInDock &&
                    widget.services.spellCheck != null &&
                    widget.services.spellCheck!.available,
                // In its place, and off: a todo.txt has one pane.
                canSwitchEditorKind: widget.onEditorKindChanged != null,
                editorKindLocked: NoteViewParts.plainTextIn(widget),
                wordCount: _parts.stats.wordCount,
                // Only a template is counted; elsewhere the checker
                // never ran and stays at nothing (T-TPL-09).
                templateProblems: NoteViewParts.templateIn(widget)
                    ? _parts.templateCheck.problemCount
                    : 0,
                statusText: _parts.status,
                onStatusTap: _parts.saves.failure.value == null
                    ? null
                    : _parts.saves.saveInBackground,
                statusActions: widget.statusActions,
                onOutline: _parts.links.openOutline,
                onFind: () => _parts.sourceFind.open(),
                onSpellCheck: _parts.commands.openSpellCheck,
                onToggleEditorKind: _parts.toggleEditorKind,
                typewriter: widget.options.typewriter,
                onToggleTypewriter: widget.onToggleTypewriter,
              ),
            ),
            toolbarBelow: !_formatAbove && !_parts.session.loading,
            showToolbar: showToolbar,
            toolbar: _toolbar,
          ),
      ],
    );
  }

  /// The formatting toolbar (T-UI-08): pure markdown commands applied
  /// through the surface; the image button keeps the file-picker flow
  /// (T-M2-09) it already had in the status row.
  Widget _toolbar(BuildContext context, {bool dense = false}) {
    final actions = _parts.commands.toolbarActions();
    final menus = _parts.commands.toolbarMenus();
    Widget bar(Set<ToolbarItem> active) => NoteToolbarBar(
      dense: dense,
      actions: actions,
      menus: menus,
      active: active,
      layout: widget.options.toolbarLayout,
    );
    // The surface publishes the formats at the caret into one notifier, read
    // off the caret's line, so a pressed button stays pressed until it is
    // toggled off (T-WYS-06, #246).
    return ValueListenableBuilder<Set<ToolbarItem>>(
      valueListenable: _parts.activeFormats,
      builder: (context, active, _) => bar(active),
    );
  }
}
