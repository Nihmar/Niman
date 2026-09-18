/// The shell's side of the workspace (issue #23): reads what was left
/// open when a library opens, follows the note the shell shows, and
/// follows the library when a note or a folder under an open note is
/// renamed, moved or deleted.
///
/// One note at a time for now — the shell's note replaces the workspace's
/// showing tab — so nothing on screen changes yet; what this lays down is
/// the model the tabs will stand on, kept current and kept on disk.
library;

import 'dart:async';

import 'package:niman/src/library/session.dart';
import 'package:niman/src/workspace/workspace_controller.dart';

/// The open library's workspace, as the shell drives it.
final class ShellWorkspace {
  /// The workspace of [session]'s library, kept through the session.
  new(LibrarySession session)
    : _session = session,
      controller = WorkspaceController(save: session.saveWorkspace);

  final LibrarySession _session;

  /// The workspace itself.
  final WorkspaceController controller;

  /// The note last followed, so an unchanged build changes nothing.
  String? _following;
  bool _followed = false;

  /// Reads back what was left open in the library on this device.
  Future<void> load() async {
    controller.adopt(await _session.savedWorkspace);
  }

  /// The shell now shows [notePath] (library-relative), or no note.
  ///
  /// Called from the shell's build, so the change lands after the frame
  /// instead of notifying in the middle of one.
  void follow(String? notePath) {
    if (_followed && notePath == _following) return;
    final previous = _following;
    _following = notePath;
    _followed = true;
    scheduleMicrotask(() {
      if (notePath != null) {
        controller.update((w) => w.replaceActive(notePath));
      } else if (previous != null) {
        controller.update((w) => w.closePath(previous));
      }
    });
  }

  /// [from] is now at [to]: a note, or a folder with notes under it.
  void moved(String from, String to) {
    if (_following case final open?
        when open == from || open.startsWith('$from/')) {
      _following = to + open.substring(from.length);
    }
    controller.update((w) => w.renamed(from, to));
  }

  /// [path] is gone: a note, or a folder with notes under it.
  void deleted(String path) => controller.update((w) => w.deleted(path));

  /// Writes what is pending and lets go.
  void dispose() => controller.dispose();
}
