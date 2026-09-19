import 'package:meta/meta.dart';

/// One misspelling found by a whole-note `EditorSpellCheck.scan` (T-PP-09).
///
/// Carries the exact range so the panel can replace it in the controller,
/// the visible word and its line, and hunspell's suggestions.
@immutable
final class SpellIssue {
  /// Creates an issue at [line], [start]..[end].
  const new({
    required this.line,
    required this.start,
    required this.end,
    required this.word,
    required this.lineText,
    required this.suggestions,
  });

  /// Zero-based buffer line.
  final int line;

  /// Start offset within the line.
  final int start;

  /// End offset within the line (exclusive).
  final int end;

  /// The misspelled word.
  final String word;

  /// The line it sits on, for context in the panel.
  final String lineText;

  /// Hunspell's suggestions, best first.
  final List<String> suggestions;

  /// The same issue [shift] characters further along its line: an earlier
  /// word on the line was replaced by one of another length.
  SpellIssue movedBy(int shift) => shift == 0
      ? this
      : SpellIssue(
          line: line,
          start: start + shift,
          end: end + shift,
          word: word,
          lineText: lineText,
          suggestions: suggestions,
        );
}
