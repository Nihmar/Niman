// The surface's connection to the platform's keyboard (#245, phase 3).
//
// A `DeltaTextInputClient` over the note's `SourceBuffer`, and the one rule
// that keeps the two copies of the note — ours and the platform's — saying the
// same thing: **the platform is told every local change at once**, the way
// `EditableText` tells it (`_updateRemoteEditingValueIfNeeded`).
//
// That rule replaces an earlier one that tried to spare the platform channel
// the note's text by not echoing, and every device bug the surface had came
// from the difference: a tap the platform never heard of was a keystroke typed
// at the old caret and a backspace that deleted nothing; a local deletion the
// platform had not heard of came back with its next delta. And the saving was
// not real: Android's `TextEditingDelta.toJSON` sends `oldText` — the whole
// note — with every delta anyway, so a delta is never "one character" on the
// channel. What the rule costs is one `setEditingState` per *local* change (a
// tap, a key the surface handles, an undo); what arrives from the platform is
// never sent back unless the note stored something else (a `\n` written as the
// note's `\r\n`).
//
// "What the platform has" is tracked as a revision, a selection and a composing
// range — three comparisons, no copy of the text.
import 'package:flutter/services.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';

/// What the surface does when the note's text changes.
typedef SourceEdited = void Function(SourceEdit edit);

/// The keyboard, wired to one note.
final class SourceInput implements DeltaTextInputClient {
  /// Wires [buffer] to the platform, reporting edits and caret moves outward.
  new({
    required this.buffer,
    required this.onEdited,
    required this.text,
    required this.selection,
    required this.onSelection,
    required this.onTokenizer,
    this.onRecord,
    this.onNewline,
  });

  /// The frames this surface's edits are logged under.
  static const AppLogger _log = AppLogger(name: 'edit');

  /// The note being edited.
  final SourceBuffer buffer;

  /// Called after every edit the platform asked for, so the view can repaint.
  final SourceEdited onEdited;

  /// The note's whole text, asked for only when the platform has to be told a
  /// whole value — a callback, because joining the note is O(n) and the view
  /// keeps it joined once per revision.
  final String Function() text;

  /// Called after an edit is applied, with what it replaced and what the note
  /// stored in its place, so a history can undo it.
  final void Function(EditRecord record)? onRecord;

  /// Asked when the platform types a line break over `[start, end)`: true when
  /// the surface put in something of its own instead (the next list marker),
  /// in which case the platform's line break is not applied and the platform
  /// is told what the note now says.
  final bool Function(int start, int end)? onNewline;

  /// Where the caret is now.
  final SelectionModel Function() selection;

  /// Where the caret goes when the platform moves it.
  final ValueChanged<SelectionModel> onSelection;

  /// The tokenizer the edits have to be handed to, so a keystroke re-tokenizes
  /// the edited lines and nothing else.
  final void Function(SourceEdit edit, SourceBuffer buffer) onTokenizer;

  TextInputConnection? _connection;

  /// Whether the platform currently has this surface attached.
  bool get isAttached => _connection?.attached ?? false;

  /// The range the IME is composing, in note offsets, or empty.
  ///
  /// The platform's to set: it arrives with a delta and goes back with every
  /// echo, because an echo without it ends the composition (§6.3.3). A local
  /// caret move ends it on this side too.
  TextRange get composing => _composing;
  TextRange _composing = TextRange.empty;

  /// The size the last whole-value update carried, for the perf trace.
  int lastWholeLength = 0;

  /// How many deltas have been applied.
  int deltaCount = 0;

  /// How many times the platform's copy had to be told the note again because
  /// it disagreed — a stored line ending, a range outside the note.
  int resyncs = 0;

  /// Whether local changes are held back (a mouse drag in progress: the
  /// platform needs the selection it ends with, not every one on the way).
  bool get holdSync => _holdSync;
  set holdSync(bool hold) {
    _holdSync = hold;
    if (!hold) _sync();
  }

  bool _holdSync = false;

  // What the platform's copy holds, as far as this side knows.
  int _remoteRevision = -1;
  SelectionModel? _remoteSelection;
  TextRange _remoteComposing = TextRange.empty;

