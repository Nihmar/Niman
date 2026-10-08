/// The clipboard's HTML as the platform runner reads it (#531): the GTK
/// runner on Linux (`linux/runner/clipboard_html.cc`), the activity's
/// bridge on Android (`ClipboardBridge.kt`), over one channel.
library;

import 'package:flutter/services.dart';
import 'package:niman/src/capture/paste/clipboard_html.dart';

/// The channel both runners answer on.
const String clipboardChannelName = 'niman/clipboard';

/// Reads the clipboard's HTML over [channel].
///
/// The runner answers `readHtml` with null when the clipboard holds no
/// HTML, or with a map: `html`, and `source` when the browser said which
/// page it was — each as the target's bytes (GTK, which leaves their
/// encoding to the reader) or as a string (Android, whose clipboard has
/// no source at all).
final class ChannelClipboardHtml implements ClipboardHtmlReader {
  /// A reader over [channel].
  const new([this.channel = const MethodChannel(clipboardChannelName)]);

  /// The runner's channel.
  final MethodChannel channel;

  @override
  Future<ClipboardHtml?> read() async {
    final Map<String, Object?>? reply;
    try {
      reply = await channel.invokeMapMethod<String, Object?>('readHtml');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
    if (reply == null) return null;
    final html = _text(reply['html']);
    if (html == null || html.trim().isEmpty) return null;
    return ClipboardHtml(
      html,
      source: clipboardSourceUrl(_text(reply['source'])),
    );
  }
}

String? _text(Object? value) => switch (value) {
  final String text => text,
  final Uint8List bytes => decodeClipboardText(bytes),
  _ => null,
};
