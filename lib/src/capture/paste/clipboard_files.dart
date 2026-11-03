/// The files on the clipboard (#1249): what a file manager's Copy puts
/// there, read as local paths a paste copies into the library.
///
/// Every platform answers with paths on this device. Windows reads
/// `CF_HDROP` itself (`windows_clipboard_files.dart`); Linux, Android,
/// macOS and iOS ask their runner over `niman/clipboard` (`readFiles`).
/// With no files, a picture alone on the clipboard — a screenshot — is
/// one, kept in a file of its own (`clipboard_picture.dart`): Windows
/// reads it itself, Linux and macOS answer `readImage`.
/// Linux answers with the raw bytes of the target the file manager wrote —
/// `x-special/gnome-copied-files` or `text/uri-list` — read here, where it
/// is tested; Android and iOS copy what a `content://` URI or an item
/// provider holds into the app's cache first, since only a path can be
/// copied on.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:niman/src/capture/paste/clipboard_picture.dart';
import 'package:niman/src/core/logging.dart';

/// Reads the files on the clipboard.
abstract interface class ClipboardFilesReader {
  /// The paths of the files on the clipboard; empty when it holds none.
  Future<List<String>> read();
}

/// A clipboard that never holds files.
final class NoClipboardFiles implements ClipboardFilesReader {
  /// The reader.
  const new();

  @override
  Future<List<String>> read() async => const [];
}

/// Asks the runner over `niman/clipboard`.
final class ChannelClipboardFiles implements ClipboardFilesReader {
  /// The reader.
  const new();

  static const _channel = MethodChannel('niman/clipboard');

  static const _log = AppLogger(name: 'paste');

  @override
  Future<List<String>> read() async {
    final Object? answer;
    try {
      answer = await _channel.invokeMethod<Object?>('readFiles');
    } on MissingPluginException {
      return const [];
    } on PlatformException catch (error) {
      _log.warning('files: the clipboard could not be read ($error)');
      return const [];
    }
    final files = clipboardFilesFrom(answer);
    if (files.isNotEmpty) return files;
    final picture = await _picture();
    return picture == null ? const [] : [await keepClipboardPicture(picture)];
  }

  /// The PNG of the picture on the clipboard when it holds one and no text
  /// (`readImage`: Linux and macOS; Android and iOS hand a copied picture
  /// over as a file already).
  Future<Uint8List?> _picture() async {
    try {
      final png = await _channel.invokeMethod<Uint8List>('readImage');
      return png == null || png.isEmpty ? null : png;
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      _log.warning('picture: the clipboard could not be read ($error)');
      return null;
    }
  }
}

/// The paths in a runner's answer: a list of paths (Android, Apple), the
/// bytes of a URI list (Linux), or nothing.
List<String> clipboardFilesFrom(Object? answer) => switch (answer) {
  // Before the list: bytes are a list of ints too.
  final Uint8List bytes => pathsOfUriList(
    utf8.decode(bytes, allowMalformed: true),
  ),
  final List<Object?> paths => [
    for (final path in paths)
      if (path is String && path.isNotEmpty) path,
  ],
  final String text => pathsOfUriList(text),
  _ => const [],
};

/// The local paths a URI list names (RFC 2483: one URI a line, `#` a
/// comment), and the same list behind the `copy` or `cut` line GNOME's
/// file managers put first. A URI that is not a `file:` one is not a file
/// on this device, and the list is taken as no files at all: a browser's
/// link is a link to paste as text, not a file to copy.
List<String> pathsOfUriList(String text) {
  final lines = [
    for (final raw in const LineSplitter().convert(text))
      if (raw.trim() case final line
          when line.isNotEmpty && !line.startsWith('#'))
        line,
  ];
  if (lines.isNotEmpty && (lines.first == 'copy' || lines.first == 'cut')) {
    lines.removeAt(0);
  }
  final paths = <String>[];
  for (final line in lines) {
    final uri = Uri.tryParse(line);
    if (uri == null ||
        uri.scheme != 'file' ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.host.isNotEmpty && uri.host != 'localhost')) {
      return const [];
    }
    // `file://localhost/…` is this device's, as `file:///…` is.
    paths.add(Uri(scheme: 'file', path: uri.path).toFilePath(windows: false));
  }
  return paths;
}
