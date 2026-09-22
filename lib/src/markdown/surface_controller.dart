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

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show TextSelection;
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// A note on the unified surface, as the shell drives it.
final class MarkdownSurfaceController {
  /// Controls [buffer], with the caret at [caret].
  new(this.buffer, {int caret = 0, EditHistory? history})
    : history = history ?? EditHistory(),
      _pending = SelectionModel.at(caret.clamp(0, buffer.length));

  /// The note.
  final SourceBuffer buffer;

  /// Its undo history — the shell's, so it survives the view.
  final EditHistory history;

  /// Called when an edit lands while no view is mounted to report it.
  VoidCallback? onChanged;

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
  void applyEdit(String text, TextSelection selection) {
    final ours = buffer.text;
    var prefix = 0;
    final shortest = ours.length < text.length ? ours.length : text.length;
    while (prefix < shortest &&
        ours.codeUnitAt(prefix) == text.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < shortest - prefix &&
        ours.codeUnitAt(ours.length - 1 - suffix) ==
            text.codeUnitAt(text.length - 1 - suffix)) {
      suffix++;
    }
    final caret = SelectionModel(
      anchor: selection.baseOffset,
      extent: selection.extentOffset,
    );
    replaceRange(
      prefix,
      ours.length - suffix,
      text.substring(prefix, text.length - suffix),
      caret: caret,
    );
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
    buffer.replaceRange(start, end, text);
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
    onChanged?.call();
  }

  /// Replaces the selection with [text] — an image's link, an inserted
  /// snippet — with the caret after it.
  void replaceSelection(String text) {
    final at = selection.clampTo(buffer.length);
    replaceRange(at.start, at.end, text);
  }

  /// Makes the note say [text] because it changed *elsewhere* — the disk, the
  /// WYSIWYG — and forgets the history: undoing past it would write the old
  /// text back over the other change. Not an edit: nothing is reported.
  void replaceAll(String text) {
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
    final next = selection.clampTo(buffer.length);
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
