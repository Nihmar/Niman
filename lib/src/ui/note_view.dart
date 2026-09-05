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
  bool _loading = true;
  bool _dirty = false;
  bool _saving = false;
  String? _error;
  String? _loadedContent;
  String? _text;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focus = FocusNode();
    _focus.addListener(_onFocusChanged);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant NoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _saveTimer?.cancel();
      // Persist the outgoing note under its own path before the buffer is
      // replaced by the incoming one.
      unawaited(_save(path: oldWidget.path, content: _text));
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (_dirty) unawaited(_save());
    _focus.dispose();
    super.dispose();
  }

  Future<String> _read(String path) => widget.readNote?.call(path) ??
      Isolate.run(() => File(path).readAsString());

  Future<void> _write(String path, String content) =>
      widget.writeNote?.call(path, content) ??
      writeFileAtomically(File(path), utf8.encode(content));

  Future<void> _load() async {
    final path = widget.path;
    setState(() {
      _loading = true;
      _error = null;
      _dirty = false;
    });
    final clock = Stopwatch()..start();
    try {
      final content = await _read(path);
      if (!mounted || widget.path != path) return;
      // The line editor is line-based: normalize to LF (strip \r).
      final text = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
      _loadedContent = text;
      _text = text;
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

  void _onUserEdit(String text) {
    if (_loading) return;
    _text = text;
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _save);
    if (mounted) setState(() {});
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus) unawaited(_save());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) unawaited(_save());
  }

  Future<void> _save({String? path, String? content}) async {
    if (!_dirty || _saving) return;
    final target = path ?? widget.path;
    final text = content ?? _text ?? '';
    _saving = true;
    final clock = Stopwatch()..start();
    try {
      await _write(target, text);
      _dirty = false;
      _log.info(
        'note saved: $target (${text.length} chars, '
        '${clock.elapsedMilliseconds} ms)',
      );
    } finally {
      _saving = false;
      if (mounted) setState(() {});
    }
  }

  String get _status {
    if (_error != null) return 'error';
    if (_loading) return 'loading…';
    if (_saving) return 'saving…';
    if (_dirty) return 'unsaved';
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
                      input: widget.input,
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
