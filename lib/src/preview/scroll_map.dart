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
///
/// The mapping walks the block heights, not a line fraction (T-PP-22): an
/// image or a display-math block is hundreds of pixels tall for a handful
/// of source lines, so the fraction put the preview behind the editor
/// next to them. Blocks the windowed preview has not laid out yet are
/// estimated from the measured blocks' own pixels-per-line average, and
/// those same heights are handed to the layout as the blocks' extents
/// ([extentFor]), so the pane's pixels and the map cannot disagree.
final class ScrollMap {
  /// Per top-level block: the source line it starts on.
  final List<int> blockStartLines = <int>[];

  /// Per top-level block: measured pixel height (0 until laid out).
  final List<double> blockHeights = <double>[];

  /// Running sums over the measured blocks, so the average used for the
  /// unmeasured ones costs nothing per scroll frame.
  double _measuredPixels = 0;
  int _measuredLines = 0;

  /// Total source lines (frontmatter excluded, like the preview parse).
  int lineCount = 0;

  /// Whether every block has been measured at least once.
  bool get isReady =>
      blockHeights.isNotEmpty &&
      blockStartLines.length == blockHeights.length &&
      blockHeights.every((h) => h > 0);

  /// Whether the map has been built for the current source.
  bool get built => blockStartLines.isNotEmpty || lineCount == 0;

  /// Lines of the note above [rebuild]'s source — its frontmatter.
  ///
  /// Every line this class is asked about, and every line it answers with,
  /// is a line of the *note*: the editor counts from the first line of the
  /// file, and a map that counted from the first line of the prose put the
  /// preview a whole frontmatter ahead of it (device report, 2026-09-10).
  int lineOffset = 0;

  /// Rebuilds from [source] (frontmatter stripped, as the preview parses).
  ///
  /// [lineOffset] is the number of lines stripped off the top, so the map
  /// keeps answering in the note's own line numbers.
  ///
  /// The previous parse's measured heights are carried over for the blocks
  /// that still start on the same source line: without that, every
  /// debounced edit (one parse per typing pause) wiped the whole map, and
  /// the preview re-measured every block on screen — each first layout
  /// after a keystroke paid a full re-learn (T-PP-22).
  void rebuild(String source, {int lineOffset = 0}) {
    this.lineOffset = lineOffset;
    final previous = <int, double>{
      for (var i = 0; i < blockStartLines.length; i++)
        if (i < blockHeights.length && blockHeights[i] > 0)
          blockStartLines[i]: blockHeights[i],
    };
    blockStartLines.clear();
    blockHeights.clear();
    _extents.clear();
    _pending.clear();
    _extentSum = 0;
    _measuredPixels = 0;
    _measuredLines = 0;
    lineCount = 0;
    if (source.isEmpty) return;
    final lines = const LineSplitter().convert(source);
    // Everything past here counts the note's lines, frontmatter included:
    // one conversion, at the edge, so the two directions cannot apply it
    // differently.
    lineCount = lineOffset + lines.length;
    blockStartLines.addAll(
      BlockLocator().locate(lines).map((line) => line + lineOffset),
    );
    for (var i = 0; i < blockStartLines.length; i++) {
      final height = previous[blockStartLines[i]];
      if (height != null) measure(i, height);
    }
    // A rebuild runs between frames, so the carried-over heights are the
    // extents straight away.
    applyMeasurements();
  }

  /// Records a measured height for block [index] (from the preview layout).
  ///
  /// The height replaces the block's estimate, but not before the frame is
  /// over: the measurement arrives *during* the sliver's layout, and an
  /// extent that moves under a block the sliver has already placed is what
  /// makes SliverVariedExtentList's offsets jump mid-pass. The preview
  /// calls [applyMeasurements] between frames.
  void measure(int index, double height) {
    if (index < 0 || index >= blockStartLines.length) return;
    while (blockHeights.length <= index) {
      blockHeights.add(0);
    }
    final previous = blockHeights[index];
    if (previous > 0) {
      _measuredPixels -= previous;
      _measuredLines -= _spanOf(index);
    }
    blockHeights[index] = height;
    if (height > 0) {
      _measuredPixels += height;
      _measuredLines += _spanOf(index);
      final frozen = index < _extents.length ? _extents[index] : 0.0;
      if ((frozen - height).abs() > _extentEpsilon) _pending[index] = height;
    }
  }

