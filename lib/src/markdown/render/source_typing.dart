import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/list_row.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/edit/bracket_pairs.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/enter_edit.dart';
import 'package:niman/src/markdown/edit/list_indent_edit.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/live_tables.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Replaces `[start, end)` of the note with [text] as one undoable edit:
/// the caret at [caret], or after what the note stored; with [verbatim] the
/// text's own line endings kept; the last [closing] characters closers
/// written ahead of the caret.
typedef SourceReplace = void Function(
  int start,
  int end,
  String text, {
  SelectionModel? caret,
  bool verbatim,
  int closing,
});

/// What the source view's typing means beyond the characters typed: a
/// bracket's pair, a list carried on by Enter, Tab's indent, the deletions
/// the surface's own keys make, and the clipboard's cut, copy and paste.
///
/// The view owns it and calls it from the platform's edits and its keys; it
/// edits the note through [_replace], the view's one way to.
final class SourceTyping {
  /// The typing over the view's [_buffer] and [_selection].
  new({
    required this._buffer,
    required this._selection,
    required this._live,
    required this._mounted,
    required this._indentWidth,
    required this._blockOf,
    required this._tokensOf,
    required this._verbatimQuotes,
    required this._replace,
    required this._stepTo,
    required this._swallowedBreak,
    required this._tableEnter,
    required this._onPaste,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// Whether the view draws `live`, where a table cell bounds a deletion.
  final bool Function() _live;

  /// Whether the view is still mounted.
  final bool Function() _mounted;

  /// How many spaces Tab indents by.
  final int Function() _indentWidth;

  /// The block holding a line, as the scan behind the colours has it.
  final Block? Function(int line) _blockOf;

  /// The runs a line is drawn with.
  final List<Token> Function(int line) _tokensOf;

  /// The quote marks before a verbatim line's text, null for a line with
  /// syntax of its own (#579).
  final int? Function(int line) _verbatimQuotes;

  /// The view's one way to edit the note.
  final SourceReplace _replace;

  /// Puts the caret at an offset past a closer the writer typed over, the
  /// typing step left open.
  final void Function(int offset) _stepTo;

  /// Whether the line break arriving is the one a completed link's `Enter`
  /// sent after the key, already taken (#475).
  final bool Function() _swallowedBreak;

  /// Enter in a table in `live`: the cell below, or out of it; whether the
  /// caret was in one.
  final bool Function() _tableEnter;

  /// What takes the clipboard before the text does, or null.
  final Future<bool> Function()? Function() _onPaste;

  /// The brackets typed in pairs, and the closing ones they wrote.
  final BracketPairs brackets = BracketPairs();

  /// [inserted] typed over `[start, end)` by the platform, outside a
  /// composition: a bracket's pair written, a closing bracket stepped over,
  /// or — the soft keyboard's delete, one character before the caret — an
  /// empty pair taken whole. Answers whether it did one of them.
  bool typed(int start, int end, String inserted) {
    if (inserted.isEmpty) {
      final caret = _selection();
      if (end - start != 1 || !caret.isCollapsed || caret.extent != end) {
        return false;
      }
      return _applyBracket(brackets.backspace(_buffer(), end));
    }
    if (inserted.length != 1) return false;
    return _applyBracket(
      brackets.typed(_buffer(), start, end, inserted, verbatimAt: _caretInCode),
    );
  }

  /// Whether a caret at [offset] stands in code or maths: on a line of a
  /// fenced or indented code block or of a `$$` block, or inside an inline
  /// code or maths span — between its delimiters, not before the opening one
  /// nor after the closing one.
  ///
  /// Answered by the scan behind the colours — the line's block, O(log
  /// blocks), and that one line's runs — so a keystroke never reads the note
  /// again. The block answers for an empty line of a fence, which has no
  /// runs; the runs answer while there is no block scan.
  bool _caretInCode(int offset) {
    final buffer = _buffer();
    final line = buffer.lineOf(offset);
    final block = _blockOf(line)?.kind;
    if (block == BlockKind.fencedCode ||
        block == BlockKind.indentedCode ||
        block == BlockKind.math) {
      return true;
    }
    final local = offset - buffer.offsetOfLine(line);
    TokenKind? before;
    TokenKind? at;
    for (final token in _tokensOf(line)) {
      final kind = token.kind;
      if (kind == TokenKind.codeFence ||
          kind == TokenKind.codeBlock ||
          kind == TokenKind.mathBlock) {
        return true;
      }
      if (kind != TokenKind.codeInline && kind != TokenKind.mathInline) {
        continue;
      }
      if (local - 1 >= token.start && local - 1 < token.end) before = kind;
      if (local >= token.start && local < token.end) at = kind;
    }
    // A span's delimiters are runs of its own kind: a caret with the span on
    // both sides of it is inside, one with a delimiter on one side only is
    // at its edge, outside.
    return before != null && before == at;
  }

  /// Makes [edit], when there is one; answers whether there was.
  bool _applyBracket(BracketEdit? edit) {
    if (edit == null) return false;
    final caret = SelectionModel(anchor: edit.anchor, extent: edit.extent);
    if (edit.text.isEmpty && edit.start == edit.end) {
      _stepTo(edit.extent);
    } else {
      // A pair written at the caret: the characters after the caret are
      // closers, which the typing inside the pair is one undo step with.
      final closing = edit.start == edit.end
          ? edit.start + edit.text.length - edit.extent
          : 0;
      _replace(edit.start, edit.end, edit.text, caret: caret, closing: closing);
    }
    return true;
  }

  /// A line break typed over `[start, end)`, when it means more than a line
  /// break: inside a list item it carries the list on, and on an empty item it
  /// ends the list (#142, the legacy editor's `applyNewLine`); inside a quote
  /// or a callout it carries the quote on (#1049). Answers whether it did any
  /// of them; otherwise the platform's line break is applied as typed.
  ///
  /// It hangs off the *line break arriving*, not off the Enter key, because
  /// that is the one place every embedder meets: an IME commits the break as
  /// text and the desktop embedders insert it themselves, so there is no key
  /// to bind that all of them send.
  bool newline(int start, int end) {
    // The line break a completed link's `Enter` sent after the key: already
    // taken as the panel's `Enter`, so it is swallowed rather than written
    // behind the link (#475).
    if (_swallowedBreak()) return true;
    // In a table in `live`: the cell below, or out of it.
    if (_tableEnter()) return true;
    if (start != end) return false;
    final buffer = _buffer();
    if (!_isPlainLine(buffer.lineOf(start))) return false;
    // The rule is `enterEdit`'s: a list item behind its quote marks is
    // carried on, a quote line starts the next with its marks, an empty
    // nested item goes back a level (#1049).
    final edit = enterEdit(buffer, start, indentWidth: _indentWidth());
    if (edit == null) return false;
    _replace(
      edit.start,
      edit.end,
      edit.text,
      caret: edit.caret,
      verbatim: edit.verbatim,
    );
    return true;
  }

  /// Whether line [index] is ordinary Markdown — not fenced code, display
  /// maths or frontmatter, where a dash starts nothing. Answered by the
  /// colours the view already keeps, so the two cannot disagree about what a
  /// list is.
  bool _isPlainLine(int index) {
    if (index < 0 || index >= _buffer().lineCount) return true;
    for (final token in _tokensOf(index)) {
      if (token.kind == TokenKind.codeFence ||
          token.kind == TokenKind.codeBlock ||
          token.kind == TokenKind.mathBlock ||
          token.kind == TokenKind.frontmatter) {
        return false;
      }
    }
    return true;
  }

  /// Whether the caret is in code ([inCodeAt]): a fenced or indented
  /// block, display maths, an inline span — where a paste stays text.
  bool get caretInCode {
    final buffer = _buffer();
    final at = _selection().extent.clamp(0, buffer.length);
    final line = buffer.lineOf(at);
    return inCodeAt(line, at - buffer.offsetOfLine(line));
  }

  /// Whether the character at [local] of line [index] is code: a line of a
  /// fenced or indented code block, a line of display maths, or an inline code
  /// or maths span over the character.
  ///
  /// Answered by the colours the view already keeps, as [_isPlainLine] is, so
  /// the two cannot disagree about what the note reads as code. A span is
  /// drawn as several runs — its delimiters, its text — and they are disjoint,
  /// so the character the offset stands on is the one to ask about: a caret
  /// past a span's last delimiter is prose again, and a link typed there is
  /// not the code's.
  bool inCodeAt(int index, int local) {
    for (final token in _tokensOf(index)) {
      final kind = token.kind;
      if (kind == TokenKind.codeFence ||
          kind == TokenKind.codeBlock ||
          kind == TokenKind.mathBlock) {
        return true;
      }
      final inline =
          kind == TokenKind.codeInline || kind == TokenKind.mathInline;
      if (inline && local >= token.start && local < token.end) return true;
    }
    return false;
  }

  /// Tab: moves the lines the selection touches in — a list item to where its
  /// list says (under the item above it), any other line by `indentWidth`
  /// spaces — or, on a plain line with a collapsed caret, inserts them at the
  /// caret. The rule is the toolbar's indent (`indentLines`).
  ///
  /// The surface's own key: left to the app, Tab moves the focus to the next
  /// widget and takes the keyboard away from the note.
  void indent() {
    final buffer = _buffer();
    final selection = _selection().clampTo(buffer.length);
    final line = buffer.lineOf(selection.start);
    if (selection.isCollapsed && ListRow(buffer.lineAt(line)).head == null) {
      final pad = ' ' * _indentWidth();
      _replace(selection.start, selection.end, pad);
      return;
    }
    _indentLines(selection, outdent: false);
  }

  /// Shift+Tab: the inverse — a list item goes back to its parent's indent,
  /// any other line out by up to `indentWidth` spaces, never taking anything
  /// but spaces.
  void outdent() {
    _indentLines(_selection().clampTo(_buffer().length), outdent: true);
  }

  /// Indents or outdents the lines [selection] touches, as one edit
  /// ([listIndentEdit]).
  void _indentLines(SelectionModel selection, {required bool outdent}) {
    final edit = listIndentEdit(
      _buffer(),
      selection,
      width: _indentWidth(),
      outdent: outdent,
    );
    if (edit == null) return;
    _replace(
      edit.start,
      edit.end,
      edit.text,
      caret: edit.caret,
      verbatim: true,
    );
  }

  /// Deletes the selection, or what [motion] takes from the caret: a
  /// character or a word either way.
  ///
  /// The surface's own key, not the platform's: the Linux embedder leaves
  /// Backspace and Delete to the framework (`fl_text_input_handler.cc`:
  /// "already handled inside the framework"), which is `EditableText`'s job
  /// and therefore this surface's. An IME's own delete key still arrives as a
  /// deletion delta.
  void delete(CaretMotion motion) {
    final buffer = _buffer();
    final selection = _selection().clampTo(buffer.length);
    if (!selection.isCollapsed) {
      _replace(selection.start, selection.end, '');
      return;
    }
    if (motion == CaretMotion.characterLeft &&
        _applyBracket(brackets.backspace(buffer, selection.extent))) {
      return;
    }
    final other = _withinCell(
      selection.extent,
      moveCaret(
        selection,
        motion,
        buffer: buffer,
        verbatimQuotes: _verbatimQuotes,
      ).extent,
    );
    if (other == selection.extent) return;
    final start = math.min(other, selection.extent);
    final end = math.max(other, selection.extent);
    _replace(start, end, '');
  }

  /// [other] kept inside the table cell [caret] is in, in `live`: a
  /// deletion from a cell stops at its edges, as Obsidian's does, rather
  /// than taking the pipes that make the table.
  int _withinCell(int caret, int other) {
    if (!_live()) return other;
    final buffer = _buffer();
    final line = buffer.lineOf(caret);
    if (_blockOf(line)?.kind != BlockKind.table) return other;
    final start = buffer.offsetOfLine(line);
    final cell = LiveTables.cellAround(buffer.lineAt(line), caret - start);
    if (cell == null) return other;
    return other.clamp(start + cell.$1, start + cell.$2);
  }

  /// The selected text, or null when the selection is a caret.
  String? get selectedText {
    final selection = _selection();
    if (selection.isCollapsed) return null;
    return _buffer().substring(selection.start, selection.end);
  }

  /// Copies the selection to the platform's clipboard.
  Future<void> copySelection() async {
    final text = selectedText;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Copies the selection and removes it, in one undo step with the removal.
  Future<void> cutSelection() async {
    final text = selectedText;
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    final selection = _selection();
    _replace(selection.start, selection.end, '');
  }

  /// Inserts the clipboard's text at the caret, replacing the selection —
  /// unless the view's paste hook takes the clipboard first.
  Future<void> paste() async {
    final hook = _onPaste();
    if (hook != null && await hook()) return;
    if (!_mounted()) return;
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    final selection = _selection();
    // The caret goes after what the note *stored*: a Windows clipboard's
    // `\r\n` pasted into an LF note is shorter than the text that was copied.
    _replace(selection.start, selection.end, text);
  }
}
