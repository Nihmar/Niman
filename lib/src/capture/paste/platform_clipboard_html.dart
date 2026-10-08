/// The clipboard's HTML reader for the platform the app runs on (#531).
library;

import 'dart:io';

import 'package:niman/src/capture/paste/channel_clipboard_html.dart';
import 'package:niman/src/capture/paste/clipboard_html.dart';
import 'package:niman/src/capture/paste/windows_clipboard_html.dart';

/// Windows reads the clipboard itself; Linux and Android ask their
/// runner; anywhere else there is no HTML to read.
ClipboardHtmlReader platformClipboardHtml() {
  if (Platform.isWindows) return WindowsClipboardHtml();
  if (Platform.isLinux || Platform.isAndroid) {
    return const ChannelClipboardHtml();
  }
  return const NoClipboardHtml();
}
