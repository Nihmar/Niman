/// The library picker's blocking listing, run in `Isolate.run`
/// (test/unit/ui_isolate_io_test.dart).
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// The folders in [documents] a library can be: not hidden, and not iOS's
/// own `Inbox`, where documents opened from elsewhere are copied.
List<String> libraryFolderNames(String documents) {
  final dir = Directory(documents);
  if (!dir.existsSync()) return const [];
  return [
    for (final entry in dir.listSync(followLinks: false))
      if (entry is Directory)
        if (p.basename(entry.path) case final name
            when !name.startsWith('.') && name != 'Inbox')
          name,
  ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
}
