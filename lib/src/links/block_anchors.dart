/// The block anchors of a note: the blocks that end with a ` ^id`, which a
/// `[[note#^id]]` link points at (#844).
///
/// The way headings are enumerated for the outline, a note's block anchors
/// are enumerated line by line over the same block state machine
/// ([ProseLineWalker]): a ` ^id` in a fence, a formula or the frontmatter is
/// not an anchor. Obsidian's rule is followed, and its limit with it:
///
/// * a paragraph, a list item or a heading carries its id at the end of its
///   last line;
/// * a quote, a callout, a table or a whole list carries it on a line of its
///   own below it, after a blank line — a part of one is not a target, only
///   the whole block (`We do not support links to specific parts of
///   quotations, callouts, and tables`);
/// * an id is made of letters, digits and dashes and is matched literally;
///   the first block that carries an id owns it.
///
/// The anchor's [BlockAnchor.line] is the line the block starts on, which is
/// where a followed link brings the note.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:niman/src/editor/highlighting.dart' show ProseLineWalker;
import 'package:niman/src/links/block_id.dart';
import 'package:niman/src/markdown/note_load.dart' show normalizedLineEndings;

/// One block that ends with a ` ^id`.
@immutable
final class BlockAnchor {
  /// Creates the anchor for the block [id] starting on [line].
  const new({required this.id, required this.line, required this.excerpt});

  /// The id, without its `^`.
  final String id;

  /// The line the block starts on: where a link to it lands.
  final int line;

  /// The block's first words, for a list of ids to show what each one is
  /// (markers and the id itself left out; at most [excerptLength] characters).
  final String excerpt;

  /// How long an [excerpt] is at most.
  static const int excerptLength = 80;

  @override
  bool operator ==(Object other) =>
      other is BlockAnchor &&
      other.id == id &&
      other.line == line &&
      other.excerpt == excerpt;

  @override
  int get hashCode => Object.hash(id, line, excerpt);

  @override
  String toString() => 'BlockAnchor(^$id @ $line)';
}

/// The id [line] ends with, or null: a space (or the line's start), a caret,
/// letters, digits and dashes, at its end.
String? trailingBlockId(String line) {
  // A line without a caret cannot end with an id: the common case costs one
  // scan and no regular expression.
  if (!line.contains('^')) return null;
  return BlockId.trailingIn(line)?.group(1);
}

/// [text] without the ` ^id` it ends with, trailing space dropped; [text]
/// itself when it ends with none.
String withoutTrailingBlockId(String text) {
  if (!text.contains('^')) return text;
  final match = BlockId.trailingIn(text);
  return match == null ? text : text.substring(0, match.start).trimRight();
}

enum _Kind { text, heading, item, quote, table }

final RegExp _headingLine = RegExp(r'^ {0,3}#{1,6}(?:\s|$)');
final RegExp _itemLine = RegExp(r'^\s*(?:[-*+]|\d{1,9}[.)])(?:\s|$)');

_Kind _kindOf(String text) {
  if (_headingLine.hasMatch(text)) return _Kind.heading;
  if (_itemLine.hasMatch(text)) return _Kind.item;
  final trimmed = text.trimLeft();
  if (trimmed.startsWith('>')) return _Kind.quote;
  if (trimmed.startsWith('|')) return _Kind.table;
  return _Kind.text;
}

/// Reads a note's block anchors as its lines are given in order.
final class BlockAnchorScanner {
  /// A scanner at the top of a note.
  new();

  final ProseLineWalker _walker = ProseLineWalker();
  final List<BlockAnchor> _anchors = <BlockAnchor>[];
  final Set<String> _seen = <String>{};

  /// The line the block being read starts on, or -1 between blocks.
  int _blockStart = -1;
  String _blockText = '';

  /// The line the run of non-blank lines being read starts on, or -1 after a
  /// blank line; and the run that ended before it.
  int _runStart = -1;
  String _runText = '';
  int _previousRunStart = -1;
  String _previousRunText = '';
  _Kind _previous = _Kind.text;

  /// The last prose line read, and the id a line ended with waiting to be
  /// owned: it belongs to the block only when the block ends on that very
  /// line — a block that runs on past its id does not carry one (#844).
  int _lastLine = -1;
  String? _pendingId;
  int _pendingAt = -1;

  /// The anchors found so far, in line order.
  List<BlockAnchor> get anchors => _anchors;