  /// Opens the connection for the view [viewId] the surface is drawn in, or,
  /// when it is open, asks for the keyboard again.
  ///
  /// The view is not optional in practice: the Windows embedder refuses a
  /// client without one ("Could not set client, view ID is null") and every
  /// `setEditingState` after that fails. And `show` on every call, because a
  /// keyboard the user put away (Android's back button) leaves the connection
  /// open: attaching once is not asking every time.
  void attach({int? viewId}) {
    if (isAttached) {
      _connection!.show();
      return;
    }
    _log.info('attach: connecting the keyboard to the note (view $viewId)');
    _composing = TextRange.empty;
    _connection = TextInput.attach(
      this,
      TextInputConfiguration(
        viewId: viewId,
        inputType: TextInputType.multiline,
        inputAction: TextInputAction.newline,
        enableDeltaModel: true,
      ),
    )..show();
    _remoteRevision = -1;
    _sync();
  }

  /// Closes the connection.
  void detach() {
    if (_connection != null) _log.info('detach: the surface lost focus');
    _connection?.close();
    _connection = null;
    _composing = TextRange.empty;
  }

  /// Tells the platform about a change this side made — a caret move, an edit
  /// the surface applied itself, an undo, a note replaced underneath.
  ///
  /// Sent **now**, before the platform can speak again, so its next delta is
  /// built on a copy that already has the change. Sending the same state twice
  /// costs nothing: `_sync` compares what the platform has and stays silent.
  void sendSelection() {
    _composing = TextRange.empty;
    _sync();
  }

  /// Sends the note when the platform's copy is not what it holds.
  void _sync() {
    if (!isAttached || _holdSync) return;
    final caret = selection().clampTo(buffer.length);
    final composing = _validComposing();
    if (_remoteRevision == buffer.revision &&
        _remoteSelection == caret &&
        _remoteComposing == composing) {
      return;
    }
    _connection!.setEditingState(
      TextEditingValue(
        text: text(),
        selection: TextSelection(
          baseOffset: caret.anchor,
          extentOffset: caret.extent,
        ),
        composing: composing,
      ),
    );
    _remoteRevision = buffer.revision;
    _remoteSelection = caret;
    _remoteComposing = composing;
  }

  /// The composing range, when it is still inside the note.
  TextRange _validComposing() {
    final range = _composing;
    if (!range.isValid || range.isCollapsed || range.end > buffer.length) {
      return TextRange.empty;
    }
    return range;
  }

  /// A delta, short enough for a log line.
  static String _short(TextEditingDelta delta) => switch (delta) {
    TextEditingDeltaInsertion() =>
      'ins@${delta.insertionOffset}'
          '+${delta.textInserted.length} '
          '"${delta.textInserted.replaceAll('\n', '⏎')}"',
    TextEditingDeltaDeletion() =>
      'del ${delta.deletedRange.start}..${delta.deletedRange.end}',
    TextEditingDeltaReplacement() =>
      'repl ${delta.replacedRange.start}..${delta.replacedRange.end}'
          '+${delta.replacementText.length}',
    TextEditingDeltaNonTextUpdate() => 'sel ${delta.selection.start}',
    _ => 'delta',
  };

  /// Applies `[start, end)` → [inserted] to the note, and says whether the
  /// note now holds exactly what the platform does (it does not when a line
  /// break was stored as the note's own line ending).
  bool _replace(int from, int to, String inserted, SelectionModel caret) {
    // The platform addresses the whole text, line endings included, and an
    // edit that starts between a `\r` and its `\n` would split the pair.
    final start = buffer.snapOutOfTerminator(from);
    final end = buffer.snapOutOfTerminator(to, forward: true);
    final before = buffer.length;
    final removed = buffer.substring(start, end);
    final edit = buffer.replaceRange(start, end, inserted);
    onTokenizer(edit, buffer);
    final stored = buffer.length - before + (end - start);
    // The history gets what the note *stored* — a line break as the note's
    // own `\r\n` — or an undo takes away the wrong number of characters.
    onRecord?.call(
      EditRecord(
        start: start,
        removed: removed,
        inserted: buffer.substring(start, start + stored),
      ),
    );
    final exact = start == from && end == to && stored == inserted.length;
    // A caret the platform computed against its own copy is off by what the
    // note stored differently; the note's own arithmetic is not.
    final landed = exact ? caret : SelectionModel.at(start + stored);
    onSelection(landed.clampTo(buffer.length));
    onEdited(edit);
    return exact;
  }

