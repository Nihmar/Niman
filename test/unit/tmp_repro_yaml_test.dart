// Temporary repro: unquoted {{...}} in a filename directive.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/templates/directives.dart';

void main() {
  test('unquoted brace values', () {
    final variants = <String, String>{
      'unquoted-date': '''
---
niman:
  filename: {{date:YYYY-MM-DD}}
---
Body
''',
      'unquoted-date-quoted': '''
---
niman:
  filename: "{{date:YYYY-MM-DD}}"
---
Body
''',
      'unquoted-today': '''
---
niman:
  filename: {{today}}
---
Body
''',
    };
    for (final e in variants.entries) {
      final d = readTemplateDirectives(e.value);
      print(
        '${e.key}: namesItself=${d.namesItself} '
        'filename=${d.filename ?? '-'} error=${d.error ?? '-'}',
      );
    }
  });
}