  /// Reads line [index] of the note, [text]; lines come in order from 0.
  void add(int index, String text) {
    if (!_walker.isProse(index, text)) {
      // A fence, a formula or the frontmatter ends the run and stands
      // between what came before it and what follows: an own-line id below
      // one names nothing of the paragraph above.
      _endRun();
      _forgetPreviousRun();
      return;
    }
    if (text.trim().isEmpty) {
      _endRun();
      return;
    }
    if (_runStart < 0 && _indentedCode(text)) {
      // Four spaces (or a tab) at the start of a block, with no run open, is
      // an indented code block: a ` ^id` in it is code, not an anchor.
      _endRun();
      _forgetPreviousRun();
      return;
    }
    final kind = _kindOf(text);
    final startsBlock =
        _runStart < 0 ||
        kind == _Kind.heading ||
        kind == _Kind.item ||
        _previous == _Kind.heading ||
        (kind != _previous && (kind == _Kind.quote || kind == _Kind.table)) ||
        (_previous == _Kind.table && kind == _Kind.text);
    if (startsBlock) {
      // The block before this line ended on the line just read: the id that
      // line carried, if any, is the block's; one an earlier line carried
      // belonged to a block that ran on past it.
      if (_runStart >= 0) _ownPending();
      if (_runStart < 0) {
        _runStart = index;
        _runText = text;
      }
      _blockStart = index;
      _blockText = text;
    }
    _previous = kind;
    _lastLine = index;
    final id = trailingBlockId(text);
    if (id == null) return;
    final own = text.trim() == '^$id';
    if (own && _runStart == index) {
      // An id on a line of its own names the block above, when there is one
      // and a blank line separates them (a list, a quote, a table). With no
      // block above it, the line is nothing but an id and names nothing.
      if (_previousRunStart >= 0) {
        _claim(id, _previousRunStart, _previousRunText);
      }
      return;
    }
    _pendingId = id;
    _pendingAt = index;
  }

  /// Claims the pending id when the block ended on the line that carried it.
  void _ownPending() {
    final id = _pendingId;
    final at = _pendingAt;
    _pendingId = null;
    _pendingAt = -1;
    if (id == null || at != _lastLine) return;
    _claim(id, _blockStart, _blockText);
  }

  /// Ends the note: the last block's id, if it carries one, is claimed.
  void finish() => _endRun();

  void _endRun() {
    if (_runStart >= 0) {
      _ownPending();
      _previousRunStart = _runStart;
      _previousRunText = _runText;
    }
    _runStart = -1;
    _blockStart = -1;
    _previous = _Kind.text;
    _pendingId = null;
    _pendingAt = -1;
  }

  /// The run before the fence, formula or code that just interrupted it is
  /// not the block an own-line id below the interruption may name.
  void _forgetPreviousRun() {
    _previousRunStart = -1;
    _previousRunText = '';
  }

  void _claim(String id, int line, String text) {
    if (!_seen.add(id)) return;
    _anchors.add(_anchor(id, line, text));
  }

  /// Whether [text] starts an indented code block: a tab or four spaces in,
  /// with no list, quote or table marker it belongs to.
  static bool _indentedCode(String text) =>
      text.startsWith('\t') || text.startsWith('    ');

  BlockAnchor _anchor(String id, int line, String text) =>
      BlockAnchor(id: id, line: line, excerpt: _excerptOf(text));

  /// The first words of a block's first line: its markers and its id off.
  static String _excerptOf(String line) {
    var text = withoutTrailingBlockId(line.trim());
    text = text.replaceFirst(RegExp(r'^(?:>\s*)+'), '');
    text = text.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
    text = text.replaceFirst(RegExp(r'^(?:[-*+]|\d{1,9}[.)])\s+'), '');
    text = text.replaceFirst(RegExp(r'^\[[ xX]\]\s+'), '').trim();
    return text.length <= BlockAnchor.excerptLength
        ? text
        : text.substring(0, BlockAnchor.excerptLength);
  }
}

/// The block anchors of [text], in line order.
///
/// The lines are the note's own, as the editor holds it: the rule loading a
/// note applies ([normalizedLineEndings]), where a CR LF and a lone CR are
/// line breaks like LF. A note written with Windows line endings has its ids
/// where the same note with LF has them.
List<BlockAnchor> blockAnchorsOfText(String text) {
  if (!text.contains('^')) return const <BlockAnchor>[];
  final scanner = BlockAnchorScanner();
  var index = 0;
  for (final line in normalizedLineEndings(text).split('\n')) {
    scanner.add(index++, line);
  }
  scanner.finish();
  return scanner.anchors;
}

/// The block anchors of a note of [count] lines, [lineAt] reading each, in
/// line order — pausing for the event loop every [yieldEvery] lines, so a
/// long note on the UI isolate does not hold a frame (a null [yieldEvery]
/// never pauses).
Future<List<BlockAnchor>> blockAnchorsOfLines(
  int count,
  String Function(int line) lineAt, {
  int? yieldEvery,
}) async {
  final scanner = BlockAnchorScanner();
  for (var index = 0; index < count; index++) {
    scanner.add(index, lineAt(index));
    if (yieldEvery != null && index % yieldEvery == yieldEvery - 1) {
      await Future<void>.delayed(Duration.zero);
    }
  }
  scanner.finish();
  return scanner.anchors;
}
