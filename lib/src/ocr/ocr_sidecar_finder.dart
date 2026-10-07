import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_sidecar.dart';
import 'package:path/path.dart' as p;

/// The sidecar of the file at [path] (library-relative) and its text, or
/// null when the file has none yet (#595): the note beside it under one
/// of [ocrSidecarNames] whose frontmatter links to it.
Future<({String path, String text})?> findOcrSidecar(
  NoteOperations ops,
  String path,
) async {
  final fileName = p.posix.basename(path);
  final folder = p.posix.dirname(path);
  for (final name in ocrSidecarNames(fileName)) {
    final candidate = p.posix.join(folder == '.' ? '' : folder, '$name.md');
    if (await ops.find(candidate) == null) continue;
    final text = await ops.readNote(candidate);
    if (isOcrSidecarOf(text, fileName)) return (path: candidate, text: text);
  }
  return null;
}
