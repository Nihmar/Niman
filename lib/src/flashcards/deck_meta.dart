/// What a deck note's frontmatter says about its deck (#533): where it
/// sits in the Study tree, which columns of a wide table are the question
/// and the answer, and its tags.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/frontmatter/parser.dart';

/// A deck's frontmatter, read.
@immutable
final class DeckMeta {
  /// A deck at [category] with [tags].
  const new({
    this.category = const <String>[],
    this.front,
    this.back,
    this.tags = const <String>[],
    this.title,
  });

  /// Reads [frontmatter], which a note without any has none of.
  factory of(Frontmatter? frontmatter) {
    if (frontmatter == null) return const DeckMeta();
    String? field(String key) {
      final values = frontmatter.fields[key];
      final value = values == null || values.isEmpty ? '' : values.first.trim();
      return value.isEmpty ? null : value;
    }

    return DeckMeta(
      category: categoryOf(field('deck') ?? ''),
      front: field('front'),
      back: field('back'),
      tags: frontmatter.tags,
      title: frontmatter.title,
    );
  }

  /// The segments of a `deck:` value, split on `/` and trimmed; empty
  /// segments dropped, so an empty value is no category.
  static List<String> categoryOf(String deck) => [
    for (final part in deck.split('/'))
      if (part.trim().isNotEmpty) part.trim(),
  ];

  /// `deck:` as the categories from the root down; empty for **No
  /// category**.
  final List<String> category;

  /// `front:`, the header of the question column of a table with more than
  /// two.
  final String? front;

  /// `back:`, the header of its answer column.
  final String? back;

  /// The note's `tags:`, normalized.
  final List<String> tags;

  /// The note's `title:`, when it has one: the deck's name over its file
  /// name.
  final String? title;
}
