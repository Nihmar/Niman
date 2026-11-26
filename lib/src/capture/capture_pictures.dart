/// A captured page's pictures, downloaded into the library's attachments
/// folder (#531) as a pasted picture is copied there: named by their
/// SHA-256, so the same picture is there once whatever page brought it.
///
/// At most [maxCapturedPictures] of them, each under
/// [maxCapturedPictureBytes], [parallelPictureDownloads] at a time. A
/// picture that does not come is left out of the map, and the note keeps
/// its address instead. The caller runs this off the UI isolate.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:niman/src/library/attachment_store.dart';
import 'package:path/path.dart' as p;

/// The most pictures a capture downloads.
const int maxCapturedPictures = 60;

/// The most bytes one picture may have.
const int maxCapturedPictureBytes = 15 * 1024 * 1024;

/// How many pictures download at once.
const int parallelPictureDownloads = 4;

/// The extension a picture of each media type is stored under.
const Map<String, String> _extensions = {
  'image/png': '.png',
  'image/jpeg': '.jpg',
  'image/jpg': '.jpg',
  'image/gif': '.gif',
  'image/webp': '.webp',
  'image/svg+xml': '.svg',
  'image/avif': '.avif',
  'image/bmp': '.bmp',
};

/// A picture fetched: its bytes and the extension it is stored under.
typedef FetchedPicture = ({Uint8List bytes, String extension});

/// Fetches the picture at an absolute http or https address; null when it
/// is not a picture, is too large or does not come, and throws on a
/// connection that fails.
typedef PictureFetcher = Future<FetchedPicture?> Function(String url);

/// The capture's own download of [client], each picture given [timeout].
PictureFetcher httpPictureFetcher(
  HttpClient client, {
  Duration timeout = const Duration(seconds: 30),
}) =>
    (url) => downloadPicture(client, url).timeout(timeout);

/// An [HttpClient] set as the capture sets its own: what every download of
/// a picture from the web — a capture, an import, an export — uses.
HttpClient pictureHttpClient() => HttpClient()
  ..connectionTimeout = const Duration(seconds: 15)
  ..userAgent = 'Niman';

/// Downloads the pictures at [urls] — absolute http, https or base64
/// `data:` addresses — into `<libraryRoot>/<attachmentsFolder>/`, and gives
/// each one that landed its library-relative path.
Future<Map<String, String>> downloadPictures(
  Iterable<String> urls, {
  required String libraryRoot,
  required String attachmentsFolder,
  Duration timeout = const Duration(seconds: 30),
}) async {
  final queue = urls.toSet().take(maxCapturedPictures).toList();
  final stored = <String, String>{};
  final client = pictureHttpClient();
  var next = 0;
  Future<void> worker() async {
    while (next < queue.length) {
      final url = queue[next++];
      try {
        final picture = await downloadPicture(client, url).timeout(timeout);
        if (picture == null) continue;
        stored[url] = await storeAttachmentBytes(
          libraryRoot: libraryRoot,
          bytes: picture.bytes,
          extension: picture.extension,
          attachmentsFolder: attachmentsFolder,
        );
      } on Object {
        // Left out: the note keeps the picture's address.
      }
    }
  }

  try {
    await Future.wait([
      for (var i = 0; i < parallelPictureDownloads; i++) worker(),
    ]);
  } finally {
    client.close(force: true);
  }
  return stored;
}

/// The picture at [url] with the extension it is stored under, or null
/// when it is not a picture, is too large, or does not come. Throws when
/// the connection fails.
Future<FetchedPicture?> downloadPicture(HttpClient client, String url) async {
  if (url.startsWith('data:')) return decodeDataPicture(url);
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return null;
  }
  final request = await client.getUrl(uri);
  final response = await request.close();
  if (response.statusCode < 200 ||
      response.statusCode >= 300 ||
      response.contentLength > maxCapturedPictureBytes) {
    await response.drain<void>();
    return null;
  }
  final type = response.headers.contentType?.mimeType;
  final extension = pictureExtension(type, uri.path);
  if (extension == null) {
    await response.drain<void>();
    return null;
  }
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in response) {
    bytes.add(chunk);
    if (bytes.length > maxCapturedPictureBytes) return null;
  }
  return (bytes: bytes.takeBytes(), extension: extension);
}

/// The extension a picture of media [type] at [path] is stored under: by
/// its type, else — no type, or a generic one — by its own name; null when
/// it is not a picture.
String? pictureExtension(String? type, String path) {
  final byType = _extensions[type];
  if (byType != null) return byType;
  if (type != null &&
      !type.startsWith('image/') &&
      type != 'application/octet-stream') {
    return null;
  }
  final own = p.url.extension(path).toLowerCase();
  return _extensions.values.contains(own) || own == '.jpeg' ? own : null;
}

/// A base64 `data:` picture, decoded; null when it is not a picture, is
/// too large, or is not valid base64.
FetchedPicture? decodeDataPicture(String url) {
  final match = RegExp(
    r'^data:\s*([^\s;,]+)\s*;\s*base64\s*,(.*)$',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(url);
  final extension = _extensions[match?[1]?.toLowerCase()];
  if (match == null || extension == null) return null;
  final Uint8List bytes;
  try {
    bytes = base64.decode(match[2]!.replaceAll(RegExp(r'\s'), ''));
  } on FormatException {
    return null;
  }
  if (bytes.length > maxCapturedPictureBytes) return null;
  return (bytes: bytes, extension: extension);
}
