/// Where a capture's notification leads back into the app (#531): what a
/// tap on it, or on one of its buttons, is routed by.
library;

const String _open = 'capture-open:';
const String _folder = 'capture-folder:';
const String _cancel = 'capture-cancel:';

/// Opens the note at a library-relative path.
String captureOpenRoute(String path) => '$_open$path';

/// Shows a folder in the tree ('' is the root).
String captureFolderRoute(String folder) => '$_folder$folder';

/// Cancels the background capture [id].
String captureCancelRoute(int id) => '$_cancel$id';

/// Where a capture's notification leads.
sealed class CaptureRoute {
  const new();
}

/// To a note.
final class CaptureOpenNote extends CaptureRoute {
  /// To the note at [path].
  const new(this.path);

  /// The note, library-relative.
  final String path;
}

/// To a folder in the tree.
final class CaptureShowFolder extends CaptureRoute {
  /// To [folder].
  const new(this.folder);

  /// The folder, library-relative ('' is the root).
  final String folder;
}

/// To a capture's end.
final class CaptureCancel extends CaptureRoute {
  /// Cancels the capture [id].
  const new(this.id);

  /// The capture.
  final int id;
}

/// The capture route [route] names, or null when it is not one.
CaptureRoute? captureRouteOf(String? route) {
  if (route == null) return null;
  if (route.startsWith(_open)) {
    return CaptureOpenNote(route.substring(_open.length));
  }
  if (route.startsWith(_folder)) {
    return CaptureShowFolder(route.substring(_folder.length));
  }
  if (route.startsWith(_cancel)) {
    final id = int.tryParse(route.substring(_cancel.length));
    return id == null ? null : CaptureCancel(id);
  }
  return null;
}
