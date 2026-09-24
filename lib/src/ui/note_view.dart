import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/editor_shortcuts.dart';
import 'package:niman/src/editor/editor_tool.dart';
import 'package:niman/src/editor/find_bar.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/list_tally.dart';
import 'package:niman/src/editor/list_tally_edit.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/library/image_import.dart';
import 'package:niman/src/library/note_write_stream.dart';
import 'package:niman/src/links/attachment_embed.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block_index.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/note_load.dart';
import 'package:niman/src/markdown/note_read_failure.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/surface.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_check_sheet.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';
import 'package:niman/src/ui/editor_menu.dart';
import 'package:niman/src/ui/editor_tools_sheet.dart';
import 'package:niman/src/ui/heading_level_sheet.dart';
import 'package:niman/src/ui/list_tally_sheet.dart';
import 'package:niman/src/ui/note_links.dart';
import 'package:niman/src/ui/note_load_error.dart';
import 'package:niman/src/ui/note_top_bar.dart';
import 'package:niman/src/ui/note_view_adapters.dart';
import 'package:niman/src/ui/note_view_chrome.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/note_view_memento.dart';
import 'package:niman/src/ui/outline_panel.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:path/path.dart' as p;

/// Saves [content] as the note at absolute [path]; [editSession] is the
/// editor session the save belongs to (one opening of the note).
typedef NoteSaver = Future<void> Function(
  String path,
  String content, {
  required int editSession,
});

/// How wide the caret is in Zen mode (#69): thicker, to be found at a
/// glance on a page with nothing else on it.
const double zenCaretWidth = 3;

/// Saves a note whose text the editor never joins: [content] makes the
/// bytes a slice at a time, and the save answers when the disk holds them.
/// See [NoteView.saveNoteStream].
typedef NoteStreamSaver = Future<void> Function(
  String path,
  NoteContentProducer content, {
  required int editSession,
});

/// Opens a note file in the source editor and keeps disk in sync.
///
/// The file is the source of truth (design.md): the initial read happens
/// off the UI isolate (a full-file read is a FUSE round trip on Android),
/// and saves are atomic. Edits persist ~500 ms after the last keystroke,
/// on focus loss, and when the app is hidden.
///
/// Line endings: the buffer uses LF; `\r` is stripped on load and the save
/// writes LF. Restoring the file's original line ending on save is a
/// deferred refinement (record it per note).
///
/// [showLineNumbers] and [autofocusEditor] are the settings toggles,
/// passed through to the editor. The note is one pane: [showPreview] says
/// which of the two it holds — the editor or the read surface.
final class NoteView extends StatefulWidget {
  /// Opens the note at [path].
  const new({
    required this.path,
    required this.showLineNumbers,
    required this.autofocusEditor,
    this.noteColumn = NoteColumn.off,
    this.barActions = const [],
    this.linkType = LinkType.wikilink,
    this.missingNoteLocation = MissingNoteLocation.currentFolder,
    this.attachmentsFolder = defaultAttachmentsFolder,
    this.indentWidth = 2,
    this.toolbarLayout = ToolbarLayout.defaults,
    this.showPreview = false,
    this.showWysiwyg = false,
    this.onWysiwygChanged,
    this.onEditorKindChanged,
    this.libraryRoot,
    this.pickImagePath,
    this.importImage,
    this.readNote,
    this.writeNote,
    this.saveNote,
    this.saveNoteStream,
    this.linkSource,
    this.onOpenNote,
    this.createMissingNote,
    this.folderExists,
    this.initialAnchor,
    this.initialCaretOffset,
    this.active = true,
    this.initialMemento,
    this.onMemento,
    this.onLoaded,
    this.kindMode = true,
    this.onNoteKindChanged,
    this.toolbarTop = false,
    this.zen = false,
    this.typewriter = false,
    this.onToggleTypewriter,
    this.unsavedTracker,
    this.statusActions = const <Widget>[],
    this.spellCheck,
    this.reloadToken = 0,
    super.key,
  });

  /// Absolute path of the note file.
  final String path;

  /// Whether the editor shows the row-number column (settings toggle).
  final bool showLineNumbers;

  /// Whether the editor shows the keyboard on open (settings toggle).
  final bool autofocusEditor;

  /// Where the note's text sits across the pane (issue #171): both
  /// editors, the preview, the toolbar, the find bars and the status row
  /// keep to it.
  final NoteColumn noteColumn;

  /// How long a note waits after the last edit before its word count and
  /// outline are refreshed, or null to wait for nothing.
  ///
  /// A test sets it to zero so the count is on screen by the frame after a
  /// keystroke; nothing in the app sets it.
  @visibleForTesting
  static Duration? statsDelayOverride;

  /// The note's own controls at the right end of the desktop's top row
  /// (#173): the kind toggles and the ⋮ menu the shell builds.
  final List<Widget> barActions;

  /// The link format the link button inserts (settings).
  final LinkType linkType;

  /// The folder (library-relative) picked images are copied into
  /// (settings, issue #56).
  final String attachmentsFolder;

  /// The indent/outdent width in spaces (settings).
  final int indentWidth;

  /// The toolbar the user arranged (settings, T-TB-04): which buttons
  /// show and in what order.
  final ToolbarLayout toolbarLayout;

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

  /// The library root (T-M2-09): relative image links in the preview
  /// resolve under it, and inserted images are copied into
  /// `<root>/assets/`. Null (tests without a library) disables insert.
  final String? libraryRoot;

  /// Picks an image file (T-M2-09); the default is the platform picker
  /// (file_picker). Tests inject a seam.
  final Future<String?> Function()? pickImagePath;

  /// Imports the picked file into the library (default
  /// [importImageToLibrary]); tests inject a seam (it runs an isolate,
  /// which FakeAsync cannot drive).
  final Future<String> Function(String libraryRoot, String sourcePath)?
  importImage;

  /// Reads a note's content. Defaults to an off-isolate file read.
  final Future<String> Function(String path)? readNote;

  /// Persists a note's content. Defaults to an atomic file write.
  ///
  /// A test seam; production passes [saveNote] instead.
  final Future<void> Function(String path, String content)? writeNote;

  /// Saves a note's content through the library's write path (`NoteOps`),
  /// with the editor session the save belongs to. Takes precedence over
  /// [writeNote]; null (no open library) falls back to a direct write.
  final NoteSaver? saveNote;

  /// Saves a note whose text is too long to join (a [NoteStreamSaver]):
  /// the producer it is handed makes the bytes one slice at a time and the
  /// write takes them as they come. Null — no library, or a note outside
  /// its root — joins the note and saves it through [saveNote] as before.
  final NoteStreamSaver? saveNoteStream;

  /// The link-resolution source (wiki targets + markdown hrefs against the
  /// open index); null (tests without a session) disables link navigation.
  final LinkSource? linkSource;

  /// Opens a note by library-relative path, then (optionally) jumps to a
  /// heading; the shell implements it (T-M3-07).
  final void Function(String path, String? anchor)? onOpenNote;

  /// Where a note created from a dead link lands (settings, issue #78);
  /// the offer itself is disabled when [createMissingNote] is null.
  final MissingNoteLocation missingNoteLocation;

  /// The note-creation path for dead links (issue #78): creates an empty
  /// note at library-relative [path] and returns its library-relative
  /// path; null (no open library) keeps the dead-link snackbar instead of
  /// the offer.
  final Future<String> Function(String path)? createMissingNote;

  /// Whether a library-relative folder exists under `[root]` (issue #78);
  /// defaults to an off-UI-isolate disk check. A test seam: widget tests
  /// run against a fake library that is not on disk.
  final Future<bool> Function(String root, String rel)? folderExists;

  /// A heading anchor to land on after the note loads (T-M3-07).
  final String? initialAnchor;

  /// A template `{{cursor}}` offset to land the caret on after the note
  /// loads (#53), measured in the created text. Clamped into the text.
  final int? initialCaretOffset;

  /// Whether this is the tab on screen (#23). A tab kept alive behind it
  /// keeps its buffer, undo and view, and hands in a memento as it goes.
  final bool active;

  /// Where the note was left, put back once it loads (#23): its
  /// selection when it was left in the editor that shows now, and its
  /// scroll. A caret landing or an anchor wins over it.
  final NoteMemento? initialMemento;

  /// Receives where the note is left: when its tab goes behind another,
  /// and when the view goes away.
  final void Function(String path, NoteMemento memento)? onMemento;

  /// Told the note's length once it is loaded: the tabs keep a note this
  /// large alive behind others only up to a point (#23).
  final void Function(String path, int length)? onLoaded;

  /// Whether the note-kind GUIs are shown (T-TK-02): a note whose
  /// frontmatter declares a known `type` opens in its kind GUI instead of
  /// the editor. False = always the raw editor.
  final bool kindMode;

  /// Reports the loaded note's kind (the frontmatter `type` value, null =
  /// plain note); the shell shows the kind toggle for known kinds.
  final void Function(String? type)? onNoteKindChanged;

  /// Whether the formatting toolbar sits above the editor (desktop)
  /// instead of below it (phone, where it extends the keyboard).
  final bool toolbarTop;

  /// Zen mode (#69): the note alone. Its row above, its status row and
  /// its row numbers go, and the caret thickens a little, since the
  /// chrome that framed it has gone.
  final bool zen;

  /// Typewriter mode (#70): the caret's row keeps to the middle of the
  /// editor, in both editors. Independent of [zen]: either may be on
  /// without the other.
  final bool typewriter;

  /// The status row's typewriter switch; null leaves it out.
  final VoidCallback? onToggleTypewriter;

  /// The app-level registry of notes with unsaved edits (T-PP-11), which
  /// the window's close guard reads; null when the owner does not track
  /// (most widget tests). The adapter below reports this note's live
  /// revision pair, so the tracker never holds a copy of the text.
  final UnsavedTracker? unsavedTracker;

  /// Extra controls at the right of the status row (T-PP-22): the desktop
  /// puts the layout/preview actions here, next to the note's own status;
  /// the phone keeps them in its note app bar (empty by default).
  final List<Widget> statusActions;

  /// The editor's spelling state (T-PP-09): underlines misspelled prose.
  /// Null (most widget tests, and a platform without hunspell) draws none.
  final EditorSpellCheck? spellCheck;

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
  static const AppLogger _log = AppLogger(name: 'editor');

