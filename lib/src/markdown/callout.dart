/// A callout, as Obsidian writes one (#279): a quote whose first line is
/// `[!type]`, with a `-` or a `+` after it for one that folds, and a title
/// of its own after that.
///
/// ```markdown
/// > [!warning]- Mind the gap
/// > What the callout says.
/// ```
///
/// The type is any word; the ones Obsidian ships have their own colour and
/// icon (`CalloutStyle`), and any other is drawn as a note, as there.
library;

import 'package:meta/meta.dart';

/// Whether a callout folds, and how it starts.
enum CalloutFold {
  /// No `-` or `+`: it does not fold.
  none,

  /// `+`: it folds, and starts open.
  open,

  /// `-`: it folds, and starts closed.
  closed,
}

/// A quote's callout line, read.
@immutable
final class Callout {
  /// A callout of [type], folding as [fold] says, titled [title].
  const new({required this.type, required this.fold, required this.title});

  /// What the first line of a quote's content — its `>` taken off — says,
  /// when it is a callout's; null when it is not one.
  static Callout? of(String line) {
    final match = _line.firstMatch(line);
    if (match == null) return null;
    final type = match[1]!.toLowerCase();
    final fold = switch (match[2]) {
      '-' => CalloutFold.closed,
      '+' => CalloutFold.open,
      _ => CalloutFold.none,
    };
    final written = (match[3] ?? '').trim();
    return Callout(
      type: type,
      fold: fold,
      title: written.isEmpty ? _titled(match[1]!) : written,
    );
  }

  /// How long the callout's mark is on [line]: `[!type]`, its `-` or `+`,
  /// and the spaces after them — what `live` hides on the title line. Zero
  /// when [line] is not a callout's.
  static int markLength(String line) {
    final match = _line.firstMatch(line);
    return match == null ? 0 : line.length - (match[3] ?? '').length;
  }

  /// `[!type]`, a fold sign, and what is left of the line, after the
  /// spaces a quote's content may start with.
  static final RegExp _line = RegExp(
    r'^[ \t]*\[!([A-Za-z][\w-]*)\]([+-])?[ \t]*(.*)$',
  );

  /// The title a callout with none has: its type as written, capitalised,
  /// as Obsidian titles it.
  static String _titled(String type) =>
      type.substring(0, 1).toUpperCase() + type.substring(1);

  /// The type, lowercased: `note`, `warning`, or any word.
  final String type;

  /// Whether it folds.
  final CalloutFold fold;

  /// The title: the one written, or the type's.
  final String title;

  @override
  bool operator ==(Object other) =>
      other is Callout &&
      other.type == type &&
      other.fold == fold &&
      other.title == title;

  @override
  int get hashCode => Object.hash(type, fold, title);

  @override
  String toString() => 'Callout($type, $fold, $title)';
}
