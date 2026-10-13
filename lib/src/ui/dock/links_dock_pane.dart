import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/files.dart' show pathInLibrary;
import 'package:niman/src/links/mention_reader.dart';
import 'package:niman/src/ui/links_to_note_controller.dart';
import 'package:niman/src/ui/links_to_note_list.dart';
import 'package:niman/src/ui/note_view_handle.dart';

/// The dock's "Links to this note" (#842), and the phone's sheet of the same:
/// the notes that link to the note shown beside, each with the line it says
/// the link on. A tap opens the note that holds the link.
final class LinksDockPane extends StatefulWidget {
  /// The notes that link to [note], looked up in [links] for the library
  /// rooted at [libraryRoot].
  const new({
    required this.note,
    required this.links,
    required this.libraryRoot,
    required this.onOpenNote,
    super.key,
  });

  /// The note shown beside; null when none is open.
  final NoteViewHandle? note;

  /// Where the links are looked up: the open library's.
  final Future<MentionSource?> links;

  /// The library's root, which the note's path is read against.
  final String? libraryRoot;

  /// Opens one of the notes that link here, by its library-relative path.
  final ValueChanged<String> onOpenNote;

  @override
  State<LinksDockPane> createState() => _LinksDockPaneState();
}

final class _LinksDockPaneState extends State<LinksDockPane> {
  final LinksToNoteController _controller = LinksToNoteController();
  MentionSource? _source;

  @override
  void initState() {
    super.initState();
    unawaited(_resolve());
    _aim();
  }

  Future<void> _resolve() async {
    final source = await widget.links;
    if (!mounted) return;
    _source = source;
    _aim();
  }

  @override
  void didUpdateWidget(LinksDockPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    _aim();
  }

  /// Points the list at the note beside, in the library's own terms.
  void _aim() {
    final note = widget.note;
    _controller.target(
      _source,
      note == null ? null : pathInLibrary(widget.libraryRoot, note.notePath),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.note == null) return const SizedBox.shrink();
    return LinksToNoteList(
      controller: _controller,
      onOpenNote: widget.onOpenNote,
    );
  }
}
