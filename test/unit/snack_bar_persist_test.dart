// A snack bar with an action stays up until it is dismissed by hand unless
// it says `persist: false` (#508): a message that offers a way somewhere
// would otherwise sit over the screen forever. Each one was fixed by hand,
// and the OCR's "Text recognized · Open text" still slipped through, so
// the rule is checked over the sources.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('every snack bar with an action says persist: false', () {
    final missing = <String>[];
    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in sources) {
      final text = file.readAsStringSync();
      for (final action in 'SnackBarAction('.allMatchesIn(text)) {
        final bar = text.lastIndexOf('SnackBar(', action);
        if (bar >= 0 && text.substring(bar, action).contains('persist:')) {
          continue;
        }
        final line = '\n'.allMatchesIn(text.substring(0, action)).length + 1;
        missing.add('${p.relative(file.path)}:$line');
      }
    }
    expect(missing, isEmpty);
  });
}

extension on String {
  /// The offsets where this string occurs in [text].
  Iterable<int> allMatchesIn(String text) =>
      allMatches(text).map((match) => match.start);
}
