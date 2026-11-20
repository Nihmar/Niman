/// The question a web page's conversion into a note asks (#1293, #1294):
/// which folder it goes in — and, for a page that is a book, how it is cut.
///
/// A single page is read first, on an isolate (`previewHtmlOnIsolate`: the
/// UI isolate does no disk work), to tell whether it is a book. A page that
/// is one is offered **One note per chapter** — the default, as the
/// chapters found are what it is for — or **One note**, as an EPUB is
/// (`epub_convert_dialog.dart`); one that is not asks only where it goes.
/// A drop of several pages asks only where, and converts each as a page.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/import/book/book_plan.dart';
import 'package:niman/src/import/html/html_conversion.dart';
import 'package:niman/src/ui/convert_words.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// What the dialog answers: the folder the pages go in, library-relative
/// ('' for the top), and — when the page is a book — how it is cut; null
/// for a page converted as one note, an article of it.
typedef HtmlConvertChoice = ({String parent, HtmlBookSplit? book});

/// Reads what the page at a path would make if it is a book:
/// [previewHtmlOnIsolate], or a test's own. Null when it is not one.
typedef HtmlPreviewer = Future<HtmlBookPreview?> Function(
  String source,
  BookWords words, {
  String? name,
});

/// Asks where to convert the pages at [sources] to; null when the dialog is
/// dismissed. [name] is what the page is called when its file is not (a
/// share's copy in the cache); it is given for a single page only.
///
/// [pickFolder] asks for another folder, from the one chosen; null keeps
/// the folder [parent] as it is.
Future<HtmlConvertChoice?> showHtmlConvertDialog(
  BuildContext context, {
  required List<String> sources,
  required String parent,
  String? name,
  Future<String?> Function(String current)? pickFolder,
  HtmlPreviewer preview = previewHtmlOnIsolate,
}) => showDialog<HtmlConvertChoice>(
  context: context,
  builder: (context) => HtmlConvertDialog(
    sources: sources,
    name: name,
    parent: parent,
    pickFolder: pickFolder,
    preview: preview,
  ),
);

/// The dialog itself.
final class HtmlConvertDialog extends StatefulWidget {
  /// Asks about the pages at [sources], going into [parent] to start with.
  const new({
    required this.sources,
    required this.parent,
    this.name,
    this.pickFolder,
    this.preview = previewHtmlOnIsolate,
    super.key,
  });

  /// The pages, absolute paths.
  final List<String> sources;

  /// What a single page is called when its file is not; see
  /// [showHtmlConvertDialog].
  final String? name;

  /// The folder they go in to start with.
  final String parent;

  /// Asks for another folder; null offers none.
  final Future<String?> Function(String current)? pickFolder;

  /// What reads a single page, to tell whether it is a book.
  final HtmlPreviewer preview;

  @override
  State<HtmlConvertDialog> createState() => _HtmlConvertDialogState();
}

final class _HtmlConvertDialogState extends State<HtmlConvertDialog> {
  late String _parent = widget.parent;

  /// Whether the single page has been read yet.
  late bool _read = widget.sources.length > 1;
  HtmlBookPreview? _book;
  bool? _oneNote;

  @override
  void initState() {
    super.initState();
    if (!_read) unawaited(_readPage());
  }

  Future<void> _readPage() async {
    HtmlBookPreview? book;
    try {
      book = await widget.preview(
        widget.sources.single,
        convertWords(),
        name: widget.name,
      );
    } on Object {
      // A page that cannot be read is no book: the conversion says why.
    }
    if (!mounted) return;
    setState(() {
      _book = book;
      _read = true;
    });
  }

  Future<void> _pick() async {
    final picked = await widget.pickFolder?.call(_parent);
    if (picked == null || !mounted) return;
    setState(() => _parent = picked);
  }

  HtmlBookSplit? get _split {
    final book = _book;
    if (book == null) return null;
    // A book of one chapter is one note either way: it starts there.
    final oneNote = _oneNote ?? book.notes <= 1;
    return oneNote ? HtmlBookSplit.oneNote : HtmlBookSplit.chapters;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final many = widget.sources.length > 1;
    final book = _book;
    return AlertDialog(
      key: const Key('html-convert-dialog'),
      title: Text(AppStrings.convertTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (many) ...[
            Text(
              AppStrings.htmlConvertMany(widget.sources.length),
              style: theme.textTheme.titleMedium,
            ),
            for (final source in widget.sources)
              Text(
                p.basename(source),
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ] else
            Text(
              htmlDisplayName(widget.sources.single, widget.name),
              key: const Key('html-convert-name'),
              style: theme.textTheme.titleMedium,
            ),
          if (book != null) ..._bookChoices(theme, book),
          const SizedBox(height: 12),
          if (!_read)
            Row(
              key: const Key('html-convert-reading'),
              children: [
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Expanded(child: Text(AppStrings.htmlConvertReading)),
              ],
            ),
          ListTile(
            key: const Key('html-convert-folder'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_outlined),
            title: Text(AppStrings.convertInto),
            subtitle: Text(_parent.isEmpty ? AppStrings.libraryRoot : _parent),
            trailing: widget.pickFolder == null
                ? null
                : const Icon(Icons.chevron_right),
            onTap: widget.pickFolder == null ? null : _pick,
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('html-convert-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('html-convert-start'),
          onPressed: !_read
              ? null
              : () =>
                    Navigator.of(context).pop((parent: _parent, book: _split)),
          child: Text(AppStrings.convertStart),
        ),
      ],
    );
  }

  /// What the page is as a book, and how to cut it.
  List<Widget> _bookChoices(ThemeData theme, HtmlBookPreview book) => [
    Text(
      book.title,
      key: const Key('html-convert-book-title'),
      style: theme.textTheme.titleSmall,
    ),
    if (book.authors.isNotEmpty)
      Text(book.authors.join(', '), style: theme.textTheme.bodyMedium),
    const SizedBox(height: 12),
    RadioGroup<bool>(
      groupValue: _split == HtmlBookSplit.oneNote,
      onChanged: (value) => setState(() => _oneNote = value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<bool>(
            key: const Key('html-convert-per-chapter'),
            value: false,
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.convertPerChapter),
            subtitle: Text(
              AppStrings.convertPerChapterDetail(book.notes, book.folders),
            ),
          ),
          RadioListTile<bool>(
            key: const Key('html-convert-one-note'),
            value: true,
            contentPadding: EdgeInsets.zero,
            title: Text(AppStrings.convertOneNote),
            subtitle: Text(AppStrings.convertOneNoteDetail),
          ),
        ],
      ),
    ),
  ];
}

/// What to tell the user about [error], a conversion of the page at
/// [source] that did not happen, called [name] when its file is not.
String htmlConvertProblem(Object error, String source, {String? name}) =>
    switch (error) {
      HtmlRefused(reason: HtmlRefusal.tooLarge) =>
        AppStrings.htmlConvertTooLarge,
      HtmlRefused(reason: HtmlRefusal.unsupportedCharset) =>
        AppStrings.htmlConvertCharset,
      HtmlRefused() => AppStrings.htmlConvertUnreadable(
        htmlDisplayName(source, name),
      ),
      _ => AppStrings.htmlConvertFailed,
    };
