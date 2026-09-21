import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/frame_log.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart';
import 'package:niman/src/core/text_scale.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/editor_shortcuts.dart';
import 'package:niman/src/editor/editor_tool.dart';
import 'package:niman/src/editor/find_panel.dart';
import 'package:niman/src/editor/highlight_sync.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/list_tally.dart';
import 'package:niman/src/editor/list_tally_edit.dart';
import 'package:niman/src/editor/markdown_editing_controller.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/note_editor.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/editor/toolbar_layout.dart';
import 'package:niman/src/editor/typewriter_scroll.dart';
import 'package:niman/src/editor/wysiwyg/quill_editor_commands.dart';
import 'package:niman/src/editor/wysiwyg/quill_tally.dart';
import 'package:niman/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/frontmatter/parser.dart';
import 'package:niman/src/library/image_import.dart';
import 'package:niman/src/links/attachment_embed.dart';
import 'package:niman/src/links/missing_note_handler.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/editor_lines.dart';
import 'package:niman/src/preview/markdown_preview.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/preview/preview_work.dart';
import 'package:niman/src/preview/preview_work_failure.dart';
import 'package:niman/src/preview/scroll_map.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/spell_check_sheet.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';
import 'package:niman/src/ui/editor_preview_split.dart';
import 'package:niman/src/ui/editor_tools_sheet.dart';
import 'package:niman/src/ui/heading_level_sheet.dart';
import 'package:niman/src/ui/list_tally_sheet.dart';
import 'package:niman/src/ui/note_links.dart';
import 'package:niman/src/ui/note_load_error.dart';
import 'package:niman/src/ui/note_text_offsets.dart';
import 'package:niman/src/ui/note_top_bar.dart';
import 'package:niman/src/ui/note_view_adapters.dart';
import 'package:niman/src/ui/note_view_chrome.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/note_view_memento.dart';
import 'package:niman/src/ui/outline_panel.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/theme/tokens.dart';
import 'package:niman/src/ui/unsaved_notes.dart';
import 'package:niman/src/workspace/note_memento.dart';
import 'package:path/path.dart' as p;
import 'package:re_editor/re_editor.dart';

