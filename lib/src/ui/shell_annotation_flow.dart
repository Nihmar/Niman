/// Annotating a PDF or a book from its pane (#284), without leaving it.
///
/// The pane says what is annotated — the place, and the passage when there
/// is one; this asks for the comment over the file ([showAnnotationSheet]),
/// writes it into the file's companion note ([CompanionNotes]), and says so,
/// offering the note. The reader stays where they were: opening the note is
/// a step of its own.
///
/// Every open note is saved first, and the one on screen re-read after:
/// the companion may be open in another pane, and its editor would write
/// its own copy back over the annotation.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/companion_notes.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/annotation_sheet.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// The shell's side of annotating a file.
final class ShellAnnotationFlow {
  /// Annotates the files of [controller]'s library.
  const new({
    required this.controller,
    required this.unsaved,
    required this.linkType,
    required this.onWritten,
    required this.onOpen,
  });

  /// The open library.
  final LibrarySession controller;

  /// The open notes, saved before the companion is written.
  final UnsavedTracker unsaved;

  /// How the library writes links.
  final LinkType Function() linkType;

  /// A companion was written: the note on screen may be it.
  final VoidCallback onWritten;

  /// Opens a note, the caret at an offset of its text.
  final void Function(String path, int offset) onOpen;

  static const AppLogger _log = AppLogger(name: 'annotations');

  /// Asks for the comment on [annotation], and writes it.
  Future<void> annotate(BuildContext context, Annotation annotation) async {
    final comment = await showAnnotationSheet(
      context,
      label: annotation.label,
      quote: annotation.quote,
    );
    if (comment == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ops = controller.ops;
      final fields = await controller.fieldSource;
      final links = await controller.linkSource;
      if (ops == null || fields == null || links == null) {
        throw StateError('no library is open');
      }
      await unsaved.saveAll();
      final written =
          await CompanionNotes(fields: fields, links: links, ops: ops).write(
            annotation.withComment(comment),
            folder: await ops.annotationsFolder,
            suffix: AppStrings.annotationNoteSuffix,
            linkType: linkType(),
          );
      _log.info('annotated ${annotation.path} in ${written.path}');
      onWritten();
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppStrings.annotationSaved),
          action: SnackBarAction(
            label: AppStrings.annotationOpenNote,
            onPressed: () => onOpen(written.path, written.offset),
          ),
        ),
      );
    } on Object catch (error) {
      _log.warning('could not annotate ${annotation.path}: $error');
      messenger.showSnackBar(
        SnackBar(content: Text(AppStrings.annotationFailed)),
      );
    }
  }
}
