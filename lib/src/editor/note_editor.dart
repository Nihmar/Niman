import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/note_editor_client.dart';
import 'package:copist/src/editor/row_model.dart';
import 'package:copist/src/editor/virtualized_text_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The interactive line editor (M2a E8d): a virtualized text view over a
/// [ComposingInput], driven by the platform IME through [NoteEditorClient].
///
/// [initialText] is the note content. [onTextChanged] fires with the full
/// buffer text after every *text* edit (autosave subscribes to it; selection
/// and composing-only changes do not fire it). The [focusNode] shows/hides
/// the IME and lets the owner save on focus loss.
///
/// The view owns the [TextInputConnection] (attached on focus); the client
/// reports the values it must push back through [NoteEditorClient.onPushValue].
final class NoteEditor extends StatefulWidget {
  /// Creates the editor over [initialText].
  ///
  /// [input] is a test seam: when given, it is used as the buffer instead of
  /// creating one from [initialText], so a test can drive
  /// [ComposingInput.apply] directly.
  const NoteEditor({
    required this.initialText,
    required this.focusNode,
    required this.onTextChanged,
    this.columns = 80,
    this.input,
    super.key,
  });

  /// The note content the editor starts with (ignored when [input] is given).
  final String initialText;

  /// The focus node; the IME shows on focus and hides on blur.
  final FocusNode focusNode;

  /// Fires with the full buffer text after every text edit.
  final ValueChanged<String> onTextChanged;

  /// The monospace grid width in characters (the visual-row wrap width).
  final int columns;

  /// The buffer to edit, or null to create one from [initialText].
  @visibleForTesting
  final ComposingInput? input;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

final class _NoteEditorState extends State<NoteEditor> {
  late final ComposingInput _input;
  late final NoteEditorClient _client;
  late final RowModel _rows;
  TextInputConnection? _connection;
  int _lastRevision = -1;

  @override
  void initState() {
    super.initState();
    _input = widget.input ?? ComposingInput(widget.initialText);
    _client = NoteEditorClient(
      input: _input,
      onPushValue: _pushValue,
      onAction: _onAction,
      onConnectionClosed: _onConnectionClosed,
    );
    _rows = RowModel(_input.buffer, columns: widget.columns);
    _lastRevision = _input.revision;
    _input.addListener(_onChange);
    widget.focusNode.addListener(_onFocusChanged);
  }

  /// Forwards a resync value from the client to the platform.
  void _pushValue(TextEditingValue value) {
    _connection?.setEditingState(value);
  }

  void _onAction(TextInputAction action) {
    // IME-action handling (newline / done) is a later sub-step.
  }

  void _onConnectionClosed() {
    // The platform dismissed the keyboard; the connection is already closed.
  }

  void _onFocusChanged() {
    if (widget.focusNode.hasFocus) {
      final connection =
          TextInput.attach(_client, const TextInputConfiguration());
      _connection = connection;
      connection
        ..setEditingState(_input.value)
        ..show();
    } else {
      _connection?.close();
      _connection = null;
    }
  }

  void _onChange() {
    _rows.sync();
    final revision = _input.revision;
    final textChanged = revision != _lastRevision;
    _lastRevision = revision;
    if (!mounted) return;
    setState(() {});
    if (textChanged) widget.onTextChanged(_input.text);
  }

  @override
  void dispose() {
    _connection?.close();
    widget.focusNode.removeListener(_onFocusChanged);
    _input.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VirtualizedTextView(model: _rows);
  }
}
