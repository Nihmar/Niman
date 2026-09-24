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
// And the platform does not hold the note: it holds a **window** of it, a few
// thousand characters of whole lines around the caret (§8.7.1). An IME reads
// the words around the caret and nothing else, and a whole note on the channel
// is a whole note encoded, sent, decoded and — on Android and Windows, whose
// deltas carry `oldText` — sent back, per keystroke: 7 ms of encoding alone at
// the 1 MB target, and a stress test at 22 MB spent 650 ms a keystroke. The
// window moves when the caret nears its edge; what the platform says is in
// window offsets, and is moved into the note's by the window's start.
//
// "What the platform has" is that window, kept as the value the platform was
// last told or last reported; it agrees with the note when the note's text over
// the same range is the same — a comparison the size of the window, not of the
// note.
import 'dart:math' as math;

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
    required this.selection,
    required this.onSelection,
    required this.onTokenizer,
    this.onRecord,
    this.onNewline,
    this.onTyped,
  });

  /// The frames this surface's edits are logged under.
  static const AppLogger _log = AppLogger(name: 'edit');

  /// The note being edited.
  final SourceBuffer buffer;

  /// Called after every edit the platform asked for, so the view can repaint.
  final SourceEdited onEdited;

  /// Called after an edit is applied, with what it replaced and what the note
  /// stored in its place, so a history can undo it.
  final void Function(EditRecord record)? onRecord;

  /// Asked when the platform types a line break over `[start, end)`: true when
  /// the surface put in something of its own instead (the next list marker),
  /// in which case the platform's line break is not applied and the platform
  /// is told what the note now says.
  final bool Function(int start, int end)? onNewline;

  /// Asked when the platform types `inserted` over `[start, end)` outside a
  /// composition — a keystroke, or the soft keyboard's delete: true when the
  /// surface made an edit of its own instead (a bracket's pair), in which
  /// case the platform's is not applied and it is told what the note says.
  final bool Function(int start, int end, String inserted)? onTyped;

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

  /// How far the platform's window reaches on each side of the caret, before
  /// it is widened to whole lines.
  static const int windowReach = 2048;

  /// How near the window's edge the caret may come before the window moves.
  static const int windowMargin = 256;

  /// Where the platform's window starts in the note.
  int get windowStart => _windowStart;
  int _windowStart = 0;

  /// What the platform holds, in window offsets, or null when that is not
  /// known (never told, or told something this side has lost track of).
  TextEditingValue? get remote => _remote;
  TextEditingValue? _remote;

  /// The note's revision when [_remote] was last seen to agree with it: until
  /// the note changes, there is nothing to compare.
  int _agreedRevision = -1;

  /// The window before the last move, for a delta the platform built before
  /// it heard of the move: it names that window's text, and its offsets are
  /// that window's.
  int _previousStart = 0;
  String? _previousText;

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
    _remote = null;
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

  /// Tells the platform what it should hold, when that is not what it holds.
  void _sync() {
    if (!isAttached || _holdSync) return;
    final value = _valueToSend();
    if (value == null) return;
    _connection!.setEditingState(value);
  }

  /// The value the platform should be told, or null when it already holds it;
  /// the value is taken as what it holds from here on.
  TextEditingValue? _valueToSend() {
    final caret = selection().clampTo(buffer.length);
    final current = _remote;
    int start;
    String text;
    if (current != null && _agrees(current) && _keeps(caret)) {
      start = _windowStart;
      text = current.text;
    } else {
      final (from, to) = _windowAround(caret);
      start = from;
      text = buffer.substring(from, to);
    }
    final value = TextEditingValue(
      text: text,
      selection: _toWindow(caret, start, text.length),
      composing: _composingIn(start, text.length),
    );
    if (current != null && start == _windowStart && current == value) {
      return null;
    }
    if (current != null && start != _windowStart) {
      _previousStart = _windowStart;
      _previousText = current.text;
    }
    _windowStart = start;
    _remote = value;
    _agreedRevision = buffer.revision;
    return value;
  }

  /// Whether [value] still says what the note says over the window.
  bool _agrees(TextEditingValue value) {
    if (_agreedRevision == buffer.revision) return true;
    final end = _windowStart + value.text.length;
    if (end > buffer.length) return false;
    if (buffer.substring(_windowStart, end) != value.text) return false;
    _agreedRevision = buffer.revision;
    return true;
  }

  /// Whether the window can stay where it is for [caret]: the caret is inside
  /// it, away from an edge that is not the note's — or the IME is composing,
  /// and moving the window under a composition ends it.
  bool _keeps(SelectionModel caret) {
    final end = _windowStart + (_remote?.text.length ?? 0);
    final at = caret.extent;
    if (at < _windowStart || at > end) return false;
    if (_validComposing().isValid && !_validComposing().isCollapsed) {
      return true;
    }
    final roomBefore = _windowStart == 0 || at - _windowStart >= windowMargin;
    final roomAfter = end == buffer.length || end - at >= windowMargin;
    return roomBefore && roomAfter;
  }

  /// The window for [caret]: [windowReach] on each side of it, the selection's
  /// other end too when it is near, widened to whole lines when they are not
  /// long, and never splitting a line break or a surrogate pair.
  (int, int) _windowAround(SelectionModel caret) {
    final length = buffer.length;
    if (length <= 2 * windowReach) return (0, length);
    var from = caret.extent - windowReach;
    var to = caret.extent + windowReach;
    if ((caret.anchor - caret.extent).abs() <= 2 * windowReach) {
      from = math.min(from, caret.anchor - windowReach ~/ 4);
      to = math.max(to, caret.anchor + windowReach ~/ 4);
    }
    from = math.max(0, from);
    to = math.min(length, to);
    // Whole lines, when the line's start is not far: an IME reading the words
    // before the caret should find a line's start there, not half a word.
    final lineStart = buffer.offsetOfLine(buffer.lineOf(from));
    if (from - lineStart <= windowReach ~/ 2) from = lineStart;
    final nextLine = buffer.lineOf(to) + 1;
    if (to < length && nextLine < buffer.lineCount) {
      final lineEnd = buffer.offsetOfLine(nextLine);
      if (lineEnd - to <= windowReach ~/ 2) to = lineEnd;
    }
    from = _snapUnit(buffer.snapOutOfTerminator(from), back: true);
    to = _snapUnit(buffer.snapOutOfTerminator(to, forward: true), back: false);
    return (from, to);
  }

  /// [offset], moved off the middle of a surrogate pair.
  int _snapUnit(int offset, {required bool back}) {
    if (offset <= 0 || offset >= buffer.length) return offset;
    final unit = buffer.substring(offset, offset + 1).codeUnitAt(0);
    if (unit < 0xDC00 || unit > 0xDFFF) return offset;
    return back ? offset - 1 : offset + 1;
  }

  /// [caret] in the offsets of a window at [start], [length] long, each end
  /// clamped into it: the platform cannot hold a selection it has not the text
  /// of.
  static TextSelection _toWindow(SelectionModel caret, int start, int length) {
    int inside(int offset) => (offset - start).clamp(0, length);
    return TextSelection(
      baseOffset: inside(caret.anchor),
      extentOffset: inside(caret.extent),
    );
  }

  /// The composing range in the offsets of a window at [start], when it lies
  /// in the window.
  TextRange _composingIn(int start, int length) {
    final range = _validComposing();
    if (!range.isValid) return TextRange.empty;
    if (range.start < start || range.end > start + length) {
      return TextRange.empty;
    }
    return TextRange(start: range.start - start, end: range.end - start);
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

  /// The window the platform holds — or, when that is not known, the one it
  /// will be told (the framework asks for this to tell it).
  @override
  TextEditingValue? get currentTextEditingValue {
    _valueToSend();
    return _remote;
  }

  /// What the platform's copy says, as this side knows it — the window it was
  /// told or reported, or the one it would be told.
  TextEditingValue get _platformValue {
    final current = _remote;
    if (current != null) return current;
    _valueToSend();
    return _remote!;
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
    final ours = _platformValue.text;
    final start = _windowStart;
    final theirs = value.text;
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
      _replace(
        start + prefix,
        start + ours.length - suffix,
        theirs.substring(prefix, theirs.length - suffix),
        _caretOf(value.selection, start),
      );
    } else {
      _reportSelection(_caretOf(value.selection, start));
    }
    _composing = _shifted(value.composing, start);
    _platformNowHas(value);
  }

  @override
  void updateEditingValueWithDeltas(List<TextEditingDelta> deltas) {
    if (deltas.isEmpty) return;
    _log.debug(
      'deltas: ${deltas.map(_short).join(", ")} '
      '(ours ${buffer.length}, caret ${selection().extent})',
    );
    var known = true;
    var value = _platformValue;
    for (final delta in deltas) {
      deltaCount++;
      // Which window the platform built this delta on: the one it holds, or
      // the one before a move it had not heard of yet.
      var origin = _windowStart;
      if (delta.oldText != value.text) {
        if (delta.oldText == _previousText) {
          origin = _previousStart;
        } else {
          // Neither: its range is applied to our window — as `EditableText`
          // applies it to its own value — and the platform is told the result.
          _log.warning(
            'platform copy ${delta.oldText.length} chars, '
            'ours ${value.text.length}',
          );
        }
        known = false;
      }
      final (from, to, inserted) = switch (delta) {
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
      var (start, end) = (origin + from, origin + to);
      // A selection wider than the window reaches the platform clamped, and
      // what it types over is the part it holds: over the whole of it, in the
      // note — select all and type is the note replaced, not a window of it.
      final wide = selection().clampTo(buffer.length);
      final held = _toWindow(wide, origin, delta.oldText.length);
      if (!wide.isCollapsed &&
          delta is! TextEditingDeltaNonTextUpdate &&
          from == held.start &&
          to == held.end) {
        (start, end) = (wide.start, wide.end);
      }
      if (delta is TextEditingDeltaNonTextUpdate) {
        _reportSelection(_caretOf(delta.selection, origin));
      } else if (from < 0 || end < start || end > buffer.length) {
        _log.warning('edit $start..$end outside the note (${buffer.length})');
        known = false;
        break;
      } else if (start == end && inserted.isEmpty) {
        _reportSelection(_caretOf(delta.selection, origin));
      } else if (inserted == '\n' && (onNewline?.call(start, end) ?? false)) {
        known = false;
      } else if (!_composes(delta) &&
          (onTyped?.call(start, end, inserted) ?? false)) {
        known = false;
      } else {
        _replace(start, end, inserted, _caretOf(delta.selection, origin));
      }
      _composing = _shifted(delta.composing, origin);
      if (known) value = delta.apply(value);
    }
    _platformNowHas(known ? value : null);
  }

  /// Whether [delta] is part of a composition, which an IME may still
  /// change: a bracket in it is not typed yet.
  static bool _composes(TextEditingDelta delta) =>
      delta.composing.isValid && !delta.composing.isCollapsed;

  /// [range], a platform range in a window at [origin], in note offsets.
  static TextRange _shifted(TextRange range, int origin) =>
      range.isValid && !range.isCollapsed
      ? TextRange(start: origin + range.start, end: origin + range.end)
      : TextRange.empty;

  /// Records what the platform's copy holds after an update it sent — [value],
  /// or null when this side cannot say — and tells it the note where that is
  /// not what the note holds: a line break stored as `\r\n`, a list marker the
  /// surface added, a delta built on a copy that was not ours.
  void _platformNowHas(TextEditingValue? value) {
    _remote = value;
    _agreedRevision = -1;
    if (value == null) {
      resyncs++;
      _sync();
      return;
    }
    final agreed = _agrees(value);
    if (!agreed) resyncs++;
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
  ///
  /// Not checked against the note's length here: a delta's caret is where it
  /// lands *after* the edit, and this is asked before the edit is applied — a
  /// keystroke at the end of the note carries a caret one past the text as it
  /// stands, and throwing that away left the caret behind every character
  /// typed there. It is clamped once the edit is in.
  SelectionModel _caretOf(TextSelection selection, int origin) =>
      selection.isValid
      ? SelectionModel(
          anchor: origin + selection.baseOffset,
          extent: origin + selection.extentOffset,
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
