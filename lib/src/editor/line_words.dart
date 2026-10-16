/// The words one line of a note adds to its word count (#1051).
///
/// The count is of the *text's* words, not of the syntax it is written in:
/// the marks before a line's text — a heading's hashes, a list marker and its
/// task box, the quote marks — are not words, and a line that is only syntax
/// — a thematic break, a table's delimiter row, a code fence — is none, nor
/// are the pipes between a table row's cells. What is left is counted as
/// [countWords] counts, so `## Title` is one word, `- [ ] buy milk` is two
/// and `---` is none.
///
/// Line-local on purpose: the value of a line is a function of that line
/// alone (and of whether the frontmatter holds it, which the word count
/// keeps), so the count stays valid when an edit recounts only the lines it
/// touched.
library;

import 'package:niman/src/editor/word_count.dart';
import 'package:niman/src/markdown/edit/line_prefix.dart';

/// The words [text], one line of a note, adds to its count.
int wordsOfLine(String text) {
  if (text.isEmpty) return 0;
  final from = lineQuoteEnd(text);
  if (_isSyntaxOnly(text, from)) return 0;
  final body = lineBodyColumn(text);
  // A table row: its pipes are what separates the cells, not words.
  if (body < text.length && text.codeUnitAt(body) == 0x7C) {
    return _countCells(text, body);
  }
  return countWords(text, start: body);
}

/// The words of a table row from [start] on, the pipes separating them as
/// white space does.
int _countCells(String text, int start) {
  var words = 0;
  var inWord = false;
  for (var at = start; at < text.length; at++) {
    final unit = text.codeUnitAt(at);
    final gap = unit == 0x7C || isWordSpace(unit);
    if (!gap && !inWord) words++;
    inWord = !gap;
  }
  return words;
}

/// Whether the line from [from] on is nothing but syntax: a thematic break, a
/// table's delimiter row or a code fence.
bool _isSyntaxOnly(String text, int from) {
  var at = from;
  var spaces = 0;
  while (at < text.length && _isSpace(text.codeUnitAt(at))) {
    if (text.codeUnitAt(at) == 0x20) spaces++;
    at++;
  }
  if (at >= text.length) return false;
  final first = text.codeUnitAt(at);
  // A fence is up to three spaces in; four make it code.
  if ((first == 0x60 || first == 0x7E) && spaces <= 3 && _isFence(text, at)) {
    return true;
  }
  if (first == 0x2D || first == 0x2A || first == 0x5F || first == 0x7C) {
    return _isBreak(text, at, first) || _isDelimiterRow(text, at);
  }
  return false;
}

/// Whether the run of [text] at [from], which starts with a backtick or a
/// tilde, opens or closes a fence: three or more of it, and — for backticks —
/// no more of them after, which would make an inline code span.
bool _isFence(String text, int from) {
  final mark = text.codeUnitAt(from);
  var at = from;
  while (at < text.length && text.codeUnitAt(at) == mark) {
    at++;
  }
  if (at - from < 3) return false;
  return mark != 0x60 || text.indexOf('`', at) < 0;
}

/// Whether the line from [from] is a thematic break: three or more of
/// [mark] (`-`, `*` or `_`), spaces between them and nothing else.
bool _isBreak(String text, int from, int mark) {
  if (mark == 0x7C) return false;
  var marks = 0;
  for (var at = from; at < text.length; at++) {
    final unit = text.codeUnitAt(at);
    if (unit == mark) {
      marks++;
    } else if (!_isSpace(unit)) {
      return false;
    }
  }
  return marks >= 3;
}

/// Whether the line from [from] is a table's delimiter row: pipes, dashes,
/// colons and spaces, with a pipe and a dash among them (`|---|:-:|`).
bool _isDelimiterRow(String text, int from) {
  var pipe = false;
  var dash = false;
  for (var at = from; at < text.length; at++) {
    final unit = text.codeUnitAt(at);
    if (unit == 0x7C) {
      pipe = true;
    } else if (unit == 0x2D) {
      dash = true;
    } else if (unit != 0x3A && !_isSpace(unit)) {
      return false;
    }
  }
  return pipe && dash;
}

bool _isSpace(int unit) => unit == 0x20 || unit == 0x09;
