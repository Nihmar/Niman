/// The phone's capture sheet (#531): what a page shared from the browser
/// opens — "Save to Niman" — and New ▸ Capture web page too, with the
/// address to type. The page is read as soon as it is known, so the sheet
/// can say how many pictures it has; Save hands the reading to the
/// background capture and the sheet closes at once, the page still being
/// read if it is. Text selected in the browser opens it on its Quote tab:
/// the quote appended to a note, or made a new one.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/shared_page.dart';
import 'package:niman/src/ui/capture/capture_dialog.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/capture/capture_page_view.dart';
import 'package:niman/src/ui/capture/capture_quote_view.dart';
import 'package:niman/src/ui/capture/capture_reading_task.dart';
import 'package:niman/src/ui/capture/capture_sheet_result.dart';
import 'package:niman/src/ui/capture/capture_steps.dart';
import 'package:niman/src/ui/strings.dart';

export 'package:niman/src/ui/capture/capture_sheet_result.dart';

/// Opens the sheet over [share], a page or a quote shared from the
/// browser, or over [url] (from New, the clipboard's when it holds one);
/// with neither, the address is typed. A quote is appended to [appendTo]
/// unless another note is picked with [pickNote].
Future<CaptureSheetResult?> showCaptureSheet(
  BuildContext context, {
  required CaptureTarget target,
  WebShare? share,
  Uri? url,
  bool fromClipboard = false,
  String? appendTo,
  Future<String?> Function(String? current)? pickNote,
}) => showModalBottomSheet<CaptureSheetResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (context) => CaptureSheet(
    target: target,
    share: share,
    url: url,
    fromClipboard: fromClipboard,
    appendTo: appendTo,
    pickNote: pickNote,
  ),
);

/// The sheet.
final class CaptureSheet extends StatefulWidget {
  /// The sheet into [target].
  const new({
    required this.target,
    this.share,
    this.url,
    this.fromClipboard = false,
    this.appendTo,
    this.pickNote,
    super.key,
  });

  /// Where the note goes.
  final CaptureTarget target;

  /// What the browser shared, when the sheet is a share's.
  final WebShare? share;

  /// The page, when the sheet is New's and an address was found.
  final Uri? url;

  /// Whether [url] came from the clipboard.
  final bool fromClipboard;

  /// The note a quote is appended to unless another is picked.
  final String? appendTo;

  /// Asks for the note a quote is appended to.
  final Future<String?> Function(String? current)? pickNote;

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

final class _CaptureSheetState extends State<CaptureSheet> {
  late final TextEditingController _address = TextEditingController(
    text: (widget.share?.pageUrl ?? widget.url)?.toString() ?? '',
  );
  late final TextEditingController _title = TextEditingController(
    text: widget.share?.title ?? '',
  );

  /// Whether the title is the user's or the share's, not the page's.
  late bool _titleChosen = widget.share?.title != null;
  late String _folder = widget.target.folder;
  final List<String> _tags = [...defaultCaptureTags];
  bool _downloadPictures = true;
  CaptureReadingTask? _reading;

  /// Whether [_reading] could not have its page.
  bool _failed = false;
  String? _error;

  /// Whether the reading went to the background capture with Save.
  bool _handedOver = false;

  /// Whether the Quote tab is on; a page is read only on the Page tab.
  late bool _quoteMode = widget.share is SharedQuote;
  late String? _appendTo = widget.appendTo;
  late bool _append = widget.appendTo != null;

  @override
  void initState() {
    super.initState();
    if (_url != null && !_quoteMode) _read();
  }

  @override
  void dispose() {
    _reading?.removeListener(_onStep);
    if (!_handedOver) _reading?.dispose();
    _address.dispose();
    _title.dispose();
    super.dispose();
  }

  /// The address typed, when it is a web page's.
  Uri? get _url => webAddressIn(_address.text);

  /// Starts reading the address.
  void _read() {
    final url = _url;
    if (url == null) {
      setState(() => _error = AppStrings.captureInvalidUrl);
      return;
    }
    if (_reading?.url == url && !_failed) {
      if (_error != null) setState(() => _error = null);
      return;
    }
    _reading?.removeListener(_onStep);
    _reading?.dispose();
    final reading = CaptureReadingTask.start(
      url,
      read: widget.target.read,
      browser: widget.target.browser,
    )..addListener(_onStep);
    unawaited(
      reading.result.then<void>(
        (_) {},
        onError: (Object error) {
          if (!mounted || !identical(_reading, reading)) return;
          setState(() {
            _failed = true;
            _error = error is PageFetchException
                ? captureFailureText(error)
                : '$error';
          });
        },
      ),
    );
    setState(() {
      _reading = reading;
      _failed = false;
      _error = null;
    });
  }

