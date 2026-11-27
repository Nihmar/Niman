// What a line says about the list item it may be: the head Enter, the indent
// and the checklist read (#142, #1341, #1342).
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/editor/list_item_head.dart';

void main() {
  group('a thematic break is not an item (#1341)', () {
    for (final line in <String>[
      '- - -',
      '* * *',
      '-  -  -',
      '- --',
      '  - - -',
      '- - - -',
      '- - -  ',
      '***',
      '---',
      '_ _ _',
    ]) {
      test(line, () => expect(listItemHead(line), isNull));
    }

    test('an item that merely starts with dashes still is one', () {
      expect(listItemHead('- - a')!.content, '- a');
      expect(listItemHead('- --a')!.content, '--a');
      expect(listItemHead('* * a')!.content, '* a');
      expect(listItemHead('- -')!.content, '-');
    });
  });
}
