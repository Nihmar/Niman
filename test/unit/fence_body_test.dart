// A fenced block taken apart (#530): the one reading the read view, `live`
// and the export share, so a Mermaid fence is the same source to all three.
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/fence_body.dart';

FenceBody? _body(String text) => fenceBody(text.split('\n'));

void main() {
  test("the language is the info string's first word", () {
    expect(_body('```mermaid title\nA\n```')?.language, 'mermaid');
    expect(_body('~~~\nA\n~~~')?.language, '');
    expect(_body('plain\nA'), isNull);
  });

  test('a closing fence is the same run, as long or longer, alone', () {
    expect(_body('```\nA\n```'), (language: '', code: 'A', closed: true));
    expect(_body('````\nA\n`````')?.closed, isTrue);
    // Shorter, of the other character, or followed by words: code.
    for (final last in ['```', '~~~~', '```` x']) {
      expect(_body('````\nA\n$last'), (
        language: '',
        code: 'A\n$last',
        closed: false,
      ), reason: last);
    }
    expect(_body('```\nA'), (language: '', code: 'A', closed: false));
    expect(_body('```'), (language: '', code: '', closed: false));
  });

  test("the opening line's indent comes off the code, as far as it goes", () {
    // A list item's indent and the fence's own, four spaces and past.
    expect(
      _body('    ```mermaid\n    mindmap\n      root\n   short\n    ```'),
      (language: 'mermaid', code: 'mindmap\n  root\nshort', closed: true),
    );
    // A tab reaching past the indent leaves its other columns as spaces.
    expect(_body('  ```\n\tA\n  ```')?.code, '  A');
  });
}