  /// Measurements from the last layout that disagree with the extents the
  /// layout used, waiting for the frame to end (see [measure]).
  final Map<int, double> _pending = <int, double>{};

  /// Height difference (px) worth a re-layout.
  static const double _extentEpsilon = 0.5;

  /// Adopts the measurements the last layout reported; true when any
  /// extent moved, which is the preview's cue to lay out again.
  bool applyMeasurements() {
    if (_pending.isEmpty) return false;
    _pending.forEach(_freeze);
    _pending.clear();
    return true;
  }

  /// Freezes block [index]'s extent for the layout (see [_extents]).
  void _freeze(int index, double extent) {
    while (_extents.length <= index) {
      _extents.add(0);
    }
    _extentSum += extent - _extents[index];
    _extents[index] = extent;
  }

  /// The sum of every extent handed out so far (see [totalExtent]).
  double _extentSum = 0;

  /// The whole document's height in the preview's own pixels.
  ///
  /// The preview hands this to the sliver as the scrollable extent. Left to
  /// itself a lazy list extrapolates from the handful of children it has
  /// laid out, which put the end of a 10 000-line note some 30 000 px away
  /// when its blocks add up to twelve times that: every jump past the
  /// guess was clamped, and the two panes came apart (device report,
  /// 2026-09-10). Walking the blocks costs one pass and settles their
  /// extents, which the mapping wants settled anyway.
  double totalExtent() {
    final count = math.max(blockStartLines.length, _extents.length);
    for (var i = 0; i < count; i++) {
      _heightOf(i);
    }
    return _extentSum;
  }

  /// Pixels between the top of the scrollable and the first block (the
  /// preview's own padding), so an offset here is a scroll position.
  double contentInset = 0;

  /// The source lines block [index] spans (at least one), and one for a
  /// block the locator never found — the preview may hold a child the
  /// locator and the parser disagreed about, and an extent is still owed
  /// for it.
  int _spanOf(int index) {
    if (index < 0 || index >= blockStartLines.length) return 1;
    final start = blockStartLines[index];
    final end = index + 1 < blockStartLines.length
        ? blockStartLines[index + 1]
        : lineCount;
    return math.max(1, end - start);
  }

  /// Pixels per source line assumed until a block has been measured (the
  /// preview's body text at 1.5 line height).
  static const double defaultPixelsPerLine = 22;

  /// Per-block extent handed to the layout and used by the mapping.
  ///
  /// A block's extent is frozen the first time it is asked for — the
  /// measured height once the preview has laid it out, the line-span
  /// estimate before — and then only replaced by that block's own
  /// measurement. Letting the shared average re-estimate blocks that were
  /// already placed is what makes SliverVariedExtentList assert: their
  /// offsets move under the scroll position.
  final List<double> _extents = <double>[];

  /// Block [index]'s height: its frozen extent (seeded here on first use),
  /// the block's measurement winning as soon as it lands.
  double _heightOf(int index) {
    while (_extents.length <= index) {
      _extents.add(0);
    }
    final frozen = _extents[index];
    if (frozen > 0) return frozen;
    final measured = index < blockHeights.length ? blockHeights[index] : 0.0;
    final perLine = _measuredLines == 0
        ? defaultPixelsPerLine
        : _measuredPixels / _measuredLines;
    final extent = measured > 0 ? measured : _spanOf(index) * perLine;
    _extents[index] = extent;
    _extentSum += extent;
    return extent;
  }

