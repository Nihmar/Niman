/// The name of the folder an import makes in the library (#75).
///
/// A folder brought in from outside — Markdown copied, web pages converted —
/// lands in a new folder of the library root named after the one dropped,
/// and the folder import itself is `import/folder/`.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// A folder name free in [root]: [wanted], or `wanted 2`, `wanted 3`…
/// while each is taken, so an import never lands on top of the library's
/// own folders.
String freeFolderName(String root, String wanted) {
  var name = wanted;
  for (
    var n = 2;
    FileSystemEntity.typeSync(p.join(root, name)) !=
        FileSystemEntityType.notFound;
    n++
  ) {
    name = '$wanted $n';
  }
  return name;
}
