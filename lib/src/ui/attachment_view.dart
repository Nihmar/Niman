/// An attachment, shown in the note pane rather than handed to another
/// application: a picture, zoomed and panned, or a PDF, page by page.
///
/// The tree lists every file of a library, and a picture or a PDF picked
/// there opened as a note that is not text — a message, and on a desktop a
/// button to the system's application, with nothing at all on a phone. The
/// common ones are shown here instead, on every platform; the rest still
/// get the message and the button.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

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
/// ([pictureExtensions]) or a PDF.
bool isShownAttachment(String path) {
  final extension = p.extension(path).toLowerCase();
  return extension == '.pdf' || pictureExtensions.contains(extension);
}

/// The attachment at [path], an absolute path, in the note pane.
final class AttachmentView extends StatelessWidget {
  /// Shows the file at [path].
  const new({
    required this.path,
    this.launcher = const OsLauncher(),
    super.key,
  });

  /// The attachment's absolute path.
  final String path;

  /// The OS seam behind the button to the system's application.
  final OsLauncher launcher;

  bool get _isPdf => p.extension(path).toLowerCase() == '.pdf';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          Expanded(child: _isPdf ? _pdf(context) : _picture(context)),
          _AttachmentBar(path: path, launcher: launcher),
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
        errorBuilder: (context, error, stack) => _unreadable(context),
      ),
    ),
  );

  /// A PDF, its pages one under the other, zoomed with a pinch or
  /// Ctrl+wheel.
  Widget _pdf(BuildContext context) => PdfViewer.file(
    path,
    key: const Key('attachment-pdf'),
    params: PdfViewerParams(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      errorBannerBuilder: (context, error, stack, documentRef) =>
          _unreadable(context),
    ),
  );

  Widget _unreadable(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        AppStrings.attachmentUnreadable,
        key: const Key('attachment-unreadable'),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

/// The row under an attachment: its name, and where the platform has one,
/// the way to the system's own application for it.
final class _AttachmentBar extends StatelessWidget {
  const new({required this.path, required this.launcher});

  final String path;

  final OsLauncher launcher;

  Future<void> _openOutside(BuildContext context) async {
    final outcome = await runTreeContextAction(
      path,
      TreeContextAction.openInDefaultApp,
      launcher: launcher,
    );
    if (!context.mounted || outcome == TreeContextOutcome.opened) return;
    final text = outcome == TreeContextOutcome.missing
        ? AppStrings.attachmentMissing
        : AppStrings.attachmentOpenFailed;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                p.basename(path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (supportsTreeContextActions)
              IconButton(
                key: const Key('attachment-open-outside'),
                tooltip: AppStrings.openInDefaultApp,
                icon: const Icon(Icons.open_in_new),
                visualDensity: VisualDensity.compact,
                onPressed: () => unawaited(_openOutside(context)),
              ),
          ],
        ),
      ),
    );
  }
}
