// GFM's task box, as `cmark-gfm` reads it: in the read view and in the
// writer alike.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/html/tree_html.dart';
import 'package:niman/src/markdown/task_box.dart';

void main() {
  test('a box and the white space after it', () {
    expect(TaskBox.of('[ ] foo'), (checked: false, length: 4));
    expect(TaskBox.of('[x]\tfoo'), (checked: true, length: 4));
    expect(TaskBox.of('[X]  foo'), (checked: true, length: 5));
  });

  test('a box the line ends at, the line ending with it', () {
    expect(TaskBox.of('[ ]'), (checked: false, length: 3));
    expect(TaskBox.of('[x] \nfoo'), (checked: true, length: 5));
  });

  test('no box', () {
    expect(TaskBox.of('[ ]foo'), isNull);
    expect(TaskBox.of('[-] foo'), isNull);
    expect(TaskBox.of('[]'), isNull);
    expect(TaskBox.of('a [ ] b'), isNull);
  });

  test('the writer draws an empty task as a box', () {
    expect(
      TreeHtml('- [ ]\n- [x] \n  foo').render(),
      '<ul>\n'
      '<li><input type="checkbox" disabled="" /> </li>\n'
      '<li><input type="checkbox" checked="" disabled="" /> foo</li>\n'
      '</ul>\n',
    );
  });
}
