/// Files and folders dropped on the window (#75).
///
/// The drag itself is taken by the platform runner, which reports what it
/// sees over `niman/drop` ([DropTargetService], #224); one target here
/// covers the whole window, above every screen, and hands what lands on it
/// to the same requests a launch makes (#41). A web page (`.html`) is asked
/// about: converted into a note, attached, or both (#1293). A Markdown file
/// opens the
/// way Open file opens one (#77): as its note inside the open library, on
/// its own anywhere else. A folder is offered for import into the library,
/// or, with no library open, opens as one. Anything else — a PDF, a
/// picture — is attached to the note on screen (#1250), or, with no note
/// to take it, named and left alone.
///
/// While something is dragged over the window a frame and a line say what
/// a drop would do. The desktops do not tell the app what is being
/// dragged until it lands, so the frame cannot tell a Markdown file from
/// anything else; what cannot be opened is said after the drop.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:niman/src/core/drop_in.dart';
import 'package:niman/src/core/launch_requests.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/editor_only.dart';
import 'package:niman/src/import/html/html_file.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What a drop holds, sorted by what each can become: the Markdown to open,
/// the folders, Notion exports and books to import, the web pages to ask
/// about (#1293), and what is left over.
typedef SortedDrop = ({
  List<String> files,
  List<String> folders,
  List<String> pages,
  List<String> rejected,
});

/// Which of the dropped paths are folders, asked on a background isolate
/// together: one stat apiece, which the UI isolate does not make (#1143).
///
/// A widget test swaps it for the same check made in place: its fake clock
/// does not drive an isolate's answer, and a test that waits for one waits
/// on a guess.
@visibleForTesting
Future<Set<String>> Function(List<String> paths) foldersAmong = _foldersAmong;

Future<Set<String>> _foldersAmong(List<String> paths) => Isolate.run(
  () => {
    for (final path in paths)
      if (FileSystemEntity.isDirectorySync(path)) path,
  },
);

/// Sorts the dropped [paths]: Markdown files to open, folders and Notion
/// exports to import, web pages to ask about, and the rest, which is
/// attached to the note on screen or left alone. [isFolder] answers
/// for the disk: [foldersAmong] asks it off the UI isolate.
SortedDrop sortDrop(
  List<String> paths, {
  required bool Function(String path) isFolder,
}) {
  final files = <String>[];
  final folders = <String>[];
  final pages = <String>[];
  final rejected = <String>[];
  for (final path in paths) {
    final extension = p.extension(path).toLowerCase().replaceFirst('.', '');
    if (isFolder(path)) {
      folders.add(path);
    } else if (editorOnlyExtensions.contains(extension)) {
      files.add(path);
    } else if (extension == 'zip' || extension == 'epub') {
      // A Notion export, offered for import (#25), or a book, offered for
      // conversion into notes (#1138): the shell decides by the extension
      // what the archive is.
      folders.add(path);
    } else if (isHtmlFile(path)) {
      // Converted into a note, attached to the note on screen, or both: the
      // shell asks (#1293).
      pages.add(path);
    } else {
      rejected.add(path);
    }
  }
  return (files: files, folders: folders, pages: pages, rejected: rejected);
}

/// Hands a sorted drop to [requests]: the web pages are offered to be
/// converted (#1293), and what nothing opens goes to the note on screen as
/// attachments (#1250), and is named through [messenger] when there is no
/// note to take it. A page nobody is there to ask about is such a file.
Future<void> deliverDrop(
  SortedDrop drop,
  LaunchRequests requests,
  ScaffoldMessengerState? messenger,
) async {
  drop.files.forEach(requests.openFile);
  drop.folders.forEach(requests.openFolder);
  // The pages are asked about last, the question being a dialog the rest
  // would wait behind; with nobody to ask, they go the way the rest does.
  final asked = drop.pages.isNotEmpty && requests.pageHandler != null;
  await _attachOrName(
    [...drop.rejected, if (!asked) ...drop.pages],
    requests,
    messenger,
  );
  if (asked && !await requests.offerPages(drop.pages)) {
    await _attachOrName(drop.pages, requests, messenger);
  }
}

/// Attaches [paths] to the note on screen, or names them when there is none.
Future<void> _attachOrName(
  List<String> paths,
  LaunchRequests requests,
  ScaffoldMessengerState? messenger,
) async {
  if (paths.isEmpty || await requests.attachFiles(paths)) return;
  messenger?.showSnackBar(
    SnackBar(
      content: Text(AppStrings.dropRejected(paths.map(p.basename).join(', '))),
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
        unawaited(_sort(paths, messenger));
    }
  }

  Future<void> _sort(
    List<String> paths,
    ScaffoldMessengerState? messenger,
  ) async {
    final folders = await foldersAmong(paths);
    if (!mounted) return;
    final sorted = sortDrop(paths, isFolder: folders.contains);
    _log.debug(
      'drop sorted: ${sorted.files.length} file(s), '
      '${sorted.folders.length} folder(s), '
      '${sorted.rejected.length} left alone',
    );
    await deliverDrop(sorted, widget.requests, messenger);
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
