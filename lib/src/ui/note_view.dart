import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/frame_log.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/core/text_scale.dart';
import 'package:copist/src/db/index_database.dart';
import 'package:copist/src/editor/find_panel.dart';
import 'package:copist/src/editor/highlight_sync.dart';
import 'package:copist/src/editor/highlighting.dart';
import 'package:copist/src/editor/md_editing.dart';
import 'package:copist/src/editor/note_editor.dart';
import 'package:copist/src/editor/outline.dart';
import 'package:copist/src/editor/toolbar.dart';
import 'package:copist/src/editor/toolbar_item.dart';
import 'package:copist/src/editor/toolbar_layout.dart';
import 'package:copist/src/editor/wysiwyg/quill_editor_commands.dart';
import 'package:copist/src/editor/wysiwyg/wysiwyg_editor.dart';
import 'package:copist/src/frontmatter/note_kind.dart';
import 'package:copist/src/frontmatter/parser.dart';
import 'package:copist/src/library/image_import.dart';
import 'package:copist/src/links/parser.dart';
import 'package:copist/src/links/resolver.dart';
import 'package:copist/src/links/slug.dart';
import 'package:copist/src/preview/editor_lines.dart';
import 'package:copist/src/preview/markdown_preview.dart';
import 'package:copist/src/preview/math_cache.dart';
import 'package:copist/src/preview/preview_work.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:copist/src/spellcheck/editor_spell_check.dart';
import 'package:copist/src/spellcheck/spell_check_sheet.dart';
import 'package:copist/src/spellcheck/spell_issue.dart';
import 'package:copist/src/ui/action_sheet.dart';
import 'package:copist/src/ui/editor_preview_split.dart';
import 'package:copist/src/ui/outline_panel.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:copist/src/ui/theme/tokens.dart';
import 'package:copist/src/ui/unsaved_notes.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:re_editor/re_editor.dart';
import 'package:url_launcher/url_launcher.dart';

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
    this.linkType = LinkType.wikilink,
    this.indentWidth = 2,
    this.toolbarLayout = ToolbarLayout.defaults,
    this.splitPreview = false,
    this.showPreview = false,
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
    this.controller,
    this.linkSource,
    this.onOpenNote,
    this.initialAnchor,
    this.kindMode = true,
    this.onNoteKindChanged,
    this.toolbarTop = false,
    this.unsavedTracker,
    this.statusActions = const <Widget>[],
    this.spellCheck,
    super.key,
  });

  /// Absolute path of the note file.
  final String path;

  /// Whether the editor shows the row-number column (settings toggle).
  final bool showLineNumbers;

  /// Whether the editor shows the keyboard on open (settings toggle).
  final bool autofocusEditor;

  /// The link format the link button inserts (settings).
  final LinkType linkType;

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

  /// Whether this note opens in the WYSIWYG surface instead of the source
  /// editor (T-WYS-05).
  final bool showWysiwyg;

  /// Reports a WYSIWYG edit as Markdown (the owner saves it).
  final ValueChanged<String>? onWysiwygChanged;

  /// Switches the library's editor kind (the status row's toggle, T-WYS-12).
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
  final Future<void> Function(String path, String content)? writeNote;

  /// The editor's controller (a test seam; one is created by default).
  final CodeLineEditingController? controller;

  /// The link-resolution source (wiki targets + markdown hrefs against the
  /// open index); null (tests without a session) disables link navigation.
  final LinkSource? linkSource;

  /// Opens a note by library-relative path, then (optionally) jumps to a
  /// heading; the shell implements it (T-M3-07).
  final void Function(String path, String? anchor)? onOpenNote;

  /// A heading anchor to land on after the note loads (T-M3-07).
  final String? initialAnchor;

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

  @override
  State<NoteView> createState() => _NoteViewState();
}

final class _NoteViewState extends State<NoteView> with WidgetsBindingObserver {
  static const AppLogger _log = AppLogger(name: 'editor');

  late final FocusNode _focus;

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
  /// find machinery over [_controller], driven by `CopistFindPanel`.
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
  String? _error;
  Timer? _saveTimer;

  /// Debounced note-statistics refresh (word count + outline, T-M2-07).
  Timer? _statsTimer;
  int _wordCount = 0;
  List<OutlineEntry> _outline = const <OutlineEntry>[];
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

