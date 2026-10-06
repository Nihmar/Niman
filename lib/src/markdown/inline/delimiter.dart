/// One run of `*`, `_` or `~` on the delimiter stack.
library;

import 'package:niman/src/markdown/inline/inline_build.dart';

/// A delimiter run: the text node holding it, and what it may do.
final class Delimiter {
  /// A run of [count] [char]s held by [node].
  new(
    this.node, {
    required this.char,
    required this.count,
    required this.canOpen,
    required this.canClose,
  }) : original = count;

  /// The text node the run is in.
  final InlineBuild node;

  /// `*`, `_` or `~`.
  final int char;

  /// How many of its characters are not used yet.
  int count;

  /// How many it had: the rule of 3 is about the runs as written.
  final int original;

  /// Whether it may open emphasis: left-flanking, and for `_` more.
  final bool canOpen;

  /// Whether it may close emphasis.
  final bool canClose;

  /// The delimiter below it on the stack.
  Delimiter? previous;

  /// The delimiter above it.
  Delimiter? next;
}
