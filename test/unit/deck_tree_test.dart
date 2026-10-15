// The Study tree (#533): decks under the categories their `deck:` names,
// counts summed up, a tag filter.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/flashcards/deck_summary.dart';
import 'package:niman/src/flashcards/deck_tree.dart';

DeckSummary deck(
  String name, {
  List<String> category = const [],
  List<String> tags = const [],
  int total = 10,
  int due = 0,
  int fresh = 0,
  int? available,
  String? path,
}) => DeckSummary(
  path: path ?? '$name.md',
  name: name,
  category: category,
  tags: tags,
  total: total,
  due: due,
  fresh: fresh,
  newAvailable: available ?? fresh,
);

List<String> names(Iterable<DeckTreeNode> nodes) => [
  for (final node in nodes) node.name,
];

void main() {
  test('groups decks under their categories, nested', () {
    final tree = DeckTree.build([
      deck('Verbs', category: ['Lingue', 'Inglese']),
      deck('Nouns', category: ['Lingue', 'Inglese']),
      deck('Verben', category: ['Lingue', 'Tedesco']),
      deck('Capitals', category: ['Geografia']),
    ]);
    expect(names(tree.roots), ['Geografia', 'Lingue']);
    final lingue = tree.roots.last as DeckCategory;
    expect(lingue.path, ['Lingue']);
    expect(names(lingue.children), ['Inglese', 'Tedesco']);
    final inglese = lingue.children.first as DeckCategory;
    expect(inglese.path, ['Lingue', 'Inglese']);
    expect(names(inglese.children), ['Nouns', 'Verbs']);
    expect(inglese.children.first, isA<DeckLeaf>());
  });

  test('a category lists its subcategories, then its decks, by name', () {
    final tree = DeckTree.build([
      deck('zeta', category: ['A']),
      deck('Alpha', category: ['A']),
      deck('sub deck', category: ['A', 'Sub']),
      deck('beta', category: ['A']),
    ]);
    final a = tree.roots.single as DeckCategory;
    expect(names(a.children), ['Sub', 'Alpha', 'beta', 'zeta']);
  });

  test('No category comes last, whatever the names', () {
    final tree = DeckTree.build([
      deck('Loose b'),
      deck('Zoology', category: ['Zoo']),
      deck('Loose a'),
    ]);
    expect(names(tree.roots), ['Zoo', '']);
    final loose = tree.roots.last as DeckCategory;
    expect(loose.uncategorized, isTrue);
    expect(loose.path, isEmpty);
    expect(names(loose.children), ['Loose a', 'Loose b']);
  });

  test('categories that differ in case only are one', () {
    final tree = DeckTree.build([
      deck('a', category: ['Lingue']),
      deck('b', category: ['lingue']),
    ]);
    expect(tree.roots, hasLength(1));
    expect(tree.roots.single.name, 'Lingue');
    expect(tree.roots.single.counts.decks, 2);
  });

  test('sums the counts up the categories', () {
    final tree = DeckTree.build([
      deck('a', category: ['L', 'E'], due: 3, fresh: 5, available: 2),
      deck('b', category: ['L', 'E'], total: 4, due: 1),
      deck('c', category: ['L'], total: 6, due: 2, fresh: 6, available: 6),
      deck('d', total: 1, fresh: 1),
    ]);
    final l = tree.roots.first as DeckCategory;
    final e = l.children.first as DeckCategory;
    expect(e.counts.total, 14);
    expect(e.counts.due, 4);
    expect(e.counts.fresh, 5);
    expect(e.counts.newAvailable, 2);
    expect(e.counts.toStudy, 6);
    expect(e.counts.decks, 2);
    expect(l.counts.total, 20);
    expect(l.counts.due, 6);
    expect(l.counts.newAvailable, 8);
    expect(l.counts.decks, 3);
    expect(tree.counts.total, 21);
    expect(tree.counts.decks, 4);
  });

  test('a category knows the decks under it, for studying it whole', () {
    final tree = DeckTree.build([
      deck('a', category: ['L', 'E']),
      deck('c', category: ['L']),
      deck('d'),
    ]);
    final l = tree.roots.first as DeckCategory;
    expect(l.decks.map((d) => d.name), ['a', 'c']);
    expect(tree.decks.map((d) => d.name), ['a', 'c', 'd']);
    expect((l.children.last as DeckLeaf).decks.single.name, 'c');
  });

  group('the tag filter', () {
    final decks = [
      deck('a', category: ['L'], tags: ['x', 'y'], total: 1),
      deck('b', category: ['L'], tags: ['x'], total: 2),
      deck('c', category: ['M'], tags: ['y'], total: 4),
      deck('d', total: 8),
    ];

    test('keeps the decks carrying all the tags and sums over them', () {
      expect(DeckTree.build(decks, tags: const {'x'}).counts.total, 3);
      expect(DeckTree.build(decks, tags: const {'x', 'y'}).counts.total, 1);
      expect(DeckTree.build(decks, tags: const {'y'}).counts.total, 5);
      expect(DeckTree.build(decks, tags: const {'z'}).roots, isEmpty);
    });

    test('drops a category left with no deck, and No category with it', () {
      final tree = DeckTree.build(decks, tags: const {'y'});
      expect(names(tree.roots), ['L', 'M']);
      expect((tree.roots.first as DeckCategory).counts.decks, 1);
    });

    test('no tag keeps every deck', () {
      expect(DeckTree.build(decks).counts.total, 15);
    });

    test('lists the tags of all the decks, alphabetically', () {
      expect(DeckTree.tagsOf(decks), ['x', 'y']);
      expect(DeckTree.tagsOf(const []), isEmpty);
    });
  });

  test('an empty tree has nothing', () {
    final tree = DeckTree.build(const []);
    expect(tree.roots, isEmpty);
    expect(tree.counts.decks, 0);
  });
}
