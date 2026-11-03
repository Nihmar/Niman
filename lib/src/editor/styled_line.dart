import 'package:niman/src/editor/token.dart';
import 'package:niman/src/editor/token_kind.dart';

/// One line of the display text with its tokens; anything not covered by a
/// token is [TokenKind.plain].
final class StyledLine {
  /// Creates a styled line.
  const new(this.text, this.tokens);

  /// The line text (without newline).
  final String text;

  /// The line's tokens, sorted by [Token.start]; disjoint.
  final List<Token> tokens;
}
