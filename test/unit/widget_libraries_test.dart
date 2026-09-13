// Library mirror (round 2, R1): the config activity's view of the
// registry.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/db/app_database.dart';
import 'package:niman/src/widget/widget_libraries.dart';

void main() {
  KnownLibrary library(String path, String name) {
    return KnownLibrary(
      path: path,
      name: name,
      lastOpened: DateTime(2026, 9, 13),
    );
  }

  test('encodes path, name and index per library', () {
    final encoded = encodeLibraryMirror(
      [library('/lib/Work', 'Work'), library('/lib/Personal', 'Personal')],
      {'/lib/Work': '/idx/a.db', '/lib/Personal': '/idx/b.db'},
    );
    expect(jsonDecode(encoded), {
      'libraries': [
        {'path': '/lib/Work', 'name': 'Work', 'index': '/idx/a.db'},
        {'path': '/lib/Personal', 'name': 'Personal', 'index': '/idx/b.db'},
      ],
    });
  });

  test('skips libraries without a known index file', () {
    final encoded = encodeLibraryMirror([library('/lib/Work', 'Work')], {});
    expect(jsonDecode(encoded), {'libraries': <Object?>[]});
  });
}
