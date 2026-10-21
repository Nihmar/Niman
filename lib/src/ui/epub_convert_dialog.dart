/// The one question a book's conversion to notes asks (#1138): how — a
/// note a chapter, or one note — and into which folder.
///
/// The book is read first (`previewEpub`, on an isolate), so the dialog
/// says what each choice makes — how many notes, in how many folders —
/// and a book that cannot be converted says why before anything is asked.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/epub/epub_archive.dart';
import 'package:niman/src/epub/epub_conversion.dart';
import 'package:niman/src/epub/epub_convert_job.dart';
import 'package:niman/src/epub/epub_convert_plan.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What the dialog answers: one note or a note a chapter, and the folder
/// the book goes in, library-relative ('' for the top).
typedef EpubConvertChoice = ({bool oneNote, String parent});

/// Reads what the book at a path would make: [previewEpubOnIsolate], or a
/// test's own.
typedef EpubPreviewer = Future<EpubConvertPreview> Function(
  String source,
  EpubConvertWords words,
);

/// The words a conversion writes, in the interface's language.
EpubConvertWords epubConvertWords() => (
  chapter: AppStrings.epubConvertChapterName,
  opening: AppStrings.epubConvertOpening,
  contents: AppStrings.epubConvertContents,
);

/// Asks how to convert the book at [source] and where to; null when the
/// dialog is dismissed or the book cannot be converted.
///
/// [pickFolder] asks for another folder, from the one chosen; null keeps
/// the folder [parent] as it is.
Future<EpubConvertChoice?> showEpubConvertDialog(
  BuildContext context, {
  required String source,
  required String parent,
  Future<String?> Function(String current)? pickFolder,
  EpubPreviewer preview = previewEpubOnIsolate,
}) => showDialog<EpubConvertChoice>(
  context: context,
  builder: (context) => EpubConvertDialog(
    source: source,
    parent: parent,
    pickFolder: pickFolder,
    preview: preview,
  ),
);

/// The dialog itself.
final class EpubConvertDialog extends StatefulWidget {
  /// Asks about the book at [source], going into [parent] to start with.
  const new({
    required this.source,
    required this.parent,
    required this.preview,
    this.pickFolder,
    super.key,
  });

  /// The book, absolute.
  final String source;

  /// The folder it goes in to start with.
  final String parent;

  /// What reads the book.
  final EpubPreviewer preview;

  /// Asks for another folder; null offers none.
  final Future<String?> Function(String current)? pickFolder;

  @override
  State<EpubConvertDialog> createState() => _EpubConvertDialogState();
}

final class _EpubConvertDialogState extends State<EpubConvertDialog> {
  EpubConvertPreview? _preview;
  String? _problem;
  bool? _oneNote;
  late String _parent = widget.parent;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  Future<void> _read() async {
    try {
      final preview = await widget.preview(widget.source, epubConvertWords());
      if (!mounted) return;
      setState(() => _preview = preview);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _problem = epubConvertProblem(error, widget.source));
    }
  }

  Future<void> _pick() async {
    final picked = await widget.pickFolder?.call(_parent);
    if (picked == null || !mounted) return;
    setState(() => _parent = picked);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final problem = _problem;
    // A book of one chapter is one note either way: it starts there.
    final oneNote = _oneNote ?? (preview != null && preview.notes <= 1);
    return AlertDialog(
      key: const Key('epub-convert-dialog'),
      title: Text(AppStrings.epubConvertTitle),
      scrollable: true,
      content: problem != null
          ? Text(problem, key: const Key('epub-convert-problem'))
          : preview == null
          ? Row(
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(AppStrings.epubConvertReading)),
              ],
            )
          : _choices(context, preview, oneNote),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        if (problem == null)
          FilledButton(
            key: const Key('epub-convert-start'),
            onPressed: preview == null
                ? null
                : () =>
                      Navigator.of(context)
                          .pop((oneNote: oneNote, parent: _parent)),
            child: Text(AppStrings.epubConvertStart),
          ),
      ],
    );
  }

  Widget _choices(
    BuildContext context,
    EpubConvertPreview preview,
    bool oneNote,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(preview.title, style: theme.textTheme.titleMedium),
        if (preview.authors.isNotEmpty)
          Text(preview.authors.join(', '), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        RadioGroup<bool>(
          groupValue: oneNote,
          onChanged: (value) => setState(() => _oneNote = value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                key: const Key('epub-convert-per-chapter'),
                value: false,
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.epubConvertPerChapter),
                subtitle: Text(
                  AppStrings.epubConvertPerChapterDetail(
                    preview.notes,
                    preview.folders,
                  ),
                ),
              ),
              RadioListTile<bool>(
                key: const Key('epub-convert-one-note'),
                value: true,
                contentPadding: EdgeInsets.zero,
                title: Text(AppStrings.epubConvertOneNote),
                subtitle: Text(AppStrings.epubConvertOneNoteDetail),
              ),
            ],
          ),
        ),
        ListTile(
          key: const Key('epub-convert-folder'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: Text(AppStrings.epubConvertInto),
          subtitle: Text(_parent.isEmpty ? AppStrings.libraryRoot : _parent),
          trailing: widget.pickFolder == null
              ? null
              : const Icon(Icons.chevron_right),
          onTap: widget.pickFolder == null ? null : _pick,
        ),
      ],
    );
  }
}

/// What to tell the user about [error], a conversion of the book at
/// [source] that did not happen.
String epubConvertProblem(Object error, String source) => switch (error) {
  EpubRefused(reason: EpubRefusal.protected) => AppStrings.epubConvertProtected,
  EpubRefused(reason: EpubRefusal.tooLarge) => AppStrings.epubConvertTooLarge,
  EpubRefused() => AppStrings.epubConvertNotABook(p.basename(source)),
  _ => AppStrings.epubConvertFailed,
};
