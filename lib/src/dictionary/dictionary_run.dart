import 'package:meta/meta.dart';

/// A stretch of an entry's text in one style: the grammar has `<i>` and
/// `<b>` inside a gloss or an example, and nothing else.
///
/// A sentence is a list of runs; the panel draws each as a `TextSpan`.
@immutable
final class DictionaryRun {
  /// [text] in italics when [italic] and in bold when [bold].
  const new(this.text, {this.italic = false, this.bold = false});

  /// The words.
  final String text;

  /// Whether it was inside `<i>`.
  final bool italic;

  /// Whether it was inside `<b>`.
  final bool bold;

  /// The text of [runs] without their styles.
  static String plain(List<DictionaryRun> runs) =>
      runs.map((run) => run.text).join();

  @override
  bool operator ==(Object other) =>
      other is DictionaryRun &&
      other.text == text &&
      other.italic == italic &&
      other.bold == bold;

  @override
  int get hashCode => Object.hash(text, italic, bold);

  @override
  String toString() =>
      'DictionaryRun(${italic ? 'i ' : ''}${bold ? 'b ' : ''}$text)';
}
