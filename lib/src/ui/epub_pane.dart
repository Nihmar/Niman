/// An EPUB, read in the note pane (#280).
///
/// The book is read into Markdown off the UI isolate ([openEpub]) and drawn
/// by the note's own read view, in the note column, with a look of its own:
/// the library's theme, brightness, face and text size for its books
/// ([EpubLooks]), set from the Aa button on the row below. Its pictures
/// come from the app's cache, its own links jump within it, and its table
/// of contents is a button on that row too.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/attachment_bar.dart';
import 'package:niman/src/ui/epub_theme.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// The folder of the app's cache the books' pictures go under.
Future<String> _epubCacheDir() async =>
    p.join((await getApplicationCacheDirectory()).path, 'epub');

/// The EPUB at [path], an absolute path, read in the note pane.
final class EpubPane extends StatefulWidget {
  /// Reads the book at [path].
  const new({
    required this.path,
    this.launcher = const OsLauncher(),
    this.column = NoteColumn.off,
    this.cacheDir = _epubCacheDir,
    this.onEditLook,
    super.key,
  });

  /// The book's absolute path.
  final String path;

  /// The OS seam behind the button to the system's application.
  final OsLauncher launcher;

  /// The shell's note column, which the book is set in like a note.
  final NoteColumn column;

  /// Where the books' pictures are extracted: the app's cache, or a test's
  /// own folder.
  final Future<String> Function() cacheDir;

  /// Opens the sheet that sets how the books look; null leaves its button
  /// on the row, disabled.
  final VoidCallback? onEditLook;

  @override
  State<EpubPane> createState() => EpubPaneState();
}

/// The pane's state, so a test can ask what it shows.
final class EpubPaneState extends State<EpubPane> {
  static const AppLogger _log = AppLogger(name: 'epub');

  final GlobalKey<MarkdownReadViewState> _readKey =
      GlobalKey<MarkdownReadViewState>();
  final ScrollController _scroll = ScrollController();
  final BlockParser _parser = BlockParser();
  final MathCache _mathCache = MathCache();

  /// The book, once read.
  EpubDocument? get document => _document;
  EpubDocument? _document;
  SourceBuffer? _buffer;

  /// Whether the book could not be read.
  bool get failed => _failed;
  bool _failed = false;

  /// Counts the opens, so a book replaced while it was read is dropped.
  int _opens = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  @override
  void didUpdateWidget(EpubPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path == widget.path) return;
    // The build that follows shows the spinner until the new book is read.
    _document = null;
    _buffer = null;
    _failed = false;
    unawaited(_open());
  }

  @override
  void dispose() {
    _scroll.dispose();
    _mathCache.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final open = ++_opens;
    try {
      final document = await openEpub(widget.path, await widget.cacheDir());
      if (!mounted || open != _opens) return;
      setState(() {
        _document = document;
        _buffer = SourceBuffer.fromText(document.markdown);
      });
    } on Object catch (error) {
      _log.warning('could not read ${widget.path}: $error');
      if (!mounted || open != _opens) return;
      setState(() => _failed = true);
    }
  }

  void _onTapLink(String text, String? href) {
    if (href == null || href.isEmpty) return;
    if (href.startsWith('${EpubDocument.linkScheme}:')) {
      final line = _document?.lineOfLink(href);
      if (line != null) _readKey.currentState?.jumpToLine(line);
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri == null || !uri.hasScheme) return;
    unawaited(_launch(uri));
  }

  Future<void> _launch(Uri uri) async {
    var launched = false;
    try {
      launched = await launchUrl(uri);
    } on Object {
      launched = false;
    }
    if (launched || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(AppStrings.openLinkFailed)));
  }

  Future<void> _showContents() async {
    final document = _document;
    if (document == null) return;
    // The chapter being read: the last entry opening at or above the top.
    final top = _readKey.currentState?.topAnchor?.line ?? 0;
    final current = document.contents.lastIndexWhere(
      (entry) => entry.line <= top,
    );
    final line = await showActionSheet<int>(
      context,
      sheetKey: const Key('epub-contents'),
      title: AppStrings.outlineTooltip,
      items: (context) => [
        for (final (index, entry) in document.contents.indexed)
          ListTile(
            key: Key('epub-contents-$index'),
            dense: true,
            selected: index == current,
            contentPadding: EdgeInsetsDirectional.only(
              start: 16 + 16.0 * entry.depth,
              end: 16,
            ),
            title: Text(
              entry.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => Navigator.of(context).pop(entry.line),
          ),
      ],
    );
    if (line != null) _readKey.currentState?.jumpToLine(line);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: EpubLooks.revision,
    // The whole pane wears the book's look, its row included.
    builder: (context, _) => Theme(
      data: epubThemeOf(context),
      child: Builder(builder: _pane),
    ),
  );

  Widget _pane(BuildContext context) {
    final document = _document;
    final buffer = _buffer;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: _failed
                ? _unreadable()
                : document == null || buffer == null
                ? const Center(child: CircularProgressIndicator())
                : _book(context, document, buffer),
          ),
          AttachmentBar(
            path: widget.path,
            launcher: widget.launcher,
            actions: [
              IconButton(
                key: const Key('epub-look-button'),
                tooltip: AppStrings.epubLookTitle,
                icon: const Icon(Icons.format_size),
                visualDensity: VisualDensity.compact,
                onPressed: widget.onEditLook,
              ),
              // Kept on the row while the book is read, and when it has no
              // contents, so the row does not move under a thumb.
              IconButton(
                key: const Key('epub-contents-button'),
                tooltip: AppStrings.outlineTooltip,
                icon: const Icon(Icons.toc),
                visualDensity: VisualDensity.compact,
                onPressed: document == null || document.contents.isEmpty
                    ? null
                    : () => unawaited(_showContents()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The book, at the books' text size rather than the interface one, as
  /// a note's read view is at the note's.
  Widget _book(
    BuildContext context,
    EpubDocument document,
    SourceBuffer buffer,
  ) => MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(textScaler: epubTextScalerOf(context)),
    child: MarkdownReadView(
      key: _readKey,
      buffer: buffer,
      parser: _parser,
      mathCache: _mathCache,
      controller: _scroll,
      column: widget.column,
      onTapLink: _onTapLink,
      embedResolver: (target) async => document.pictures[target],
    ),
  );

  Widget _unreadable() => Center(
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
