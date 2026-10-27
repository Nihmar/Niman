// #1234: the paths a drag carries are copied when a drag looks at them, once,
// not when the row that can be dragged is built.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/ui/lazy_drag_paths.dart';

void main() {
  test('copies nothing until it is looked at, and then once', () {
    var copies = 0;
    final marked = {'a.md', 'b.md'};
    final paths = LazyDragPaths(() {
      copies++;
      return marked.toList();
    });

    expect(copies, 0);
    expect(paths.isResolved, isFalse);

    marked.add('c.md');
    expect(paths.length, 3, reason: 'the marks as they are when looked at');
    expect(paths, ['a.md', 'b.md', 'c.md']);
    expect(paths.first, 'a.md');
    expect(copies, 1);

    marked.add('d.md');
    expect(paths.length, 3, reason: 'a drag carries what it started with');
    expect(copies, 1);
  });

  test('is a list a drop can take, and cannot be changed', () {
    final paths = LazyDragPaths(() => ['a.md', 'b.md']);

    expect([for (final path in paths) path.toUpperCase()], ['A.MD', 'B.MD']);
    expect(() => paths.add('c.md'), throwsUnsupportedError);
    expect(() => paths[0] = 'x.md', throwsUnsupportedError);
  });
}