  late final FocusNode _focus;

  /// The unified source pane's find & replace, over [_surface]'s buffer.
  late final SourceFindController _sourceFind = SourceFindController(
    surface: () => _surface,
    onClose: _focus.requestFocus,
  );

  bool _loading = true;
  bool _ready = false;
  bool _saving = false;
  bool _savePending = false;

  /// Why the note could not be opened, in the user's words; the raw error
  /// goes to the log only (issue #156).
  String? _error;

  /// The failed file is not text at all: the error pane offers it to the
  /// OS instead.
  bool _notText = false;
  Timer? _saveTimer;

  /// Hands in where the note is, a moment after the reader stops (#23):
  /// a window closed with nothing to save goes without asking the app,
  /// so the memento cannot wait for the view to go away.
  Timer? _mementoTimer;

  /// How long after the last move, scroll or edit the memento goes in.
  static const _mementoDelay = Duration(seconds: 1);

  /// Debounced note-statistics refresh (word count + outline, T-M2-07).
  Timer? _statsTimer;
  int _wordCount = 0;
  List<OutlineEntry> _outline = const <OutlineEntry>[];

  /// [_outline], published for the panels beside the note (#175).
  final ValueNotifier<List<OutlineEntry>> _outlineNotifier = ValueNotifier(
    const <OutlineEntry>[],
  );

  @override
  ValueListenable<List<OutlineEntry>> get outline => _outlineNotifier;

  @override
  String get currentText => _currentText;

  @override
  void jumpToHeading(int line) => _jumpToHeading(line);

  @override
  bool get canInsert {
    if (!_ready) return false;
    final kind = _noteKind == null ? null : NoteKinds.forType(_noteKind);
    return !(widget.kindMode && kind != null);
  }

  @override
  void insertAtCaret(String markdown) {
    if (!canInsert) return;
    _runCommand(
      (text, selection) =>
          insertSnippet(text: text, selection: selection, snippet: markdown),
      // A block keeps a blank line from the lines either side.
      context: 1,
    );
  }

  /// The unified note's revision the word count and the outline were last
  /// read at, or -1 before the first read. Comparing revisions is what says
  /// a note changed, where the statistics used to compare its whole text.
  int _unifiedStatsRevision = -1;

  /// What the note's file looked like when it was last read or written.
  ///
  /// A reload is asked for by a watcher, and a watcher is not a promise: a
  /// touch, a rescan, or a change to a file that was already saved all arrive
  /// as "the note changed". Knowing the file's size and time is O(1), and it
  /// is what tells a real change from an event — the read, the normalize and
  /// the comparison against the pane's text are what cost on a 246 MB note
  /// (208 ms to join the pane's text, 734 ms to normalize a fresh read, 44 ms
  /// to compare; measured 2026-09-22).
  DiskStamp? _diskStat;

  /// Why the note's frontmatter block does not parse, or null when it
  /// does (or when there is no block). Refreshed on the stats debounce.
  String? _frontmatterError;

  /// The read pane's refresh (T-M2-08), after a pause in the typing.
  Timer? _previewTimer;

  /// The note's current text.
  String get _currentText => _unifiedText;

  /// The formats on at the caret: the toolbar's pressed state.
  ///
  /// Written by the surface, which reads them off the caret's line
  /// (`MarkdownSurface.activeItems`), so the toolbar and the context menu read
  /// one notifier in every mode (T-WYS-06, #246).
  final ValueNotifier<Set<ToolbarItem>> _activeFormats =
      ValueNotifier<Set<ToolbarItem>>(const <ToolbarItem>{});
  late final ScrollController _previewScroll = ScrollController();

  /// The source pane's state, for its headings: the outline is read off the
  /// blocks the colours are already drawn from.
  final GlobalKey<MarkdownSourceViewState> _sourceViewKey =
      GlobalKey<MarkdownSourceViewState>();

  /// The read mode's own state, so an anchor jump can ask it for a line: the
  /// read view knows which block a line belongs to and where that block starts,
  /// which is what a jump needs and what a line *fraction* of the note cannot
  /// say (#256).
  final GlobalKey<MarkdownReadViewState> _readViewKey =
      GlobalKey<MarkdownReadViewState>();
  late final MathCache _mathCache = MathCache();

  /// The unified engine's parser: one for the view's life, so its per-block
  /// cache survives a rebuild and invalidates itself when the text changes.
  final BlockParser _unifiedParser = BlockParser();

  /// The unified engine's buffer, rebuilt only when the text changes.
  ///
  /// A `SourceBuffer` is a line array with a prefix index: building one per
  /// frame would cost 1.2 ms of `text` and a 7 ms scan on a 930 KB note, which
  /// is exactly what the windowed read view exists to avoid. The preview
  /// refreshes on a 500 ms debounce, so this is rebuilt at that cadence.
  SourceBuffer? _unifiedBuffer;

  /// The editor's buffer and its revision the read pane should show, while
  /// the source pane is the unified surface: the pane is given a snapshot of
  /// that buffer's lines ([SourceBuffer.snapshot]) rather than a buffer read
  /// again from the note's joined text.
  SourceBuffer? _previewOf;
  int _previewRevision = -1;

  /// Whether [_unifiedBuffer] is such a snapshot, and of which revision.
  bool _bufferIsSnapshot = false;
  SourceBuffer? _snapshotFrom;
  int _snapshotRevision = -1;

  /// The note's text as the unified source surface has it, read by
  /// [_currentText], which is where saving, the preview and the statistics all
  /// get their text from — so this pane reaches every one of them through one
  /// door.
  ///
  /// Joined from the surface's buffer when it is asked for, once per revision:
  /// the surface reports an edit without its text, because joining the note on
  /// every keystroke is O(n) for a text only the save debounce needs.
  String get _unifiedText {
    final buffer = _unifiedSurfaceBuffer;
    if (buffer == null) return _unifiedTextCache;
    if (!identical(buffer, _unifiedTextBuffer) ||
        buffer.revision != _unifiedTextRevision) {
      _unifiedTextCache = buffer.text;
      _unifiedTextBuffer = buffer;
      _unifiedTextRevision = buffer.revision;
    }
    return _unifiedTextCache;
  }

  /// Seeds [_unifiedText] with the text [_unifiedSurfaceBuffer] was read from.
  set _unifiedText(String text) {
    _unifiedTextCache = text;
    _unifiedTextBuffer = _unifiedSurfaceBuffer;
    _unifiedTextRevision = _unifiedSurfaceBuffer?.revision ?? -1;
  }

  String _unifiedTextCache = '';
  SourceBuffer? _unifiedTextBuffer;
  int _unifiedTextRevision = -1;

  /// Whether the preview's text is behind the note because the preview was
  /// not on screen when the note changed (see [_refreshPreview]).
  bool _previewStale = false;

  /// The note on the unified source surface: its buffer, its undo history and
  /// the door every command comes in through (the toolbar, an image, a
  /// spelling fix, a reload). One per open note, so the history survives the
  /// pane being rebuilt.
  MarkdownSurfaceController? _surface;

  /// The buffer the unified source surface edits. Its own, not the read pane's:
  /// the read pane's is rebuilt from the preview text on a debounce, and a pane
  /// cannot edit an object that another part of the shell replaces underneath
  /// it.
  SourceBuffer? get _unifiedSurfaceBuffer => _surface?.buffer;

  /// A controller over [text], reporting its edits the way the surface does:
  /// over [ready]'s buffer when the note came made ready, which the UI
  /// isolate then does not split.
  MarkdownSurfaceController _surfaceFor(
    String text, {
    int caret = 0,
    LoadedNote? ready,
  }) {
    final surface =
        MarkdownSurfaceController(
            ready?.buffer ?? SourceBuffer.fromText(text),
            caret: caret,
          )
          ..onChanged = (edit) => _noteChanged(
            caretLine: _surfaceCaretLine ?? _caretLine,
            edit: edit,
          );
    _adoptWords(surface);
    return surface;
  }

  /// Gives [surface] its word count, here for a note small enough to walk
  /// and in the background for one that is not (see [WordCount]).
  ///
  /// It has to be there before the first edit: the count follows the lines
  /// an edit touched, and one that is not built yet has no lines to follow.
  void _adoptWords(MarkdownSurfaceController surface) {
    if (surface.words.isCounted) return;
    final buffer = surface.buffer;
    if (buffer.length > _syncWorkLimit) {
      unawaited(surface.buildWords());
      return;
    }
    surface.words.adopt(buffer);
  }

