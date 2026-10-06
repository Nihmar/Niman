/// One `[` or `![` waiting for its `]`.
library;

import 'package:niman/src/markdown/inline/delimiter.dart';
import 'package:niman/src/markdown/inline/inline_build.dart';

/// An open bracket: the text node holding it and where the link text
/// after it starts.
final class Bracket {
  /// A bracket held by [node], its link text starting at [textStart].
  new(
    this.node, {
    required this.textStart,
    required this.image,
    required this.previousDelimiter,
    required this.previous,
    required this.links,
  });

  /// The text node of `[` or `![`.
  final InlineBuild node;

  /// Where the text between the brackets starts.
  final int textStart;

  /// Whether it opens an image.
  final bool image;

  /// The delimiter on top of the stack when it was pushed: emphasis inside
  /// the link is matched down to it.
  final Delimiter? previousDelimiter;

  /// The bracket below it.
  final Bracket? previous;

  /// How many links the parse had made when it was pushed. A link inside
  /// a link deactivates the link brackets before it: one is active while
  /// no link has been made since, which costs nothing to keep — walking
  /// the stack to deactivate them was quadratic (`cmark`'s pathological
  /// `![[]()`).
  final int links;

  /// Whether another bracket was opened after it: its text is then no
  /// shortcut reference.
  bool bracketAfter = false;
}
