import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/tree_moves.dart';

void main() {
  test('the folders moved since a revision are the union of its changes', () {
    final moves = TreeMoves()
      ..record(revision: 1, treeRevision: 1, folders: {0})
      ..record(revision: 2) // a save's size and time: not the tree's
      ..record(revision: 3, treeRevision: 2, folders: {7})
      ..record(revision: 4, treeRevision: 3, folders: {9});
    expect(moves.since(1, tree: true), {7, 9});
    expect(moves.since(3, tree: true), isEmpty, reason: 'nothing since');
    expect(moves.since(2, tree: false), {7, 9});
  });

  test('a change that does not say where answers any', () {
    final moves = TreeMoves()
      ..record(revision: 1, treeRevision: 1, folders: {0})
      ..record(revision: 2, treeRevision: 2)
      ..record(revision: 3, treeRevision: 3, folders: {5});
    expect(moves.since(0, tree: true), isNull);
    expect(moves.since(2, tree: true), {5});
    // The contents of a save: the library's revision says nothing of where.
    expect((TreeMoves()..record(revision: 1)).since(0, tree: false), isNull);
  });

  test('a reader older than the log reads everything again', () {
    final moves = TreeMoves(kept: 2);
    for (var r = 1; r <= 5; r++) {
      moves.record(revision: r, treeRevision: r, folders: {r});
    }
    expect(moves.since(3, tree: true), {4, 5});
    expect(moves.since(2, tree: true), isNull, reason: 'revision 3 forgotten');
  });

  test('contents-only changes pushing the tree changes out claim nothing', () {
    // The tree change is forgotten and only saves' sizes and times are held:
    // an empty log of tree changes must not read as "the tree did not move".
    final moves = TreeMoves()
      ..record(revision: 1, treeRevision: 1, folders: {7});
    for (var r = 2; r <= 70; r++) {
      moves.record(revision: r);
    }
    expect(moves.since(0, tree: true), isNull, reason: 'revision 1 forgotten');
    expect(moves.since(1, tree: true), isEmpty, reason: 'nothing after it');
    expect(moves.since(0, tree: false), isNull);
    expect(moves.since(6, tree: false), isNull);
    expect(moves.since(70, tree: false), isEmpty);
  });

  test('a log that forgot only older changes still answers for newer', () {
    final moves = TreeMoves(kept: 3)
      ..record(revision: 1, treeRevision: 1, folders: {1})
      ..record(revision: 2)
      ..record(revision: 3)
      ..record(revision: 4, treeRevision: 2, folders: {2})
      ..record(revision: 5);
    expect(moves.since(1, tree: true), {2});
    expect(moves.since(0, tree: true), isNull);
  });
}
