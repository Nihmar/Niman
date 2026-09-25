/// An attachment, shown in the note pane rather than handed to another
/// application: a picture, zoomed and panned, a PDF, page by page, or an
/// EPUB, read like a note ([EpubPane]).
///
/// The tree lists every file of a library, and a picture, a PDF or a book
/// picked there opened as a note that is not text — a message, and on a
/// desktop a button to the system's application, with nothing at all on a
/// phone. The common ones are shown here instead, on every platform; the
/// rest still get the message and the button.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/ui/attachment_bar.dart';
import 'package:niman/src/ui/attachment_unreadable.dart';
import 'package:niman/src/ui/epub_pane.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/pdf_document_view.dart';
import 'package:path/path.dart' as p;

/// The picture files the pane shows itself: the ones Flutter decodes on
/// every platform.
const Set<String> pictureExtensions = {
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.webp',
  '.bmp',
};

/// Whether the file at [path] is an attachment the pane shows: a picture
/// ([pictureExtensions]), a PDF or an EPUB.
bool isShownAttachment(String path) {
  final extension = p.extension(path).toLowerCase();
  return extension == '.pdf' ||
      extension == '.epub' ||
      pictureExtensions.contains(extension);
}

/// The attachment at [path], an absolute path, in the note pane.
final class AttachmentView extends StatelessWidget {
  /// Shows the file at [path].
  const new({
    required this.path,
    this.launcher = const OsLauncher(),
    this.column = NoteColumn.off,
    this.onEditEpubLook,
    this.positions,
    this.anchor,
    this.reloadToken = 0,
    this.linkType = LinkType.wikilink,
    super.key,
  });

  /// The attachment's absolute path.
  final String path;

  /// The OS seam behind the button to the system's application.
  final OsLauncher launcher;

  /// The shell's note column: a book is set in it like a note.
  final NoteColumn column;

  /// Opens the sheet that sets how the books look ([EpubPane.onEditLook]).
  final VoidCallback? onEditEpubLook;

  /// Where the library keeps where each book and PDF was left; null keeps
  /// none.
  final ReadingPositions? positions;

  /// The fragment of the link the file was opened by: a place in a book or
  /// a PDF (#282), which it opens at.
  final String? anchor;

  /// Bumped when the same link is followed again.
  final int reloadToken;

  /// How the library writes links, for the one to the place being read in
  /// a book or a PDF.
  final LinkType linkType;

  bool get _isPdf => p.extension(path).toLowerCase() == '.pdf';

  bool get _isEpub => p.extension(path).toLowerCase() == '.epub';

  @override
  Widget build(BuildContext context) {
    // A book reads on the note's own ground, and brings its own row.
    if (_isEpub) {
      return EpubPane(
        path: path,
        launcher: launcher,
        column: column,
        onEditLook: onEditEpubLook,
        positions: positions,
        anchor: anchor,
        reloadToken: reloadToken,
        linkType: linkType,
      );
    }
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLowest,
      // A PDF brings its own row, with the link to its page.
      child: _isPdf
          ? PdfDocumentView(
              path: path,
              launcher: launcher,
              linkType: linkType,
              positions: positions,
              anchor: anchor,
              reloadToken: reloadToken,
            )
          : Column(
              children: [
                Expanded(child: _picture(context)),
                AttachmentBar(path: path, launcher: launcher),
              ],
            ),
    );
  }

  /// A picture at the size the pane allows, a pinch or a wheel away from
  /// its pixels.
  Widget _picture(BuildContext context) => InteractiveViewer(
    key: const Key('attachment-picture'),
    minScale: 0.5,
    maxScale: 16,
    child: Center(
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stack) => const AttachmentUnreadable(),
      ),
    ),
  );
}