/// Saves [content] as the note at absolute [path]; [editSession] is the
/// editor session the save belongs to (one opening of the note).
typedef NoteSaver = Future<void> Function(
  String path,
  String content, {
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
/// passed through to the editor. T-M2-08: [splitPreview] resolves the layout
/// (true = editor|preview side by side, false = one full-screen pane with a
/// top switch); [splitFraction]/[onSplitFractionChanged]-[onSplitDragEnd]
/// drive the draggable divider and its persistence.
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
    this.splitPreview = false,
    this.showPreview = false,
    this.unifiedMarkdown = false,
    this.showWysiwyg = false,
    this.onWysiwygChanged,
    this.onEditorKindChanged,
    this.splitFraction = defaultSplitRatio,
    this.onSplitFractionChanged,
    this.onSplitDragEnd,
    this.libraryRoot,
    this.pickImagePath,
    this.importImage,
    this.readNote,
    this.writeNote,
    this.saveNote,
    this.controller,
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

  /// Whether the preview sits side by side (split) or behind a switch.
  final bool splitPreview;

  /// Preview visibility (T-UI-06): the shared app bar owns the switch
  /// and passes the state down; NoteView just follows it.
  final bool showPreview;

  /// Whether this note is drawn by the unified engine instead of the preview
  /// (docs/dev/unified-surface.md): one parse, one theme, three modes over the
  /// same pipeline. Off by default — the render has to be shown to agree with
  /// the preview before it replaces it.
  final bool unifiedMarkdown;

  /// Whether this note opens in the WYSIWYG surface instead of the source
  /// editor (T-WYS-05).
  final bool showWysiwyg;

  /// Reports a WYSIWYG edit as Markdown (the owner saves it).
  final ValueChanged<String>? onWysiwygChanged;

  /// Switches the library's editor kind (the status row's toggle,
  /// T-WYS-12); null hides the toggle, which is what a library with a
  /// single enabled editor passes.
  final ValueChanged<EditorKind>? onEditorKindChanged;

  /// The editor's share of the split (0..1).
  final double splitFraction;

  /// Live divider-fraction changes (the shell keeps the settings value).
  final ValueChanged<double>? onSplitFractionChanged;

  /// The divider drag lifted (the shell persists the ratio).
  final VoidCallback? onSplitDragEnd;

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

  /// The editor's controller (a test seam; one is created by default).
  final CodeLineEditingController? controller;

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

  /// The WYSIWYG surface's focus node: the phone's formatting toolbar
  /// rides the editor's focus either way (it shows only while the
  /// keyboard is up), so the surface is given this node instead of its
  /// own, and NoteView owns its disposal.
  final FocusNode _wysiwygFocus = FocusNode();

  /// The editor's controller: owned here so the save path can read the text
  /// without a full string crossing the widget tree per keystroke — the
  /// editor edits it, the save reads it. Created with a spanBuilder that
  /// styles lines through [_highlight].
  late final CodeLineEditingController _controller;

  /// The incremental highlighter that keeps the line tokenizer
  /// (editor/highlighting.dart) in sync with [_controller] (changed lines
  /// only) and builds/serves each line's styled span.
  late final EditorHighlightSync _highlight;

  /// Whether a controller was supplied by the owner (a test seam the state
  /// must not dispose) or created here.
  late final bool _ownsController;

  /// The in-editor find & replace state (the classic bar): re_editor's
  /// find machinery over [_controller], driven by `NimanFindPanel`.
  late final CodeFindController _findController;

  /// The `CodeLines` the last processed text edit produced. A controller
  /// change that reuses the same instance is selection-only (no save).
  /// Identity comparison keeps this O(1) at any file size.
  CodeLines? _lastLines;

  /// The editor's scroll: the outline jump (and the future scroll sync)
  /// lands through it.
  late final CodeScrollController _scroll;

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
  String? _lastStatsText;

  /// Why the note's frontmatter block does not parse, or null when it
  /// does (or when there is no block). Refreshed on the stats debounce.
  String? _frontmatterError;

  /// Preview pane (T-M2-08): debounced text, its own scroll + map + math
  /// cache, and the switch-mode visibility.
  Timer? _previewTimer;
  String _previewText = '';

  /// The serialized Markdown of the WYSIWYG surface; null while the source
  /// editor owns the buffer (T-WYS-05).
  String? _wysiwygText;

  /// The note's current text, whichever surface holds it.
  String get _currentText =>
      widget.showWysiwyg ? _wysiwygText ?? '' : _controller.text;

  /// The WYSIWYG surface's state (the toolbar's Quill commands need it).
  final GlobalKey<WysiwygEditorState> _wysiwygKey =
      GlobalKey<WysiwygEditorState>();

  /// The formats on at the WYSIWYG caret: the toolbar's pressed state.
  final ValueNotifier<Set<ToolbarItem>> _wysiwygActive =
      ValueNotifier<Set<ToolbarItem>>(const <ToolbarItem>{});
  late final ScrollController _previewScroll = ScrollController();
  late final ScrollMap _previewMap = ScrollMap();
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
  String _unifiedBufferText = '';

  /// The buffer the unified engine draws, built once per text change.
  SourceBuffer get _unifiedSource {
    if (_unifiedBuffer == null || _unifiedBufferText != _previewText) {
      _unifiedBufferText = _previewText;
      _unifiedBuffer = SourceBuffer.fromText(_previewText);
    }
    return _unifiedBuffer!;
  }

  /// The source lines the editor has on screen — the scroll sync's editor
  /// side (T-M2-06). The editor fills it as the package builds its
  /// indicator.
  late final EditorLineView _editorLines = EditorLineView();

  /// The find bar builder, hoisted so the cached editor pane below keeps a
  /// stable closure (a fresh closure per build would defeat the identity
  /// cache on every frame).
  PreferredSizeWidget _findBuilder(
    BuildContext context,
    CodeFindController controller,
    bool readOnly,
  ) => NimanFindPanel(
    controller: controller,
    readOnly: readOnly,
    column: widget.noteColumn,
  );

  /// The source-editor pane, cached by identity (the 0e3571e pattern): when
  /// the parent rebuilds with unchanged editor inputs — e.g. a pure
  /// editor↔preview flip — the identical widget instance makes the
  /// framework skip the whole editor subtree, so the row numbers and fold
  /// markers are not rebuilt on every switch. Any input change (path,
  /// toggles, note font size) rebuilds the pane once.
  Widget? _editorPaneCache;
  ({
    String path,
    bool numbers,
    bool autofocus,
    double fontSize,
    int? caret,
    NoteColumn column,
    bool zen,
    bool typewriter,
  })?
  _editorPaneConfig;

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
    _wysiwygFocus.addListener(_onWysiwygFocusChanged);
    _ownsController = widget.controller == null;
    _highlight = EditorHighlightSync();
    _scroll = CodeScrollController();
    _editorLines.scroller = _scroll.verticalScroller;
    // Wrapped so Enter carries a list on (#142). The wrapper forwards
    // everything else, and disposing it disposes what it wraps — so it
    // is disposed exactly when the controller inside it is ours.
    _controller = MarkdownEditingController(
      delegate:
          widget.controller ??
          CodeLineEditingController(spanBuilder: _buildHighlightSpan),
      isPlain: _isPlainLine,
    );
    _findController = CodeFindController(_controller);
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
    // Listen to the controller itself, not CodeEditor.onChanged: the value
    // set in _load happens BEFORE the editor field exists (its change
    // callback would never fire for it), and the load is exactly when the
    // buffer (and the highlight document) is first populated.
    _controller.addListener(_onValueChanged);
    _controller.addListener(_followCaret);
    _scroll.verticalScroller.addListener(_scheduleMemento);
    // The WYSIWYG publishes the formats at its caret on every selection
    // change: the same moment its memento moves.
    _wysiwygActive.addListener(_scheduleMemento);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant NoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Device trace (preview toggle needs two presses on huge notes) —
    // temporary: remove once the trace is in.
    if (oldWidget.showPreview != widget.showPreview) {
      final scroll = _previewScroll.hasClients
          ? '${_previewScroll.offset.toStringAsFixed(0)}/'
                '${_previewScroll.position.maxScrollExtent.toStringAsFixed(0)}'
          : 'detached';
      const AppLogger(name: 'preview').info(
        'flip showPreview=${widget.showPreview} '
        'chars=${_previewText.length} scroll=$scroll',
      );
    }
    if (oldWidget.active && !widget.active) _handMemento(oldWidget.path);
    // Switched on while writing: the caret goes to the middle at once.
    if (widget.typewriter && !oldWidget.typewriter) _followCaret();
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
    // its own — request it like a fresh mount did. Split mode never
    // remounted either, so focus stays untouched there.
    final splitNow = _splitIn(widget) && !widget.showWysiwyg;
    if (!splitNow && _previewIn(oldWidget) && !_previewIn(widget)) {
      if (widget.autofocusEditor) {
        if (widget.showWysiwyg) {
          _wysiwygFocus.requestFocus();
        } else {
          _focus.requestFocus();
        }
      }
    }
    // The preview has no editable: a note opening in it, or the switch
    // flipping to it, dismisses the keyboard instead of leaving it up.
    final wasPreviewOnly = !_splitIn(oldWidget) && _previewIn(oldWidget);
    if (_previewOnly && (widget.path != oldWidget.path || !wasPreviewOnly)) {
      _dismissKeyboardForPreview();
    }
    // Hand the buffer over when the editor kind changes (T-WYS-05): the
    // WYSIWYG surface opens with what the source editor holds, and the
    // source editor takes back what WYSIWYG serialized.
    if (oldWidget.showWysiwyg != widget.showWysiwyg) {
      if (widget.showWysiwyg) {
        _wysiwygText = _controller.text;
      } else if (_wysiwygText != null && _wysiwygText != _controller.text) {
        _controller.text = _wysiwygText!;
      }
    }
  }

  @override
  void dispose() {
    _handMemento(widget.path);
    _mementoTimer?.cancel();
    _scroll.verticalScroller.removeListener(_scheduleMemento);
    _wysiwygActive.removeListener(_scheduleMemento);
    _saveTimer?.cancel();
    _statsTimer?.cancel();
    _previewTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onValueChanged);
    _controller.removeListener(_followCaret);
    _typewriter.dispose();
    if (_revision != _lastSavedRevision) unawaited(_save());
    _unsaved?.unregister(_unsavedNote);
    widget.spellCheck?.removeListener(_onSpellCheckChanged);
    _findController.dispose();
    _outlineNotifier.dispose();
    _wysiwygActive.dispose();
    _formatKeys.detach();
    _focus.dispose();
    _wysiwygFocus.dispose();
    _scroll.verticalScroller.dispose();
    _scroll.horizontalScroller.dispose();
    _previewScroll.dispose();
    _editorLines.dispose();
    _mathCache.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Hands where the note at [path] was left to [NoteView.onMemento]:
  /// only a loaded note has a place to have been left at.
  void _handMemento(String path) {
    final receive = widget.onMemento;
    if (receive == null || !_ready) return;
    if (widget.showWysiwyg) {
      final state = _wysiwygKey.currentState;
      if (state == null) return;
      final selection = state.controller.selection;
      receive(
        path,
        NoteMemento(
          selectionBase: selection.baseOffset,
          selectionExtent: selection.extentOffset,
          scrollOffset: state.scrollOffset,
          editorKind: wysiwygEditorKind,
          preview: widget.showPreview,
        ),
      );
      return;
    }
    receive(
      path,
      sourceMemento(_controller, _scroll, preview: widget.showPreview),
    );
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
    if (!wysiwyg) {
      if (sameEditor) restoreSourceSelection(_controller, memento);
      restoreScroll(_scroll.verticalScroller, memento.scrollOffset);
      return;
    }
    // The surface is built from the text on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _wysiwygKey.currentState;
      if (!mounted || state == null) return;
      final extent = memento.selectionExtent;
      if (sameEditor && extent != null) {
        final length = state.controller.document.length - 1;
        state.controller.updateSelection(
          TextSelection(
            baseOffset: (memento.selectionBase ?? extent).clamp(0, length),
            extentOffset: extent.clamp(0, length),
          ),
          quill.ChangeSource.local,
        );
      }
      restoreScroll(state.scrollController, memento.scrollOffset);
    });
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
      if (widget.readNote != null) {
        // The test seam: content per the injected reader.
        content = await widget.readNote!(path);
      } else {
        // Production: the top-level isolate entry reads the file, and only
        // that. It used to compute the stats in the same pass, which put
        // the outline's full-document highlight in front of the note: a
        // 931K note read in 44 ms and then spun for another ~1.16 s before
        // showing text whose first frame paints in 0.4 ms (device log,
        // 2026-09-11). The stats follow the note on screen instead, via
        // _refreshStats below. No closures cross the boundary (an instance
        // closure is rejected by the isolate: the message carried
        // _AsyncCompleter + the whole element graph and every note failed
        // to load).
        final loaded = await PreviewWork.run('read', path);
        if (loaded is PreviewWorkFailure) throw loaded;
        if (loaded is! String) throw StateError('$loaded');
        content = loaded;
      }
      if (!mounted || widget.path != path) return;
      // The buffer uses LF: normalize line endings on load.
      final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      // The note kind (T-TK-02): the frontmatter `type` decides the body
      // (kind GUI or plain editor); detection scans the leading block
      // only, never the whole text.
      _noteKind = frontmatterTypeOf(text);
      _controller.text = text;
      // Loading is not an edit: without this the first Ctrl+Z took the
      // buffer back to what it held before — nothing — and the save that
      // followed wrote an empty note.
      _controller.clearHistory();
      _wysiwygText = text;
      // A template `{{cursor}}` landing (#53): the offset was measured in
      // this same text, so placing it is a line walk, not a guess. The
      // selection-only change schedules no save (see _onValueChanged).
      if (widget.initialCaretOffset case final caret?) {
        final at = caret.clamp(0, text.length);
        final pos = linePosition(text, at);
        _controller.selection = CodeLineSelection.collapsed(
          index: pos.line,
          offset: pos.offset,
        );
      } else if (widget.initialAnchor == null) {
        _restoreMemento();
      }
      // The spell cache is keyed by line index + text; a different note can
      // reuse the same indices, so forget the previous file's answers.
      widget.spellCheck?.reset();
      _lastLines = _controller.codeLines;
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
      final notText = error is PreviewWorkFailure && error.notText;
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
    if (widget.showWysiwyg) {
      _log.debug('reload skipped (wysiwyg): ${widget.path}');
      return;
    }
    final path = widget.path;
    final String content;
    try {
      if (widget.readNote != null) {
        content = await widget.readNote!(path);
      } else {
        final loaded = await PreviewWork.run('read', path);
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
    final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if (text == _controller.text) return;
    // Mute the programmatic change like _load does: the listener returns
    // before the revision bump and the save schedule.
    _loading = true;
    _controller.text = text;
    // The disk's text is where undo starts from now: undoing past it
    // would write the replaced text back over the other program's change.
    _controller.clearHistory();
    _wysiwygText = text;
    _lastLines = _controller.codeLines;
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

  void _onValueChanged() {
    final clock = Stopwatch()..start();
    final value = _controller.value;
    final textChanged = !identical(value.codeLines, _lastLines);
    // The incremental highlighter follows every buffer change (also the
    // load: the document is empty until the first value arrives, then it is
    // built from the full line list).
    _highlight.onBufferChanged(value.codeLines);
    if (_loading) return;
    // Selection-only changes reuse the CodeLines instance: no text changed,
    // no save. The identity check is O(1) at any file size — the full-text
    // join lives on the save path only, never the keystroke path.
    _scheduleMemento();
    if (!textChanged) return;
    _log.debug(
      'keystroke: highlight+select sync '
      '${(clock.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms, '
      'line ${value.selection.extentIndex}',
    );
    _lastLines = value.codeLines;
    _revision++;
    _unsaved?.noteChanged();
    // No setState: the status line follows the save state only. The debounce
    // lengthens while a save is in flight (typing fast: one trailing save,
    // not a queue).
    _saveTimer?.cancel();
    final debounce = _saving
        ? const Duration(seconds: 1)
        : const Duration(milliseconds: 500);
    _saveTimer = Timer(debounce, _save);
    // Word count + outline (T-M2-07): the O(n) passes live behind a
    // debounce, never on the keystroke path.
    _statsTimer?.cancel();
    _statsTimer = Timer(const Duration(milliseconds: 350), _refreshStats);
    // Preview text (T-M2-08): the same dry-run cadence as saves.
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 500), _refreshPreview);
  }

  void _refreshPreview() {
    if (!mounted || _loading) return;
    final text = _currentText;
    if (text == _previewText) return;
    setState(() => _previewText = text);
  }

  /// Flips between the source editor and the WYSIWYG surface (T-WYS-12);
  /// the owner persists it and refreshes the shell.
  void _toggleEditorKind() {
    final next = widget.showWysiwyg ? EditorKind.source : EditorKind.wysiwyg;
    widget.onEditorKindChanged?.call(next);
  }

  /// A WYSIWYG edit, reported as Markdown: the serialized Markdown becomes
  /// the buffer, and the usual save/preview cadence follows (T-WYS-05).
  void _onWysiwygChanged(String markdown) {
    if (!mounted) return;
    _wysiwygText = markdown;
    _revision++;
    _unsaved?.noteChanged();
    _saveTimer?.cancel();
    final debounce = _saving
        ? const Duration(seconds: 1)
        : const Duration(milliseconds: 500);
    _saveTimer = Timer(debounce, _save);
    _statsTimer?.cancel();
    _statsTimer = Timer(const Duration(milliseconds: 350), _refreshStats);
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 500), _refreshPreview);
    widget.onWysiwygChanged?.call(markdown);
  }

  /// Typewriter mode's follow of the source editor's caret (#70).
  late final TypewriterFollow _typewriter = TypewriterFollow(
    _centerSourceCaret,
  );

  /// The source caret moved, or the text under it did: typewriter mode
  /// brings its row to the middle. Only while someone is writing here —
  /// the editor or its find bar has the focus — so a note loading, or its
  /// place being put back, stays where it was put.
  void _followCaret() {
    if (!widget.typewriter || widget.showWysiwyg || !widget.active) return;
    if (!_focus.hasFocus && _findController.value == null) return;
    _typewriter.caretMoved();
  }

  bool _centerSourceCaret() {
    final y = _editorLines.caretRowCenter(_controller.selection.extent);
    if (y == null) {
      // Off screen, so not laid out: the editor brings it to the middle
      // as best it can guess, and the next frame puts it there exactly.
      _controller.makeCursorCenterIfInvisible();
      return false;
    }
    centerCaret(_scroll.verticalScroller, y);
    return true;
  }

  /// Whether only the preview is on screen (the editor hidden): the IME
  /// has no editable target, so it must go.
  bool get _previewOnly => !_splitIn(widget) && _previewIn(widget);

  /// Whether [view] shows its preview. In Zen (#69) too: a note read
  /// rather than written is read there in its preview (0.0.8 test round).
  /// Zen only takes the split apart, and the tab's own flag then says
  /// which of the two it shows.
  static bool _previewIn(NoteView view) => view.showPreview;

  /// Whether [view] sets editor and preview side by side; never in Zen.
  static bool _splitIn(NoteView view) => view.splitPreview && !view.zen;

  /// Dismisses the keyboard when the preview is the only pane: a note
  /// opening in preview, or the switch flipping to it, must not leave
  /// the IME up over a pane with nothing editable.
  void _dismissKeyboardForPreview() {
    if (_previewOnly) FocusManager.instance.primaryFocus?.unfocus();
  }

  Widget _buildEditor() => Listener(
    // Desktop Ctrl+click on a wikilink/MD link (T-M3-07): a mouse
    // click lands the caret under the pointer through the package's
    // own tap handling, so the token under the caret is read after
    // this frame. Touch-like clicks stay edit-only (mobile navigates
    // from the preview).
    onPointerDown: (event) {
      if (event.kind != PointerDeviceKind.mouse) return;
      if (!HardwareKeyboard.instance.isControlPressed) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_tryOpenLinkAtCaret());
      });
    },
    child: NoteEditor(
      key: ValueKey(widget.path),
      controller: _controller,
      focusNode: _focus,
      showLineNumbers: widget.showLineNumbers && !widget.zen,
      caretWidth: widget.zen ? zenCaretWidth : null,
      typewriter: widget.typewriter,
      // A template `{{cursor}}` landing (#53) always takes focus: the
      // note was just created around that caret, and with the keyboard
      // down the first tap re-places it wherever the finger lands.
      autofocus: widget.autofocusEditor || widget.initialCaretOffset != null,
      // Read from the global rather than passed down the shell: the app
      // root rebuilds everything when the setting changes, so this is
      // read fresh on the very frame the slider moves (T-M6-12).
      fontSize: AppTextScales.noteFontSize,
      scrollController: _scroll,
      onIndicator: _editorLines.attach,
      findController: _findController,
      findBuilder: _findBuilder,
      shortcutsActivators: const NimanShortcutsActivatorsBuilder(),
      spellCheck: widget.spellCheck,
      column: widget.noteColumn,
      formatMenu: _formatMenu,
    ),
  );

  /// The source editor pane, served from the identity cache above. Only the
  /// source editor is cached: the WYSIWYG surface takes the live text every
  /// build by design.
  Widget _sourcePane() {
    final config = (
      path: widget.path,
      numbers: widget.showLineNumbers,
      zen: widget.zen,
      typewriter: widget.typewriter,
      autofocus: widget.autofocusEditor,
      fontSize: AppTextScales.noteFontSize,
      caret: widget.initialCaretOffset,
      column: widget.noteColumn,
    );
    if (_editorPaneCache == null || _editorPaneConfig != config) {
      _editorPaneConfig = config;
      _editorPaneCache = _buildEditor();
    }
    return _editorPaneCache!;
  }

  /// The editor pane: the WYSIWYG surface or the source editor (T-WYS-05).
  ///
  /// The switch mode handles the eye for both: the WYSIWYG surface and the
  /// source editor are one pane, never two.
  Widget _editorPane() => widget.showWysiwyg
      ? WysiwygEditor(
          key: _wysiwygKey,
          data: _currentText,
          onChanged: _onWysiwygChanged,
          autoFocus: widget.autofocusEditor,
          spellCheck: widget.spellCheck,
          activeItems: _wysiwygActive,
          focusNode: _wysiwygFocus,
          column: widget.noteColumn,
          formatMenu: _formatMenu,
          typewriter: widget.typewriter,
        )
      : _sourcePane();

  /// The preview, at the *note* text size rather than the interface one
  /// (T-M6-12).
  ///
  /// The app root put the interface scale on every MediaQuery below it;
  /// here it is replaced, so the same note reads the same size whichever
  /// pane shows it.
  Widget _buildPreview(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: noteTextScalerOf(context)),
    child: widget.unifiedMarkdown
        ? _buildUnifiedPreview(context)
        : _buildLegacyPreview(context),
  );

  /// The unified surface's read mode: one engine, the same theme as the editor
  /// (docs/dev/unified-surface.md). Opt-in behind `MarkdownEngine.unified`,
  /// because its render has to be shown to agree with the preview below before
  /// it can replace it.
  Widget _buildUnifiedPreview(BuildContext context) => MarkdownReadView(
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
  );

  /// The preview the app has always had, kept until the unified render is
  /// shown to match it.
  Widget _buildLegacyPreview(BuildContext context) => MarkdownPreview(
    data: _previewText,
    controller: _previewScroll,
    scrollMap: _previewMap,
    mathCache: _mathCache,
    imageDirectory: widget.libraryRoot,
    onTapLink: (text, href, title) =>
        unawaited(openHref(context, href ?? '', _linkTargets)),
    onWikiLink: (ref, display) =>
        unawaited(openWiki(context, ref, _linkTargets)),
    embedResolver: _resolveEmbed,
    column: widget.noteColumn,
  );

  /// Schedules the caret-link check for the end of a frame; the caret the
  /// package's tap handler placed may land one frame after the pointer up,
  /// so a miss is retried a couple of frames before giving up.
  void _scheduleCaretCheck([int attempt = 0]) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_tryOpenLinkAtCaret(attempt));
    });
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

  /// Whether line [index] is ordinary Markdown rather than fenced code,
  /// display math or the frontmatter — where a dash starts nothing, so
  /// Enter has no list to carry on (#142).
  ///
  /// Answered from the highlighter the editor already keeps, so the two
  /// cannot disagree about what a list is.
  bool _isPlainLine(int index) {
    for (final token in _highlight.tokensOf(index)) {
      if (token.kind == TokenKind.codeFence ||
          token.kind == TokenKind.mathBlock ||
          token.kind == TokenKind.frontmatter) {
        return false;
      }
    }
    return true;
  }

  /// Editor side of link navigation: the caret sits on a wikilink or MD
  /// link token (the package placed it under the Ctrl+click); open it.
  Future<void> _tryOpenLinkAtCaret([int attempt = 0]) async {
    final selection = _controller.selection;
    final line = selection.extentIndex;
    final offset = selection.extentOffset;
    final tokens = _highlight.tokensOf(line);
    Token? hit;
    for (final token in tokens) {
      if (token.kind != TokenKind.wikilink && token.kind != TokenKind.link) {
        continue;
      }
      if (offset > token.start && offset <= token.end) {
        hit = token;
        break;
      }
    }
    final token = hit;
    if (token == null) {
      if (attempt < 3) _scheduleCaretCheck(attempt + 1);
      return;
    }
    final text = _controller.codeLines[line].text;
    final raw = text.substring(token.start, token.end);
    if (token.kind == TokenKind.wikilink) {
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
    _controller.replaceSelection(snippet);
    _scroll.makeCenterIfInvisible(
      CodeLinePosition(index: _controller.selection.extentIndex, offset: 0),
    );
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

  void _refreshStats() {
    if (!mounted || _loading) return;
    final text = _currentText;
    if (text == _lastStatsText) return;
    _lastStatsText = text;
    final revision = ++_statsRevision;
    // The frontmatter check rides the stats debounce (T-M4-01: parsed on
    // edit, debounced). It reads only the leading block, so it stays on
    // this isolate whatever the note's size.
    final frontmatterError = frontmatterErrorIn(text);
    if (frontmatterError != _frontmatterError) {
      setState(() => _frontmatterError = frontmatterError);
    }
    void apply(Object? result) {
      if (!mounted || revision != _statsRevision) return;
      final stats = PreviewWork.statsOf(result);
      if (stats == null) return;
      setState(() {
        _wordCount = stats.words;
        _outline = stats.outline
            .map(parseOutlineRow)
            .whereType<OutlineEntry>()
            .toList();
      });
      _outlineNotifier.value = _outline;
    }

    // Word count + outline are O(n) pure passes. Notes above the threshold
    // run them on an isolate (a 931K note costs ~400 ms — never on the
    // main thread, that was the 1.2 s open stall); small ones stay
    // synchronous (deterministic for tests).
    if (text.length <= _syncWorkLimit) {
      final result = statsFor(text);
      apply((result.$1, result.$2));
      return;
    }
    unawaited(PreviewWork.run('stats', text).then(apply));
  }

  static const int _syncWorkLimit = 64 * 1024;

  int _statsRevision = 0;

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
    _controller.selection = CodeLineSelection.collapsed(index: line, offset: 0);
    _scroll.makeCenterIfInvisible(CodeLinePosition(index: line, offset: 0));
    _syncPreviewToLine(line);
  }

  /// Scrolls the preview so the block starting at source [line] is in
  /// view (no-op when the preview is hidden or not laid out yet).
  ///
  /// The preview windowing lays out only the blocks near the viewport, so
  /// right after open the scroll map is incomplete and the list's total
  /// extent is an estimate: a single jump lands at the line-fraction
  /// estimate, and the blocks it passes then measure, growing the extent.
  /// A few post-frame passes refine the position (T-M3-09 device report:
  /// anchor taps in the phone preview-only mode never moved — the jump
  /// bailed on the incomplete map). The loop stops when the map is
  /// complete, the position stops moving, or the attempts run out.
  void _syncPreviewToLine(int line, {int attempt = 0}) {
    if (!_previewIn(widget) || !mounted) return;
    const log = AppLogger(name: 'links');
    log.debug(
      'anchor jump: scheduling preview scroll to line $line '
      '(attempt $attempt, preview ${widget.showPreview ? 'shown' : 'hidden'})',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_previewScroll.hasClients) {
        log.debug('anchor jump: preview scroll not attached — skipped');
        return;
      }
      final map = _previewMap;
      final position = _previewScroll.position;
      final maxExtent = position.maxScrollExtent;
      if (maxExtent <= 0 || map.lineCount == 0) {
        log.debug(
          'anchor jump: preview not laid out yet '
          '(extent $maxExtent, lines ${map.lineCount}) — skipped',
        );
        return;
      }
      final offset = map.previewOffsetForLine(line, maxExtent: maxExtent);
      if (offset == null) {
        log.debug('anchor jump: no blocks laid out — skipped');
        return;
      }
      final moved = (position.pixels - offset).abs() > 1;
      if (moved) {
        log.debug(
          'anchor jump: source line $line -> preview offset '
          '${offset.round()}px (extent ${maxExtent.round()}px, '
          'map ${map.isReady ? 'complete' : 'estimating'}, '
          'attempt $attempt)',
        );
        position.jumpTo(offset);
      }
      if (moved && !map.isReady && attempt < 12 && offset > 0) {
        // One more pass: the jump measured the blocks it passed, so the
        // extent (and the landing) is closer now.
        _syncPreviewToLine(line, attempt: attempt + 1);
      }
    });
    // In the phone preview-only layout nothing invalidates after the tap
    // (no editor caret, no ink), so no frame is scheduled and the
    // callback above would starve — production Flutter draws frames on
    // demand. Guarantee the next frame runs it.
    WidgetsBinding.instance.scheduleFrame();
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

  /// The WYSIWYG surface's focus moved: the phone's toolbar rides it the
  /// same way.
  void _onWysiwygFocusChanged() {
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
  Future<void> _performSave(int revision, String target) async {
    final clock = Stopwatch()..start();
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
        _unsaved?.noteChanged();
      }
      _log.info(
        'note saved: $target (${text.length} chars, '
        '${clock.elapsedMilliseconds} ms)',
      );
    } finally {
      _saving = false;
      final trailing = _savePending;
      _savePending = false;
      if (mounted) setState(() {});
      if (trailing) unawaited(_save());
    }
  }

  /// The close guard's save (T-PP-11): writes until the disk holds the
  /// latest revision — waiting out a save that was already in flight — and
  /// completes with the write's error when one fails. The caller keeps the
  /// window open on a failure: the edits are still only in the buffer.
  Future<void> _saveForClose() async {
    while (_revision != _lastSavedRevision) {
      await _save();
    }
  }

  /// Spelling results changed (the note loaded, or a settings toggle):
  /// cached line spans must be rebuilt with the new ranges.
  void _onSpellCheckChanged() {
    if (!mounted) return;
    _highlight.clearSpans();
    setState(() {});
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
    if (widget.showWysiwyg) {
      final lines =
          _wysiwygKey.currentState?.plainTextLines ?? const <String>[];
      return spell.startScan(
        lineCount: lines.length,
        lineAt: (i) => (text: lines[i], skip: const <TextRange>[]),
      );
    }
    final lines = _controller.codeLines;
    return spell.startScan(
      lineCount: lines.length,
      lineAt: (i) =>
          (text: lines[i].text, skip: spellSkipRanges(_highlight.tokensOf(i))),
    );
  }

  /// Replaces one issue's word in the controller (the panel's fix).
  void _applySpelling(SpellIssue issue, String replacement) {
    if (widget.showWysiwyg) {
      _wysiwygKey.currentState?.replaceDocumentRange(
        issue.line,
        issue.start,
        issue.end,
        replacement,
      );
      return;
    }
    _controller.replaceSelection(
      replacement,
      CodeLineSelection(
        baseIndex: issue.line,
        baseOffset: issue.start,
        extentIndex: issue.line,
        extentOffset: issue.end,
      ),
    );
    _highlight.clearSpans();
  }

  /// The [CodeLineSpanBuilder] over [_highlight]: styles each line the
  /// editor lays out, dark/light per the app brightness, and underlines the
  /// misspelled prose (T-PP-09) once the spell checker knows the line.
  TextSpan _buildHighlightSpan({
    required BuildContext context,
    required int index,
    required CodeLine codeLine,
    required TextSpan textSpan,
    required TextStyle style,
  }) {
    final spell = widget.spellCheck;
    final spellRanges = spell == null
        ? const <TextRange>[]
        : spell.rangesFor(
            index,
            codeLine.text,
            skip: spellSkipRanges(_highlight.tokensOf(index)),
          );
    return _highlight.spanFor(
      index: index,
      text: codeLine.text,
      base: style,
      syntax: SyntaxColors.of(context),
      dark: Theme.of(context).brightness == Brightness.dark,
      spellRanges: spellRanges,
      spellStyle: spellRanges.isEmpty
          ? null
          : TextStyle(
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.wavy,
              decorationColor: Theme.of(context).colorScheme.error,
            ),
    );
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
    _controller.text = newText;
    _wysiwygText = newText;
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
  bool get _keyboardUp =>
      widget.showWysiwyg ? _wysiwygFocus.hasFocus : _focus.hasFocus;

  @override
  Widget build(BuildContext context) {
    final error = _error;
    // The WYSIWYG surface is never split: it already is a rendering, and the
    // shell's previewSplits agrees — this is the belt to its braces.
    final split = _splitIn(widget) && !widget.showWysiwyg;
    final showPreview = _previewIn(widget);
    // The toolbar formats the editor: it stays in split mode (the editor
    // is on screen) and hides in full-screen preview mode. On the phone
    // it also rides the keyboard (it shows only while the keyboard is
    // up); on desktop it never does.
    // Hiding every button hides the toolbar itself; the editor keeps its
    // keyboard shortcuts.
    final showToolbar =
        (split || !showPreview) &&
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
                    : split
                    ? EditorPreviewSplit(
                        editor: _editorPane(),
                        preview: _buildPreview(context),
                        editorScroll: _scroll.verticalScroller,
                        previewScroll: _previewScroll,
                        map: _previewMap,
                        lines: _editorLines,
                        fraction: widget.splitFraction,
                        onFractionChanged:
                            widget.onSplitFractionChanged ?? (_) {},
                        onDragEnd: widget.onSplitDragEnd,
                      )
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
                    splitPreview: _splitIn(widget),
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
                    onFind: widget.showWysiwyg
                        ? () => _wysiwygKey.currentState?.openFind()
                        : _findController.findMode,
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
  /// through the controller; the image button keeps the file-picker flow
  /// (T-M2-09) it already had in the status row.
  ///
  /// The toolbar is an extension of the keyboard: re_editor unfocuses the
  /// editor on any tap outside its tap region (every toolbar tap dismissed
  /// and re-showed the keyboard), so the toolbar joins the editor's tap
  /// region and tapping it keeps the editor focused.
  Widget _toolbar(BuildContext context, {bool dense = false}) {
    final actions = _toolbarActions();
    // The re_editor tap region keeps the keyboard up for the source editor;
    // the WYSIWYG surface has its own focus handling, and publishes which
    // formats are on at the caret so a pressed button stays pressed until
    // it is toggled off (T-WYS-06).
    if (!widget.showWysiwyg) {
      return CodeEditorTapRegion(
        child: NoteToolbarBar(
          dense: dense,
          actions: actions,
          active: const <ToolbarItem>{},
          layout: widget.toolbarLayout,
        ),
      );
    }
    return ValueListenableBuilder<Set<ToolbarItem>>(
      valueListenable: _wysiwygActive,
      builder: (context, active, _) => NoteToolbarBar(
        dense: dense,
        actions: actions,
        active: active,
        layout: widget.toolbarLayout,
      ),
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
    final active = widget.showWysiwyg
        ? _wysiwygActive.value
        : const <ToolbarItem>{};
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

  Map<ToolbarItem, VoidCallback> _toolbarActions() {
    if (widget.showWysiwyg) return _quillToolbarActions();
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
      ToolbarItem.heading: _showHeadingDialog,
      ToolbarItem.list: () => _prefixLines(prefix: '- '),
      ToolbarItem.orderedList: _insertOrderedList,
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
  bool get _hasListToCount {
    if (!widget.showWysiwyg) return tallyTargetsIn(_controller.text).isNotEmpty;
    final state = _wysiwygKey.currentState;
    if (state == null) return false;
    return quillTallyTargets(state.controller.document).isNotEmpty;
  }

  /// Counts a list into a checklist, on whichever surface is showing.
  Future<void> _countList() =>
      widget.showWysiwyg ? _countListWysiwyg() : _countListSource();

  Future<void> _countListSource() async {
    final text = _controller.text;
    final targets = tallyTargetsIn(text);
    if (targets.isEmpty) return;
    final here = tallyTargetAt(text, _controller.selection.baseIndex);
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

  Future<void> _countListWysiwyg() async {
    final state = _wysiwygKey.currentState;
    if (state == null) return;
    final controller = state.controller;
    final targets = quillTallyTargets(controller.document);
    if (targets.isEmpty) return;
    final here = quillTallyTargetAt(
      controller.document,
      controller.selection.baseOffset,
    );
    final choice = await showListTallySheet(
      context,
      candidates: <TallyCandidate>[
        for (final target in targets)
          TallyCandidate(
            rows: target.rows,
            checks: target.checks,
            replaces: target.replaces,
          ),
      ],
      initialIndex: here == null
          ? 0
          : targets.indexWhere((t) => t.start == here.start),
    );
    if (!mounted || choice == null) return;
    final target = targets[choice.index];
    applyQuillTally(
      controller,
      target,
      tallyList(
        rows: target.rows,
        cut: choice.cut,
        sort: choice.sort,
        checked: target.checks,
      ),
    );
    state.requestEditorFocus();
  }

  /// The toolbar's commands against the WYSIWYG document (T-WYS-06): the
  /// same buttons, the Quill formats behind them.
  Map<ToolbarItem, VoidCallback> _quillToolbarActions() => {
    for (final item in ToolbarItem.values) item: () => _applyQuillItem(item),
  };

  /// Applies a pure markdown command's result: the whole text is set
  /// (undoable) and the selection lands where the command put it — inside
  /// the markers for wraps, the same lines for line edits. The editor
  /// keeps its focus (the IME stays up); focus is re-requested
  /// defensively.
  void _applyMarkdownEdit(MarkdownEdit edit) {
    _controller.text = edit.text;
    _controller.selection = codeLineSelection(_controller.text, edit.selection);
    _focus.requestFocus();
  }

  void _wrapSelection({required String left, required String right}) {
    _applyMarkdownEdit(
      wrapSelection(
        text: _controller.text,
        selection: textSelection(_controller.text, _controller.selection),
        left: left,
        right: right,
      ),
    );
  }

  void _insertCodeBlock() {
    _applyMarkdownEdit(
      codeBlock(
        text: _controller.text,
        selection: textSelection(_controller.text, _controller.selection),
      ),
    );
  }

  void _prefixLines({required String prefix}) {
    _applyMarkdownEdit(
      prefixLines(
        text: _controller.text,
        selection: textSelection(_controller.text, _controller.selection),
        prefix: prefix,
      ),
    );
  }

  /// Inserts a link in the format chosen in settings (wikilink `[[…]]`
  /// or markdown `[…](…)`).
  void _insertLink() {
    final markdown = widget.linkType == LinkType.markdown;
    _applyMarkdownEdit(
      wrapSelection(
        text: _controller.text,
        selection: textSelection(_controller.text, _controller.selection),
        left: markdown ? '[' : '[[',
        right: markdown ? '](...)' : ']]',
      ),
    );
  }

  /// Numbers the selected line(s) as an ordered list.
  void _insertOrderedList() {
    _applyMarkdownEdit(
      orderedList(
        text: _controller.text,
        selection: textSelection(_controller.text, _controller.selection),
      ),
    );
  }

  /// Indents (or outdents, [outdent] true) the selected line(s) by the
  /// width chosen in settings.
  void _indentLines({required bool outdent}) {
    _applyMarkdownEdit(
      indentLines(
        text: _controller.text,
        selection: textSelection(_controller.text, _controller.selection),
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
    _applyMarkdownEdit(
      setHeading(
        text: _controller.text,
        selection: textSelection(_controller.text, _controller.selection),
        level: level,
      ),
    );
  }

  /// Applies a toolbar item to the WYSIWYG document (T-WYS-06).
  ///
  /// The focus returns to the surface, on the caret the command acted on:
  /// on the desktop a toolbar tap moves focus out of the editor, and
  /// without this the writer would have to click back in before typing —
  /// losing the just-toggled format (e.g. bold on an empty caret). The
  /// dialog/picker items refocus when their flow closes instead.
  void _applyQuillItem(ToolbarItem item) {
    final state = _wysiwygKey.currentState;
    if (state == null) return;
    _quillCommands(state).apply(item);
    if (item == ToolbarItem.image ||
        item == ToolbarItem.heading ||
        item == ToolbarItem.tools) {
      return;
    }
    state.requestEditorFocus();
  }

  /// The Quill commands over the open surface's controller.
  QuillEditorCommands _quillCommands(WysiwygEditorState state) =>
      QuillEditorCommands(
        controller: state.controller,
        onLink: _insertQuillLink,
        onImage: _insertQuillImage,
        onHeading: _showQuillHeadingDialog,
        onTools: () => unawaited(_openTools()),
      );

  /// The heading picker, applied to the Quill selection.
  Future<void> _showQuillHeadingDialog() async {
    final state = _wysiwygKey.currentState;
    if (state == null) return;
    final level = await showHeadingLevelDialog(context);
    if (!mounted) return;
    if (level != null) _quillCommands(state).applyHeader(level);
    state.requestEditorFocus();
  }

  /// The link button in WYSIWYG: the same syntax the source editor inserts,
  /// as text (the codec writes it back unchanged, T-WYS-06).
  void _insertQuillLink() {
    final state = _wysiwygKey.currentState;
    if (state == null) return;
    final controller = state.controller;
    final selection = controller.selection;
    final selected = controller.document.getPlainText(
      selection.start,
      selection.end - selection.start,
    );
    final markdown = widget.linkType == LinkType.markdown;
    final snippet = markdown ? '[$selected](...)' : '[[$selected]]';
    controller.replaceText(
      selection.start,
      selection.end - selection.start,
      snippet,
      TextSelection.collapsed(offset: selection.start + snippet.length),
    );
    state.requestEditorFocus();
  }

  /// The image button in WYSIWYG: the source editor's picker/import flow,
  /// with the resulting snippet inserted as text (T-WYS-06).
  Future<void> _insertQuillImage() async {
    final state = _wysiwygKey.currentState;
    final root = widget.libraryRoot;
    if (state == null || root == null) return;
    final source = await (widget.pickImagePath?.call() ?? _pickImageFile());
    if (!mounted) return;
    if (source == null) {
      state.requestEditorFocus();
      return;
    }
    final relative =
        await (widget.importImage?.call(root, source) ??
            importImageToLibrary(
              libraryRoot: root,
              sourcePath: source,
              attachmentsFolder: widget.attachmentsFolder,
            ));
    if (!mounted) return;
    final label = p.basenameWithoutExtension(source);
    final snippet = attachmentEmbed(
      relativePath: relative,
      label: label,
      linkType: widget.linkType,
    );
    final controller = state.controller;
    final index = controller.selection.start;
    controller.replaceText(
      index,
      0,
      snippet,
      TextSelection.collapsed(offset: index + snippet.length),
    );
    state.requestEditorFocus();
  }
}
