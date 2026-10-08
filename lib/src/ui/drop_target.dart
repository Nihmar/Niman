/// Files and folders dropped on the window (#75).
///
/// The drag itself is taken by the platform runner, which reports what it
/// sees over `niman/drop` ([DropTargetService], #224); one target here
/// covers the whole window, above every screen, and hands what lands on it
/// to the same requests a launch makes (#41). A Markdown file opens the
/// way Open file opens one (#77): as its note inside the open library, on
/// its own anywhere else. A folder is offered for import into the library,
/// or, with no library open, opens as one. Anything else is named and left
/// alone.
///
/// While something is dragged over the window a frame and a line say what
/// a drop would do. The desktops do not tell the app what is being
/// dragged until it lands, so the frame cannot tell a Markdown file from
/// anything else; what cannot be opened is said after the drop.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/drop_in.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What a drop holds, sorted by what each can become.
typedef SortedDrop = ({
  List<String> files,
  List<String> folders,
  List<String> rejected,
});

/// Sorts the dropped [paths]: Markdown files to open, folders and Notion
/// exports to import, and the rest, which is left alone. [isFolder]
/// stands in for the disk in tests.
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
    } else if (extension == 'zip') {
      // A Notion export, offered for import (#25): the shell decides by
      // the extension what the archive is.
      folders.add(path);
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
///
/// The drag is taken by the platform runner: this listens to what it
/// reports and is where a drop becomes an open file or an offer to import.
final class AppDropTarget extends StatefulWidget {
  /// Takes drops over [child] and hands them to [requests].
  const new({
    required this.requests,
    required this.drops,
    required this.child,
    super.key,
  });

  /// Where the dropped files and folders go.
  final LaunchRequests requests;

  /// What the window's own target reports ([DropTargetService]).
  final DropTargetService drops;

  /// The app.
  final Widget child;

  @override
  State<AppDropTarget> createState() => _AppDropTargetState();
}

final class _AppDropTargetState extends State<AppDropTarget> {
  static const AppLogger _log = AppLogger(name: 'drop');

  late final StreamSubscription<WindowDrop> _drops;
  bool _over = false;
  bool _link = false;

  @override
  void initState() {
    super.initState();
    _drops = widget.drops.events.listen(_onDrop);
  }

  @override
  void dispose() {
    unawaited(_drops.cancel());
    super.dispose();
  }

  void _onDrop(WindowDrop event) {
    if (!mounted) return;
    switch (event) {
      case DragEntered(:final link):
        setState(() {
          _over = true;
          _link = link;
        });
      case DragExited():
        setState(() => _over = false);
      case LinksDropped(:final links):
        setState(() => _over = false);
        // One page at a time: the dialog captures the first.
        widget.requests.capturePage(links.first);
      case Dropped(:final paths):
        setState(() => _over = false);
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (paths.isEmpty) {
          messenger?.showSnackBar(
            SnackBar(content: Text(AppStrings.dropNothing)),
          );
          return;
        }
        final sorted = sortDrop(paths);
        _log.debug(
          'drop sorted: ${sorted.files.length} file(s), '
          '${sorted.folders.length} folder(s), '
          '${sorted.rejected.length} left alone',
        );
        deliverDrop(sorted, widget.requests, messenger);
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_over) Positioned.fill(child: DropFrame(link: _link)),
    ],
  );
}

/// The frame shown while something is dragged over the window: what a
/// drop of files does, or, for a browser's link, that it is captured.
final class DropFrame extends StatelessWidget {
  /// Creates the frame.
  const new({this.link = false, super.key});

  /// Whether a link is dragged.
  final bool link;

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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      link ? AppStrings.captureDropHint : AppStrings.dropHint,
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                    if (link)
                      Text(
                        AppStrings.captureDropDetail,
                        style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
