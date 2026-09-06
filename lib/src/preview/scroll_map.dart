import 'dart:convert';
import 'dart:math' as math;

/// The editor ↔ preview scroll map (M2 T-M2-06).
///
/// Each render pass (per debounced preview parse) the source is scanned
/// structurally into top-level blocks — the same segmentation the markdown
/// parser produces (the locator tests assert the block count matches the
/// AST on the coverage fixture) — giving every preview block its starting
/// source line. The preview then measures each block's height during
/// layout, and the map answers the two sync queries: source line → preview
/// offset (editor scrolls → preview follows) and preview offset → source
/// line (preview scrolls → editor follows).
final class ScrollMap {
  /// Per top-level block: the source line it starts on.
  final List<int> blockStartLines = <int>[];

  /// Per top-level block: measured pixel height (0 until laid out).
  final List<double> blockHeights = <double>[];

  /// Total source lines (frontmatter excluded, like the preview parse).
  int lineCount = 0;

  /// Whether every block has been measured at least once.
  bool get isReady =>
      blockHeights.isNotEmpty &&
      blockStartLines.length == blockHeights.length &&
      blockHeights.every((h) => h > 0);

  /// Whether the map has been built for the current source.
  bool get built => blockStartLines.isNotEmpty || lineCount == 0;

  /// Rebuilds from [source] (frontmatter stripped, as the preview parses).
  void rebuild(String source) {
    blockStartLines.clear();
    blockHeights.clear();
    lineCount = 0;
    if (source.isEmpty) return;
    final lines = const LineSplitter().convert(source);
    lineCount = lines.length;
    blockStartLines.addAll(BlockLocator().locate(lines));
  }

  /// Records a measured height for block [index] (from the preview layout).
  void measure(int index, double height) {
    if (index < 0 || index >= blockStartLines.length) return;
    while (blockHeights.length <= index) {
      blockHeights.add(0);
    }
    blockHeights[index] = height;
  }

  /// The block index containing source [line].
  int blockForLine(int line) {
    var lo = 0;
    var hi = blockStartLines.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (blockStartLines[mid] <= line) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo == 0 ? 0 : lo - 1;
  }

  /// The preview offset that shows [line], or null when nothing is laid out
  /// yet. Proportional (line fraction × content height): the mapping table
  /// pins the block structure, but the scroll position itself is a fraction
  /// — which is what lines up with the editor's own (wrap-dependent)
  /// extent.
  double? previewOffsetForLine(int line, {required double maxExtent}) {
    if (blockStartLines.isEmpty || maxExtent <= 0 || lineCount == 0) {
      return null;
    }
    final fraction = (line / math.max(1, lineCount - 1)).clamp(0.0, 1.0);
    return maxExtent * fraction;
  }

  /// The source line shown at preview [offset], or null when unknown.
  int? lineForPreviewOffset(double offset, {required double maxExtent}) {
    if (blockStartLines.isEmpty || maxExtent <= 0 || lineCount == 0) {
      return null;
    }
    final fraction = (offset / maxExtent).clamp(0.0, 1.0);
    return ((lineCount - 1) * fraction).round();
  }
}

/// Structural top-level block scanner: source lines → block start lines,
/// mirroring the top-level blocks the markdown parser produces with the
/// preview's syntax set (GFM + display math). The locator tests assert the
/// count matches the parser's AST over the coverage fixture.
final class BlockLocator {
  /// Creates the locator.
  BlockLocator();

  final RegExp _setext = RegExp(r'^(=+|-+)\s*$');
  final RegExp _hr = RegExp(r'^\s{0,3}(-{3,}|_{3,}|\*{3,})\s*$');
  final RegExp _quote = RegExp(r'^\s{0,3}>');
  final RegExp _listMarker = RegExp(r'^\s{0,3}(?:[-*+]|\d{1,9}[.)])(?:\s|$)');
  final RegExp _tableDelimiter =
      RegExp(r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?)*\|\s*$');
  final RegExp _header = RegExp(r'^\s{0,3}(#{1,6})(?:\s|$)');

