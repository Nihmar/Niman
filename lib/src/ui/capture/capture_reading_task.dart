/// A page being read, for whoever waits on it (#531): the phone's sheet,
/// which shows what the page holds as soon as it is known, and the
/// background capture that saves it once the user has said where — before
/// or after the reading is done.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/ui/capture/capture_dialog.dart';

/// The reading of one page, started at once; it notifies at each step and
/// when it is done.
final class CaptureReadingTask extends ChangeNotifier {
  /// Reads [url] with [read], running a page with too little text in the
  /// browser [browser] finds.
  new start(
    this.url, {
    required CaptureRead read,
    Future<PageBrowser?> Function()? browser,
  }) {
    result = _run(read, browser);
    // Whoever waits on the result hears a failure; nobody waiting — a
    // sheet closed before it was done — is not an unhandled error.
    unawaited(result.then<void>((_) {}, onError: (Object _) {}));
  }

  /// The page.
  final Uri url;

  /// The page read; throws a [PageFetchException] when it could not be
  /// had.
  late final Future<WebReading> result;

  /// Where the reading is.
  CaptureProgress get progress => _progress;
  CaptureProgress _progress = (
    stage: CaptureStage.downloading,
    bytes: 0,
    words: 0,
  );

  /// The reading once it is done, else null.
  WebReading? get done => _done;
  WebReading? _done;

  bool _disposed = false;

  Future<WebReading> _run(
    CaptureRead read,
    Future<PageBrowser?> Function()? browser,
  ) async {
    final found = await browser?.call();
    final reading = await read(
      url,
      browser: found,
      onProgress: (step) {
        _progress = step;
        if (!_disposed) notifyListeners();
      },
    );
    _done = reading;
    if (!_disposed) notifyListeners();
    return reading;
  }

  /// Stops notifying; the reading itself runs to its end.
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
