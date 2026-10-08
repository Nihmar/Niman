/// The capture dialog (#531): the page's address, each step as the page is
/// read, then the note it will be — title, folder, tags, preview, its
/// pictures, its frontmatter, what was left out — and Save. It resolves to
/// the note it made, or null.
///
/// The desktop's way to a capture — from the command palette, a link
/// pasted outside the editor or dropped on the window. A phone asks with
/// the capture sheet instead, and saves in the background.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/capture/capture_ready_form.dart';
import 'package:niman/src/ui/capture/capture_steps.dart';
import 'package:niman/src/ui/strings.dart';

/// Reads a page: [readWebPage], or a test's.
typedef CaptureRead = Future<WebReading> Function(
  Uri url, {
  PageBrowser? browser,
  void Function(CaptureProgress progress)? onProgress,
});

/// Downloads a page's pictures and writes its note: [saveWebCapture], or
/// a test's.
typedef CaptureSave = Future<({CapturedNote note, int pictures})> Function(
  PageReading page, {
  required String libraryRoot,
  required String attachmentsFolder,
  required String unreadableNotice,
  required DateTime captured,
  String? title,
  bool downloadPictures,
  List<String> tags,
  LinkType linkType,
});

/// Where a capture goes, and how it gets there.
final class CaptureTarget {
  /// A capture into the library at [libraryRoot].
  const new({
    required this.libraryRoot,
    required this.attachmentsFolder,
    required this.linkType,
    required this.folder,
    required this.pickFolder,
    required this.create,
    this.browser,
    this.read = _readWebPage,
    this.save = saveWebCapture,
    this.clock = DateTime.now,
  });

  /// The library's root, absolute.
  final String libraryRoot;

  /// The library's attachments folder.
  final String attachmentsFolder;

  /// How the library writes its links.
  final LinkType linkType;

  /// The folder the note goes in unless the user picks another.
  final String folder;

  /// Asks for another folder, from the current one; null keeps it.
  final Future<String?> Function(String current) pickFolder;

  /// Creates the note — its folder, its name, its text — and gives its
  /// library-relative path.
  final Future<String> Function(String folder, String name, String text) create;

  /// The browser a page with too little text is run in; null has none.
  final Future<PageBrowser?> Function()? browser;

  /// Reads a page.
  final CaptureRead read;

  /// Saves a page's note text.
  final CaptureSave save;

  /// The time now.
  final DateTime Function() clock;
}

Future<WebReading> _readWebPage(
  Uri url, {
  PageBrowser? browser,
  void Function(CaptureProgress progress)? onProgress,
}) => readWebPage(url, browser: browser, onProgress: onProgress);

/// The tags a captured note starts with.
const List<String> defaultCaptureTags = ['web'];

