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

/// A ` ^id` at the end of a line, or a line that is nothing else.
final RegExp _trailingId = RegExp(r'(?:^|[ \t])\^([A-Za-z0-9-]+)[ \t]*$');

/// The id [line] ends with, or null: a space (or the line's start), a caret,
/// letters, digits and dashes, at its end.
String? trailingBlockId(String line) {
  // A line without a caret cannot end with an id: the common case costs one
  // scan and no regular expression.
  if (!line.contains('^')) return null;
  return _trailingId.firstMatch(line)?.group(1);
}

/// [text] without the ` ^id` it ends with, trailing space dropped; [text]
/// itself when it ends with none.
String withoutTrailingBlockId(String text) {
  if (!text.contains('^')) return text;
  final match = _trailingId.firstMatch(text);
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

  /// The anchors found so far, in line order.
  List<BlockAnchor> get anchors => _anchors;

  /// Reads line [index] of the note, [text]; lines come in order from 0.
  void add(int index, String text) {
    if (!_walker.isProse(index, text) || text.trim().isEmpty) {
      _endRun();
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
    if (_runStart < 0) {
      _runStart = index;
      _runText = text;
    }
    if (startsBlock) {
      _blockStart = index;
      _blockText = text;
    }
    _previous = kind;
    final id = trailingBlockId(text);
    if (id == null || !_seen.add(id)) return;
    final own = text.trim() == '^$id';
    if (own && _runStart == index && _previousRunStart >= 0) {
      // An id on a line of its own after a blank line names the block above:
      // the whole run it ended (a list, a quote, a table).
      _anchors.add(_anchor(id, _previousRunStart, _previousRunText));
      return;
    }
    _anchors.add(_anchor(id, _blockStart, _blockText));
  }

  void _endRun() {
    if (_runStart >= 0) {
      _previousRunStart = _runStart;
      _previousRunText = _runText;
    }
    _runStart = -1;
    _blockStart = -1;
    _previous = _Kind.text;
  }

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
List<BlockAnchor> blockAnchorsOfText(String text) {
  if (!text.contains('^')) return const <BlockAnchor>[];
  final scanner = BlockAnchorScanner();
  var index = 0;
  for (final line in text.split('\n')) {
    scanner.add(index++, line);
  }
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
  return scanner.anchors;
}
