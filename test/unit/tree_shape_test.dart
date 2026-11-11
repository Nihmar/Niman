// #1266: where the tree stands — beside the panes, or over them on a touch
// device whose panes would be too narrow beside it.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/tree_shape.dart';

void main() {
  test('a mouse keeps the tree beside, whatever the room', () {
    expect(
      treeShapeFor(touch: false, portrait: true, panesBeside: 100),
      TreeShape.beside,
    );
  });

  test('a thumb in landscape keeps it beside panes wide enough', () {
    expect(
      treeShapeFor(
        touch: true,
        portrait: false,
        panesBeside: minPanesBesideTree,
      ),
      TreeShape.beside,
    );
    expect(
      treeShapeFor(
        touch: true,
        portrait: false,
        panesBeside: minPanesBesideTree - 1,
      ),
      TreeShape.over,
    );
  });

  test('a thumb in portrait has it over the note, whatever the room', () {
    expect(
      treeShapeFor(touch: true, portrait: true, panesBeside: 900),
      TreeShape.over,
    );
  });

  test('a thumb lays it over Home and Todo, a mouse does not', () {
    expect(
      treeShapeFor(touch: true, portrait: false, panesBeside: 900, page: true),
      TreeShape.over,
    );
    expect(
      treeShapeFor(touch: false, portrait: false, panesBeside: 900, page: true),
      TreeShape.beside,
    );
  });

  test('a thumb lays it over a note being written in', () {
    expect(
      treeShapeFor(
        touch: true,
        portrait: false,
        panesBeside: 900,
        writing: true,
      ),
      TreeShape.over,
    );
  });
}