  /// The extent to give block [index] in the preview's layout
  /// (`SliverVariedExtentList`): the same height the mapping walks, so the
  /// pane's pixels and the map can never disagree. With an extent per
  /// block, a jump lays out only the blocks it lands on instead of every
  /// block in between (the scroll cost on math-heavy notes, T-PP-22).
  double extentFor(int index) => _heightOf(index);

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
  /// yet. It walks the blocks above [line]'s, adding their measured (or
  /// estimated) heights and the line's fraction inside its own block.
  ///
  /// [into] is how far down that line the reader is (0 at its first row, 1
  /// at its last): a line of prose wraps over several rows in the editor,
  /// and without it the preview steps a whole paragraph at a time.
  double? previewOffsetForLine(
    int line, {
    required double maxExtent,
    double into = 0,
  }) {
    if (blockStartLines.isEmpty || maxExtent <= 0 || lineCount == 0) {
      return null;
    }
    final index = blockForLine(line);
    var content = 0.0;
    for (var i = 0; i < index; i++) {
      content += _heightOf(i);
    }
    final span = _spanOf(index);
    final within =
        ((line - blockStartLines[index] + into.clamp(0.0, 1.0)) / span).clamp(
          0.0,
          1.0,
        );
    content += _heightOf(index) * within;
    // The preview's layout uses exactly these extents, so the offset needs
    // no rescaling to the pane's current extent — only the pane's own
    // padding, which sits above the first block.
    return (content + contentInset).clamp(0.0, maxExtent);
  }

  /// The source line shown at preview [offset], or null when unknown. The
  /// mirror of [previewOffsetForLine]: blocks are walked, not fractions.
  int? lineForPreviewOffset(double offset, {required double maxExtent}) {
    if (blockStartLines.isEmpty || maxExtent <= 0 || lineCount == 0) {
      return null;
    }
    final content = offset - contentInset;
    var acc = 0.0;
    for (var i = 0; i < blockStartLines.length; i++) {
      final height = _heightOf(i);
      if (acc + height > content) {
        final within = height <= 0
            ? 0.0
            : ((content - acc) / height).clamp(0.0, 1.0);
        final span = _spanOf(i);
        final line = blockStartLines[i] + (within * span).floor();
        return line.clamp(blockStartLines[i], blockStartLines[i] + span - 1);
      }
      acc += height;
    }
    return lineCount - 1;
  }
}

/// Structural top-level block scanner: source lines → block start lines,
/// mirroring the top-level blocks the markdown parser produces with the
/// preview's syntax set (GFM + display math). The locator tests assert the
/// count matches the parser's AST over the coverage fixture.
final class BlockLocator {
  /// Creates the locator.
  new();

  final RegExp _setext = RegExp(r'^(=+|-+)\s*$');
  final RegExp _hr = RegExp(r'^\s{0,3}(-{3,}|_{3,}|\*{3,})\s*$');
  final RegExp _quote = RegExp(r'^\s{0,3}>');
  final RegExp _listMarker = RegExp(r'^\s{0,3}(?:[-*+]|\d{1,9}[.)])(?:\s|$)');
  final RegExp _tableDelimiter = RegExp(
    r'^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?)*\|\s*$',
  );
  final RegExp _header = RegExp(r'^\s{0,3}(#{1,6})(?:\s|$)');
  final RegExp _footnoteDef = RegExp(r'^\s{0,3}\[\^[^\]\s]+\]:');

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
      // Every footnote definition in a row is one block: the parser
      // gathers them all into the single section it appends at the end of
      // the document, and the preview draws that section as one block.
      if (_footnoteDef.hasMatch(lines[i])) {
        starts.add(i);
        i = _footnoteEnd(lines, i) + 1;
        continue;
      }
      final setextLine =
          i + 1 < lines.length && _setext.hasMatch(lines[i + 1].trim());
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
        while (i + 1 < lines.length && _quote.hasMatch(lines[i + 1])) {
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
      _footnoteDef.hasMatch(lines[i]) ||
      (i + 1 < lines.length && _setext.hasMatch(lines[i + 1].trim())) ||
      _isHr(lines[i], prev: lines[i - 1]) ||
      _quote.hasMatch(lines[i]) ||
      _listMarker.hasMatch(lines[i]) ||
      _tableStart(lines, i);

  /// The last line of the run of footnote definitions opening at [i]:
  /// their indented continuations, and the definitions after them.
  int _footnoteEnd(List<String> lines, int i) {
    var end = i;
    var j = i + 1;
    while (j < lines.length) {
      final line = lines[j];
      if (line.trim().isEmpty) {
        j++;
        continue;
      }
      final continues =
          _footnoteDef.hasMatch(line) ||
          line.startsWith('    ') ||
          line.startsWith('\t');
      if (!continues) break;
      end = j;
      j++;
    }
    return end;
  }

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
