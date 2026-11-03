/// The clipboard's files reader for the platform the app runs on (#1249).
library;

import 'dart:io';

import 'package:niman/src/capture/paste/clipboard_files.dart';
import 'package:niman/src/capture/paste/windows_clipboard_files.dart';

/// Windows reads the clipboard itself; Linux, Android, macOS and iOS ask
/// their runner (the Apple ones' is `packages/niman_apple`); anywhere else
/// there are no files to read.
ClipboardFilesReader platformClipboardFiles() {
  if (Platform.isWindows) return WindowsClipboardFiles();
  if (Platform.isLinux ||
      Platform.isAndroid ||
      Platform.isMacOS ||
      Platform.isIOS) {
    return const ChannelClipboardFiles();
  }
  return const NoClipboardFiles();
}
