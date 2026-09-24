/// What the shell holds of a note on the unified surface (#245, §8.7.6).
///
/// The shell's commands — the toolbar, the format keys, an image inserted, a
/// spelling fixed, a list counted, a note reloaded from disk, the WYSIWYG
/// handing text back — all edited the legacy editor's controller, which the
/// unified pane does not show: the edit went nowhere while a save was still
/// scheduled, so the command's work was lost. This is the one door they go
/// through instead.
///
/// It outlives the view: it is the shell's, one per open note, so the undo
/// history survives the pane being rebuilt (a WYSIWYG round trip, an error
/// pane, a kind GUI in front of it), and a command that arrives while no view
/// is mounted — a kind GUI's edit — still edits the note and still counts.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show TextSelection;
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/md_editing.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/editor/word_count_index.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/source_styler.dart';

/// A note on the unified surface, as the shell drives it.
final class MarkdownSurfaceController {
  /// Controls [buffer], with the caret at [caret].
  ///
  /// [words] is the note's word count already worked out, for a caller that
  /// built it off the UI isolate; without it the count is empty and
  /// [buildWords] fills it in.
  new(this.buffer, {int caret = 0, EditHistory? history, WordCount? words})
    : history = history ?? EditHistory(),
      words = words ?? WordCount(),
      _pending = SelectionModel.at(caret.clamp(0, buffer.length));

  /// The note.
  final SourceBuffer buffer;

  /// Its undo history — the shell's, so it survives the view.
  final EditHistory history;

  /// The note's word count, kept current by its edits: no pass over the text
  /// when a reader asks, and none after a pause in the typing
  /// ([WordCount]).
  final WordCount words;

  /// The revision [buffer] is at: what a caller compares to know whether
  /// what it derived from the note is still current.
  int get revision => buffer.revision;

  /// Counts the note's words in an isolate, when it has not been counted:
  /// 675 ms on a 246 MB note, so never on the UI isolate.
  ///
  /// The answer is dropped when the note moved on while it was being worked
  /// out — the next call starts again — and the count is adopted whole, so a
  /// reader never sees half of one.
  Future<void> buildWords() {
    if (words.isCounted) return Future<void>.value();
    // Asked again while the count is under way (every statistics refresh
    // asks): the same count answers, rather than a second one.
    return _counting ??= _countWords().whenComplete(() => _counting = null);
  }

  Future<void>? _counting;

  Future<void> _countWords() async {
    final revision = buffer.revision;
    final counted = await countInBackground(buffer);
    // The note was typed in while the count was worked out: what came back
    // is not its count. The next call starts again.
    if (buffer.revision != revision) return;
    // Taken as it came back: counting the buffer again here was the whole
    // pass the isolate was there to spare, on the UI isolate.
    words.adoptCount(counted);
  }

  /// The note's headings, read off a scan this controller keeps for itself.
  ///
  /// The fallback for a pane that is not on screen: a mounted source pane
  /// or read pane answers its own, and this is what a hidden tab, a kind
  /// GUI in front of the note, or a pane that has not scanned yet gets
  /// instead. Cached by revision — the scan is O(note), and the caller asks
  /// on every statistics refresh.
  List<OutlineEntry>? get headings {
    final styler = _styler;
    if (styler != null && _stylerRevision == styler.revision) return _headings;
    return null;
  }

  /// Scans the note here and now, for [headings].
  ///
  /// O(note) on this isolate, so only for a note small enough that the
  /// caller took that path deliberately (see [SourceStyler.inBackground] for
  /// the big ones).
  void scanHere() {
    final styler = SourceStyler(buffer);
    _styler = styler;
    _stylerRevision = styler.revision;
    _headings = styler.headings;
  }

  SourceStyler? _styler;
  int _stylerRevision = -1;
  List<OutlineEntry>? _headings;

  /// Called when an edit lands while no view is mounted to report it.
  ValueChanged<SourceEdit>? onChanged;

  MarkdownSourceViewState? _view;
  SelectionModel _pending;
  double? _pendingScroll;

  /// Whether a view is showing the note.
  bool get hasView => _view != null;

  /// Where the caret is, and what it has selected.
  SelectionModel get selection => _view?.selection ?? _pending;

  /// The selection a view starts with, when it mounts.
  SelectionModel get initialSelection => _pending.clampTo(buffer.length);

  /// The tokenizer's runs on line [line], as the view has them; none without
  /// a view.
  List<Token> tokensOf(int line) => _view?.tokensOf(line) ?? const <Token>[];

  /// How far the view is scrolled, or null without one.
  double? get scrollOffset => _view?.scrollOffset;