  /// Keeps the note where it was read when it moves between `source`,
  /// `live` and the read view: the line at the top of the pane going away,
  /// shown at the top of the one taking over once it has drawn. Pixels are
  /// no measure across them — a heading is taller in `live`, a definition
  /// takes no room in the read view — and a pane that kept its own offset
  /// showed wherever it had last been, the top of the note when it had not.
  void _keepPlaceAcrossModes(NoteView oldWidget) {
    if (!_ready) return;
    if (oldWidget.path != widget.path) return;
    final wasRead = oldWidget.showPreview;
    final read = widget.showPreview;
    final modeChanged = oldWidget.showWysiwyg != widget.showWysiwyg;
    if (wasRead == read && (read || !modeChanged)) return;
    final anchor = wasRead
        ? _readViewKey.currentState?.topAnchor
        : _sourceViewKey.currentState?.topAnchor;
    if (anchor == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.showPreview) {
        _readViewKey.currentState?.showAnchor(anchor);
      } else {
        _sourceViewKey.currentState?.showAnchor(anchor);
      }
    });
  }

  /// The mode the unified surface is built in: the WYSIWYG pane is `live`, the
  /// source pane is `source` (`docs/dev/unified-surface.md` §8.6.3).
  MarkdownSurfaceMode get _unifiedMode => widget.showWysiwyg
      ? MarkdownSurfaceMode.live
      : MarkdownSurfaceMode.source;

  /// The buffer the unified engine draws, built once per text change.
  SourceBuffer get _unifiedSource {
    final live = _previewOf;
    if (live != null) {
      if (_unifiedBuffer == null ||
          !_bufferIsSnapshot ||
          !identical(_snapshotFrom, live) ||
          _snapshotRevision != _previewRevision) {
        _unifiedBuffer = live.snapshot();
        _bufferIsSnapshot = true;
        _snapshotFrom = live;
        _snapshotRevision = _previewRevision;
      }
      return _unifiedBuffer!;
    }
    // No note yet: an empty page.
    if (_unifiedBuffer == null || _bufferIsSnapshot) {
      _unifiedBuffer = SourceBuffer.fromText('');
      _bufferIsSnapshot = false;
    }
    return _unifiedBuffer!;
  }

  /// Text-edit counter; the disk matches [_lastSavedRevision]. A saved note
  /// is a revision, not a text copy.
  int _revision = 0;
  int _lastSavedRevision = 0;

  /// Process-wide source of [_editSession] ids.
  static int _editSessions = 0;

  /// The editor session: a new id each time a note's text is taken from
  /// disk (opened, or adopted after an outside change). History keys its
  /// "state before this session's edits" snapshot on it.
  int _editSession = 0;

  /// The save in flight, if any: a coalesced [_save] hands it back, so a
  /// caller that must know the disk moved ([_saveForClose]) awaits the
  /// real write instead of the pending flag.
  Future<void>? _activeSave;

  /// The app-level unsaved registry this editor reports into (T-PP-11),
  /// or null when the owner does not track.
  late final UnsavedTracker? _unsaved;

  /// The [UnsavedNote] view handed to [_unsaved]; it reads this state's
  /// revision pair live, so it cannot hold stale text.
  late final UnsavedNoteAdapter _unsavedNote = UnsavedNoteAdapter(
    notePath: () => widget.path,
    loading: () => _loading,
    revision: () => _revision,
    lastSavedRevision: () => _lastSavedRevision,
    saveForClose: _saveForClose,
  );

  /// The loaded note's kind (the frontmatter `type` value, null = plain
  /// note); null again while a load is in flight.
  String? _noteKind;

  /// The kind GUIs' window onto the note (T-TK-02).
  late final NoteKindHostAdapter _kindHost;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focus = FocusNode();
    _focus.addListener(_onFocusChanged);
    // The formatting keys, while this editor is the focused one (#205).
    _formatKeys.attach();
    _kindHost = NoteKindHostAdapter(
      noteText: () => _currentText,
      applyNoteEdit: _applyKindEdit,
      noteFilePath: () => widget.path,
      rootDirectory: () => widget.libraryRoot,
      attachmentsFolderOf: () => widget.attachmentsFolder,
      linkTypeOf: () => widget.linkType,
    );
    _unsaved = widget.unsavedTracker;
    _unsaved?.register(_unsavedNote);
    widget.spellCheck?.addListener(_onSpellCheckChanged);
    // The WYSIWYG publishes the formats at its caret on every selection
    // change: the same moment its memento moves.
    _activeFormats.addListener(_scheduleMemento);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant NoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _keepPlaceAcrossModes(oldWidget);
    // Device trace (preview toggle needs two presses on huge notes) —
    // temporary: remove once the trace is in.
    if (oldWidget.showPreview != widget.showPreview) {
      final scroll = _previewScroll.hasClients
          ? '${_previewScroll.offset.toStringAsFixed(0)}/'
                '${_previewScroll.position.maxScrollExtent.toStringAsFixed(0)}'
          : 'detached';
      const AppLogger(name: 'preview').info(
        'flip showPreview=${widget.showPreview} '
        'scroll=$scroll',
      );
      if (widget.showPreview && _previewStale) {
        _previewStale = false;
        _previewOf = _surface?.buffer;
        _previewRevision = _previewOf?.revision ?? -1;
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
    if (oldWidget.active && !widget.active) _handMemento(oldWidget.path);
    if (!oldWidget.active && widget.active && _ready) {
      // Back on screen: the shell asks the showing note what kind it is.
      widget.onNoteKindChanged?.call(_noteKind);
      _dismissKeyboardForPreview();
    }
    if (oldWidget.path != widget.path) {
      _handMemento(oldWidget.path);
      _saveTimer?.cancel();
      _savePending = false;
      // Persist the outgoing note under its own path before the buffer is
      // replaced by the incoming one (its text is read synchronously at the
      // start of _save, before the _load below resets the buffer). An
      // in-flight save already holds the outgoing text + path: skip.
      if (!_saving && _revision != _lastSavedRevision) {
        unawaited(_save(path: oldWidget.path));
      }
      // The tracker now sees the incoming path (the adapter reads it
      // live) — re-read the dirty set so the guard does not act on the
      // outgoing note.
      _unsaved?.noteChanged();
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
    if (_previewIn(oldWidget) && !_previewIn(widget)) {
      if (widget.autofocusEditor) _focus.requestFocus();
    }
    // The preview has no editable: a note opening in it, or the switch
    // flipping to it, dismisses the keyboard instead of leaving it up.
    final wasPreviewOnly = _previewIn(oldWidget);
    if (_previewOnly && (widget.path != oldWidget.path || !wasPreviewOnly)) {
      _dismissKeyboardForPreview();
    }
  }

  @override
  void dispose() {
    _handMemento(widget.path);
    _mementoTimer?.cancel();
    _activeFormats.removeListener(_scheduleMemento);
    _saveTimer?.cancel();
    _statsTimer?.cancel();
    _previewTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_revision != _lastSavedRevision) unawaited(_save());
    _unsaved?.unregister(_unsavedNote);
    widget.spellCheck?.removeListener(_onSpellCheckChanged);
    _sourceFind.dispose();
    _outlineNotifier.dispose();
    _activeFormats.dispose();
    _formatKeys.detach();
    _focus.dispose();
    _previewScroll.dispose();
    _mathCache.dispose();
    super.dispose();
  }

  /// Hands where the note at [path] was left to [NoteView.onMemento]:
  /// only a loaded note has a place to have been left at.
  void _handMemento(String path) {
    final receive = widget.onMemento;
    if (receive == null || !_ready) return;
    final surface = _surface;
    if (surface != null) {
      // Source offsets either way: `live` draws the same text, so an offset
      // means what it means in `source`, and a tab switch between the two
      // panes keeps the caret. The *editor kind* is the pane's, so the switch
      // comes back to the mode the note was left in.
      final selection = surface.selection;
      receive(
        path,
        NoteMemento(
          selectionBase: selection.anchor,
          selectionExtent: selection.extent,
          scrollOffset: surface.scrollOffset,
          editorKind: widget.showWysiwyg ? wysiwygEditorKind : sourceEditorKind,
          preview: widget.showPreview,
        ),
      );
      return;
    }
  }

  /// Puts the note back where [NoteView.initialMemento] left it: the
  /// selection only in the editor it was taken in (their offsets count
  /// different things), the scroll either way.
  void _restoreMemento() {
    final memento = widget.initialMemento;
    if (memento == null || memento.isEmpty) return;
    final wysiwyg = widget.showWysiwyg;
    final sameEditor =
        memento.editorKind == (wysiwyg ? wysiwygEditorKind : sourceEditorKind);
    // One surface, two modes, the same text and the same offsets: the
    // selection is restored whenever the memento was taken in this pane, and
    // the scroll either way. The buffer is already built (the load made it).
    _surface?.restore(
      base: sameEditor ? memento.selectionBase : null,
      extent: sameEditor ? memento.selectionExtent : null,
      scroll: memento.scrollOffset,
    );
  }

  Future<void> _write(String path, String content, int editSession) async {
    final saver = widget.saveNote;
    if (saver != null) {
      await saver(path, content, editSession: editSession);
      return;
    }
    final seam = widget.writeNote;
    if (seam != null) {
      await seam(path, content);
      return;
    }
    // Encode + atomic write off the UI isolate: the utf8 encode is an O(n)
    // string pass and the write the FUSE round trips — neither may touch
    // the UI frame.
    final (bytes, encodeMs, writeMs) = await Isolate.run(() async {
      final encodeClock = Stopwatch()..start();
      final encoded = utf8.encode(content);
      final encodeMs = encodeClock.elapsedMilliseconds;
      final writeClock = Stopwatch()..start();
      await writeFileAtomically(File(path), encoded);
      final writeMs = writeClock.elapsedMilliseconds;
      return (encoded.length, encodeMs, writeMs);
    });
    _log.debug(
      'save write: $bytes bytes (encode $encodeMs ms, write $writeMs ms, '
      'off-isolate)',
    );
  }

  Future<void> _load() async {
    final path = widget.path;
    // The buffer stops being any note's text here: the outgoing note's
    // save already left with its own path and text (didUpdateWidget), and
    // the incoming one is not read yet. Nothing in it is owed to the disk,
    // so the close guard has nothing to wait for (#156).
    _lastSavedRevision = _revision;
    setState(() {
      _loading = true;
      _ready = false;
      _error = null;
      _notText = false;
      _noteKind = null;
    });
    final clock = Stopwatch()..start();
    try {
      final String content;
      // The note made ready off the UI isolate — its buffer with its text —
      // for the unified surface, which is what it draws.
      LoadedNote? ready;
      if (widget.readNote != null) {
        // The test seam: content per the injected reader.
        content = await widget.readNote!(path);
      } else {
        final loaded = await loadNote(path);
        if (loaded is NoteReadFailure) throw loaded;
        ready = loaded as LoadedNote;
        content = ready.text;
      }
      if (!mounted || widget.path != path) return;
      // The buffer uses LF: normalize line endings on load.
      final text = ready?.text ?? normalizedLineEndings(content);
      // The note kind (T-TK-02): the frontmatter `type` decides the body
      // (kind GUI or plain editor); detection scans the leading block
      // only, never the whole text.
      _noteKind = frontmatterTypeOf(text);
      // What the bar found was in the note that went.
      _sourceFind.close(refocus: false);
      _surface = _surfaceFor(
        text,
        caret: (widget.initialCaretOffset ?? 0).clamp(0, text.length),
        ready: ready,
      );
      _surfaceCaretLine = null;
      _unifiedText = text;
      // A template `{{cursor}}` landing (#53): the surface was given the
      // caret with its buffer, above, and a memento must not take it back
      // (a note created at a path that had one lost its `{{cursor}}`).
      if (widget.initialCaretOffset == null && widget.initialAnchor == null) {
        _restoreMemento();
      }
      // The spell cache is keyed by line index + text; a different note can
      // reuse the same indices, so forget the previous file's answers.
      widget.spellCheck?.reset();
      _lastSavedRevision = _revision;
      _editSession = ++_editSessions;
      _log.debug('edit session $_editSession: $path');
      _unsaved?.noteChanged();
      setState(() {
        _loading = false;
        _ready = true;
      });
      // Opened straight into the preview: the IME has no target here.
      _dismissKeyboardForPreview();
      widget.onNoteKindChanged?.call(_noteKind);
      // Word count + outline: asked for only now, with the note already on
      // screen, because computing them costs an order of magnitude more
      // than reading the note (see PreviewWork's `read`). Small notes
      // answer synchronously inside this call; big ones go to an isolate
      // and land a moment later.
      _refreshStats();
      // The editor gets this frame: the preview's parse and first layout
      // start right after the text is on screen, so a large note shows it
      // before the preview works (T-PP-22).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshPreview();
      });
      final anchor = widget.initialAnchor;
      if (anchor != null && mounted) {
        jumpToAnchor(context, anchor, _linkTargets);
      }
      widget.onLoaded?.call(path, text.length);
      _recordDiskStat(path);
      _log.info(
        'note loaded: $path (${text.length} chars, '
        '${clock.elapsedMilliseconds} ms)',
      );
      // The read time above is what the disk/isolate cost; this is what the
      // user waited for — load plus the frame that paints the loaded note.
      logNextFrame('editor', 'note open first frame (${text.length} chars)');
    } on Object catch (error) {
      if (!mounted) return;
      // A file that is not text is an attachment, not a broken note: it
      // says so, and nothing about it is ever reported saved (#156).
      final notText = error is NoteReadFailure && error.notText;
      setState(() {
        _loading = false;
        _notText = notText;
        _error = notText ? AppStrings.noteNotText : AppStrings.noteLoadFailed;
      });
      _log.error('note load failed: $path ($error)');
    }
  }

  /// Adopts the disk text when it changed under the open note (a
  /// home-screen widget toggle edits the file in a background isolate,
  /// like any other external edit).
  ///
  /// Only when the buffer is clean: a save in flight, a pending save, or
  /// unsaved edits keep the user's text — the disk converges on the next
  /// save instead. Identical content is a no-op, so a resume without an
  /// external edit never disturbs the caret. The WYSIWYG surface owns a
  /// live document the buffer cannot replace, so it never auto-reloads.
  Future<void> _reloadIfChanged() async {
    if (_loading || _saving || _savePending) {
      _log.debug('reload skipped (busy): ${widget.path}');
      return;
    }
    if (_revision != _lastSavedRevision) {
      _log.debug('reload skipped (unsaved edits): ${widget.path}');
      return;
    }
    final path = widget.path;
    // What the file looked like when it was last read or written, before the
    // read: O(1) against 250 ms of joining and comparing, and O(1) against
    // the read itself. The test seam reads nothing, so it has no stat to
    // check and reads on.
    if (widget.readNote == null && _unchangedOnDisk(path)) {
      _log.debug('reload skipped (the file did not change): $path');
      return;
    }
    final String content;
    try {
      if (widget.readNote != null) {
        content = await widget.readNote!(path);
      } else {
        final loaded = await readNoteText(path);
        if (loaded is! String) return;
        content = loaded;
      }
    } on Object catch (error) {
      _log.warning('reload read failed: $path ($error)');
      return;
    }
    if (!mounted || widget.path != path) return;
    // The user may have typed during the read: re-check clean before
    // adopting anything.
    if (_loading ||
        _saving ||
        _savePending ||
        _revision != _lastSavedRevision) {
      return;
    }
    final text = normalizedLineEndings(content);
    if (text == _currentText) return;
    // Mute the programmatic change like _load does: the listener returns
    // before the revision bump and the save schedule.
    _loading = true;
    // The buffer adopts the disk's text.
    _surface?.replaceAll(text);
    _lastSavedRevision = _revision;
    // Text taken from disk again: edits from here on are a new session.
    _editSession = ++_editSessions;
    _log.debug('edit session $_editSession: $path (adopted disk text)');
    _noteKind = frontmatterTypeOf(text);
    widget.spellCheck?.reset();
    _loading = false;
    _unsaved?.noteChanged();
    widget.onNoteKindChanged?.call(_noteKind);
    _refreshStats();
    _refreshPreview();
    if (mounted) setState(() {});
    _log.info('note reloaded: $path (external change, ${text.length} chars)');
  }

  /// The note changed, from either source pane: the text, and where the caret
  /// is
  /// in it (a line, which is what the preview's sync speaks in).
  ///
  /// The surface reports the pair through `onChanged` and `onSelection`, and
  /// everything downstream — the save debounce, the unsaved marker, the
  /// statistics, the preview text — is one code path for every mode.
  void _noteChanged({required int caretLine, SourceEdit? edit}) {
    if (edit != null) {
      // Before the revision moves: the count follows the edit's own lines,
      // which is the whole point of keeping it per line.
      _surface?.words.edited(edit, _surface!.buffer);
    }
    _revision++;
    _unsaved?.noteChanged();
    _caretLine = caretLine;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _save);
    _statsTimer?.cancel();
    _statsTimer = Timer(_statsDelay, _refreshStats);
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 500), _refreshPreview);
  }

  /// Where the caret is, in the preview's own terms.
  int _caretLine = 0;

  void _refreshPreview() {
    if (!mounted || _loading) return;
    if (!_previewIn(widget)) {
      // The read pane is off stage behind the source pane, and bringing it up
      // to date means re-reading and re-parsing the whole note: done when it
      // is shown, not every time the writer pauses.
      _previewStale = true;
      return;
    }
    final live = _surface?.buffer;
    if (live == null) return;
    // The editor's own lines, by revision: no text joined, no text compared.
    if (identical(live, _previewOf) && live.revision == _previewRevision) {
      return;
    }
    setState(() {
      _previewOf = live;
      _previewRevision = live.revision;
    });
  }

  /// Flips between the source editor and the WYSIWYG surface (T-WYS-12);
  /// the owner persists it and refreshes the shell.
  void _toggleEditorKind() {
    final next = widget.showWysiwyg ? EditorKind.source : EditorKind.wysiwyg;
    widget.onEditorKindChanged?.call(next);
  }

  /// Whether only the preview is on screen (the editor hidden): the IME
  /// has no editable target, so it must go.
  bool get _previewOnly => _previewIn(widget);

  /// Whether [view] shows its preview. In Zen (#69) too: a note read
  /// rather than written is read there in its preview (0.0.8 test round).
  static bool _previewIn(NoteView view) => view.showPreview;

  /// Dismisses the keyboard when the preview is the only pane: a note
  /// opening in preview, or the switch flipping to it, must not leave
  /// the IME up over a pane with nothing editable.
  void _dismissKeyboardForPreview() {
    if (!_previewOnly) return;
    FocusManager.instance.primaryFocus?.unfocus();
    // The read pane takes the keyboard instead, for the keys a page is read
    // with (the arrows, the page keys, Home and End); a tab behind another
    // leaves it where it is.
    if (!widget.active) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _previewOnly && widget.active) {
        _readViewKey.currentState?.focus();
      }
    });
  }

  /// The editor pane: the unified surface, in `source` or `live`.
  Widget _editorPane() => _unifiedSurfacePane();

  /// The editor pane as the unified surface (#245, #246).
  ///
  /// The same widget the read mode's engine is built from, in one of its
  /// modes:
  /// `source` is the note as written, `live` is the same note with the
  /// markers hidden and the caret's own revealed — the WYSIWYG the phase 4
  /// round is about. Both hold the caret, the motions, the undo history and
  /// the windowing, and both report the text and the caret line through
  /// [_noteChanged] — so saving, the preview and the statistics do not know
  /// which mode is on screen.
  Widget _unifiedSurfacePane() {
    var surface = _surface;
    if (surface == null) {
      final text = _currentText;
      surface = _surface = _surfaceFor(text);
      _unifiedText = text;
    }
    final buffer = surface.buffer;
    // At the *note* text size, as the preview is (T-M6-12): without this the
    // surface drew the note at the interface size, so the note's size setting
    // did nothing. The find bar above it keeps the interface's.
    final note = MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: noteTextScalerOf(context)),
      child: MarkdownSurface(
        viewKey: _sourceViewKey,
        buffer: buffer,
        surface: surface,
        // The shell's own focus node: the phone toolbar, the format keys,
        // save-on-blur and the refocus when the preview goes all ask *it*
        // whether the editor has the focus.
        focusNode: _focus,
        mode: _unifiedMode,
        // Its metrics at the note's size: this context is above the scaler
        // set just around the surface.
        theme: markdownThemeOf(context, scaler: noteTextScalerOf(context)),
        showLineNumbers: widget.showLineNumbers && !widget.zen,
        caretWidth: widget.zen ? zenCaretWidth : null,
        typewriter: widget.typewriter,
        // The keyboard-on-open setting, and a template `{{cursor}}` landing,
        // which always takes the focus (#53).
        autofocus: widget.autofocusEditor || widget.initialCaretOffset != null,
        indentWidth: widget.indentWidth,
        column: widget.noteColumn,
        formatMenu: _formatMenu,
        editorMenu: _editorMenu,
        spellCheck: widget.spellCheck,
        activeItems: _activeFormats,
        // What `live` draws in place of the source it hides: the formulas
        // and pictures the read view draws, from the same cache and disk.
        mathCache: _mathCache,
        embedResolver: _resolveEmbed,
        findMatches: _sourceFind,
        onOpenLink: (kind, raw) => unawaited(_openLinkToken(kind, raw)),
        onChanged: (edit) {
          _sourceFind.noteEdited();
          _noteChanged(caretLine: _surfaceCaretLine ?? _caretLine, edit: edit);
        },
        onSelection: (selection) {
          _surfaceCaretLine = buffer.lineOf(selection.extent) + 1;
        },
      ),
    );
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _sourceFindKey,
      child: Column(
        children: <Widget>[
          ListenableBuilder(
            listenable: _sourceFind,
            builder: (context, _) => FindBar(
              controller: _sourceFind,
              column: widget.noteColumn,
              keyPrefix: 'source',
            ),
          ),
          Expanded(child: note),
        ],
      ),
    );
  }

  /// The find keys, for the note and its bar: Ctrl+F finds, Ctrl+H and
  /// Ctrl+Alt+F replace, F3 and Shift+F3 walk the matches, Escape closes the
  /// bar.
  ///
  /// A key handler rather than shortcuts, so that a key it has nothing to do
  /// with — Escape with the bar closed — goes on to the shell.
  KeyEventResult _sourceFindKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    bool pressed(SingleActivator key) => key.accepts(event, keyboard);
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    final find = SingleActivator(
      LogicalKeyboardKey.keyF,
      control: !mac,
      meta: mac,
    );
    final replace = SingleActivator(
      LogicalKeyboardKey.keyF,
      control: !mac,
      meta: mac,
      alt: true,
    );
    if (pressed(replace) ||
        (!mac &&
            pressed(
              const SingleActivator(LogicalKeyboardKey.keyH, control: true),
            ))) {
      _sourceFind.open(replace: true);
      return KeyEventResult.handled;
    }
    if (pressed(find)) {
      _sourceFind.open();
      return KeyEventResult.handled;
    }
    if (!_sourceFind.visible) return KeyEventResult.ignored;
    if (pressed(const SingleActivator(LogicalKeyboardKey.f3))) {
      _sourceFind.nextMatch();
      return KeyEventResult.handled;
    }
    if (pressed(const SingleActivator(LogicalKeyboardKey.f3, shift: true))) {
      _sourceFind.previousMatch();
      return KeyEventResult.handled;
    }
    if (pressed(const SingleActivator(LogicalKeyboardKey.escape))) {
      _sourceFind.close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The line the unified surface's caret is on (1-based), or null before it
  /// has
  /// reported one.
  int? _surfaceCaretLine;

  /// The preview, at the *note* text size rather than the interface one
  /// (T-M6-12).
  ///
  /// The app root put the interface scale on every MediaQuery below it;
  /// here it is replaced, so the same note reads the same size whichever
  /// pane shows it.
  Widget _buildPreview(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: noteTextScalerOf(context)),
    child: _buildUnifiedPreview(context),
  );

  /// The unified surface's read mode: one engine, the same theme as the editor
  /// (docs/dev/unified-surface.md).
  Widget _buildUnifiedPreview(BuildContext context) => MarkdownReadView(
    key: _readViewKey,
    buffer: _unifiedSource,
    parser: _unifiedParser,
    mathCache: _mathCache,
    controller: _previewScroll,
    onTapLink: (text, href) =>
        unawaited(openHref(context, href ?? '', _linkTargets)),
    onTapWikiLink: (span) => unawaited(
      // The same rule the masker and the preview use, so a wikilink means one
      // thing however it is drawn.
      openWiki(context, parseWikiRef(span.text), _linkTargets),
    ),
    embedResolver: _resolveEmbed,
    column: widget.noteColumn,
    // The editor's numbers' room, kept so the text does not move at a flip.
    lineNumbers: widget.showLineNumbers && !widget.zen,
    knownScan: _editorScanOf,
    onToggleTask: _toggleTaskFromRead,
  );

  /// Ticks or unticks the task item on [line] of the note the read pane is
  /// showing: an edit to the note itself, through the editor's own door —
  /// one undo step, saved like any other — and the pane shown the note as
  /// it now is at once, rather than when the preview's debounce comes round.
  ///
  /// Only when the pane shows the editor's note as it is: its lines are a
  /// snapshot, and a line number of an older one is not this note's.
  void _toggleTaskFromRead(int line) {
    final surface = _surface;
    final from = _snapshotFrom;
    if (surface == null ||
        from == null ||
        !identical(from, surface.buffer) ||
        from.revision != _snapshotRevision ||
        line >= from.lineCount) {
      return;
    }
    for (final token in surface.tokensOf(line)) {
      if (token.kind != TokenKind.taskBox) continue;
      final at = from.offsetOfLine(line) + token.start + 1;
      final ticked = from.lineAt(line).codeUnitAt(token.start + 1) != 0x20;
      surface.replaceRange(
        at,
        at + 1,
        ticked ? ' ' : 'x',
        caret: surface.selection,
      );
      _refreshPreview();
      return;
    }
  }

  /// The blocks and definitions of [buffer] as the source pane already holds
  /// them, when [buffer] is the snapshot of its note at the revision the pane
  /// has read — or null, and the read pane scans for itself.
  ///
  /// One reading of the note for both panes: the editor keeps its own current
  /// edit by edit, and scanning the snapshot again was 3.3 s in an isolate on
  /// a 246 MB note, after holding the frame that opened the pane to hand the
  /// note over.
  DocumentScan? _editorScanOf(SourceBuffer buffer) {
    final from = _snapshotFrom;
    if (!_bufferIsSnapshot ||
        !identical(buffer, _unifiedBuffer) ||
        from == null ||
        from.revision != _snapshotRevision) {
      return null;
    }
    final editor = _sourceViewKey.currentState;
    if (editor == null || !identical(editor.widget.buffer, from)) return null;
    final scan = editor.handOver();
    if (scan == null || scan.revision != from.revision) return null;
    // The same lines, in a buffer of their own: the definitions are read
    // against it from now on.
    return DocumentScan(
      blocks: scan.blocks,
      scope: scan.scope.on(buffer, buffer.revision),
      revision: buffer.revision,
      changes: scan.changes,
    );
  }

  /// Resolves an `![[…]]` embed: library-root-relative first (the
  /// attachments/assets layout), then relative to the note's own folder,
  /// then by unique name through the link index (`![[foo.png]]` resolving
  /// to `Attachments/foo.png`, the Obsidian layout).
  Future<String?> _resolveEmbed(String target) async {
    final root = widget.libraryRoot;
    if (root == null || target.isEmpty) return null;
    var candidate = File(p.join(root, target));
    if (candidate.existsSync()) return candidate.path;
    candidate = File(p.join(p.dirname(widget.path), target));
    if (candidate.existsSync()) return candidate.path;
    final source = widget.linkSource;
    if (source == null) return null;
    final resolved = await source.resolveWiki(target);
    if (resolved is ResolvedNote) {
      final viaIndex = File(p.join(root, resolved.note.path));
      if (viaIndex.existsSync()) return viaIndex.path;
    }
    return null;
  }

  /// Opens a link token's target: [raw] is the token as written, `[[…]]` for
  /// a wikilink and `[…](…)` for a Markdown link.
  Future<void> _openLinkToken(TokenKind kind, String raw) async {
    if (kind == TokenKind.wikilink) {
      await openWiki(
        context,
        parseWikiRef(raw.substring(2, raw.length - 2)),
        _linkTargets,
      );
    } else {
      final close = raw.indexOf(']');
      final href = close < 0 ? '' : raw.substring(close + 2, raw.length - 1);
      await openHref(context, href, _linkTargets);
    }
  }

  /// T-M2-09: pick an image, copy it into the library's attachments
  /// folder, insert a library-relative link at the caret — in the
  /// library's link format (wikilink embed or Markdown image).
  Future<void> _insertImage() async {
    final root = widget.libraryRoot;
    if (root == null) return;
    final source = await (widget.pickImagePath?.call() ?? _pickImageFile());
    if (source == null || !mounted) return;
    final relative =
        await (widget.importImage?.call(root, source) ??
            importImageToLibrary(
              libraryRoot: root,
              sourcePath: source,
              attachmentsFolder: widget.attachmentsFolder,
            ));
    if (!mounted) return;
    // Alt text comes from the picked file's name; the link itself is the
    // content-addressed library path, so `photo.png` keeps a readable label.
    final label = p.basenameWithoutExtension(source);
    final snippet = attachmentEmbed(
      relativePath: relative,
      label: label,
      linkType: widget.linkType,
    );
    _surface?.replaceSelection(snippet);
    _focus.requestFocus();
    _refreshStats();
    _refreshPreview();
  }

  Future<String?> _pickImageFile() async {
    // Picker returns [] when canceled: static API (v12).
    final result = await FilePicker.pickFiles(type: FileType.image);
    final file = result.isEmpty ? null : result.first;
    return file?.path;
  }

  /// Refreshes the word count and the outline (T-M2-07).
  ///
  /// Neither reads the note any more, which is what this used to cost: the
  /// statistics joined the whole text (190 ms on the 246 MB note), compared
  /// it to the last one for equality, copied it to an isolate and walked it
  /// twice there (1.2 s). Now the count is kept by the edits
  /// ([MarkdownSurfaceController.words]) and the outline is read off the
  /// blocks the styling is already drawn from, so this is O(blocks) at
  /// worst — and the frontmatter check, which only ever wanted the leading
  /// block, gets the note's first lines rather than the whole note.
  void _refreshStats() {
    if (!mounted || _loading) return;
    final surface = _surface;
    if (surface != null) {
      // The surface counts its own words as it is edited. A note whose
      // count is not there yet (a big one, counted in the background) keeps
      // the count it has and takes the next refresh's.
      final revision = surface.revision;
      if (revision == _unifiedStatsRevision && surface.words.isCounted) return;
      final counted = surface.words.isCounted ? surface.words.words : null;
      final headings = _outlineNow(surface);
      // The pane's scan may still be carrying on an edit that changed the rest
      // of the note, and the outline is the whole note's: this revision is not
      // done until it lands, so the refresh asks again rather than keeping
      // the outline from before the edit for as long as nobody types.
      if (_sourceViewKey.currentState?.scanSettled ?? true) {
        _unifiedStatsRevision = revision;
      } else {
        _statsTimer?.cancel();
        _statsTimer = Timer(_statsDelay, _refreshStats);
      }
      final frontmatter = _frontmatterErrorOf(surface.buffer);
      setState(() {
        if (counted != null) _wordCount = counted;
        if (headings != null) _outline = headings;
        _frontmatterError = frontmatter;
      });
      if (headings != null) _outlineNotifier.value = _outline;
      // Nothing else asks again once the count lands: a note nobody types
      // in would keep showing none.
      if (!surface.words.isCounted) {
        unawaited(surface.buildWords().then((_) => _statsAgain(surface)));
      }
    }
  }

  /// Refreshes the statistics once [surface]'s count has landed, if it is
  /// still the note on screen.
  void _statsAgain(MarkdownSurfaceController surface) {
    if (!mounted || !identical(_surface, surface)) return;
    if (!surface.words.isCounted) return;
    _unifiedStatsRevision = -1;
    _refreshStats();
  }

  /// The note's headings, from a scan something already paid for, or worked
  /// out here for a note small enough to walk now.
  ///
  /// The source pane's own reading of the blocks, the read pane's — scanned
  /// for the page — or the surface's, for a note whose pane is hidden or has
  /// not scanned yet. The first three cost nothing; the last is
  /// [outlineOfText] over the note's text, which is why it is behind
  /// [_syncWorkLimit] and nothing larger takes it.
  List<OutlineEntry>? _outlineNow(MarkdownSurfaceController? surface) {
    final source = _sourceViewKey.currentState;
    if (source != null) {
      final headings = source.headings;
      if (headings != null) return headings;
    }
    final read = _readViewKey.currentState;
    if (read != null) {
      final headings = read.headings;
      if (headings != null) return headings;
    }
    final scanned = surface?.headings;
    if (scanned != null) return scanned;
    if (surface == null) return null;
    // Nothing has scanned this note yet — a note just opened, or one whose
    // pane is off stage — and only a small one may be walked for its
    // headings here. A big one keeps the outline it has until a pane's own
    // scan lands ([_refreshStats] asks again).
    if (surface.buffer.length > _syncWorkLimit) return null;
    return outlineOfBlocks(
      BlockIndex(
        blocks: BlockScanner(surface.buffer).index.blocks,
        revision: surface.revision,
      ),
      surface.buffer.lineAt,
    );
  }

  /// The frontmatter's error, from the note's first lines only.
  ///
  /// [frontmatterErrorIn] reads the leading block and stops; a note's
  /// frontmatter is its first handful of lines, so it is handed those
  /// rather than the joined note.
  String? _frontmatterErrorOf(SourceBuffer buffer) {
    if (buffer.lineCount == 0) return null;
    final buffer0 = StringBuffer();
    for (
      var line = 0;
      line < buffer.lineCount && buffer0.length < _frontmatterLookahead;
      line++
    ) {
      buffer0
        ..write(buffer.lineAt(line))
        ..write(buffer.terminatorAt(line));
    }
    return frontmatterErrorIn(buffer0.toString());
  }

  /// How much of a note's head the frontmatter check is given.
  static const int _frontmatterLookahead = 8 * 1024;

  static const int _syncWorkLimit = 64 * 1024;

  ///
  /// They read the whole note — joined, sent to an isolate, scanned — so a
  /// note of hundreds of megabytes waits for a real pause rather than for
  /// every breath between words (0.0.9 stress test: a 246 MB note paid 12 s
  /// of isolate time after each one).
  Duration get _statsDelay {
    final override = NoteView.statsDelayOverride;
    if (override != null) return override;
    final length = _noteLength;
    if (length > 16 << 20) return const Duration(seconds: 5);
    if (length > 2 << 20) return const Duration(seconds: 2);
    return const Duration(milliseconds: 350);
  }

  /// How long after the last edit the note is saved.
  ///
  /// Half a second, or a second while a save is in flight (typing fast: one
  /// trailing save, not a queue). A note that size waits for a real pause, as
  /// the statistics do: the save no longer stalls the frames — it goes over
  /// in slices (see [_performSave]) — but it is still a write of hundreds of
  /// megabytes, and there is no reason to make one for every breath between
  /// words.
  Duration get _saveDelay {
    final length = _noteLength;
    if (length > 16 << 20) return const Duration(seconds: 5);
    if (length > 2 << 20) return const Duration(seconds: 2);
    return _saving
        ? const Duration(seconds: 1)
        : const Duration(milliseconds: 500);
  }

  /// The note's length, without joining it.
  int get _noteLength => _surface?.buffer.length ?? 0;

  /// Records what the note's file looks like now, for [_unchangedOnDisk].
  ///
  /// Best effort: a file that cannot be stat'ed (gone, or on a filesystem
  /// that will not answer) records nothing, and the next reload reads and
  /// compares the way it always did.
  void _recordDiskStat(String path) => _diskStat = DiskStamp.of(path);

  /// Whether the file at [path] is the one [_diskStat] recorded.
  ///
  /// A file that cannot be stat'ed, or one nothing recorded, is read: the
  /// fallback is the comparison this stands in front of.
  bool _unchangedOnDisk(String path) => _diskStat?.matches(path) ?? false;

  /// Opens the outline sheet and jumps to whatever was picked.
  Future<void> _openOutline() async {
    final line = await showOutlineSheet(context, entries: _outline);
    if (line == null || !mounted) return;
    _jumpToHeading(line);
  }

  /// The outline jump: caret to the heading line, then bring it into view.
  ///
  /// When the preview is visible (phone switch mode) the editor caret is
  /// off-screen — the preview is brought to the heading's block as well,
  /// so the jump is visible in every layout.
  void _jumpToHeading(int line) {
    const AppLogger(name: 'links').debug('jump to source line $line');
    _surface?.jumpToLine(line);
    _syncPreviewToLine(line);
  }

  /// Scrolls the read pane so the block starting at source [line] is in
  /// view (no-op when the read pane is hidden or not built yet).
  void _syncPreviewToLine(int line) {
    if (!_previewIn(widget) || !mounted) return;
    const log = AppLogger(name: 'links');
    // The read mode's own answer: the line resolves to a block and the
    // block to its offset in the height map, measured where a frame has
    // drawn and estimated where none has (#256).
    final state = _readViewKey.currentState;
    if (state == null) {
      log.debug('anchor jump: the read view is not built yet — skipped');
      return;
    }
    log.debug('anchor jump: read mode, source line $line');
    state.jumpToLine(line);
  }

  /// What following a link from this note needs (issue #100 moved the
  /// following itself into `note_links.dart`).
  NoteLinkTargets get _linkTargets => NoteLinkTargets(
    source: widget.linkSource,
    notePath: widget.path,
    libraryRoot: widget.libraryRoot,
    missingNoteLocation: widget.missingNoteLocation,
    outline: _outline,
    jumpToHeading: _jumpToHeading,
    onOpenNote: widget.onOpenNote,
    createMissingNote: widget.createMissingNote,
    folderExists: widget.folderExists,
  );

  void _onFocusChanged() {
    if (!_focus.hasFocus) unawaited(_save());
    _onToolbarFocusChanged();
  }

  /// The phone's formatting toolbar shows only while the keyboard is up,
  /// so a focus change repaints it; the desktop's top toolbar never rides
  /// the keyboard and does not repaint for it.
  void _onToolbarFocusChanged() {
    if (mounted && !widget.toolbarTop) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.info('lifecycle: ${state.name}');
    if (state == AppLifecycleState.paused) unawaited(_save());
    // Leaving the foreground may be the last thing this process does.
    if (state != AppLifecycleState.resumed && widget.active) {
      _mementoTimer?.cancel();
      _handMemento(widget.path);
    }
  }

  /// Restarts the countdown to handing in the showing note's memento.
  void _scheduleMemento() {
    if (widget.onMemento == null || !widget.active || !_ready) return;
    _mementoTimer?.cancel();
    _mementoTimer = Timer(_mementoDelay, () {
      if (mounted) _handMemento(widget.path);
    });
  }

  /// Saves the buffer at most once: a request that finds a save in flight
  /// coalesces into one trailing save (the text is re-read from the buffer
  /// at that point, so nothing is lost) and returns the write already
  /// running, so an awaiting caller still learns when the disk moved.
  Future<void> _save({String? path}) {
    // Until the note at widget.path is loaded, the buffer is not its text:
    // it is the previous note's, or nothing — and when the load failed,
    // widget.path may be a picture. Only a save with its own path (the
    // outgoing note's) may write then (#156).
    if (path == null && !_ready) return Future<void>.value();
    final revision = _revision;
    if (revision == _lastSavedRevision) {
      return Future<void>.value(); // nothing new on disk
    }
    if (path == null && _saving) {
      _savePending = true;
      return _activeSave ?? Future<void>.value();
    }
    _saving = true;
    final future = _performSave(revision, path ?? widget.path);
    _activeSave = future;
    return future;
  }

  /// The actual write for [_save]; a write error reaches every caller
  /// awaiting the returned future.
  ///
  /// On the unified surface the note is handed over in slices and never
  /// joined whole: the join and the encode of a 246 MB note cost the UI
  /// isolate 300–530 ms in one go (see `docs/dev/huge-notes.md`), and both
  /// are cut here into turns of a few milliseconds that leave the frames
  /// their gaps. A note with no streaming writer (a note outside a library, a
  /// test) is joined and saved whole.
  Future<void> _performSave(int revision, String target) async {
    final clock = Stopwatch()..start();
    final stream = _takeStreamSave();
    if (stream != null) {
      unawaited(_saveStreamed(stream, revision, target, clock));
      return;
    }
    // The full-text join (O(n)) happens here only — the save path, never
    // the keystroke path.
    final joinClock = Stopwatch()..start();
    final text = _currentText;
    final joinMs = joinClock.elapsedMilliseconds;
    // Read with the text, before the first await: a note switch that
    // saves the outgoing note is followed by a _load that starts the next
    // session, and this save belongs to the one it came from.
    final session = _editSession;
    _log.info(
      'save start: $target (${text.length} chars, join $joinMs ms, '
      'session $session)',
    );
    try {
      await _write(target, text, session);
      if (target == widget.path) {
        _lastSavedRevision = revision;
        _recordDiskStat(target);
        _unsaved?.noteChanged();
      }
      _log.info(
        'note saved: $target (${text.length} chars, '
        '${clock.elapsedMilliseconds} ms)',
      );
    } finally {
      _finishSave();
    }
  }

  /// Saves with the note handed over in slices, off the join.
  ///
  /// The write is away from this isolate, so this only awaits it — after
  /// reading the trailing-save flag the write's own edits may have set,
  /// which is what keeps an edit that landed mid-save from being the one
  /// nobody writes.
  Future<void> _saveStreamed(
    _StreamSave stream,
    int revision,
    String target,
    Stopwatch clock,
  ) async {
    final buffer = stream.buffer;
    // Read with the buffer, before the first await: a note switch that
    // saves the outgoing note is followed by a _load that starts the next
    // session, and this save belongs to the one it came from.
    final session = _editSession;
    _log.info(
      'save start: $target (${buffer.length} chars in '
      '${stream.slices} slices, session $session)',
    );
    try {
      await widget.saveNoteStream!(
        target,
        (index) => _nextSlice(stream, index),
        editSession: session,
      );
      if (target == widget.path) {
        _lastSavedRevision = revision;
        _recordDiskStat(target);
        _unsaved?.noteChanged();
      }
      _log.info(
        'note saved: $target (${buffer.length} chars, '
        '${clock.elapsedMilliseconds} ms)',
      );
    } on Object catch (error) {
      _log.error('note save failed: $target ($error)');
      rethrow;
    } finally {
      _finishSave();
    }
  }

  /// The save is over, however it ended: the flag goes, the pane repaints,
  /// and a save that arrived meanwhile runs its own turn.
  void _finishSave() {
    _saving = false;
    final trailing = _savePending;
    _savePending = false;
    if (mounted) setState(() {});
    if (trailing) unawaited(_save());
  }

  /// The note as this save will write it, or null when there is nothing to
  /// stream (no seam, no unified buffer, an empty note).
  ///
  /// The buffer is taken whole — a copy of the two line lists, O(lines) of
  /// pointers, the strings themselves shared — so an edit that lands
  /// between two slices cannot make the note it writes a different note
  /// from the one it started. It is what a save of a note being typed in
  /// has to be: the writer's own text at one moment, never half of one and
  /// half of another.
  _StreamSave? _takeStreamSave() {
    if (widget.saveNoteStream == null) return null;
    final buffer = _unifiedSurfaceBuffer;
    if (buffer == null || buffer.lineCount == 0) {
      return null;
    }
    return _StreamSave(buffer.snapshot());
  }

  /// The next slice of [stream]'s buffer, or null when the note is out.
  ///
  /// Each slice is built and encoded here, on the UI isolate, because that
  /// is where the note's strings are — a string is copied between
  /// isolates, never shared, and one copy of the whole note is what this
  /// exists to avoid. Each is small enough that the frame after it is on
  /// time.
  Future<NoteBytes?> _nextSlice(_StreamSave stream, int index) async {
    final first = index * kSaveSliceLines;
    if (first >= stream.buffer.lineCount) return null;
    final text = stream.buffer.sliceText(
      first,
      first + kSaveSliceLines,
      kSaveSliceChars,
    );
    // Building the first slice is what starts the save; the gap the frames
    // need is the one after it, not before it.
    if (index > 0) await Future<void>.delayed(Duration.zero);
    return utf8.encode(text);
  }

  /// Lines one slice of a streaming save asks for, and the character count
  /// that cuts it short — a note of very long lines would otherwise build
  /// a slice of megabytes. Around four milliseconds of join and encode per
  /// slice at these figures, measured on the 2.7 M-line fixture.
  static const int kSaveSliceLines = 16384;
  static const int kSaveSliceChars = 4 << 20;

  /// The close guard's save (T-PP-11): writes until the disk holds the
  /// latest revision — waiting out a save that was already in flight — and
  /// completes with the write's error when one fails. The caller keeps the
  /// window open on a failure: the edits are still only in the buffer.
  Future<void> _saveForClose() async {
    while (_revision != _lastSavedRevision) {
      await _save();
    }
  }

  /// Spelling results changed (the note loaded, or a settings toggle): the
  /// pane is drawn again with the new ranges.
  void _onSpellCheckChanged() {
    if (mounted) setState(() {});
  }

  /// Opens the spelling review panel (T-PP-09).
  Future<void> _openSpellCheck() async {
    final spell = widget.spellCheck;
    if (spell == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SpellCheckSheet(
        start: _scanSpelling,
        suggest: spell.suggestionsFor,
        apply: _applySpelling,
        available: spell.available,
      ),
    );
    if (mounted) setState(() {});
  }

  /// A pass over the whole note, in reading order (the panel's), reading
  /// each line — and tokenizing it for what to skip — only as the pass
  /// gets to it (#61).
  SpellScan _scanSpelling() {
    final spell = widget.spellCheck!;
    final surface = _surface;
    if (surface == null) {
      return spell.startScan(lineCount: 0, lineAt: (_) => (text: '', skip: []));
    }
    // The surface's own lines, and its own tokenizer's runs: code, maths,
    // links and markers are skipped as they are in the underline.
    final buffer = surface.buffer;
    return spell.startScan(
      lineCount: buffer.lineCount,
      lineAt: (i) =>
          (text: buffer.lineAt(i), skip: spellSkipRanges(surface.tokensOf(i))),
    );
  }

  /// Replaces one issue's word in the controller (the panel's fix).
  void _applySpelling(SpellIssue issue, String replacement) {
    final surface = _surface;
    if (surface == null) return;
    final buffer = surface.buffer;
    if (issue.line >= buffer.lineCount) return;
    final start = buffer.offsetOfLine(issue.line);
    surface.replaceRange(start + issue.start, start + issue.end, replacement);
  }

  String get _status {
    if (_error != null) return AppStrings.noteStatusError;
    if (_loading) return AppStrings.noteStatusLoading;
    if (_saving) return AppStrings.noteStatusSaving;
    if (_revision != _lastSavedRevision) return AppStrings.noteStatusUnsaved;
    return AppStrings.noteStatusSaved;
  }

  /// A kind GUI's byte-stable edit: the buffer takes the new text (the
  /// highlighter, stats and preview follow it as with any edit) and the
  /// note is saved immediately.
  void _applyKindEdit(String newText) {
    final surface = _surface;
    if (surface != null && newText != _unifiedText) {
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
    setState(() {});
    unawaited(_save());
  }

  /// The formatting keys (#205), applied through the toolbar's own
  /// actions for whichever surface is showing.
  late final EditorFormatKeys _formatKeys = EditorFormatKeys(
    actions: _toolbarActions,
    active: () => mounted && _keyboardUp,
  );

  /// Whether the editor on screen holds the focus — the phone's proxy for
  /// "the keyboard is up": the formatting toolbar shows only while the
  /// keyboard is up (it is the keyboard's row, and in preview there is
  /// nothing to format), so it rides this focus.
  bool get _keyboardUp => _focus.hasFocus;

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final showPreview = _previewIn(widget);
    // The toolbar formats the editor: it hides while the preview holds
    // the pane, which has nothing to format. On the phone it also rides
    // the keyboard (it shows only while the keyboard is up); on desktop
    // it never does.
    // Hiding every button hides the toolbar itself; the editor keeps its
    // keyboard shortcuts.
    final showToolbar =
        !showPreview &&
        (widget.toolbarTop || _keyboardUp) &&
        widget.toolbarLayout.visible.isNotEmpty;
    // Kind mode (T-TK-02): a known `type` swaps the body for the kind GUI
    // and hides the editor chrome (outline, status row, toolbar) — the
    // note is a list, not a document, on screen.
    final kindGui = _noteKind == null ? null : NoteKinds.forType(_noteKind);
    final kindBody = widget.kindMode && kindGui != null;
    // A list or a voice note keeps to the note column like text does
    // (0.0.8 test round): the column is the app's shape, not the editor's.
    final kindChild = kindBody
        ? NoteColumnPadding(
            column: widget.noteColumn,
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
            column: widget.noteColumn,
            toolbar: showToolbar && !kindBody && !_loading && error == null
                ? _toolbar(context, dense: true)
                : null,
            actions: widget.barActions,
          ),
        Expanded(
          child: error == null
              ? (!_ready || _loading
                    ? const Center(child: CircularProgressIndicator())
                    : kindBody
                    ? kindChild!
                    // Both panes stay mounted and only one is on stage:
                    // coming back to the preview finds its parse, scroll
                    // offset, typeset math and images where they were
                    // (device report, 2026-09-11: every return re-parsed
                    // the note and restarted from the top). Offstage
                    // children skip hit testing, painting and the default
                    // finders; the panes never show together.
                    : Stack(
                        children: [
                          Offstage(
                            offstage: showPreview,
                            child: KeyedSubtree(
                              key: ValueKey(
                                widget.showWysiwyg
                                    ? 'pane-wysiwyg'
                                    : 'pane-editor',
                              ),
                              child: _editorPane(),
                            ),
                          ),
                          Offstage(
                            offstage: !showPreview,
                            child: KeyedSubtree(
                              key: const ValueKey('pane-preview'),
                              child: _buildPreview(context),
                            ),
                          ),
                        ],
                      ))
              : NoteLoadError(
                  message: error,
                  path: widget.path,
                  offerDefaultApp: _notText,
                ),
        ),
        if (!kindBody && !widget.zen) ...[
          SafeArea(
            // The bottom chrome only: top stays false so the status-bar
            // inset is never inserted between the preview and this row
            // (issue #3: that gap read as empty space above the toolbar).
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_loading && _frontmatterError != null)
                  FrontmatterWarningBanner(message: _frontmatterError!),
                NoteColumnPadding(
                  column: widget.noteColumn,
                  child: NoteStatusRow(
                    loading: _loading,
                    showPreview: showPreview,
                    showWysiwyg: widget.showWysiwyg,
                    spellCheckAvailable:
                        widget.spellCheck != null &&
                        widget.spellCheck!.available,
                    canSwitchEditorKind: widget.onEditorKindChanged != null,
                    wordCount: _wordCount,
                    statusText: _status,
                    statusActions: widget.statusActions,
                    onOutline: _openOutline,
                    onFind: () => _sourceFind.open(),
                    onSpellCheck: _openSpellCheck,
                    onToggleEditorKind: _toggleEditorKind,
                    typewriter: widget.typewriter,
                    onToggleTypewriter: widget.onToggleTypewriter,
                  ),
                ),
                // The toolbar fades + sizes in and out (hidden in preview
                // mode). It is only mounted once loaded, so it appears
                // immediately on load and animates only when preview mode
                // toggles. Phone only: on desktop it lives above the
                // editor (the top slot).
                if (!widget.toolbarTop && !_loading)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: showToolbar
                        ? NoteColumnPadding(
                            column: widget.noteColumn,
                            child: _toolbar(context),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// The malformed-frontmatter line (T-M4-01).
  ///
  /// A block that does not parse is indexed as if it were not there —
  /// no title, no tags, no fields — and nothing else in the app would say
  /// so. This does, with the parser's own message, while the note is open
  /// and the mistake is still in front of the person who made it.
  /// The formatting toolbar (T-UI-08): pure markdown commands applied
  /// through the surface; the image button keeps the file-picker flow
  /// (T-M2-09) it already had in the status row.
  Widget _toolbar(BuildContext context, {bool dense = false}) {
    final actions = _toolbarActions();
    Widget bar(Set<ToolbarItem> active) => NoteToolbarBar(
      dense: dense,
      actions: actions,
      active: active,
      layout: widget.toolbarLayout,
    );
    // The surface publishes the formats at the caret into one notifier, read
    // off the caret's line, so a pressed button stays pressed until it is
    // toggled off (T-WYS-06, #246).
    return ValueListenableBuilder<Set<ToolbarItem>>(
      valueListenable: _activeFormats,
      builder: (context, active, _) => bar(active),
    );
  }

  /// What each toolbar button does. The catalogue and the order live in
  /// `editor/toolbar_item.dart`; the commands stay here, with the
  /// controller they act on.
  /// The toolbar's buttons as context-menu entries (#174): the same
  /// visible items in the same order, the same actions, and the same
  /// pressed state — read when the menu opens, so it is the caret's now.
  List<FormatMenuEntry> _formatMenu() {
    final actions = _toolbarActions();
    final active = _activeFormats.value;
    return [
      for (final item in widget.toolbarLayout.visible)
        if (actions[item] case final action?)
          FormatMenuEntry(
            item: item,
            onPressed: action,
            active: active.contains(item),
          ),
    ];
  }

  /// The unified surface's context menu, grouped (#260): read as it
  /// opens, so its lit entries are the caret's now.
  ContextMenuPart _editorMenu() {
    final surface = _surface;
    var level = 0;
    if (surface != null) {
      final buffer = surface.buffer;
      final line = buffer.lineOf(surface.selection.extent);
      final text = buffer.lineAt(line);
      while (level < text.length && level < 7 && text[level] == '#') {
        level++;
      }
      if (level > 6 || (level < text.length && text[level] != ' ')) level = 0;
    }
    return editorMenu(
      active: _activeFormats.value,
      headingLevel: level,
      run: _runCommand,
      onImage: _insertImage,
      onFootnote: _insertFootnote,
    );
  }

  /// A footnote cited at the caret, defined under its paragraph, numbered
  /// one past the note's highest (#260).
  void _insertFootnote() {
    final surface = _surface;
    if (surface != null) {
      final labels = _sourceViewKey.currentState?.footnoteLabels;
      final label = nextFootnoteLabel(labels ?? const <String>[]);
      // The caret's paragraph, as far as its first blank line: the lines
      // the definition goes under.
      final buffer = surface.buffer;
      final start = buffer.lineOf(surface.selection.extent);
      var last = start;
      while (last + 1 < buffer.lineCount &&
          last - start < _footnoteReach &&
          buffer.lineAt(last + 1).trim().isNotEmpty) {
        last++;
      }
      surface.applyLineCommand(
        (text, selection) =>
            insertFootnote(text: text, selection: selection, label: label),
        through: last + 1,
      );
      _focus.requestFocus();
    }
  }

  /// How far down a paragraph the footnote's definition is looked for a
  /// place under it: a paragraph longer than that has it here.
  static const int _footnoteReach = 2000;

  Map<ToolbarItem, VoidCallback> _toolbarActions() {
    return {
      ToolbarItem.bold: () => _wrapSelection(left: '**', right: '**'),
      ToolbarItem.italic: () => _wrapSelection(left: '*', right: '*'),
      ToolbarItem.strikethrough: () => _wrapSelection(left: '~~', right: '~~'),
      ToolbarItem.superscript: () =>
          _wrapSelection(left: '<sup>', right: '</sup>'),
      ToolbarItem.underline: () => _wrapSelection(left: '<u>', right: '</u>'),
      ToolbarItem.link: _insertLink,
      ToolbarItem.code: _insertCodeBlock,
      ToolbarItem.image: _insertImage,
      ToolbarItem.table: () => _runCommand(
        (text, selection) => insertTable(text: text, selection: selection),
        // The lines either side: the table keeps a blank line from them.
        context: 1,
      ),
      ToolbarItem.heading: _showHeadingDialog,
      ToolbarItem.list: () => _prefixLines(prefix: '- '),
      ToolbarItem.orderedList: _insertOrderedList,
      ToolbarItem.checklist: () => _runCommand(
        (text, selection) => toggleTaskList(text: text, selection: selection),
      ),
      ToolbarItem.quote: () => _prefixLines(prefix: '> '),
      ToolbarItem.outdent: () => _indentLines(outdent: true),
      ToolbarItem.indent: () => _indentLines(outdent: false),
      ToolbarItem.tools: () => unawaited(_openTools()),
    };
  }

  /// Opens the editor's Tools sheet (#136) and runs whatever was picked.
  ///
  /// The availability is worked out here rather than in the sheet: only
  /// this side knows which surface is showing, and each one finds its
  /// lists its own way.
  Future<void> _openTools() async {
    final tool = await showEditorToolsSheet(
      context,
      available: <EditorTool>{if (_hasListToCount) EditorTool.countList},
    );
    if (!mounted || tool == null) return;
    switch (tool) {
      case EditorTool.countList:
        await _countList();
    }
  }

  /// Whether the note has a list the count could run on.
  ///
  /// Asks the pane's own scan rather than reading the note: the tool sheet
  /// lists every tool and greys the ones that cannot run, so this used to
  /// join a 246 MB note and tokenize it every time the sheet opened
  /// (`tallyTargetsIn` builds a whole `HighlightDocument`). The scan is what
  /// the colours are drawn from, and it already knows a list item when it
  /// makes one (see `blockList`).
  bool get _hasListToCount {
    // The pane on screen has the note scanned; a hidden one does not, and
    // then the source pane's own copy is asked for its blocks rather than
    // the text being read again.
    final source = _sourceViewKey.currentState;
    final scanned = source?.blocks ?? _readViewKey.currentState?.blocks;
    final buffer = _unifiedSurfaceBuffer;
    if (scanned != null) return blockList(scanned);
    if (buffer != null) return blockList(BlockScanner(buffer).index.blocks);
    return blockList(scannedBlocksOf(_editText));
  }

  /// Counts a list into a checklist, on whichever surface is showing.
  Future<void> _countList() => _countListSource();

  Future<void> _countListSource() async {
    final text = _editText;
    final targets = tallyTargetsIn(text);
    if (targets.isEmpty) return;
    final here = tallyTargetAt(text, _editCaretLine);
    final choice = await showListTallySheet(
      context,
      candidates: <TallyCandidate>[
        for (final target in targets)
          TallyCandidate(
            rows: target.rows,
            checks: tallyChecksAt(text, target),
            replaces: target.replaces,
          ),
      ],
      initialIndex: here == null
          ? 0
          : targets.indexWhere((t) => t.sourceStart == here.sourceStart),
    );
    if (!mounted || choice == null) return;
    final target = targets[choice.index];
    _applyMarkdownEdit(
      applyTally(
        text: text,
        target: target,
        rows: tallyList(
          rows: target.rows,
          cut: choice.cut,
          sort: choice.sort,
          checked: tallyChecksAt(text, target),
        ),
      ),
    );
  }

  /// Applies a pure markdown command's result: the whole text is set
  /// (undoable) and the selection lands where the command put it — inside
  /// the markers for wraps, the same lines for line edits. The editor
  /// keeps its focus (the IME stays up); focus is re-requested
  /// defensively.
  void _applyMarkdownEdit(MarkdownEdit edit) {
    // Through the surface: one undoable edit, the platform told, the save
    // scheduled.
    _surface?.applyEdit(edit.text, edit.selection);
    _focus.requestFocus();
  }

  /// The source text a command works on.
  String get _editText => _unifiedText;

  /// Runs a Markdown [command] on the source pane on screen.
  ///
  /// It is handed the lines the selection touches, not the note
  /// ([MarkdownSurfaceController.applyLineCommand]).
  void _runCommand(
    MarkdownEdit Function(String text, TextSelection selection) command, {
    int context = 0,
  }) {
    _surface?.applyLineCommand(command, context: context);
    _focus.requestFocus();
  }

  /// The line the command's caret is on (0-based).
  int get _editCaretLine {
    final surface = _surface;
    if (surface == null) return 0;
    return surface.buffer.lineOf(surface.selection.anchor);
  }

  void _wrapSelection({required String left, required String right}) {
    _runCommand(
      (text, selection) => wrapSelection(
        text: text,
        selection: selection,
        left: left,
        right: right,
      ),
    );
  }

  void _insertCodeBlock() {
    _runCommand(
      (text, selection) => codeBlock(text: text, selection: selection),
    );
  }

  void _prefixLines({required String prefix}) {
    _runCommand(
      (text, selection) =>
          prefixLines(text: text, selection: selection, prefix: prefix),
    );
  }

  /// Inserts a link in the format chosen in settings (wikilink `[[…]]`
  /// or markdown `[…](…)`).
  void _insertLink() {
    final markdown = widget.linkType == LinkType.markdown;
    _runCommand(
      (text, selection) => wrapSelection(
        text: text,
        selection: selection,
        left: markdown ? '[' : '[[',
        right: markdown ? '](...)' : ']]',
      ),
    );
  }

  /// Numbers the selected line(s) as an ordered list.
  void _insertOrderedList() {
    _runCommand(
      (text, selection) => orderedList(text: text, selection: selection),
    );
  }

  /// Indents (or outdents, [outdent] true) the selected line(s) by the
  /// width chosen in settings.
  void _indentLines({required bool outdent}) {
    _runCommand(
      (text, selection) => indentLines(
        text: text,
        selection: selection,
        width: widget.indentWidth,
        outdent: outdent,
      ),
    );
  }

  /// Shows the heading-level picker (H1..H6) and applies the chosen level
  /// to the selected line(s).
  Future<void> _showHeadingDialog() async {
    final level = await showHeadingLevelDialog(context);
    if (level == null) return;
    _runCommand(
      (text, selection) =>
          setHeading(text: text, selection: selection, level: level),
    );
  }
}

/// What a streaming save holds of the note while it runs: the lines as they
/// were when the save started, which no later edit reaches.
final class _StreamSave {
  /// Saves [buffer]'s lines, slice by slice.
  const new(this.buffer);

  /// The note's lines, at the moment the save began.
  final SourceBuffer buffer;

  /// How many slices the save will hand over; for the log only.
  int get slices =>
      (buffer.lineCount + _NoteViewState.kSaveSliceLines - 1) ~/
      _NoteViewState.kSaveSliceLines;
}
