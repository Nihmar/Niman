/// An iPhone's libraries in the app's container (decision 4 of
/// docs/records/apple-platforms.md): `…/Application/<UUID>/Documents/<name>`.
///
/// The container's own path is not the app's to keep: a reinstall gives it
/// a new UUID, and the system may move it. A path remembered on an earlier
/// run — the last library, the known list — is rebased onto today's
/// Documents before it is used, and a library's index is named after its
/// path inside Documents, so neither is lost when the container moves.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A container path is always POSIX, whatever host reads it: the host's own
/// context would turn its `/` into `\` on Windows.
final p.Context _posix = p.posix;

/// Where an iPhone's libraries live: the app's Documents, which the Files
/// app shows. Null off iOS.
Future<String?> containerDocuments() async =>
    Platform.isIOS ? (await getApplicationDocumentsDirectory()).path : null;

/// [path] inside today's [documents], when it is a path into an app
/// container's Documents — this one's, or one an earlier run had — and
/// [path] as it is otherwise.
String rebaseContainerPath(String path, String documents) {
  final normal = _posix.normalize(path);
  if (_posix.isWithin(documents, normal) || _posix.equals(documents, normal)) {
    return normal;
  }
  final inside = containerRelative(normal);
  return inside == null ? normal : _posix.join(documents, inside);
}

/// [path] relative to its app container's Documents, or null when it is
/// in none: `<anything>/Application/<UUID>/Documents/<rest>` gives `<rest>`.
String? containerRelative(String path) {
  final parts = _posix.split(_posix.normalize(path));
  for (var i = parts.length - 1; i >= 2; i--) {
    if (parts[i] == 'Documents' && parts[i - 2] == 'Application') {
      final rest = parts.sublist(i + 1);
      return rest.isEmpty ? '' : _posix.joinAll(rest);
    }
  }
  return null;
}

/// What names [libraryPath]'s index: on iOS its path inside Documents,
/// which outlives the container's; elsewhere the path itself.
String libraryIndexKey(String libraryPath) {
  if (!Platform.isIOS) return p.normalize(libraryPath);
  final normal = _posix.normalize(libraryPath);
  final inside = containerRelative(normal);
  return inside == null ? normal : 'ios-documents:$inside';
}