  /// Called by the view as it mounts; not for the shell. A method, not a
  /// setter, because it pairs with [detachView].
  // ignore: use_setters_to_change_properties
  void attachView(MarkdownSourceViewState view) => _view = view;

  /// Called by the view as it goes; not for the shell.
  void detachView(MarkdownSourceViewState view) {
    if (!identical(_view, view)) return;
    _pending = view.selection;
    _view = null;
  }

  /// The scroll offset a mounting view should restore, once.
  double? takePendingScroll() {
    final scroll = _pendingScroll;
    _pendingScroll = null;
    return scroll;
  }

  /// Makes the note say [text] with [selection] — a command's result, which
  /// the pure Markdown commands (`md_editing.dart`) hand over whole.
  ///
  /// Applied as the one range the two texts differ in, so it is one undo
  /// step and one edit for the tokenizer, however long the note is.
  ///
  /// [text] may be of a part of the note only — `[start, end)` of it — and
  /// [selection] is then in [text]'s offsets too ([applyLineCommand]).
  void applyEdit(
    String text,
    TextSelection selection, {
    int start = 0,
    int? end,
  }) {
    final range = _changedRange(start, end ?? buffer.length, text);
    if (range == null) return;
    final caret = SelectionModel(
      anchor: start + selection.baseOffset,
      extent: start + selection.extentOffset,
    );
    replaceRange(range.at, range.to, range.replacement, caret: caret);
  }

  /// The one range `[start, end)` of the note has to become [text], or null
  /// when it already says it.
  ///
  /// Found line by line rather than by cutting the note out and comparing the
  /// two strings: a kind GUI hands its whole note back after every change,
  /// and a `substring` of it is a copy of the whole note on the UI isolate —
  /// 247 MB of copy for a checkbox ticking (0.0.9 stress test). This way the
  /// unchanged head and tail are only ever compared, line by line, and the
  /// replacement is the part that actually differs.
  ({int at, int to, String replacement})? _changedRange(
    int start,
    int end,
    String text,
  ) {
    final first = buffer.lineOf(start);
    final last = buffer.lineOf(end);
    // The range ends where its last line does, before that line's
    // terminator: the terminator is the text after the range, not the
    // range's. Counted as the range's, an edit whose last line was empty
    // matched the new text's closing line break against it and lost one.
    String terminatorOf(int line) =>
        line == last ? '' : buffer.terminatorAt(line);
    var head = first;
    var textAt = 0;
    while (head < last + 1) {
      final line = buffer.lineAt(head);
      final terminator = terminatorOf(head);
      final whole = line.length + terminator.length;
      if (textAt + whole > text.length) break;
      if (!_sameAt(text, textAt, line) ||
          !_sameAt(text, textAt + line.length, terminator)) {
        break;
      }
      textAt += whole;
      head++;
    }
    if (head > last) {
      // Every line is what it was, and so is the length: nothing changed.
      return textAt == text.length
          ? null
          : (at: end, to: end, replacement: text.substring(textAt));
    }
    // The tail, from the ends back: the last line first, which settles the
    // whole suffix for a note whose end did not move. What it finds is the
    // first line the change did *not* reach, which is where the removal
    // stops.
    var tail = last + 1;
    var textEnd = text.length;
    while (tail - 1 >= head) {
      final line = buffer.lineAt(tail - 1);
      final terminator = terminatorOf(tail - 1);
      final whole = line.length + terminator.length;
      if (textEnd - whole < textAt) break;
      final lineAt = textEnd - whole;
      if (!_sameAt(text, lineAt, line) ||
          !_sameAt(text, lineAt + line.length, terminator)) {
        break;
      }
      textEnd = lineAt;
      tail--;
    }
    final at = head == 0 ? 0 : buffer.offsetOfLine(head);
    final to = tail > last ? end : buffer.offsetOfLine(tail);
    if (at == to && textAt == textEnd) return null;
    return (at: at, to: to, replacement: text.substring(textAt, textEnd));
  }

  /// Whether [text] says [part] at [at].
  static bool _sameAt(String text, int at, String part) {
    if (at < 0 || at + part.length > text.length) return false;
    for (var i = 0; i < part.length; i++) {
      if (text.codeUnitAt(at + i) != part.codeUnitAt(i)) return false;
    }
    return true;
  }

  /// [selection] with both ends where a caret can stand
  /// ([SourceBuffer.caretOffset]).
  SelectionModel _caretSelection(SelectionModel selection) => SelectionModel(
    anchor: buffer.caretOffset(selection.anchor),
    extent: buffer.caretOffset(selection.extent),
  );