  // -------------------------------------------------------- TextInputClient

  @override
  TextEditingValue? get currentTextEditingValue {
    final caret = selection().clampTo(buffer.length);
    return TextEditingValue(
      text: text(),
      selection: TextSelection(
        baseOffset: caret.anchor,
        extentOffset: caret.extent,
      ),
      composing: _validComposing(),
    );
  }

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValue(TextEditingValue value) {
    // The whole-value path: an embedder that does not speak deltas. The note
    // is changed by the smallest range the two texts differ in, so a keystroke
    // is still one edit and one undo step rather than a whole note replaced.
    lastWholeLength = value.text.length;
    _log.debug('whole value: ${value.text.length} chars');
    final ours = text();
    final theirs = value.text;
    var exact = true;
    if (ours != theirs) {
      var prefix = 0;
      final shortest = ours.length < theirs.length
          ? ours.length
          : theirs.length;
      while (prefix < shortest &&
          ours.codeUnitAt(prefix) == theirs.codeUnitAt(prefix)) {
        prefix++;
      }
      var suffix = 0;
      while (suffix < shortest - prefix &&
          ours.codeUnitAt(ours.length - 1 - suffix) ==
              theirs.codeUnitAt(theirs.length - 1 - suffix)) {
        suffix++;
      }
      exact = _replace(
        prefix,
        ours.length - suffix,
        theirs.substring(prefix, theirs.length - suffix),
        _caretOf(value.selection),
      );
    } else {
      _reportSelection(_caretOf(value.selection));
    }
    _composing = value.composing;
    _platformNowHas(value.selection, value.composing, exact: exact);
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> deltas) {
    if (deltas.isEmpty) return;
    _log.debug(
      'deltas: ${deltas.map(_short).join(", ")} '
      '(ours ${buffer.length}, caret ${selection().extent})',
    );
    var exact = true;
    for (final delta in deltas) {
      deltaCount++;
      if (delta.oldText.length != buffer.length) {
        // The platform built this delta on a copy that is not ours. Its range
        // is applied to ours — as `EditableText` applies it to its own value —
        // and the platform is told the result afterwards.
        _log.warning(
          'platform copy ${delta.oldText.length} chars, ours ${buffer.length}',
        );
        exact = false;
      }
      final (start, end, inserted) = switch (delta) {
        TextEditingDeltaInsertion() => (
          delta.insertionOffset,
          delta.insertionOffset,
          delta.textInserted,
        ),
        TextEditingDeltaDeletion() => (
          delta.deletedRange.start,
          delta.deletedRange.end,
          '',
        ),
        TextEditingDeltaReplacement() => (
          delta.replacedRange.start,
          delta.replacedRange.end,
          delta.replacementText,
        ),
        _ => (-1, -1, ''),
      };
      if (delta is TextEditingDeltaNonTextUpdate) {
        _reportSelection(_caretOf(delta.selection));
      } else if (start < 0 || end < start || end > buffer.length) {
        _log.warning('edit $start..$end outside the note (${buffer.length})');
        exact = false;
        break;
      } else if (start == end && inserted.isEmpty) {
        _reportSelection(_caretOf(delta.selection));
      } else if (inserted == '\n' && (onNewline?.call(start, end) ?? false)) {
        exact = false;
      } else if (!_replace(start, end, inserted, _caretOf(delta.selection))) {
        exact = false;
      }
      _composing = delta.composing;
    }
    _platformNowHas(deltas.last.selection, deltas.last.composing, exact: exact);
  }

