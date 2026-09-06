import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/core/settings/library_settings.dart';
import 'package:copist/src/editor/highlight_sync.dart';
import 'package:copist/src/editor/note_editor.dart';
import 'package:copist/src/editor/outline.dart';
import 'package:copist/src/preview/markdown_preview.dart';
import 'package:copist/src/preview/math_cache.dart';
import 'package:copist/src/preview/preview_work.dart';
import 'package:copist/src/preview/scroll_map.dart';
import 'package:copist/src/ui/editor_preview_split.dart';
import 'package:copist/src/ui/outline_panel.dart';
import 'package:copist/src/ui/strings.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

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
  const NoteView({
    required this.path,
    required this.showLineNumbers,
    required this.autofocusEditor,
    this.splitPreview = false,
    this.splitFraction = defaultSplitRatio,
    this.onSplitFractionChanged,
    this.onSplitDragEnd,
    this.readNote,
    this.writeNote,
    this.controller,
    super.key,
  });

  /// Absolute path of the note file.
  final String path;

  /// Whether the editor shows the row-number column (settings toggle).
  final bool showLineNumbers;

  /// Whether the editor shows the keyboard on open (settings toggle).
  final bool autofocusEditor;

  /// Whether the preview sits side by side (split) or behind a switch.
  final bool splitPreview;

  /// The editor's share of the split (0..1).
  final double splitFraction;

  /// Live divider-fraction changes (the shell keeps the settings value).
  final ValueChanged<double>? onSplitFractionChanged;

  /// The divider drag lifted (the shell persists the ratio).
  final VoidCallback? onSplitDragEnd;

  /// Reads a note's content. Defaults to an off-isolate file read.
  final Future<String> Function(String path)? readNote;

  /// Persists a note's content. Defaults to an atomic file write.
  final Future<void> Function(String path, String content)? writeNote;

  /// The editor's controller (a test seam; one is created by default).
  final CodeLineEditingController? controller;

  @override
  State<NoteView> createState() => _NoteViewState();
}

