/// What a capture runs on (#531): how a page is read and saved, and the
/// captures made with the app off screen — the real ones, or a test's.
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/ui/capture/background_capture.dart';
import 'package:niman/src/ui/capture/capture_dialog.dart';
import 'package:niman/src/ui/capture/plugin_capture_notifier.dart';

/// The capture's services.
final class CaptureServices {
  /// Services reading pages with [read] — in [browser]'s when the
  /// download has too little text — and saving them with [save],
  /// capturing in [background].
  new({
    required this.background,
    this.read = readPageToCapture,
    this.save = saveWebCapture,
    this.browser = findPageBrowser,
  });

  /// Finds the browser a page with too little text is run in.
  final Future<PageBrowser?> Function() browser;

  /// Reads a page.
  final CaptureRead read;

  /// Saves a page's note.
  final CaptureSave save;

  /// The captures that run with the app off screen.
  final BackgroundCapture background;
}

/// Reads a page with [readWebPage].
Future<WebReading> readPageToCapture(
  Uri url, {
  PageBrowser? browser,
  void Function(CaptureProgress progress)? onProgress,
}) => readWebPage(url, browser: browser, onProgress: onProgress);

/// The app's capture services: on Android the notifications say how a
/// background capture goes; elsewhere none runs — the desktop's dialog
/// stays on screen until the note is made.
final captureServicesProvider = Provider<CaptureServices>(
  (ref) => CaptureServices(
    background: BackgroundCapture(
      notifier: Platform.isAndroid
          ? PluginCaptureNotifier()
          : const SilentCaptureNotifier(),
    ),
  ),
);

/// A notifier that says nothing.
final class SilentCaptureNotifier implements CaptureNotifier {
  /// The notifier.
  const new();

  @override
  Future<void> begin({
    required String title,
    String? body,
    String? cancel,
  }) async {}

  @override
  Future<void> update({
    required String title,
    String? body,
    String? cancel,
  }) async {}

  @override
  Future<void> end() async {}

  @override
  Future<void> result({
    required String title,
    required String body,
    String? open,
    String? folder,
  }) async {}
}
