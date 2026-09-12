/// Pure text/selection math for one open note (#51): flat offsets to
/// line+column and back, outline row parsing, and the one-line link
/// outcome for the logs. No widget state — everything takes explicit
/// arguments, so these are unit-testable without pumping an editor.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:re_editor/re_editor.dart';

/// Converts a whole-text [selection] in [text] to the controller's
/// line+offset form (the inverse of [textSelection]).
CodeLineSelection codeLineSelection(String text, TextSelection selection) {
  final (baseIndex, baseOffset) = lineAndOffset(text, selection.baseOffset);
  final (extentIndex, extentOffset) = lineAndOffset(
    text,
    selection.extentOffset,
  );
  return CodeLineSelection(
    baseIndex: baseIndex,
    baseOffset: baseOffset,
    extentIndex: extentIndex,
    extentOffset: extentOffset,
  );
}

/// The (line, offset-within-line) for the absolute [offset] in [text].
(int, int) lineAndOffset(String text, int offset) {
  var line = 0;
  var lineStart = 0;
  for (var i = 0; i < offset && i < text.length; i++) {
    if (text.codeUnitAt(i) == 0x0A) {
      line++;
      lineStart = i + 1;
    }
  }
  return (line, offset - lineStart);
}

/// Converts the controller's line+offset [selection] in [text] to
/// whole-text offsets (called once per toolbar tap, so the O(n) scan is
/// fine).
TextSelection textSelection(String text, CodeLineSelection selection) {
  return TextSelection(
    baseOffset: globalOffset(text, selection.baseIndex, selection.baseOffset),
    extentOffset: globalOffset(
      text,
      selection.extentIndex,
      selection.extentOffset,
    ),
  );
}

/// The flat offset of ([line], [offset]) in [text].
int globalOffset(String text, int line, int offset) {
  var index = 0;
  for (var current = 0; current < line; current++) {
    final nl = text.indexOf('\n', index);
    if (nl < 0) return text.length;
    index = nl + 1;
  }
  return index + offset;
}

/// Flat text offset to line + column, for the template cursor landing
/// (#53). One O(n) scan on note open.
({int line, int offset}) linePosition(String text, int flat) {
  var line = 0;
  var start = 0;
  while (true) {
    final nl = text.indexOf('\n', start);
    if (nl < 0 || nl >= flat) return (line: line, offset: flat - start);
    line++;
    start = nl + 1;
  }
}

/// Parses one `line|level|text` outline row, or null when malformed.
OutlineEntry? parseOutlineRow(String row) {
  final parts = row.split('|');
  if (parts.length < 3) return null;
  final line = int.tryParse(parts[0]);
  final level = int.tryParse(parts[1]);
  if (line == null || level == null) return null;
  return OutlineEntry(
    line: line,
    level: level,
    text: parts.sublist(2).join('|'),
  );
}

/// The one-line link outcome for the logs.
String describeResolved(ResolveResult resolved) {
  return switch (resolved) {
    ExternalLink(:final url) => 'ExternalLink($url)',
    LocalAnchor(:final heading) => 'LocalAnchor(#$heading)',
    ResolvedNote(:final note) => 'ResolvedNote(${note.path})',
    AmbiguousNote(:final candidates) =>
      'AmbiguousNote(${candidates.length} candidates)',
    UnresolvedNote(:final target) => 'UnresolvedNote("$target")',
  };
}
