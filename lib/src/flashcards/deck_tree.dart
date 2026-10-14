/// The Study tree (#533): decks as leaves under the categories their
/// `deck:` names, counts summed up the categories, a tag filter.
///
/// Pure: built from [DeckSummary]s, no read.
library;

import 'package:meta/meta.dart';
import 'package:niman/src/flashcards/deck_summary.dart';

/// The counts of a deck or of everything under a category.
@immutable
final class DeckCounts {
  /// Counts of [decks] decks.
  const new({
    this.decks = 0,
    this.total = 0,
    this.due = 0,
    this.fresh = 0,
    this.newAvailable = 0,
  });

  /// The counts of the deck [summary].
  factory of(DeckSummary summary) => DeckCounts(
    decks: 1,
    total: summary.total,
    due: summary.due,
    fresh: summary.fresh,
    newAvailable: summary.newAvailable,
  );

  /// The decks counted.
  final int decks;

  /// All their cards.
  final int total;

  /// Their cards due today or earlier.
  final int due;

  /// Their cards never reviewed.
  final int fresh;

  /// The new cards today's study shows: each deck's own share of the day's
  /// limit, summed.
  final int newAvailable;

  /// What a study shows today.
  int get toStudy => due + newAvailable;

  /// These counts and [other]'s together.
  DeckCounts operator +(DeckCounts other) => DeckCounts(
    decks: decks + other.decks,
    total: total + other.total,
    due: due + other.due,
    fresh: fresh + other.fresh,
    newAvailable: newAvailable + other.newAvailable,
  );
}

/// A row of the Study tree.
@immutable
sealed class DeckTreeNode {
  const new();

  /// What the row says: a category's name, a deck's name; empty for the
  /// **No category** group, which the screen names in the user's language.
  String get name;

  /// The counts of the deck, or summed over the category's decks.
  DeckCounts get counts;

  /// The decks at or under this row, in tree order: what a study of it
  /// reviews.
  List<DeckSummary> get decks;
}

/// A deck.
final class DeckLeaf extends DeckTreeNode {
  /// The leaf of [summary].
  new(this.summary) : counts = DeckCounts.of(summary);

  /// The deck, counted.
  final DeckSummary summary;

  @override
  String get name => summary.name;

  @override
  final DeckCounts counts;

  @override
  List<DeckSummary> get decks => [summary];
}

/// A category: its subcategories (alphabetical), then its decks (by name).
final class DeckCategory extends DeckTreeNode {
  /// A category holding [children].
  new({
    required this.name,
    required this.path,
    required this.children,
    this.uncategorized = false,
  }) : counts = children.fold(
         const DeckCounts(),
         (sum, child) => sum + child.counts,
       );

  @override
  final String name;

  /// The category's own place, from the root: `[Lingue, Inglese]`. Empty
  /// for **No category**.
  final List<String> path;

  /// Its rows.
  final List<DeckTreeNode> children;

  /// Whether this is the **No category** group.
  final bool uncategorized;

  @override
  final DeckCounts counts;

  @override
  late final List<DeckSummary> decks = [
    for (final child in children) ...child.decks,
  ];
}

/// The Study tree of a set of decks.
@immutable
final class DeckTree {
  /// A tree with [roots].
  const new(this.roots);

  /// Builds the tree of [summaries]. With [tags], only the decks that carry
  /// **all** of them stay, and the counts are summed over those.
  ///
  /// Categories with the same name in any case are one, written as first
  /// met. **No category** comes last.
  factory build(
    Iterable<DeckSummary> summaries, {
    Set<String> tags = const <String>{},
  }) {
    final kept = [
      for (final summary in summaries)
        if (tags.every(summary.tags.contains)) summary,
    ];
    final root = _Group('');
    for (final summary in kept) {
      var group = root;
      for (final segment in summary.category) {
        group = group.child(segment);
      }
      group.decks.add(summary);
    }
    final loose = root.decks;
    return DeckTree([
      ...root.categories(const []),
      if (loose.isNotEmpty)
        DeckCategory(
          name: '',
          path: const [],
          children: _leaves(loose),
          uncategorized: true,
        ),
    ]);
  }

  /// The tags the decks carry, alphabetically: the chips over the tree. Of
  /// all the decks, not of the filtered ones, so a chip stays to be taken
  /// off.
  static List<String> tagsOf(Iterable<DeckSummary> summaries) =>
      ({for (final summary in summaries) ...summary.tags}.toList()..sort());

  /// The top rows: categories alphabetically, **No category** last.
  final List<DeckTreeNode> roots;

  /// The counts of the whole tree.
  DeckCounts get counts =>
      roots.fold(const DeckCounts(), (sum, node) => sum + node.counts);

  /// Every deck, in tree order.
  List<DeckSummary> get decks => [for (final node in roots) ...node.decks];
}

List<DeckLeaf> _leaves(List<DeckSummary> decks) =>
    ([...decks]..sort(_byName)).map(DeckLeaf.new).toList();

int _byName(DeckSummary a, DeckSummary b) {
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  return byName != 0 ? byName : a.path.compareTo(b.path);
}

/// A category being built.
final class _Group {
  new(this.name);

  final String name;
  final Map<String, _Group> _children = {};
  final List<DeckSummary> decks = [];

  _Group child(String segment) =>
      _children.putIfAbsent(segment.toLowerCase(), () => _Group(segment));

  List<DeckCategory> categories(List<String> parent) {
    final groups = _children.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return [
      for (final group in groups)
        DeckCategory(
          name: group.name,
          path: [...parent, group.name],
          children: [
            ...group.categories([...parent, group.name]),
            ..._leaves(group.decks),
          ],
        ),
    ];
  }
}
