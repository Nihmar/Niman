/// What one line of a note adds to its definitions: the footnotes it cites,
/// the footnote or the link references it defines — read once, kept by the
/// scope's reader, and combined again after an edit that changed only a few
/// lines of them.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/markdown/inline/link_references.dart';

/// One line's part of a note's definitions, with the lines after it that it
/// was read from.
@immutable
final class ScopeEntry {
  /// What the line adds: [cited] labels, a footnote [footnote] defined with
  /// [body], or the link [references] of a definition; [span] lines after
  /// its own were looked at to read it.
  const new({
    this.cited = const <String>[],
    this.footnote,
    this.footnoteKey,
    this.body = '',
    this.references,
    this.span = 0,
  });

  /// The footnote labels the line cites, in order.
  final List<String> cited;

  /// The label of the footnote the line defines, or null.
  final String? footnote;

  /// [footnote], normalized: what a `[^label]` is matched against.
  final String? footnoteKey;

  /// The footnote's body: the line's own text and the lines under it.
  final String body;

  /// The link references the line starts a definition of, by normalized
  /// label, or null.
  final Map<String, LinkReference>? references;

  /// How many lines after its own it looked at: a definition's destination
  /// and title, a footnote's continuation. An edit on one of them may
  /// change the entry.
  final int span;

  /// Whether [other] adds the same to the note's definitions.
  bool sameAs(ScopeEntry other) {
    if (footnote != other.footnote ||
        body != other.body ||
        cited.length != other.cited.length) {
      return false;
    }
    for (var at = 0; at < cited.length; at++) {
      if (cited[at] != other.cited[at]) return false;
    }
    final mine = references;
    final theirs = other.references;
    if (mine == null || theirs == null) return mine == theirs;
    if (mine.length != theirs.length) return false;
    for (final entry in mine.entries) {
      final match = theirs[entry.key];
      if (match == null ||
          match.destination != entry.value.destination ||
          match.title != entry.value.title) {
        return false;
      }
    }
    return true;
  }
}
