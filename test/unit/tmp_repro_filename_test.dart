// Temporary repro for the "filename directive still asks for a name" report.
// ignore_for_file: avoid_print, prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/templates/directives.dart';

void main() {
  test('variants', () {
    final variants = <String, String>{
      'plain': '''
---
niman:
  filename: My Daily
---
Body {{title}}
''',
      'quoted': '''
---
niman:
  filename: "My Daily"
---
Body
''',
      'date': '''
---
niman:
  filename: "{{date:YYYY-MM-DD}}"
---
Body
''',
      'with-title': '''
---
niman:
  filename: "Report {{title}}"
---
Body
''',
      'flow-map': '''
---
niman: {filename: Inline}
---
Body
''',
      'no-niman-nesting': '''
---
filename: Flat
---
Body
''',
    };
    variants.forEach((label, source) {
      final d = readTemplateDirectives(source);
      print(
        '$label: namesItself=${d.namesItself} '
        'filename=${d.filename ?? '-'} error=${d.error ?? '-'}',
      );
    });
  });
}