  void _onStep() {
    final done = _reading?.done;
    if (done != null && !_titleChosen) _title.text = done.page.title;
    if (mounted) setState(() {});
  }

  Future<void> _pickFolder() async {
    final folder = await widget.target.pickFolder(_folder);
    if (folder == null || !mounted) return;
    setState(() => _folder = folder);
  }

  Future<void> _pickNote() async {
    final note = await widget.pickNote?.call(_appendTo);
    if (note == null || !mounted) return;
    setState(() {
      _appendTo = note;
      _append = true;
    });
  }

  void _keepQuote() {
    final quote = widget.share;
    if (quote is! SharedQuote) return;
    final note = _append ? _appendTo : null;
    Navigator.pop(
      context,
      CaptureQuoteChosen(
        quote,
        appendTo: note,
        folder: _folder,
        tags: List.of(_tags),
      ),
    );
  }

  void _save() {
    _read();
    final reading = _reading;
    if (reading == null || _error != null || _failed) return;
    reading.removeListener(_onStep);
    _handedOver = true;
    final title = _title.text.trim();
    Navigator.pop(
      context,
      CapturePageChosen(reading, (
        folder: _folder,
        title: title.isEmpty ? null : title,
        tags: List.of(_tags),
        downloadPictures: _downloadPictures,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final share = widget.share;
    final quote = share is SharedQuote ? share : null;
    return Padding(
      key: const Key('capture-sheet'),
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              share != null
                  ? AppStrings.captureSaveToNiman
                  : AppStrings.captureWebPage,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            // A share always shows both tabs; Quote is there to pick only
            // when text was selected, and keeps its place when it was not.
            if (share != null) ...[
              SegmentedButton<bool>(
                key: const Key('capture-sheet-mode'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(AppStrings.capturePageField),
                  ),
                  ButtonSegment(
                    value: true,
                    enabled: quote != null,
                    label: Text(AppStrings.captureQuote),
                  ),
                ],
                selected: {_quoteMode},
                onSelectionChanged: (selected) {
                  setState(() => _quoteMode = selected.single);
                  if (!_quoteMode) _read();
                },
              ),
              const SizedBox(height: 12),
            ],
            if (_quoteMode && quote != null)
              CaptureQuoteView(
                quote: quote,
                append: _append,
                appendTo: _appendTo,
                folder: _folder,
                onAppend: () => setState(() => _append = true),
                onNewNote: () => setState(() => _append = false),
                onPickNote: () => unawaited(_pickNote()),
                onPickFolder: () => unawaited(_pickFolder()),
              )
            else
              CapturePageView(
                address: share == null ? _address : null,
                autofocus: widget.url == null,
                fromClipboard: widget.fromClipboard,
                title: _title,
                host: _reading?.url.host,
                error: _error,
                folder: _folder,
                tags: _tags,
                attachmentsFolder: widget.target.attachmentsFolder,
                pictures: _reading?.done?.pictures.length,
                downloadPictures: _downloadPictures,
                // A corrected address can be saved, and is read then.
                onAddressChanged: () {
                  if (_error != null) setState(() => _error = null);
                },
                onAddressSubmitted: _read,
                onTitleChanged: () => _titleChosen = true,
                onPickFolder: () => unawaited(_pickFolder()),
                onTagsChanged: () => setState(() {}),
                onDownloadPictures: (on) =>
                    setState(() => _downloadPictures = on),
              ),
            const SizedBox(height: 8),
            if (_quoteMode)
              FilledButton(
                key: const Key('capture-sheet-save'),
                onPressed: _append && _appendTo == null ? null : _keepQuote,
                child: Text(
                  _append
                      ? AppStrings.captureAppend
                      : AppStrings.captureSaveNote,
                ),
              )
            else
              FilledButton(
                key: const Key('capture-sheet-save'),
                // Save after a failure reads the page again, in the
                // background: a share has no address to correct.
                onPressed: _save,
                child: Text(AppStrings.captureSaveNote),
              ),
            if (share != null) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.captureBackgroundHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