  /// Runs [command] over the lines the selection touches, and applies what
  /// it made.
  ///
  /// [command] is one of the pure Markdown commands (`md_editing.dart`), and
  /// each of them reads and writes the lines its selection touches and
  /// nothing else: a wrap, the selected range; a prefix, a heading, a number,
  /// an indent, each touched line on its own. So those lines are everything
  /// it looks at, and the answer is the one it gives over the whole note —
  /// which `surface_controller_test.dart` holds for every command. Handing it
  /// the note meant joining it, building its formatted copy and comparing
  /// the two: seconds for a bold on a 246 MB note (0.0.9 stress test), for
  /// two asterisks.
  ///
  /// A command that looks at the lines around the ones it changes — an
  /// inserted table keeps a blank line from its neighbours — asks for
  /// [context] lines either side, and gets them; one that reaches further
  /// down — a footnote defined under its paragraph — asks for the lines
  /// [through] a line of its own.
  void applyLineCommand(
    MarkdownEdit Function(String text, TextSelection selection) command, {
    int context = 0,
    int? through,
  }) {
    final current = _caretSelection(selection);
    final first = math.max(0, buffer.lineOf(current.start) - context);
    final last = math.min(
      buffer.lineCount - 1,
      math.max(buffer.lineOf(current.end) + context, through ?? 0),
    );
    final start = buffer.offsetOfLine(first);
    final end = buffer.offsetOfLine(last) + buffer.lineLengthAt(last);
    final result = command(
      buffer.substring(start, end),
      TextSelection(
        baseOffset: current.anchor - start,
        extentOffset: current.extent - start,
      ),
    );
    applyEdit(result.text, result.selection, start: start, end: end);
  }

  /// Replaces `[start, end)` with [text], as one undoable edit, leaving the
  /// caret at [caret] or after the text.
  void replaceRange(int start, int end, String text, {SelectionModel? caret}) {
    final view = _view;
    if (view != null) {
      view.replaceText(start, end, text, caret: caret);
      return;
    }
    if (start < 0 || end < start || end > buffer.length) return;
    final before = buffer.length;
    final removed = buffer.substring(start, end);
    final edit = buffer.replaceRange(start, end, text);
    final stored = buffer.length - before + (end - start);
    history.record(
      EditRecord(
        start: start,
        removed: removed,
        inserted: buffer.substring(start, start + stored),
      ),
    );
    _pending = (caret ?? SelectionModel.at(start + stored)).clampTo(
      buffer.length,
    );
    onChanged?.call(edit);
  }

  /// Replaces the selection with [text] — an image's link, an inserted
  /// snippet — with the caret after it.
  void replaceSelection(String text) {
    final at = selection.clampTo(buffer.length);
    replaceRange(at.start, at.end, text);
  }

  /// Makes the note say [text] because it changed *elsewhere* — the disk, the
  /// WYSIWYG — and forgets the history: undoing past it would write the old
  /// text back over the other change. Not an edit: nothing is reported, and
  /// the word count, which only edits keep, is dropped for the caller to
  /// build again — kept, it counted the old lines, and the first edit on a
  /// line the old text did not have threw.
  void replaceAll(String text) {
    words.forget();
    final view = _view;
    if (view != null) {
      view.replaceAll(text);
      return;
    }
    buffer.replaceRange(0, buffer.length, text);
    history.clear();
    _pending = _pending.clampTo(buffer.length);
  }

  /// Selects [selection] and brings its end into view.
  void select(SelectionModel selection) {
    final next = _caretSelection(selection);
    final view = _view;
    if (view != null) {
      view.select(next);
      return;
    }
    _pending = next;
  }

  /// Puts the caret at [offset] and brings its line into view.
  void placeCaret(int offset) {
    final view = _view;
    if (view != null) {
      view.placeCaret(offset);
      return;
    }
    _pending = SelectionModel.at(offset.clamp(0, buffer.length));
  }

  /// Puts the selection back where a memento left it, and the scroll offset
  /// for the view to restore when it lays the note out.
  void restore({int? base, int? extent, double? scroll}) {
    if (extent != null) {
      final next = SelectionModel(
        anchor: base ?? extent,
        extent: extent,
      ).clampTo(buffer.length);
      final view = _view;
      if (view != null) {
        view.select(next);
      } else {
        _pending = next;
      }
    }
    if (scroll != null) {
      final view = _view;
      if (view != null) {
        view.jumpToOffset(scroll);
      } else {
        _pendingScroll = scroll;
      }
    }
  }

  /// Brings line [line] to the top of the view, caret at its start.
  void jumpToLine(int line) {
    if (line < 0 || line >= buffer.lineCount) return;
    placeCaret(buffer.offsetOfLine(line));
    _view?.jumpToLine(line);
  }
}