  /// Records what the platform's copy holds after an update it sent, and tells
  /// it the note when that is not what the note holds.
  void _platformNowHas(
    TextSelection selection,
    TextRange composing, {
    required bool exact,
  }) {
    if (exact) {
      _remoteRevision = buffer.revision;
      _remoteSelection = selection.isValid
          ? SelectionModel(
              anchor: selection.baseOffset,
              extent: selection.extentOffset,
            ).clampTo(buffer.length)
          : null;
      _remoteComposing = composing.isValid && !composing.isCollapsed
          ? composing
          : TextRange.empty;
    } else {
      resyncs++;
      _remoteRevision = -1;
    }
    // Sends only what differs — nothing, for an update applied as it came.
    _sync();
  }

  /// Reports [next] when the caret really moved.
  void _reportSelection(SelectionModel next) {
    final current = selection();
    if (next.anchor == current.anchor && next.extent == current.extent) return;
    onSelection(next.clampTo(buffer.length));
  }

  /// The caret a platform update carries, when it carries a usable one — the
  /// platform sends `-1..-1` in its non-text updates, and that is not a caret.
  SelectionModel _caretOf(TextSelection selection) =>
      selection.isValid &&
          selection.baseOffset <= buffer.length &&
          selection.extentOffset <= buffer.length
      ? SelectionModel(
          anchor: selection.baseOffset,
          extent: selection.extentOffset,
        )
      : this.selection();

  @override
  void performAction(TextInputAction action) {
    // Nothing to do for `newline`: the line break has already arrived as text.
    // The Linux and Windows embedders insert `\n`, send it as a delta and
    // *then* call this action (`fl_text_input_handler.cc`,
    // `text_input_plugin.cc`), and an IME commits it the same way — so
    // inserting here as well is one Enter becoming two lines. `EditableText`
    // does nothing here for a multiline field either.
    _log.debug('action: $action');
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  // The rest of the client surface is not something a note-shaped field does;
  // each is a no-op rather than a decision (Flutter's own defaults, spelled out
  // because `implements` does not inherit them).
  @override
  bool onFocusReceived() => true;

  @override
  void showToolbar() {}

  @override
  void insertContent(KeyboardInsertedContent content) {
    // A keyboard's rich content arrives as bytes and a MIME type, not as text:
    // a note is text, so what lands is the URI the platform offered.
    final caret = selection().clampTo(buffer.length);
    _replace(
      caret.start,
      caret.end,
      content.uri,
      SelectionModel.at(caret.start + content.uri.length),
    );
    sendSelection();
  }

  @override
  void performSelector(String selectorName) {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void didChangeInputControl(
    TextInputControl? oldControl,
    TextInputControl? newControl,
  ) {}

  @override
  void connectionClosed() {
    // The next tap opens it again (`attach` answers a closed connection by
    // opening a new one) — once the framework has let go of this one, which
    // it does only when told, the way `EditableText` tells it.
    _connection?.connectionClosedReceived();
    _connection = null;
    _composing = TextRange.empty;
    _log.info('the platform closed the input connection');
  }

  /// Tells the IME where the note is on screen and where the caret is in it,
  /// so its candidate window and the phone's handles sit by the text.
  void setGeometry(Size size, Matrix4 transform, Rect caret) {
    if (!isAttached) return;
    if (size != _geometrySize || transform != _geometryTransform) {
      _geometrySize = size;
      _geometryTransform = transform;
      _connection!.setEditableSizeAndTransform(size, transform);
    }
    if (caret != _geometryCaret) {
      _geometryCaret = caret;
      _connection!.setCaretRect(caret);
    }
  }

  Size? _geometrySize;
  Matrix4? _geometryTransform;
  Rect? _geometryCaret;

  /// The tokenizer's view of an edit: the lines that changed, and nothing else.
  ///
  /// This is what keeps a keystroke off the note's whole length — the phase's
  /// 0.507 ms incremental-edit number is this call plus the buffer's own
  /// `replaceRange`.
  static void retokenize(
    HighlightDocument tokens,
    SourceEdit edit,
    SourceBuffer buffer,
  ) {
    tokens.replaceLines(edit.firstLine, edit.removedLines, <String>[
      for (var at = 0; at < edit.insertedLines; at++)
        buffer.lineAt(edit.firstLine + at),
    ]);
  }
}