  /// The located blocks' start lines, in parse order.
  List<int> locate(List<String> lines) {
    final starts = <int>[];
    var i = 0;
    while (i < lines.length) {
      if (lines[i].trim().isEmpty) {
        i++;
        continue;
      }
      if (_isMathOpen(lines[i])) {
        starts.add(i);
        i = _mathEnd(lines, i) + 1;
        continue;
      }
      final fence = _fenceOpen(lines[i]);
      if (fence != null) {
        starts.add(i);
        i = _fenceEnd(lines, i, fence) + 1;
        continue;
      }
      if (_header.hasMatch(lines[i])) {
        starts.add(i);
        i++;
        continue;
      }
      final setextLine = i + 1 < lines.length &&
          _setext.hasMatch(lines[i + 1].trim());
      if (setextLine) {
        starts.add(i);
        i += 2;
        continue;
      }
      if (_isHr(lines[i], prev: i == 0 ? '' : lines[i - 1])) {
        starts.add(i);
        i++;
        continue;
      }
      if (_quote.hasMatch(lines[i])) {
        starts.add(i);
        while (i + 1 < lines.length &&
            _quote.hasMatch(lines[i + 1])) {
          i++;
        }
        i++;
        continue;
      }
      if (_listMarker.hasMatch(lines[i])) {
        starts.add(i);
        i = _listEnd(lines, i) + 1;
        continue;
      }
      if (_tableStart(lines, i)) {
        starts.add(i);
        while (i + 1 < lines.length && lines[i + 1].contains('|')) {
          i++;
        }
        i++;
        continue;
      }
      // Paragraph: consume until a blank line or a structural start.
      starts.add(i);
      while (i + 1 < lines.length &&
          lines[i + 1].trim().isNotEmpty &&
          !_startsBlock(lines, i + 1)) {
        i++;
      }
      i++;
    }
    return starts;
  }

  bool _startsBlock(List<String> lines, int i) =>
      _isMathOpen(lines[i]) ||
      _fenceOpen(lines[i]) != null ||
      _header.hasMatch(lines[i]) ||
      (i + 1 < lines.length && _setext.hasMatch(lines[i + 1].trim())) ||
      _isHr(lines[i], prev: lines[i - 1]) ||
      _quote.hasMatch(lines[i]) ||
      _listMarker.hasMatch(lines[i]) ||
      _tableStart(lines, i);

  bool _isMathOpen(String line) => line.trim().startsWith(r'$$');

  int _mathEnd(List<String> lines, int i) {
    final trimmed = lines[i].trim();
    if (trimmed.length >= 4 &&
        trimmed.startsWith(r'$$') &&
        trimmed.endsWith(r'$$')) {
      return i;
    }
    var j = i + 1;
    while (j < lines.length && !lines[j].trim().startsWith(r'$$')) {
      j++;
    }
    return j < lines.length ? j : lines.length - 1;
  }

  /// The fence length when [line] opens a code fence (>=3 backticks/tildes
  /// with only whitespace/language after), else null.
  int? _fenceOpen(String line) {
    final t = line.trimLeft();
    if (t.length < 3) return null;
    final c = t.codeUnitAt(0);
    if (c != 0x60 && c != 0x7E) return null;
    var len = 0;
    while (len < t.length && t.codeUnitAt(len) == c) {
      len++;
    }
    if (len < 3) return null;
    final rest = t.substring(len);
    if (rest.startsWith('`') || rest.startsWith('~')) return null;
    return len;
  }

  int _fenceEnd(List<String> lines, int i, int openLen) {
    final c = lines[i].trimLeft().codeUnitAt(0);
    var j = i + 1;
    while (j < lines.length) {
      final t = lines[j].trim();
      var len = 0;
      while (len < t.length && t.codeUnitAt(len) == c) {
        len++;
      }
      if (len >= openLen && t.length == len) return j;
      j++;
    }
    return j - 1;
  }

  bool _isHr(String line, {required String prev}) {
    if (!_hr.hasMatch(line)) return false;
    if (line.trim().startsWith('-')) {
      // A '-' HR is a setext underline when the previous line is prose.
      return prev.trim().isEmpty;
    }
    return true;
  }

  int _listEnd(List<String> lines, int i) {
    final marker = _listMarker.firstMatch(lines[i])![0]!;
    final indent = marker.length - marker.trimLeft().length;
    final ordered = RegExp(r'^\d').hasMatch(marker.trimLeft());
    var j = i + 1;
    while (j < lines.length) {
      final line = lines[j];
      if (line.trim().isEmpty) {
        j++;
        continue;
      }
      final m = _listMarker.hasMatch(line);
      if (m) {
        // A different marker kind (bullet vs numbered) after a blank line
        // ends the list — the parser produces a separate block.
        final mMarker = _listMarker.firstMatch(line)![0]!;
        final mOrdered = RegExp(r'^\d').hasMatch(mMarker.trimLeft());
        if (mOrdered != ordered && j > i + 1 && lines[j - 1].trim().isEmpty) {
          break;
        }
        j++;
        continue;
      }
      final lineIndent = line.length - line.trimLeft().length;
      if (lineIndent > indent) {
        j++;
        continue;
      }
      break;
    }
    var end = j - 1;
    while (end > i && lines[end].trim().isEmpty) {
      end--;
    }
    return end;
  }

  bool _tableStart(List<String> lines, int i) {
    if (i + 1 >= lines.length) return false;
    if (!lines[i].contains('|')) return false;
    return _tableDelimiter.hasMatch(lines[i + 1].trim());
  }
}