  /// The source lines the editor has on screen — the scroll sync's editor
  /// side (T-M2-06). The editor fills it as the package builds its
  /// indicator.
  late final EditorLineView _editorLines = EditorLineView();

  /// Text-edit counter; the disk matches [_lastSavedRevision]. A saved note
  /// is a revision, not a text copy.
  int _revision = 0;
  int _lastSavedRevision = 0;

  /// The save in flight, if any: a coalesced [_save] hands it back, so a
  /// caller that must know the disk moved ([_saveForClose]) awaits the
  /// real write instead of the pending flag.
  Future<void>? _activeSave;

  /// The app-level unsaved registry this editor reports into (T-PP-11),
  /// or null when the owner does not track.
  late final UnsavedTracker? _unsaved;

  /// The [UnsavedNote] view handed to [_unsaved]; it reads this state's
  /// revision pair live, so it cannot hold stale text.
  late final _UnsavedNoteAdapter _unsavedNote = _UnsavedNoteAdapter(this);

  /// The loaded note's kind (the frontmatter `type` value, null = plain
  /// note); null again while a load is in flight.
  String? _noteKind;

  /// The kind GUIs' window onto the note (T-TK-02).
  late final _NoteKindHost _kindHost;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focus = FocusNode();
    _focus.addListener(_onFocusChanged);
    _ownsController = widget.controller == null;
    _highlight = EditorHighlightSync();
    _scroll = CodeScrollController();
    _controller = widget.controller == null
        ? CodeLineEditingController(spanBuilder: _buildHighlightSpan)
        : widget.controller!;
    _findController = CodeFindController(_controller);
    _kindHost = _NoteKindHost(this);
    _unsaved = widget.unsavedTracker;
    _unsaved?.register(_unsavedNote);
    widget.spellCheck?.addListener(_onSpellCheckChanged);
    // Listen to the controller itself, not CodeEditor.onChanged: the value
    // set in _load happens BEFORE the editor field exists (its change
    // callback would never fire for it), and the load is exactly when the
    // buffer (and the highlight document) is first populated.
    _controller.addListener(_onValueChanged);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant NoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
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
    // The preview has no editable: a note opening in it, or the switch
    // flipping to it, dismisses the keyboard instead of leaving it up.
    final wasPreviewOnly = !oldWidget.splitPreview && oldWidget.showPreview;
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
    _saveTimer?.cancel();
    _statsTimer?.cancel();
    _previewTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onValueChanged);
    if (_revision != _lastSavedRevision) unawaited(_save());
    _unsaved?.unregister(_unsavedNote);
    widget.spellCheck?.removeListener(_onSpellCheckChanged);
    _findController.dispose();
    _wysiwygActive.dispose();
    _focus.dispose();
    _scroll.verticalScroller.dispose();
    _scroll.horizontalScroller.dispose();
    _previewScroll.dispose();
    _editorLines.dispose();
    _mathCache.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Applies precomputed stats (from the load isolate) to the state.
  /// Applies precomputed stats (from the load isolate) to the state.
  void _applyStats(String text, int words, List<String> outlineRows) {
    _lastStatsText = text;
    setState(() {
      _frontmatterError = frontmatterErrorIn(text);
      _wordCount = words;
      _outline = outlineRows
          .map(_parseOutlineRow)
          .whereType<OutlineEntry>()
          .toList();
    });
  }

  Future<void> _write(String path, String content) async {
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
    setState(() {
      _loading = true;
      _ready = false;
      _error = null;
      _noteKind = null;
    });
    final clock = Stopwatch()..start();
    try {
      String content;
      (int, List<String>)? stats;
      if (widget.readNote != null) {
        // The test seam: content per the injected reader; stats are
        // computed afterwards (the synchronous path for small notes).
        content = await widget.readNote!(path);
        stats = null;
      } else {
        // Production: the top-level isolate entry reads the file AND
        // computes the stats in one pass — word count + outline are ready
        // the moment the load ends. No closures cross the boundary (an
        // instance closure is rejected by the isolate: the message carried
        // _AsyncCompleter + the whole element graph and every note failed
        // to load).
        final loaded = await PreviewWork.run('read', path);
        if (loaded is! (String, int, List<String>)) {
          throw StateError('$loaded');
        }
        content = loaded.$1;
        stats = (loaded.$2, loaded.$3);
      }
      if (!mounted || widget.path != path) return;
      // The buffer uses LF: normalize line endings on load.
      final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      // The note kind (T-TK-02): the frontmatter `type` decides the body
      // (kind GUI or plain editor); detection scans the leading block
      // only, never the whole text.
      _noteKind = frontmatterTypeOf(text);
      if (stats != null) {
        _applyStats(text, stats.$1, stats.$2);
      }
      _controller.text = text;
      _wysiwygText = text;
      // The spell cache is keyed by line index + text; a different note can
      // reuse the same indices, so forget the previous file's answers.
      widget.spellCheck?.reset();
      _lastLines = _controller.codeLines;
      _lastSavedRevision = _revision;
      _unsaved?.noteChanged();
      setState(() {
        _loading = false;
        _ready = true;
      });
      // Opened straight into the preview: the IME has no target here.
      _dismissKeyboardForPreview();
      widget.onNoteKindChanged?.call(_noteKind);
      // Word count + outline on open: debounced for edits only; the
      // production load already has them from its isolate (the seam path
      // uses the regular refresh).
      if (stats == null) _refreshStats();
      // The editor gets this frame: the preview's parse and first layout
      // start right after the text is on screen, so a large note shows it
      // before the preview works (T-PP-22).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshPreview();
      });
      final anchor = widget.initialAnchor;
      if (anchor != null) _jumpToAnchor(anchor);
      _log.info(
        'note loaded: $path (${text.length} chars, '
        '${clock.elapsedMilliseconds} ms)',
      );
      // The read time above is what the disk/isolate cost; this is what the
      // user waited for — load plus the frame that paints the loaded note.
      logNextFrame('editor', 'note open first frame (${text.length} chars)');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$error';
      });
      _log.error('note load failed: $path ($error)');
    }
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

  /// Whether only the preview is on screen (the editor hidden): the IME
  /// has no editable target, so it must go.
  bool get _previewOnly => !widget.splitPreview && widget.showPreview;

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
      showLineNumbers: widget.showLineNumbers,
      autofocus: widget.autofocusEditor,
      // Read from the global rather than passed down the shell: the app
      // root rebuilds everything when the setting changes, so this is
      // read fresh on the very frame the slider moves (T-M6-12).
      fontSize: AppTextScales.noteFontSize,
      scrollController: _scroll,
      onIndicator: _editorLines.attach,
      findController: _findController,
      findBuilder: (context, controller, readOnly) =>
          CopistFindPanel(controller: controller, readOnly: readOnly),
      shortcutsActivators: const CopistShortcutsActivatorsBuilder(),
    ),
  );

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
        )
      : _buildEditor();

  /// The preview, at the *note* text size rather than the interface one
  /// (T-M6-12).
  ///
  /// The app root put the interface scale on every MediaQuery below it;
  /// here it is replaced, so the same note reads the same size whichever
  /// pane shows it.
  Widget _buildPreview(BuildContext context) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: noteTextScalerOf(context)),
    child: MarkdownPreview(
      data: _previewText,
      controller: _previewScroll,
      scrollMap: _previewMap,
      mathCache: _mathCache,
      imageDirectory: widget.libraryRoot,
      onTapLink: (text, href, title) => unawaited(_openHref(href ?? '')),
      onWikiLink: (ref, display) => unawaited(_openWiki(ref)),
      embedResolver: _resolveEmbed,
    ),
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
      await _openWiki(parseWikiRef(raw.substring(2, raw.length - 2)));
    } else {
      final close = raw.indexOf(']');
      final href = close < 0 ? '' : raw.substring(close + 2, raw.length - 1);
      await _openHref(href);
    }
  }

  /// T-M2-09: pick an image, copy it into the library's `assets/`, insert a
  /// library-relative link at the caret.
  Future<void> _insertImage() async {
    final root = widget.libraryRoot;
    if (root == null) return;
    final source = await (widget.pickImagePath?.call() ?? _pickImageFile());
    if (source == null || !mounted) return;
    final relative =
        await (widget.importImage?.call(root, source) ??
            importImageToLibrary(libraryRoot: root, sourcePath: source));
    if (!mounted) return;
    // Alt text comes from the picked file's name; the link itself is the
    // content-addressed library path, so `photo.png` keeps a readable label.
    final label = p.basenameWithoutExtension(source);
    final snippet = '![$label]($relative)';
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
            .map(_parseOutlineRow)
            .whereType<OutlineEntry>()
            .toList();
      });
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

  static OutlineEntry? _parseOutlineRow(String row) {
    final parts = row.split('|');
    if (parts.length < 3) return null;
    final line = int.tryParse(parts[0]);
    final level = int.tryParse(parts[1]);
    if (line == null || level == null) return null;
    return OutlineEntry(
      line: line,
      level: level,
      text: parts.sublist(2).join('|'),
    );
  }

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
    if (!widget.showPreview || !mounted) return;
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

  /// The preview's link handler (T-M3-07): `.md` relative links navigate
  /// in-app, http(s) launch the browser, `#anchor` stays local.
  Future<void> _openHref(String href) async {
    const log = AppLogger(name: 'links');
    final source = widget.linkSource;
    log.debug(
      'md link tap in ${p.basename(widget.path)}: href="$href" '
      '(source ${source == null ? 'not loaded' : 'ready'})',
    );
    if (source == null) return;
    final resolved = await source.resolveMarkdown(href);
    log.debug('md link "$href" -> ${_describe(resolved)}');
    await _applyResolved(resolved);
  }

  /// The preview's wikilink handler: `[[x]]` targets resolve and open;
  /// empty-target forms (`[[#h]]`, `[[|a]]`) stay local.
  Future<void> _openWiki(WikiRef ref) async {
    const log = AppLogger(name: 'links');
    final source = widget.linkSource;
    final alias = ref.alias == null ? '-' : '"${ref.alias}"';
    final heading = ref.heading == null ? '-' : '"${ref.heading}"';
    final src = source == null ? 'not loaded' : 'ready';
    log.debug(
      'wikilink tap in ${p.basename(widget.path)}: '
      'target="${ref.target}" alias=$alias heading=$heading (source $src)',
    );
    if (ref.target.isEmpty) {
      final heading = ref.heading;
      if (heading == null) {
        log.debug('wikilink: empty target and no heading — snackbar');
        return _linkSnack(AppStrings.unresolvedLinkTitle);
      }
      log.debug('wikilink: local anchor — jump to heading "$heading"');
      _jumpToAnchor(heading);
      return;
    }
    if (source == null) return;
    // The documented form: `[[target]]`, `[[target#heading]]`,
    // `[[target|alias]]` — the first part is the target.
    var resolved = await source.resolveWiki(ref.target);
    log.debug('wikilink target "${ref.target}" -> ${_describe(resolved)}');
    var anchor = ref.heading;
    if (resolved is! ResolvedNote && ref.alias != null) {
      // Label-first links — `[[a label|filename]]`, the display text
      // first — parse with the target and alias swapped, so when the
      // target-first interpretation finds nothing, the aliased part is
      // tried as the target (an optional `#heading` rides on it) before
      // the link is declared dead. A link whose first part resolves
      // never reaches this fallback.
      final alias = ref.alias!;
      final hash = alias.indexOf('#');
      final aliasTarget = hash == -1 ? alias : alias.substring(0, hash);
      final aliasHeading = hash == -1 || hash == alias.length - 1
          ? null
          : alias.substring(hash + 1);
      if (aliasTarget.trim().isNotEmpty) {
        log.debug(
          'wikilink: target-first unresolved — retrying the aliased '
          'part "$aliasTarget" as the target',
        );
        final swapped = await source.resolveWiki(aliasTarget.trim());
        log.debug('wikilink alias "$aliasTarget" -> ${_describe(swapped)}');
        if (swapped is ResolvedNote || swapped is AmbiguousNote) {
          resolved = swapped;
          anchor = aliasHeading;
        }
      }
    }
    if (resolved is ResolvedNote) {
      // The parser splits `[[x#H]]` off before the resolver sees it, so
      // the anchor is carried from the ref (or from a label-first
      // `#heading` on the aliased target).
      await _openNoteResult(resolved.note, anchor ?? resolved.heading);
      return;
    }
    await _applyResolved(resolved);
  }

  /// One-line summary of a resolution, for the link trace.
  static String _describe(ResolveResult resolved) {
    return switch (resolved) {
      ExternalLink(:final url) => 'ExternalLink($url)',
      LocalAnchor(:final heading) => 'LocalAnchor(#$heading)',
      ResolvedNote(:final note) => 'ResolvedNote(${note.path})',
      AmbiguousNote(:final candidates) =>
        'AmbiguousNote(${candidates.length} candidates)',
      UnresolvedNote(:final target) => 'UnresolvedNote("$target")',
    };
  }

  Future<void> _applyResolved(ResolveResult resolved) async {
    const log = AppLogger(name: 'links');
    switch (resolved) {
      case ExternalLink(:final url):
        log.debug('link outcome: launching url $url');
        try {
          await launchUrl(Uri.parse(url));
        } on Object {
          if (mounted) _linkSnack(AppStrings.openLinkFailed);
        }
      case LocalAnchor(:final heading):
        log.debug('link outcome: jump to local heading "$heading"');
        _jumpToAnchor(heading);
      case ResolvedNote(:final note, :final heading):
        await _openNoteResult(note, heading);
      case AmbiguousNote(:final candidates):
        log.debug(
          'link outcome: ${candidates.length} ambiguous candidates — '
          'picker',
        );
        await _pickAmbiguous(candidates);
      case UnresolvedNote():
        log.debug('link outcome: unresolved — snackbar');
        if (mounted) _linkSnack(AppStrings.unresolvedLinkTitle);
    }
  }

  /// Opens [note] via the shell (or jumps locally when it is already the
  /// open note).
  Future<void> _openNoteResult(Note note, String? anchor) async {
    const log = AppLogger(name: 'links');
    final root = widget.libraryRoot;
    final currentRel = root == null
        ? null
        : p.relative(widget.path, from: root);
    if (currentRel != null && note.path == currentRel) {
      // Same note: stay and jump (or nothing when there is no anchor).
      log.debug(
        'link outcome: target is the current note — '
        '${anchor == null ? 'no-op' : 'local jump to "$anchor"'}',
      );
      if (anchor != null) _jumpToAnchor(anchor);
      return;
    }
    final open = widget.onOpenNote;
    if (open == null) {
      log.debug(
        'link outcome: resolved ${note.path} but no onOpenNote — '
        'snackbar',
      );
      if (mounted) _linkSnack(AppStrings.unresolvedLinkTitle);
      return;
    }
    log.debug(
      'link outcome: open ${note.path} '
      'anchor=${anchor == null ? '-' : '"$anchor"'}',
    );
    open(note.path, anchor);
  }

  /// The minimal ambiguous-link picker (M3 list + select; polish M6).
  Future<void> _pickAmbiguous(List<Note> candidates) async {
    if (!mounted) return;
    final chosen = await showDialog<Note>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppStrings.ambiguousLinkTitle),
        children: [
          for (final note in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, note),
              child: Text(note.path),
            ),
        ],
      ),
    );
    if (chosen != null) await _openNoteResult(chosen, null);
  }

  /// Jumps to the heading whose slug matches [heading] (the shared slug,
  /// so `[[x#My Heading]]` and `## My Heading` agree).
  void _jumpToAnchor(String heading) {
    final slug = headingSlug(heading);
    OutlineEntry? entry;
    for (final e in _outline) {
      if (headingSlug(e.text) == slug) {
        entry = e;
        break;
      }
    }
    if (entry == null) {
      // Trace the outline so a dead anchor is diagnosable from the log:
      // is the heading missing, or does its text differ from the link's?
      final entries = _outline;
      final shown = entries.length <= 40
          ? entries
          : [...entries.take(20), ...entries.skip(entries.length - 20)];
      const AppLogger(name: 'links').debug(
        'heading "$heading" (slug "$slug") not found among '
        '${entries.length} outline entr(ies): '
        '${shown.map((e) => '${e.line}:"${e.text}"').join(', ')}',
      );
      _linkSnack(AppStrings.headingNotFoundTitle);
      return;
    }
    _jumpToHeading(entry.line);
  }

  void _linkSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus) unawaited(_save());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.info('lifecycle: ${state.name}');
    if (state == AppLifecycleState.paused) unawaited(_save());
  }

  /// Saves the buffer at most once: a request that finds a save in flight
  /// coalesces into one trailing save (the text is re-read from the buffer
  /// at that point, so nothing is lost) and returns the write already
  /// running, so an awaiting caller still learns when the disk moved.
  Future<void> _save({String? path}) {
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
    _log.info('save start: $target (${text.length} chars, join $joinMs ms)');
    try {
      await _write(target, text);
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
        scan: _scanSpelling,
        apply: _applySpelling,
        available: spell.available,
      ),
    );
    if (mounted) setState(() {});
  }

  /// The whole note's issues, in reading order (the panel's pass).
  List<SpellIssue> _scanSpelling() {
    final spell = widget.spellCheck;
    if (spell == null) return const <SpellIssue>[];
    if (widget.showWysiwyg) {
      final state = _wysiwygKey.currentState;
      if (state == null) return const <SpellIssue>[];
      return spell.scan(<SpellLine>[
        for (final line in state.plainTextLines)
          (text: line, skip: const <TextRange>[]),
      ]);
    }
    final lines = _controller.codeLines;
    return spell.scan(<SpellLine>[
      for (var i = 0; i < lines.length; i++)
        (text: lines[i].text, skip: spellSkipRanges(_highlight.tokensOf(i))),
    ]);
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
    if (_error != null) return 'error';
    if (_loading) return 'loading…';
    if (_saving) return 'saving…';
    if (_revision != _lastSavedRevision) return 'unsaved';
    return 'saved';
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

  @override
  Widget build(BuildContext context) {
    final error = _error;
    // The WYSIWYG surface is never split: it already is a rendering, and the
    // shell's previewSplits agrees — this is the belt to its braces.
    final split = widget.splitPreview && !widget.showWysiwyg;
    // The toolbar formats the editor: it stays in split mode (the editor
    // is on screen) and hides in full-screen preview mode.
    // Hiding every button hides the toolbar itself; the editor keeps its
    // keyboard shortcuts.
    final showToolbar =
        (split || !widget.showPreview) &&
        widget.toolbarLayout.visible.isNotEmpty;
    // Kind mode (T-TK-02): a known `type` swaps the body for the kind GUI
    // and hides the editor chrome (outline, status row, toolbar) — the
    // note is a list, not a document, on screen.
    final kindGui = _noteKind == null ? null : NoteKinds.forType(_noteKind);
    final kindBody = widget.kindMode && kindGui != null;
    return Column(
      children: [
        // Desktop: the toolbar is editor chrome, above the editor, with a
        // divider setting it off the text. Phone: it extends the keyboard,
        // below (see the bottom slot).
        if (widget.toolbarTop && !kindBody && !_loading)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: showToolbar
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_toolbar(context), const Divider(height: 1)],
                  )
                : const SizedBox(width: double.infinity),
          ),
        Expanded(
          child: error == null
              ? (!_ready || _loading
                    ? const Center(child: CircularProgressIndicator())
                    : kindBody
                    ? kindGui.buildBody(context, _kindHost)
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
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, animation) =>
                            FadeTransition(opacity: animation, child: child),
                        // The outgoing pane leaves immediately: an
                        // editor and its twin must never coexist.
                        layoutBuilder: (currentChild, previousChildren) =>
                            currentChild ?? const SizedBox.shrink(),
                        child: widget.showPreview
                            ? KeyedSubtree(
                                key: const ValueKey('pane-preview'),
                                child: _buildPreview(context),
                              )
                            : KeyedSubtree(
                                key: ValueKey(
                                  widget.showWysiwyg
                                      ? 'pane-wysiwyg'
                                      : 'pane-editor',
                                ),
                                child: _editorPane(),
                              ),
                      ))
              : Center(child: Text(error)),
        ),
        if (!kindBody) ...[
          SafeArea(
            // The bottom chrome only: top stays false so the status-bar
            // inset is never inserted between the preview and this row
            // (issue #3: that gap read as empty space above the toolbar).
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_loading && _frontmatterError != null)
                  _frontmatterWarning(context, _frontmatterError!),
                _statusRow(context),
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
                        ? _toolbar(context)
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
  Widget _frontmatterWarning(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('frontmatter-error'),
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 16,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.frontmatterInvalid(message),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The status row (T-UI-07): outline toggle + word count left, saved/
  /// unsaved right.
  Widget _statusRow(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelSmall;
    return Padding(
      key: const Key('status-row'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Row(
        children: [
          if (!_loading)
            IconButton(
              key: const Key('outline-toggle'),
              tooltip: AppStrings.outlineTooltip,
              icon: const Icon(Icons.toc),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
              onPressed: () => unawaited(_openOutline()),
            ),
          // Find & replace lives in the editor pane (hidden in
          // preview-only mode).
          if (!_loading && (widget.splitPreview || !widget.showPreview))
            IconButton(
              key: const Key('editor-find-open'),
              tooltip: AppStrings.findInNoteTooltip,
              icon: const Icon(Icons.search),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
              onPressed: widget.showWysiwyg
                  ? () => _wysiwygKey.currentState?.openFind()
                  : _findController.findMode,
            ),
          if (!_loading &&
              widget.spellCheck != null &&
              widget.spellCheck!.available)
            IconButton(
              key: const Key('spell-check-open'),
              tooltip: AppStrings.spellCheckTooltip,
              icon: const Icon(Icons.spellcheck),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
              onPressed: () => unawaited(_openSpellCheck()),
            ),
          // The quick way between the two editors (T-WYS-12): the setting
          // stays per library, the button just flips it.
          if (!_loading && widget.onEditorKindChanged != null)
            IconButton(
              key: const Key('editor-kind-toggle'),
              tooltip: widget.showWysiwyg
                  ? AppStrings.switchToSourceTooltip
                  : AppStrings.switchToWysiwygTooltip,
              icon: Icon(
                widget.showWysiwyg ? Icons.code : Icons.edit_note,
                size: 18,
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
              onPressed: _toggleEditorKind,
            ),
          if (!_loading)
            Text(
              '$_wordCount words',
              style: labelStyle?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const Spacer(),
          Text(_status, style: labelStyle),
          for (final action in widget.statusActions) ...[
            const SizedBox(width: 6),
            action,
          ],
        ],
      ),
    );
  }

  /// The formatting toolbar (T-UI-08): pure markdown commands applied
  /// through the controller; the image button keeps the file-picker flow
  /// (T-M2-09) it already had in the status row.
  ///
  /// The toolbar is an extension of the keyboard: re_editor unfocuses the
  /// editor on any tap outside its tap region (every toolbar tap dismissed
  /// and re-showed the keyboard), so the toolbar joins the editor's tap
  /// region and tapping it keeps the editor focused.
  Widget _toolbar(BuildContext context) {
    final actions = _toolbarActions();
    // The re_editor tap region keeps the keyboard up for the source editor;
    // the WYSIWYG surface has its own focus handling, and publishes which
    // formats are on at the caret so a pressed button stays pressed until
    // it is toggled off (T-WYS-06).
    if (!widget.showWysiwyg) {
      return CodeEditorTapRegion(
        child: _toolbarBar(actions, const <ToolbarItem>{}),
      );
    }
    return ValueListenableBuilder<Set<ToolbarItem>>(
      valueListenable: _wysiwygActive,
      builder: (context, active, _) => _toolbarBar(actions, active),
    );
  }

  Widget _toolbarBar(
    Map<ToolbarItem, VoidCallback> actions,
    Set<ToolbarItem> active,
  ) => EditorToolbar(
    buttons: [
      for (final item in widget.toolbarLayout.visible)
        EditorToolbarButton(
          key: item.widgetKey,
          icon: item.icon,
          tooltip: item.label,
          active: active.contains(item),
          onPressed: actions[item]!,
        ),
    ],
  );

  /// What each toolbar button does. The catalogue and the order live in
  /// `editor/toolbar_item.dart`; the commands stay here, with the
  /// controller they act on.
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
    };
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
    _controller.selection = _codeLineSelection(edit.selection);
    _focus.requestFocus();
  }

  /// Converts a whole-text [selection] to the controller's line+offset
  /// form (the inverse of [_textSelection]).
  CodeLineSelection _codeLineSelection(TextSelection selection) {
    final text = _controller.text;
    final (baseIndex, baseOffset) = _lineAndOffset(text, selection.baseOffset);
    final (extentIndex, extentOffset) = _lineAndOffset(
      text,
      selection.extentOffset,
    );
    return CodeLineSelection(
      baseIndex: baseIndex,
      baseOffset: baseOffset,
      extentIndex: extentIndex,
      extentOffset: extentOffset,
    );
  }

  /// The (line, offset-within-line) for the absolute [offset] in [text].
  (int, int) _lineAndOffset(String text, int offset) {
    var line = 0;
    var lineStart = 0;
    for (var i = 0; i < offset && i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        line++;
        lineStart = i + 1;
      }
    }
    return (line, offset - lineStart);
  }

  void _wrapSelection({required String left, required String right}) {
    _applyMarkdownEdit(
      wrapSelection(
        text: _controller.text,
        selection: _textSelection(_controller.selection),
        left: left,
        right: right,
      ),
    );
  }

  void _insertCodeBlock() {
    _applyMarkdownEdit(
      codeBlock(
        text: _controller.text,
        selection: _textSelection(_controller.selection),
      ),
    );
  }

  void _prefixLines({required String prefix}) {
    _applyMarkdownEdit(
      prefixLines(
        text: _controller.text,
        selection: _textSelection(_controller.selection),
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
        selection: _textSelection(_controller.selection),
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
        selection: _textSelection(_controller.selection),
      ),
    );
  }

  /// Indents (or outdents, [outdent] true) the selected line(s) by the
  /// width chosen in settings.
  void _indentLines({required bool outdent}) {
    _applyMarkdownEdit(
      indentLines(
        text: _controller.text,
        selection: _textSelection(_controller.selection),
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
        selection: _textSelection(_controller.selection),
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
    if (item == ToolbarItem.image || item == ToolbarItem.heading) return;
    state.requestEditorFocus();
  }

  /// The Quill commands over the open surface's controller.
  QuillEditorCommands _quillCommands(WysiwygEditorState state) =>
      QuillEditorCommands(
        controller: state.controller,
        onLink: _insertQuillLink,
        onImage: _insertQuillImage,
        onHeading: _showQuillHeadingDialog,
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
            importImageToLibrary(libraryRoot: root, sourcePath: source));
    if (!mounted) return;
    final label = p.basenameWithoutExtension(source);
    final snippet = '![$label]($relative)';
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

  /// Converts re_editor's line+offset selection to whole-text offsets
  /// (called once per toolbar tap, so the O(n) scan is fine).
  TextSelection _textSelection(CodeLineSelection selection) {
    return TextSelection(
      baseOffset: _globalOffset(selection.baseIndex, selection.baseOffset),
      extentOffset: _globalOffset(
        selection.extentIndex,
        selection.extentOffset,
      ),
    );
  }

  int _globalOffset(int line, int offset) {
    final text = _controller.text;
    var index = 0;
    for (var current = 0; current < line; current++) {
      final nl = text.indexOf('\n', index);
      if (nl < 0) return text.length;
      index = nl + 1;
    }
    return index + offset;
  }
}

/// The [UnsavedNote] view over [_NoteViewState]'s revision pair
/// (T-PP-11): no text copy, so the dirty bit cannot drift from the buffer.
final class _UnsavedNoteAdapter implements UnsavedNote {
  const new(this._state);

  final _NoteViewState _state;

  @override
  String get path => _state.widget.path;

  @override
  // While a load is in flight the buffer holds the outgoing note and the
  // incoming one has nothing to save yet: not dirty, so a close landing on
  // the swap cannot write stale text under the new path.
  bool get unsaved =>
      !_state._loading && _state._revision != _state._lastSavedRevision;

  @override
  Future<void> save() => _state._saveForClose();
}

/// The kind GUIs' window onto the note (T-TK-02): the buffer text, and
/// byte-stable edits that persist through the regular save path.
final class _NoteKindHost implements NoteKindHost {
  new(this._state);

  final _NoteViewState _state;

  @override
  String get text => _state._currentText;

  @override
  void applyEdit(String newText) => _state._applyKindEdit(newText);
}

/// Shows the heading-level picker (H1..H6); resolves to the chosen level
/// (1..6) or null (dismissed).
Future<int?> showHeadingLevelDialog(BuildContext context) {
  return showActionSheet<int>(
    context,
    sheetKey: const Key('heading-level-sheet'),
    title: AppStrings.headingDialogTitle,
    items: (context) => [
      for (var level = 1; level <= 6; level++)
        ListTile(
          key: ValueKey<int>(level),
          onTap: () => Navigator.of(context).pop(level),
          // The label is set in the size the heading will be, which says
          // more about the choice than the number does.
          title: Text(
            AppStrings.headingLevelLabel(level),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 26.0 - level * 2),
          ),
        ),
    ],
  );
}
