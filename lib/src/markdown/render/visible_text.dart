/// What a reader sees of a block, and which characters the renderer hides.
///
/// The parser's answer is a run per construct, and a run covers its
/// **markers**: `**bold**` is one run over eight characters. `read` mode shows
/// four. So between the runs and the screen there is one question — which
/// characters are syntax — and this is where it is answered.
///
/// Two things are set aside, and they are not the same thing:
///
/// * **markers**, which belong to a construct the reader sees *without* them:
///   the `**` of strong, the backticks of a code span, the `[` and `](href)` of
///   a link, the `#` of a heading. Each kind's rule is in [_markersOf];
/// * **replaced spans**, which the reader does not see as text at all: math is
///   typeset, an embed becomes an image, a wikilink is drawn as a link. The
///   masker recorded those before the parser ever saw them.
///
/// Everything else is visible, and its style is the innermost construct
/// covering it — which is what makes nesting work without the renderer having
/// to think about it.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/markdown/extension_span.dart';
import 'package:niman/src/markdown/parsed_block.dart';
import 'package:niman/src/markdown/style_run.dart';

/// A run of visible characters and the construct they belong to.
@immutable
final class VisibleSegment {
  /// Creates a segment covering `[start, end)` of the block's text.
  const new({
    required this.start,
    required this.end,
    required this.kind,
    required this.depth,
    this.href,
  });

  /// Its first offset in the block's text.
  final int start;

  /// One past its last offset.
  final int end;

  /// The innermost construct covering it, or [StyleKind.plain].
  final StyleKind kind;

  /// How deep that construct is.
  final int depth;

  /// The link or image target, when there is one.
  final String? href;

  /// How many characters it covers.
  int get length => end - start;

  @override
  String toString() => '${kind.name}[$start..$end]';
}

/// A block as a reader sees it.
@immutable
final class VisibleText {
  /// Creates a visible-text view of [text].
  const new({
    required this.text,
    required this.segments,
    required this.replaced,
  });

  /// Reads [block] into visible segments.
  factory of(ParsedBlock block) {
    final hidden = hiddenRangesOf(block);
    final replaced = block.extensions;
    for (final span in replaced) {
      hidden.add((span.start, span.end));
    }
    // Anything the parser did not account for *before its first construct* is
    // container syntax: the `- ` of a list item, the `> ` of a quote, the
    // `[x] ` of a task box. The parser strips them, so no run covers them, and
    // without this they are read as text — which is what put `[x] - [x]` on
    // screen where the preview drew a checkbox.
    if (block.runs.isNotEmpty || replaced.isNotEmpty) {
      var contentStart = block.text.length;
      for (final run in block.runs) {
        if (run.start < contentStart) contentStart = run.start;
      }
      for (final span in replaced) {
        if (span.start < contentStart) contentStart = span.start;
      }
      if (contentStart > 0) hidden.add((0, contentStart));
    }
    final segments = <VisibleSegment>[];
    final text = block.text;
    var at = 0;
    while (at < text.length) {
      if (_hiddenAt(hidden, at)) {
        at++;
        continue;
      }
      final run = _innermostRun(block.runs, at);
      var end = at + 1;
      while (end < text.length &&
          !_hiddenAt(hidden, end) &&
          _sameRun(block.runs, end, run)) {
        end++;
      }
      segments.add(
        VisibleSegment(
          start: at,
          end: end,
          kind: run?.kind ?? StyleKind.plain,
          depth: run?.depth ?? 0,
          href: run?.href,
        ),
      );
      at = end;
    }
    return VisibleText(text: text, segments: segments, replaced: replaced);
  }

  /// The block's own text.
  final String text;

  /// The visible runs, in offset order and non-overlapping.
  final List<VisibleSegment> segments;

  /// The spans drawn rather than typed, in offset order.
  final List<ExtensionSpan> replaced;

  /// Whether anything is drawn rather than typed.
  bool get hasReplaced => replaced.isNotEmpty;

  /// The text a reader sees, with the markers taken out — the string a
  /// selection or a screen reader should be given.
  ///
  /// A drawn span contributes whatever a reader would hear: the tex of a
  /// formula, the target of a wikilink, the word inside a code span. Its
  /// delimiters are not read aloud, which is the point of taking them out.
  String get plainText {
    final buffer = StringBuffer();
    var replaced = 0;
    for (final segment in segments) {
      while (replaced < this.replaced.length &&
          this.replaced[replaced].end <= segment.start) {
        buffer.write(this.replaced[replaced].inner);
        replaced++;
      }
      buffer.write(text.substring(segment.start, segment.end));
    }
    while (replaced < this.replaced.length) {
      buffer.write(this.replaced[replaced].inner);
      replaced++;
    }
    return buffer.toString();
  }

  @override
  String toString() =>
      'VisibleText(${segments.length} segments, ${replaced.length} drawn)';
}

/// Whether [offset] falls in any of [ranges].
bool _hiddenAt(List<(int, int)> ranges, int offset) {
  for (final range in ranges) {
    if (offset >= range.$1 && offset < range.$2) return true;
  }
  return false;
}

/// The innermost run covering [offset], or null for plain text.
StyleRun? _innermostRun(List<StyleRun> runs, int offset) {
  StyleRun? found;
  for (final run in runs) {
    if (!run.contains(offset)) continue;
    if (found == null || run.depth >= found.depth) found = run;
  }
  return found;
}

