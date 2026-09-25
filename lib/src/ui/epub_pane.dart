/// An EPUB, read in the note pane (#280).
///
/// The book is read into Markdown off the UI isolate ([openEpub]) and drawn
/// by the note's own read view, in the note column, with a look of its own:
/// the library's theme, brightness, face and text size for its books
/// ([EpubLooks]), set from the Aa button on the row below. Its pictures
/// come from the app's cache, its own links jump within it, and its table
/// of contents is a button on that row too. It opens where it was left
/// ([ReadingPositions]), or where the link it was opened by points
/// ([BookLocation.fromFragment]).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/epub/epub_document.dart';
import 'package:niman/src/epub/epub_looks.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/reading/book_location.dart';
import 'package:niman/src/reading/reading_positions.dart';
import 'package:niman/src/reading/reading_tracker.dart';
import 'package:niman/src/ui/attachment_unreadable.dart';
import 'package:niman/src/ui/epub_bar.dart';
import 'package:niman/src/ui/epub_contents_sheet.dart';
import 'package:niman/src/ui/epub_theme.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/place_link_button.dart';
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
    this.positions,
    this.anchor,
    this.reloadToken = 0,
    this.linkType = LinkType.wikilink,
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

  /// Where the library keeps its reading positions; null keeps none, and
  /// the book opens at its start.
  final ReadingPositions? positions;

  /// The fragment of the link the book was opened by (#282), naming a place
  /// in it: `chapter=OEBPS/ch5.xhtml&line=12`. It wins over where the book
  /// was left.
  final String? anchor;

  /// Bumped when the same link is followed again, so the book goes back to
  /// its place.
  final int reloadToken;

  /// How the library writes links, for the one to the place being read.
  final LinkType linkType;

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

  late ReadingTracker _reading;

  /// The link's fragment last gone to: handed again as a tab comes back,
  /// it does not move the reader.
  String? _anchorTaken;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_open());
  }

  @override
  void didUpdateWidget(EpubPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path == widget.path) {
      final anchor = widget.anchor;
      final document = _document;
      final again =
          anchor != _anchorTaken || widget.reloadToken != oldWidget.reloadToken;
      if (anchor == null || !again || document == null) return;
      // Still being read, the book takes the link when it opens.
      _anchorTaken = anchor;
      final place = _linked();
      if (place == null) return;
      _reading.flush();
      if (_show(document, place)) _reading.placed(place);
      return;
    }
    _reading.flush();
    // The build that follows shows the spinner until the new book is read.
    _document = null;
    _buffer = null;
    _failed = false;
    unawaited(_open());
  }

  @override
  void dispose() {
    _reading.flush();
    _scroll.dispose();
    _mathCache.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final open = ++_opens;
    final reading = _reading = ReadingTracker(widget.positions, widget.path);
    try {
      final left = reading.read();
      final document = await openEpub(widget.path, await widget.cacheDir());
      final saved = switch (await left) {
        final EpubLocation location => location,
        _ => null,
      };
      if (!mounted || open != _opens) return;
      setState(() {
        _document = document;
        _buffer = SourceBuffer.fromText(document.markdown);
      });
      // Once the view is there to be scrolled: the link's place, else
      // where the book was left, else its start.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || open != _opens) return;
        _anchorTaken = widget.anchor;
        final place = [_linked(), saved].firstWhere(
          (place) => place != null && _show(document, place),
          orElse: () => null,
        );
        reading.placed(place);
      });
    } on Object catch (error) {
      _log.warning('could not read ${widget.path}: $error');
      if (!mounted || open != _opens) return;
      setState(() => _failed = true);
    }
  }

  /// The place the link's fragment names, when it names one in a book.
  EpubLocation? _linked() =>
      switch (BookLocation.fromFragment(widget.anchor ?? '')) {
        final EpubLocation place => place,
        _ => null,
      };

  /// Scrolls to [place], if [document] has it.
  bool _show(EpubDocument document, EpubLocation place) {
    final line = document.lineOfLocation(place);
    if (line == null) return false;
    _readKey.currentState?.showAnchor((line: line, fraction: place.fraction));
    return true;
  }

  void _onScroll() {
    final anchor = _readKey.currentState?.topAnchor;
    final here = anchor == null
        ? null
        : _document?.locationAt(anchor.line, anchor.fraction);
    if (here != null) _reading.moved(here);
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
    final top = _readKey.currentState?.topAnchor?.line ?? 0;
    final line = await showEpubContents(context, document, top);
    if (line != null) _readKey.currentState?.jumpToLine(line);
  }

  /// The place being read, for a link to it: the line at the top of the
  /// view, or the next one when the view is mostly past it.
  PlaceToLink? _here() {
    final document = _document;
    final path = widget.positions?.keyOf(widget.path);
    final anchor = _readKey.currentState?.topAnchor;
    if (document == null || path == null || anchor == null) return null;
    final line = anchor.line + (anchor.fraction > 0.5 ? 1 : 0);
    final place = document.locationAt(line, 0);
    if (place == null) return null;
    final name = p.basenameWithoutExtension(widget.path);
    final entry = document.entryAt(line);
    return (
      path: path,
      place: place,
      label: entry == -1 ? name : '$name, ${document.contents[entry].title}',
    );
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
                ? const AttachmentUnreadable()
                : document == null || buffer == null
                ? const Center(child: CircularProgressIndicator())
                : _book(context, document, buffer),
          ),
          EpubBar(
            path: widget.path,
            launcher: widget.launcher,
            linkType: widget.linkType,
            onEditLook: widget.onEditLook,
            onContents: document == null || document.contents.isEmpty
                ? null
                : () => unawaited(_showContents()),
            here: document == null || widget.positions == null ? null : _here,
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
}
