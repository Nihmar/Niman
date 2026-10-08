/// The Android page browser (#531): a WebView of the app's own, through the
/// `niman/page_reader` channel (`PageReaderBridge.kt`) — JavaScript on,
/// network pictures off, no file access, no JavaScript interface — whose
/// `outerHTML` is read once the page has stopped growing.
///
/// Called off the UI isolate, the channel is reached through the
/// background isolate messenger, with the token taken on the UI isolate.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:niman/src/capture/browser/page_browser.dart';

/// The channel the page reader answers on.
const String pageReaderChannel = 'niman/page_reader';

/// Reads pages with the Android WebView.
final class WebViewPageBrowser implements PageBrowser {
  /// A browser whose channel is reached with [token]: the UI isolate's.
  const new(this.token);

  /// The browser for the isolate this is called on, the UI one; null where
  /// there is no token to take.
  static WebViewPageBrowser? forThisIsolate() {
    final token = RootIsolateToken.instance;
    return token == null ? null : WebViewPageBrowser(token);
  }

  /// The UI isolate's token, for a background isolate to reach the channel.
  final RootIsolateToken token;

  static const MethodChannel _channel = MethodChannel(pageReaderChannel);

  @override
  Future<String?> read(Uri url) async {
    if (!(url.isScheme('http') || url.isScheme('https'))) return null;
    // Off the UI isolate the channel goes through the background
    // messenger; on it, through the app's own.
    if (RootIsolateToken.instance == null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(token);
    }
    try {
      return await _channel
          .invokeMethod<String>('read', <String, Object>{
            'url': url.toString(),
            'timeoutMs': browserReadTimeout.inMilliseconds,
            'maxCharacters': maxBrowserDomCharacters,
          })
          // A little past the bridge's own watchdog, which answers first.
          .timeout(browserReadTimeout + const Duration(seconds: 5));
    } on TimeoutException {
      unawaited(cancel());
      return null;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// Stops the read in flight, if any.
  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancel');
    } on MissingPluginException {
      // No bridge: nothing to stop.
    } on PlatformException {
      // A cancel that raced the read's own end is not a failure.
    }
  }
}
