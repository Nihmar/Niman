// The capture's services for a widget test (#531): no browser looked for
// — on Windows that is a registry query, a real process — and no network.
import 'dart:async';

import 'package:niman/src/capture/web_capture.dart';
import 'package:niman/src/ui/capture/background_capture.dart';
import 'package:niman/src/ui/capture/capture_services.dart';

/// Services whose reading never ends: what a test needs that only looks
/// at where a capture opens.
CaptureServices quietCaptureServices() => CaptureServices(
  background: BackgroundCapture(notifier: const SilentCaptureNotifier()),
  browser: () async => null,
  read: (url, {browser, onProgress}) => Completer<WebReading>().future,
);