/// Opens the dialog, reading [url] at once when one is given; resolves to
/// the library-relative path of the note made, or null.
Future<String?> showCaptureDialog(
  BuildContext context, {
  required CaptureTarget target,
  Uri? url,
  bool fromClipboard = false,
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      CaptureDialog(target: target, url: url, fromClipboard: fromClipboard),
);

enum _Phase { address, reading, failed, ready, saving }

/// The dialog.
final class CaptureDialog extends StatefulWidget {
  /// The dialog into [target], over [url] when one is given.
  const new({
    required this.target,
    this.url,
    this.fromClipboard = false,
    super.key,
  });

  /// Where the note goes.
  final CaptureTarget target;

  /// The page, when the dialog opens on one.
  final Uri? url;

  /// Whether [url] came from the clipboard.
  final bool fromClipboard;

  @override
  State<CaptureDialog> createState() => _CaptureDialogState();
}

final class _CaptureDialogState extends State<CaptureDialog> {
  late final TextEditingController _address = TextEditingController(
    text: widget.url?.toString() ?? '',
  );
  _Phase _phase = _Phase.address;
  CaptureProgress _progress = (
    stage: CaptureStage.downloading,
    bytes: 0,
    words: 0,
  );
  String? _error;
  WebReading? _reading;
  CaptureChoices? _choices;
  late final DateTime _captured = widget.target.clock();

  @override
  void initState() {
    super.initState();
    if (widget.url != null) unawaited(_read());
  }

  @override
  void dispose() {
    _address.dispose();
    _choices?.dispose();
    super.dispose();
  }

  /// The address typed, when it is a web page's.
  Uri? get _url {
    final uri = Uri.tryParse(_address.text.trim());
    return uri != null &&
            (uri.isScheme('http') || uri.isScheme('https')) &&
            uri.host.isNotEmpty
        ? uri
        : null;
  }

  Future<void> _read() async {
    final url = _url;
    if (url == null) {
      setState(() {
        _phase = _Phase.failed;
        _error = AppStrings.captureInvalidUrl;
      });
      return;
    }
    setState(() {
      _phase = _Phase.reading;
      _error = null;
    });
    try {
      final browser = await widget.target.browser?.call();
      final reading = await widget.target.read(
        url,
        browser: browser,
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress);
        },
      );
      if (!mounted) return;
      _choices?.dispose();
      setState(() {
        _reading = reading;
        _choices = CaptureChoices(
          reading: reading,
          folder: widget.target.folder,
          tags: [...defaultCaptureTags],
        );
        _phase = _Phase.ready;
      });
    } on Object catch (error) {
      // Whatever went wrong is said: a reading that failed otherwise than
      // as a fetch would leave the dialog reading for good (#639).
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error = error is PageFetchException
            ? captureFailureText(error)
            : '$error';
      });
    }
  }

  Future<void> _pickFolder() async {
    final choices = _choices;
    if (choices == null) return;
    final folder = await widget.target.pickFolder(choices.folder);
    if (folder == null || !mounted) return;
    setState(() => choices.folder = folder);
  }

  Future<void> _save() async {
    final reading = _reading;
    final choices = _choices;
    if (reading == null || choices == null) return;
    setState(() => _phase = _Phase.saving);
    final target = widget.target;
    try {
      final saved = await target.save(
        reading.page,
        libraryRoot: target.libraryRoot,
        attachmentsFolder: target.attachmentsFolder,
        unreadableNotice: AppStrings.captureUnreadableNotice(
          reading.page.url.toString(),
        ),
        captured: _captured,
        title: choices.title.text,
        downloadPictures: choices.downloadPictures,
        tags: choices.tags,
        linkType: target.linkType,
      );
      final path = await target.create(
        choices.folder,
        saved.note.name,
        saved.note.text,
      );
      if (mounted) Navigator.pop(context, path);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.ready;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reading = _reading;
    final choices = _choices;
    final ready = _phase == _Phase.ready || _phase == _Phase.saving;
    return AlertDialog(
      key: const Key('capture-dialog'),
      title: Text(AppStrings.captureWebPage),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, minWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!ready) ...[
                TextField(
                  key: const Key('capture-address'),
                  controller: _address,
                  autofocus: widget.url == null,
                  enabled: _phase != _Phase.reading,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: AppStrings.capturePageField,
                    hintText: 'https://',
                    helperText: widget.fromClipboard
                        ? AppStrings.captureFromClipboard
                        : null,
                  ),
                  onSubmitted: (_) => unawaited(_read()),
                ),
                const SizedBox(height: 12),
              ],
              if (_phase == _Phase.reading) CaptureSteps(progress: _progress),
              if (_error case final error?)
                Text(
                  error,
                  key: const Key('capture-error'),
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              if (ready && reading != null && choices != null)
                CaptureReadyForm(
                  reading: reading,
                  choices: choices,
                  captured: _captured,
                  attachmentsFolder: widget.target.attachmentsFolder,
                  onPickFolder: () => unawaited(_pickFolder()),
                  onChanged: () => setState(() {}),
                ),
              if (_phase == _Phase.saving) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(AppStrings.captureSaving),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppStrings.actionCancel),
        ),
        if (ready)
          FilledButton(
            key: const Key('capture-save'),
            onPressed: _phase == _Phase.saving
                ? null
                : () => unawaited(_save()),
            child: Text(AppStrings.captureSaveNote),
          )
        else
          FilledButton(
            key: const Key('capture-read'),
            onPressed: _phase == _Phase.reading
                ? null
                : () => unawaited(_read()),
            child: Text(AppStrings.captureRead),
          ),
      ],
    );
  }
}
