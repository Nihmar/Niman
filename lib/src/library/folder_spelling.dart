/// Resolving a folder path to the spelling the library holds it under
/// (#1246).
library;

import 'package:niman/src/core/settings/library_config.dart'
    show cleanFolderPath;

/// A folder segment as the library spells it, and whatever the caller
/// carries to look up the next one: its row, its path, an id.
typedef HeldSegment<T> = ({String name, T token});

/// [folder] as the library spells it, segment by segment (#1246).
///
/// A path [exact] holds is the one there, its spelling and all; otherwise
/// each segment [child] holds under other capitals is that segment, and
/// from the first segment the library does not hold the rest is kept as
/// written. Nothing is made: a folder to be created is still created by
/// whoever writes into it.
///
/// The callbacks match names the way the index does: a segment counts as
/// the same folder when it differs only in case, as SQLite's `NOCASE`
/// collation reads it — ASCII only, so a capital outside A–Z does not
/// fold (#847, #857).
///
/// The folder comes back cleaned the way `NoteOps.ensureFolder` cleans it:
/// empty, `.` and `..` segments dropped, no leading or trailing slash.
Future<String> resolveFolderSpelling<T>(
  String folder, {
  required Future<T?> Function(String path) exact,
  required Future<HeldSegment<T>?> Function(T? parent, String segment) child,
}) async {
  final clean = cleanFolderPath(folder, '');
  if (clean.isEmpty) return '';
  if (await exact(clean) != null) return clean;
  final parts = clean.split('/');
  final segments = <String>[];
  T? parent;
  for (var i = 0; i < parts.length; i++) {
    final held = await child(parent, parts[i]);
    if (held == null) {
      segments.addAll(parts.skip(i));
      break;
    }
    segments.add(held.name);
    parent = held.token;
  }
  return segments.join('/');
}
