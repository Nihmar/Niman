/// Files and folders dropped on the window (#75).
///
/// One target covers the whole window, above every screen, and hands what
/// lands on it to the same requests a launch makes (#41). A Markdown file
/// opens the way Open file opens one (#77): as its note inside the open
/// library, on its own anywhere else. A folder is offered for import into
/// the library, or, with no library open, opens as one. Anything else is
/// named and left alone.
///
/// While something is dragged over the window a frame and a line say what
/// a drop would do. The desktops do not tell the app what is being
/// dragged until it lands, so the frame cannot tell a Markdown file from
/// anything else; what cannot be opened is said after the drop.
library;

import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What a drop holds, sorted by what each can become.
typedef SortedDrop = ({
  List<String> files,
  List<String> folders,
  List<String> rejected,
});

/// Sorts the dropped [paths]: Markdown files to open, folders to import,
/// and the rest, which is left alone. [isFolder] stands in for the disk
/// in tests.
SortedDrop sortDrop(
  List<String> paths, {
  bool Function(String path)? isFolder,
}) {
  final folder = isFolder ?? FileSystemEntity.isDirectorySync;
  final files = <String>[];
  final folders = <String>[];
  final rejected = <String>[];
  for (final path in paths) {
    final extension = p.extension(path).toLowerCase().replaceFirst('.', '');
    if (folder(path)) {
      folders.add(path);
    } else if (editorOnlyExtensions.contains(extension)) {
      files.add(path);
    } else {
      rejected.add(path);
    }
  }
  return (files: files, folders: folders, rejected: rejected);
}

/// Hands a sorted drop to [requests], and names what it left alone
/// through [messenger].
void deliverDrop(
  SortedDrop drop,
  LaunchRequests requests,
  ScaffoldMessengerState? messenger,
) {
  drop.files.forEach(requests.openFile);
  drop.folders.forEach(requests.openFolder);
  if (drop.rejected.isEmpty) return;
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        AppStrings.dropRejected(drop.rejected.map(p.basename).join(', ')),
      ),
    ),
  );
}

/// The window's drop target, with its drag-over frame.
final class AppDropTarget extends StatefulWidget {
  /// Takes drops over [child] and hands them to [requests].
  const new({required this.requests, required this.child, super.key});

  /// Where the dropped files and folders go.
  final LaunchRequests requests;

  /// The app.
  final Widget child;

  @override
  State<AppDropTarget> createState() => _AppDropTargetState();
}

final class _AppDropTargetState extends State<AppDropTarget> {
  bool _over = false;

  /// Linux and Windows: the phone has nothing to drag from, and the
  /// plugin's Android side would only take drops from another app's
  /// window.
  static final bool _desktop = Platform.isLinux || Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    if (!_desktop) return widget.child;
    return DropTarget(
      onDragEntered: (_) => setState(() => _over = true),
      onDragExited: (_) => setState(() => _over = false),
      onDragDone: (details) {
        setState(() => _over = false);
        deliverDrop(
          sortDrop([for (final item in details.files) item.path]),
          widget.requests,
          ScaffoldMessenger.maybeOf(context),
        );
      },
      child: Stack(
        children: [
          widget.child,
          if (_over) const Positioned.fill(child: DropFrame()),
        ],
      ),
    );
  }
}

/// The frame shown while something is dragged over the window.
final class DropFrame extends StatelessWidget {
  /// Creates the frame.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: DecoratedBox(
        key: const Key('drop-frame'),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.06),
          border: Border.all(color: scheme.primary, width: 2),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Material(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  AppStrings.dropHint,
                  style: TextStyle(color: scheme.onPrimaryContainer),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
