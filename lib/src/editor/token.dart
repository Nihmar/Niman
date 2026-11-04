import 'package:meta/meta.dart';
import 'package:niman/src/editor/styled_line.dart';
import 'package:niman/src/editor/token_kind.dart';

/// One styled run of a line; offsets are relative to [StyledLine.text].
///
/// A line's tokens are disjoint and sorted by [start]; the region after a
/// [TokenKind.headingMarker] token up to end-of-line is styled as heading
/// text by the painter.
@immutable
final class Token {
  /// Creates a token of [kind] covering [start]..[end).
  const new(
    this.kind,
    this.start,
    this.end, {
    this.marker = false,
    this.outer = const <TokenKind>[],
  });

  /// The style of the run.
  final TokenKind kind;

  /// The inline constructs the run sits inside, outermost first: the
  /// underline around `**x**` in `<u>**x**</u>`. A line's tokens are disjoint,
  /// so a stretch is one token of the innermost construct over it, and this
  /// is what keeps the ones around it — without it the underline was lost.
  /// Only the unified surface's styler fills it.
  final List<TokenKind> outer;

  /// Whether the run is the syntax of a construct rather than its text: the
  /// `**` of a bold run, a link's `](href)`. What `live` mode hides. Only the
  /// unified surface's styler tells them apart; this tokenizer never does.
  final bool marker;

  /// Offset of the first character of the run.
  final int start;

  /// Offset one past the last character of the run.
  final int end;

  /// `kind[start,end)="text"`; for tests and logs.
  String describe(String line) =>
      '$kind[$start,$end)="${line.substring(start, end)}"';

  @override
  bool operator ==(Object other) =>
      other is Token &&
      other.kind == kind &&
      other.start == start &&
      other.end == end &&
      other.marker == marker &&
      _sameKinds(other.outer, outer);

  @override
  int get hashCode =>
      Object.hash(kind, start, end, marker, Object.hashAll(outer));

  static bool _sameKinds(List<TokenKind> a, List<TokenKind> b) {
    if (a.length != b.length) return false;
    for (var at = 0; at < a.length; at++) {
      if (a[at] != b[at]) return false;
    }
    return true;
  }
}

/// [tokens], a line's, disjoint and sorted, with [ranges] of the line —
/// disjoint and in order — laid over them as runs of [kind]: what a token
/// covered inside a range gives way to it, and what it covered outside
/// stays, cut where the range begins and ends. A template command
/// (`{{date}}`) is laid over the Markdown around it this way.
List<Token> overlayTokens(
  List<Token> tokens,
  List<(int, int)> ranges,
  TokenKind kind,
) {
  if (ranges.isEmpty) return tokens;
  Token piece(Token token, int start, int end) =>
      Token(token.kind, start, end, marker: token.marker, outer: token.outer);
  final out = <Token>[
    for (final (start, end) in ranges) Token(kind, start, end),
  ];
  for (final token in tokens) {
    var at = token.start;
    for (final (start, end) in ranges) {
      if (end <= at || start >= token.end) continue;
      if (start > at) out.add(piece(token, at, start));
      if (end > at) at = end;
      if (at >= token.end) break;
    }
    if (at < token.end) out.add(piece(token, at, token.end));
  }
  return out..sort((a, b) => a.start.compareTo(b.start));
}