final class _NoteViewState extends State<NoteView>
    with WidgetsBindingObserver {
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
  bool _showOutline = false;

  /// Preview pane (T-M2-08): debounced text, its own scroll + map + math
  /// cache, and the switch-mode visibility.
  Timer? _previewTimer;
  String _previewText = '';
  late final ScrollController _previewScroll = ScrollController();
  late final ScrollMap _previewMap = ScrollMap();
  late final MathCache _mathCache = MathCache();
  bool _showPreview = false;

  /// Text-edit counter; the disk matches [_lastSavedRevision]. A saved note
  /// is a revision, not a text copy.
  int _revision = 0;
  int _lastSavedRevision = 0;

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
      unawaited(_load());
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
    _focus.dispose();
    _scroll.verticalScroller.dispose();
    _scroll.horizontalScroller.dispose();
    _previewScroll.dispose();
    _mathCache.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  /// Applies precomputed stats (from the load isolate) to the state.
  /// Applies precomputed stats (from the load isolate) to the state.
  void _applyStats(String text, int words, List<String> outlineRows) {
    _lastStatsText = text;
    setState(() {
      _wordCount = words;
      _outline = outlineRows
          .map(_parseOutlineRow)
          .whereType<OutlineEntry>()
          .toList();
    });
  }  Future<void> _write(String path, String content) async {
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
      if (stats != null) {
        _applyStats(text, stats.$1, stats.$2);
      }
      _controller.text = text;
      _lastLines = _controller.codeLines;
      _lastSavedRevision = _revision;
      setState(() {
        _loading = false;
        _ready = true;
      });
      // Word count + outline on open: debounced for edits only; the
      // production load already has them from its isolate (the seam path
      // uses the regular refresh).
      if (stats == null) _refreshStats();
      _refreshPreview();
      _log.info(
        'note loaded: $path (${text.length} chars, '
        '${clock.elapsedMilliseconds} ms)',
      );
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
    final text = _controller.text;
    if (text == _previewText) return;
    setState(() => _previewText = text);
  }

  Widget _buildEditor() => NoteEditor(
        key: ValueKey(widget.path),
        controller: _controller,
        focusNode: _focus,
        showLineNumbers: widget.showLineNumbers,
        autofocus: widget.autofocusEditor,
        scrollController: _scroll,
      );

  Widget _buildPreview() => MarkdownPreview(
        data: _previewText,
        controller: _previewScroll,
        scrollMap: _previewMap,
        mathCache: _mathCache,
      );

  void _refreshStats() {
    if (!mounted || _loading) return;
    final text = _controller.text;
    if (text == _lastStatsText) return;
    _lastStatsText = text;
    final revision = ++_statsRevision;
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

  /// The outline jump: caret to the heading line, then bring it into view.
  void _jumpToHeading(int line) {
    _controller.selection = CodeLineSelection.collapsed(
      index: line,
      offset: 0,
    );
    _scroll.makeCenterIfInvisible(
      CodeLinePosition(index: line, offset: 0),
    );
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus) unawaited(_save());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.info('lifecycle: ${state.name}');
    if (state == AppLifecycleState.paused) unawaited(_save());
  }

  Future<void> _save({String? path}) async {
    final revision = _revision;
    if (revision == _lastSavedRevision) return; // nothing new on disk
    if (path == null && _saving) {
      // A save is in flight: coalesce into one trailing save (the text is
      // re-read from the buffer at that point, so nothing is lost).
      _savePending = true;
      return;
    }
    _saving = true;
    final target = path ?? widget.path;
    final clock = Stopwatch()..start();
    // The full-text join (O(n)) happens here only — the save path, never
    // the keystroke path.
    final joinClock = Stopwatch()..start();
    final text = _controller.text;
    final joinMs = joinClock.elapsedMilliseconds;
    _log.info(
      'save start: $target (${text.length} chars, join $joinMs ms)',
    );
    try {
      await _write(target, text);
      if (target == widget.path) _lastSavedRevision = revision;
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

  /// The [CodeLineSpanBuilder] over [_highlight]: styles each line the
  /// editor lays out, dark/light per the app brightness.
  TextSpan _buildHighlightSpan({
    required BuildContext context,
    required int index,
    required CodeLine codeLine,
    required TextSpan textSpan,
    required TextStyle style,
  }) {
    return _highlight.spanFor(
      index: index,
      text: codeLine.text,
      base: style,
      dark: Theme.of(context).brightness == Brightness.dark,
    );
  }

  String get _status {
    if (_error != null) return 'error';
    if (_loading) return 'loading…';
    if (_saving) return 'saving…';
    if (_revision != _lastSavedRevision) return 'unsaved';
    return 'saved';
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final split = widget.splitPreview;
    return Column(
      children: [
        if (!split) _paneSwitchBar(context),
        Expanded(
          child: error == null
              ? (!_ready || _loading
                  ? const Center(child: CircularProgressIndicator())
                  : split
                      ? EditorPreviewSplit(
                          editor: _buildEditor(),
                          preview: _buildPreview(),
                          editorScroll: _scroll.verticalScroller,
                          previewScroll: _previewScroll,
                          map: _previewMap,
                          fraction: widget.splitFraction,
                          onFractionChanged: widget.onSplitFractionChanged ??
                              (_) {},
                          onDragEnd: widget.onSplitDragEnd,
                        )
                      : (_showPreview ? _buildPreview() : _buildEditor()))
              : Center(child: Text(error)),
        ),
        if (_showOutline && _outline.isNotEmpty)
          OutlinePanel(
            entries: _outline,
            onJump: _jumpToHeading,
          ),
        SafeArea(
          child: Padding(
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
                    constraints: const BoxConstraints(
                      minWidth: 34,
                      minHeight: 26,
                    ),
                    onPressed: () =>
                        setState(() => _showOutline = !_showOutline),
                  ),
                if (!_loading)
                  Text(
                    '$_wordCount words',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                Text(
                  _status,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The top switch bar (phone mode): one button flips editor ↔ preview.
  Widget _paneSwitchBar(BuildContext context) {
    return SizedBox(
      height: 34,
      child: IconButton(
        key: const Key('preview-switch'),
        tooltip: _showPreview
            ? AppStrings.showEditorTooltip
            : AppStrings.showPreviewTooltip,
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        icon: Icon(
          _showPreview ? Icons.edit : Icons.visibility,
        ),
        onPressed: () => setState(() => _showPreview = !_showPreview),
      ),
    );
  }
}
