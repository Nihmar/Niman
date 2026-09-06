import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:copist/src/core/files.dart';
import 'package:copist/src/core/logging.dart';
import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/note_editor.dart';
import 'package:flutter/material.dart';

/// Opens a note file in the M2a line editor and keeps disk in sync.
///
/// The file is the source of truth (design.md): the initial read happens
/// off the UI isolate (a full-file read is a FUSE round trip on Android),
/// and saves are atomic. Edits persist ~500 ms after the last keystroke,
/// on focus loss, and when the app is hidden.
///
/// Line endings: the buffer uses LF (the line editor is line-based); `\r`
/// is stripped on load and the save writes LF. Restoring the file's original
/// line ending on save is a deferred refinement (record it per note).
final class NoteView extends StatefulWidget {
  /// Opens the note at [path].
  const NoteView({
    required this.path,
    this.readNote,
    this.writeNote,
    this.input,
    super.key,
  });

  /// Absolute path of the note file.
  final String path;

  /// Reads a note's content. Defaults to an off-isolate file read.
  final Future<String> Function(String path)? readNote;

  /// Persists a note's content. Defaults to an atomic file write.
  final Future<void> Function(String path, String content)? writeNote;

  /// The editor's buffer (a test seam; the editor creates one by default).
  final ComposingInput? input;

  @override
  State<NoteView> createState() => _NoteViewState();
}

final class _NoteViewState extends State<NoteView>
    with WidgetsBindingObserver {
  static const AppLogger _log = AppLogger(name: 'editor');

  late final FocusNode _focus;

  /// The editor's buffer: owned here so the save path can read the buffer
  /// text without a full string crossing the widget tree per keystroke
  /// (M2a fix P1) — the editor edits it, the save reads it.
  late final ComposingInput _input;

  bool _loading = true;
  bool _saving = false;
  bool _savePending = false;
  String? _error;
  String? _loadedContent;
  Timer? _saveTimer;

  /// The buffer [ComposingInput.revision] the disk currently matches. The
  /// dirty flag is `revision != _lastSavedRevision` (a saved note is a
  /// revision, not a text copy).
  int _lastSavedRevision = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focus = FocusNode();
    _focus.addListener(_onFocusChanged);
    _input = widget.input ?? ComposingInput('');
    // A seam buffer (a test) arrives with its content already loaded; the
    // file load below re-anchors it to the disk text.
    _lastSavedRevision = _input.revision;
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
      if (!_saving && _input.revision != _lastSavedRevision) {
        unawaited(_save(path: oldWidget.path));
      }
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_input.revision != _lastSavedRevision) unawaited(_save());
    _focus.dispose();
    super.dispose();
  }

  Future<String> _read(String path) => widget.readNote?.call(path) ??
      Isolate.run(() => File(path).readAsString());

  Future<void> _write(String path, String content) async {
    final seam = widget.writeNote;
    if (seam != null) {
      await seam(path, content);
      return;
    }
    // Encode + atomic write off the UI isolate (the ~4 s save freeze, M2a
    // fix P3): the utf8 encode is an O(n) string pass and the write the
    // FUSE round trips — neither may touch the UI frame.
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
      _error = null;
    });
    final clock = Stopwatch()..start();
    try {
      final content = await _read(path);
      if (!mounted || widget.path != path) return;
      // The line editor is line-based: normalize to LF (strip \r).
      final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      _input.reset(text);
      _loadedContent = text;
      _lastSavedRevision = _input.revision;
      setState(() => _loading = false);
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

  void _onUserEdit(int revision) {
    if (_loading) return;
    // No text, no setState: the revision is the dirty flag and the status
    // line follows the save state only (M2a fix P1/P3 — no parent rebuild
    // per keystroke). The debounce lengthens while a save is in flight
    // (typing fast: one trailing save, not a queue).
    _saveTimer?.cancel();
    final debounce = _saving
        ? const Duration(seconds: 1)
        : const Duration(milliseconds: 500);
    _saveTimer = Timer(debounce, _save);
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
    final revision = _input.revision;
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
    // the keystroke path (M2a fix P1).
    final joinClock = Stopwatch()..start();
    final text = _input.text;
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

  String get _status {
    if (_error != null) return 'error';
    if (_loading) return 'loading…';
    if (_saving) return 'saving…';
    if (_input.revision != _lastSavedRevision) return 'unsaved';
    return 'saved';
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final content = _loadedContent;
    return Column(
      children: [
        Expanded(
          child: error == null
              ? (content == null || _loading
                  ? const Center(child: CircularProgressIndicator())
                  : NoteEditor(
                      key: ValueKey(widget.path),
                      initialText: content,
                      focusNode: _focus,
                      onTextChanged: _onUserEdit,
                      input: _input,
                    ))
              : Center(child: Text(error)),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            child: Text(
              _status,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      ],
    );
  }
}
