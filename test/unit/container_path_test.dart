// An iPhone's libraries in the app's container (decision 4 of
// docs/records/apple-platforms.md): a path remembered before the container
// moved is rebased onto today's Documents, and the folders offered as
// libraries are the ones there that can be.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/library/container_path.dart';
import 'package:niman/src/ui/library_picker_blocking.dart';
import 'package:path/path.dart' as p;

void main() {
  final old = p.join(
    '/private',
    'var',
    'mobile',
    'Containers',
    'Data',
    'Application',
    'OLD-UUID',
    'Documents',
  );
  final today = p.join(
    '/private',
    'var',
    'mobile',
    'Containers',
    'Data',
    'Application',
    'NEW-UUID',
    'Documents',
  );

  test("a library in an earlier container is today's at the same place", () {
    expect(
      rebaseContainerPath(p.join(old, 'Notes', 'Work'), today),
      p.join(today, 'Notes', 'Work'),
    );
    expect(containerRelative(p.join(old, 'Notes')), 'Notes');
    expect(containerRelative(old), '');
  });

  test("a path in today's container, or in none, stays as it is", () {
    expect(
      rebaseContainerPath(p.join(today, 'Notes'), today),
      p.join(today, 'Notes'),
    );
    final elsewhere = p.join('/Users', 'me', 'Documents', 'Notes');
    expect(containerRelative(elsewhere), isNull);
    expect(rebaseContainerPath(elsewhere, today), elsewhere);
  });

  test('the libraries offered are the visible folders, not the Inbox', () {
    final dir = Directory.systemTemp.createTempSync('niman_documents_');
    addTearDown(() => dir.deleteSync(recursive: true));
    for (final name in ['Work', 'archive', '.hidden', 'Inbox']) {
      Directory(p.join(dir.path, name)).createSync();
    }
    File(p.join(dir.path, 'loose.md')).writeAsStringSync('x');
    expect(libraryFolderNames(dir.path), ['archive', 'Work']);
  });
}
