import 'package:niman/src/editor/code_fence.dart';
import 'package:niman/src/editor/math_rule.dart';

/// A math span in absolute text offsets, markers included (`$…$` / `$$…$$`).
final class MathSpan {
  /// Creates a math span covering [start]..[end).
  const new(this.start, this.end, {required this.block});

  /// Offset of the opening marker.
  final int start;

  /// Offset one past the closing marker.
  final int end;

  /// True for `$$…$$` spans; false for `$…$`.
  final bool block;
}

/// All math spans in [text], absolute offsets, markers included.
///
/// `$$…$$` (single-line or multi-line) spans are [MathSpan.block]; `$…$`
/// spans are inline. Rules: inline math opens at a `$` whose next char is
/// not whitespace or `$`, closes at a `$` whose previous char is not
/// whitespace, is not `\$`, and is not followed by a digit; a display block
/// opens at a line starting with `$$` (unless the line ends with `$$` again)
/// and closes at the next such line; an unterminated block spans to EOF.
List<MathSpan> mathSpansIn(String text) {
  final lines = text.isEmpty ? <String>[''] : text.split('\n');
  final spans = <MathSpan>[];
  var fenceChar = 0;
  var fenceLen = 0;
  var inFence = false;
  var inFm = false;
  var inMath = false;
  var mathStart = 0;
  var offset = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trim();
    final lineStart = offset;
    offset = lineStart + line.length + 1;
    final lineEnd = lineStart + line.length;
    if (inFence) {
      if (isFenceCloseInfo(line, fenceChar, fenceLen)) inFence = false;
      continue;
    }
    final fenceOpen = fenceOpenInfo(line);
    if (fenceOpen != null) {
      inFence = true;
      fenceChar = fenceOpen.$1;
      fenceLen = fenceOpen.$2;
      continue;
    }
    if (inFm) {
      if (trimmed == '---' || trimmed == '...') inFm = false;
      continue;
    }
    if (i == 0 && trimmed == '---') {
      inFm = true;
      continue;
    }
    if (inMath) {
      if (trimmed.startsWith(r'$$')) {
        final indent = line.length - line.trimLeft().length;
        spans.add(MathSpan(mathStart, lineStart + indent + 2, block: true));
        inMath = false;
      } else if (i == lines.length - 1) {
        spans.add(MathSpan(mathStart, lineEnd, block: true));
        inMath = false;
      }
      continue;
    }
    if (trimmed.startsWith(r'$$')) {
      if (isSingleLineDisplay(trimmed)) {
        final indent = line.length - line.trimLeft().length;
        spans.add(
          MathSpan(
            lineStart + indent,
            lineStart + indent + trimmed.length,
            block: true,
          ),
        );
      } else {
        inMath = true;
        mathStart = lineStart + (line.length - line.trimLeft().length);
      }
      continue;
    }
    for (final (s, e) in allInlineMath(line)) {
      spans.add(MathSpan(lineStart + s, lineStart + e, block: false));
    }
  }
  spans.sort((a, b) => a.start.compareTo(b.start));
  return spans;
}
