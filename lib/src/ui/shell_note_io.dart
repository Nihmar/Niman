/// How an open note reaches the disk through the library (split out of
/// `shell.dart` for #710): the editor's whole and sliced writes, and the
/// note a dead link creates — each null while no library is ready.
library;

import 'package:niman/src/core/files.dart';
import 'package:niman/src/library/note_writer.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/note_view.dart';
import 'package:path/path.dart' as p;

/// The editor's write path into the open library: [NoteOperations.saveNote]
/// with the editor's absolute path turned library-relative. Null while no
/// library is ready, or for a note outside the library root — the editor
/// then writes the file itself.
NoteSaver? noteSaverFor(LibrarySession controller) {
  final ops = controller.ops;
  final root = controller.root;
  if (ops == null || root == null) return null;
  return (path, content, {required editSession}) {
    if (!p.isWithin(root, path)) {
      return writeNoteOffIsolate(path, content).then((_) {});
    }
    return ops.saveNote(relPath(path, root), content, editSession: editSession);
  };
}

/// The same write path for a note handed over in slices
/// ([NoteView.saveNoteStream]): the joined twin above, without the join.
///
/// Null for a note outside the library root as well, which is the one
/// case the streaming write does not cover — [NoteView] then joins the
/// note and saves it through [noteSaverFor].
NoteStreamSaver? noteStreamSaverFor(LibrarySession controller) {
  final ops = controller.ops;
  final root = controller.root;
  if (ops == null || root == null) return null;
  return (path, content, {required editSession, references}) {
    if (!p.isWithin(root, path)) {
      return Future<void>.error(StateError('"$path" is outside the library'));
    }
    return ops.saveNoteStream(
      relPath(path, root),
      content,
      editSession: editSession,
      references: references,
    );
  };
}

/// The dead-link note-creation path (issue #78): an empty note through
/// the library's own creation path; null while no library is ready,
/// which keeps the dead-link snackbar instead of the offer.
Future<String> Function(String relPath)? missingNoteCreatorFor(
  LibrarySession controller,
) {
  final ops = controller.ops;
  if (ops == null) return null;
  return (relPath) async {
    final note = await ops.createNote(
      parentPath: parentOf(relPath),
      name: p.basenameWithoutExtension(relPath),
    );
    return note.path;
  };
}