/// Whether [offset] is covered by the same run as the segment being built.
bool _sameRun(List<StyleRun> runs, int offset, StyleRun? run) =>
    identical(_innermostRun(runs, offset), run);

/// The characters of [block] that are syntax rather than text.
///
/// Every rule here is the inverse of one in the bridge, which is what widened a
/// construct's range over its markers in the first place. A rule that cannot
/// recognise its own construct hides nothing, so a malformed construct shows as
/// written rather than losing characters.
///
/// Public because this list has a second reader: the editable surface makes
/// these the ranges a caret steps over rather than stopping inside (§8.6.0's
/// atomic ranges, `edit/selection_model.dart`). One rule for what is hidden,
/// rather than one per reader.
List<(int, int)> hiddenRangesOf(ParsedBlock block) {
  final text = block.text;
  final hidden = <(int, int)>[];
  for (final run in block.runs) {
    hidden.addAll(_markersOf(text, run));
  }
  return hidden;
}

/// The marker ranges of one run.
List<(int, int)> _markersOf(String text, StyleRun run) {
  switch (run.kind) {
    case StyleKind.emphasis:
    case StyleKind.strong:
    case StyleKind.strikethrough:
      return _delimiterRuns(text, run, <int>[0x2A, 0x5F, 0x7E]);
    case StyleKind.highlight:
      return _delimiterRuns(text, run, const <int>[0x3D]);
    case StyleKind.code:
      return _delimiterRuns(text, run, const <int>[0x60]);
    case StyleKind.underline:
    case StyleKind.superscript:
    case StyleKind.subscript:
      // `<u>` and `</u>`: the tags the parser measured the run over.
      return <(int, int)>[
        if (run.innerStart > run.start) (run.start, run.innerStart),
        if (run.end > run.innerEnd) (run.innerEnd, run.end),
      ];
    case StyleKind.heading:
      return _headingMarkers(text, run);
    case StyleKind.link:
    case StyleKind.image:
      return _linkMarkers(text, run);
    case StyleKind.plain:
    case StyleKind.hardBreak:
      return const <(int, int)>[];
  }
}

/// The opening and closing runs of a delimiter character.
///
/// `**bold**` hides its two leading and two trailing asterisks; `*it*` hides
/// one each. The closing run is found by walking back from the end over the
/// same character, which is what the parser consumed to close the construct.
List<(int, int)> _delimiterRuns(String text, StyleRun run, List<int> chars) {
  var open = run.start;
  while (open < run.end && chars.contains(text.codeUnitAt(open))) {
    open++;
  }
  var close = run.end;
  while (close > open && chars.contains(text.codeUnitAt(close - 1))) {
    close--;
  }
  final markers = <(int, int)>[];
  if (open > run.start) markers.add((run.start, open));
  if (close < run.end) markers.add((close, run.end));
  return markers;
}

/// A heading's opening `#`s and any closing `#`s.
List<(int, int)> _headingMarkers(String text, StyleRun run) {
  var open = run.start;
  while (open < run.end && text.codeUnitAt(open) == 0x23) {
    open++;
  }
  while (open < run.end) {
    final char = text.codeUnitAt(open);
    if (char != 0x20 && char != 0x09) break;
    open++;
  }
  final markers = <(int, int)>[(run.start, open)];
  var close = run.end;
  // A closing run of `#`s matters only when a space precedes it.
  while (close > open && text.codeUnitAt(close - 1) == 0x23) {
    close--;
  }
  if (close < run.end && close > open && text.codeUnitAt(close - 1) == 0x20) {
    markers.add((close - 1, run.end));
  }
  return markers;
}

/// A link's or an image's brackets and destination.
///
/// A run comes in one of two shapes, and the rule has to know both:
///
/// * **widened** — an inline link, where the bridge grew the run over the whole
///   `[text](url)` construct, so the brackets are *inside* it and the text part
///   ends at its `](`;
/// * **unwidened** — a footnote or a reference link, where the parser's text
///   node is the visible text and the syntax sits outside it: `[^` before, `]`
///   or `][label]` after.
///
/// Reading the delimiters off the source instead of assuming one spelling is
/// what lets `[^1]` draw as its superscript without a rule of its own.
List<(int, int)> _linkMarkers(String text, StyleRun run) {
  final markers = <(int, int)>[];
  final braced = text.codeUnitAt(run.start) == 0x5B;
  final bangBraced =
      text.codeUnitAt(run.start) == 0x21 &&
      run.start + 1 < text.length &&
      text.codeUnitAt(run.start + 1) == 0x5B;
  if (braced || bangBraced) {
    markers.add((run.start, run.start + (bangBraced ? 2 : 1)));
  } else {
    var open = run.start;
    while (open > 0 && '[^!'.contains(text[open - 1])) {
      open--;
    }
    if (open < run.start) markers.add((open, run.start));
  }

  final widened = text.indexOf('](', run.start);
  if (widened >= 0 && widened < run.end) {
    markers.add((widened, run.end));
    return markers;
  }
  final close = run.end;
  if (close < text.length && text.codeUnitAt(close) == 0x5D) {
    final label = text.indexOf(']', close + 1);
    markers.add((run.end, label < 0 ? close + 1 : label + 1));
  }
  return markers;
}
