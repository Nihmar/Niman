import 'package:copist/src/editor/caret_geometry.dart';
import 'package:copist/src/editor/caret_painter.dart';
import 'package:copist/src/editor/composing_input.dart';
import 'package:copist/src/editor/editor_gestures.dart';
import 'package:copist/src/editor/hit_test.dart';
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
  late final CaretGeometry _caretGeometry;
  late final HitTest _hitTest;
  late final EditorGestures _gestures;
  late final ScrollController _scrollController;
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
    final charWidth = VirtualizedTextView.measureCharWidth();
    _caretGeometry = CaretGeometry(
      rowModel: _rows,
      charWidth: charWidth,
      rowHeight: VirtualizedTextView.rowHeight,
      leftPadding: VirtualizedTextView.leftPadding,
    );
    _hitTest = HitTest(
      rows: _rows,
      rowHeight: VirtualizedTextView.rowHeight,
      charWidth: charWidth,
    );
    _gestures = EditorGestures(hitTest: _hitTest, input: _input);
    _scrollController = ScrollController();
    _lastRevision = _input.revision;
    _input.addListener(_onChange);
    widget.focusNode.addListener(_onFocusChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() => setState(() {});

  double get _scrollOffset =>
      _scrollController.hasClients ? _scrollController.offset : 0;

  /// The pointer's x relative to the text start (the [HitTest] contract is
  /// "x from the first glyph", so the row's left inset is subtracted).
  double _textX(double localX) => localX - VirtualizedTextView.leftPadding;

  /// A tap (no drag) places the caret at the tapped position.
  void _handleTapUp(TapUpDetails details) {
    _focusEditor();
    _gestures.tapAt(
      _textX(details.localPosition.dx),
      details.localPosition.dy + _scrollOffset,
    );
  }

  /// A drag begins a selection anchored at the drag start.
  void _handlePanStart(DragStartDetails details) {
    _focusEditor();
    _gestures.dragStartAt(
      _textX(details.localPosition.dx),
      details.localPosition.dy + _scrollOffset,
    );
  }

  /// A drag move extends the selection to the pointer.
  void _handlePanUpdate(DragUpdateDetails details) {
    _gestures.dragTo(
      _textX(details.localPosition.dx),
      details.localPosition.dy + _scrollOffset,
    );
  }

  /// The drag ends: the selection collapses to its caret (the E8a
  /// drag-select contract; a persistent selection is a later sub-step).
  void _handlePanEnd(DragEndDetails details) => _gestures.dragEnd();

  void _focusEditor() {
    if (!widget.focusNode.hasFocus) {
      widget.focusNode.requestFocus();
    }
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
    if (mounted) setState(() {});
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caret = _input.caret;
    // The caret is steady (no blink yet); it shows only while the editor is
    // focused and the IME is not mid-composition (the underline takes over).
    final caretVisible =
        caret != null && widget.focusNode.hasFocus && !_input.isComposing;
    return Focus(
      focusNode: widget.focusNode,
      child: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: _handleTapUp,
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            child: VirtualizedTextView(
              model: _rows,
              scrollController: _scrollController,
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: CaretPainter(
                geometry: _caretGeometry,
                caretOffset: caret ?? 0,
                composing: _input.composing,
                caretVisible: caretVisible,
                selection: _input.selection,
                scrollOffset: _scrollOffset,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
