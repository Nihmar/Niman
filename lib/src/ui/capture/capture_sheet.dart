/// The phone's capture sheet (#531): what a page shared from the browser
/// opens — "Save to Niman" — and New ▸ Capture web page too, with the
/// address to type. The page is read as soon as it is known, so the sheet
/// can say how many pictures it has; Save hands the reading to the
/// background capture and the sheet closes at once, the page still being
/// read if it is.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/shared_page.dart';
import 'package:niman/src/ui/capture/background_capture.dart';
import 'package:niman/src/ui/capture/capture_dialog.dart';
import 'package:niman/src/ui/capture/capture_flow.dart';
import 'package:niman/src/ui/capture/capture_reading_task.dart';
import 'package:niman/src/ui/capture/capture_steps.dart';
import 'package:niman/src/ui/capture/capture_tags.dart';
import 'package:niman/src/ui/strings.dart';

/// What the sheet was closed with.
sealed class CaptureSheetResult {
  const new();
}

/// A page to capture: its reading, under way or done, and the choices.
final class CapturePageChosen extends CaptureSheetResult {
  /// The page [reading] reads, saved as [chosen].
  const new(this.reading, this.chosen);

  /// The page's reading; the capture's from here on.
  final CaptureReadingTask reading;

  /// Where and how the note is made.
  final CaptureChosen chosen;
}

/// Opens the sheet over [share], a page or a quote shared from the
/// browser, or over [url] (from New, the clipboard's when it holds one);
/// with neither, the address is typed.
Future<CaptureSheetResult?> showCaptureSheet(
  BuildContext context, {
  required CaptureTarget target,
  WebShare? share,
  Uri? url,
  bool fromClipboard = false,
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

  @override
  void initState() {
    super.initState();
    if (_url != null) _read();
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
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final shared = widget.share != null;
    final pictures = _reading?.done?.pictures.length;
    final attachments = widget.target.attachmentsFolder;
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
              shared
                  ? AppStrings.captureSaveToNiman
                  : AppStrings.captureWebPage,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (!shared) ...[
              TextField(
                key: const Key('capture-sheet-address'),
                controller: _address,
                autofocus: widget.url == null,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: AppStrings.capturePageField,
                  hintText: 'https://',
                  helperText: widget.fromClipboard
                      ? AppStrings.captureFromClipboard
                      : null,
                ),
                // A corrected address can be saved, and is read then.
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _read(),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              key: const Key('capture-sheet-title'),
              controller: _title,
              decoration: InputDecoration(
                labelText: AppStrings.captureTitleField,
                helperText: _reading?.url.host,
              ),
              onChanged: (_) => _titleChosen = true,
            ),
            if (_error case final error?) ...[
              const SizedBox(height: 8),
              Text(
                error,
                key: const Key('capture-sheet-error'),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            const SizedBox(height: 4),
            ListTile(
              key: const Key('capture-sheet-folder'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_outlined),
              title: Text(_folder.isEmpty ? '/' : _folder),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => unawaited(_pickFolder()),
            ),
            CaptureTags(tags: _tags, onChanged: () => setState(() {})),
            // Before the page has said how many pictures it holds, the
            // choice is offered all the same; a page with none keeps the
            // row, disabled, so Save does not move under the thumb.
            CheckboxListTile(
              key: const Key('capture-sheet-pictures'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _downloadPictures && pictures != 0,
              onChanged: pictures == 0
                  ? null
                  : (value) => setState(() => _downloadPictures = value!),
              title: Text(
                pictures == null
                    ? AppStrings.captureDownloadPicturesTo(attachments)
                    : AppStrings.captureDownloadPictures(pictures, attachments),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('capture-sheet-save'),
              // Save after a failure reads the page again, in the
              // background: a share has no address to correct.
              onPressed: _save,
              child: Text(AppStrings.captureSaveNote),
            ),
            if (shared) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.captureBackgroundHint,
                style: muted,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
