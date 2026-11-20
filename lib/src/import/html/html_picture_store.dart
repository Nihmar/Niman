/// The pictures of an imported page (#1293), kept in the hidden folder the
/// conversion is staged in, named by their SHA-256 as the library's
/// attachments are: the same picture is there once, whichever of the page's
/// `src`s brought it. The conversion moves them into the library's
/// attachments folder when it finishes.
///
/// Local pictures are read, `data:` ones decoded, web ones fetched through
/// [PictureFetcher] — the capture's own download, with its limits: at most
/// [maxCapturedPictures] web pictures, each under
/// [maxCapturedPictureBytes], as every other picture is.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:niman/src/capture/capture_pictures.dart';
import 'package:niman/src/import/html/html_picture_source.dart';
import 'package:path/path.dart' as p;

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

/// An [HttpClient] set as the capture sets its own.
HttpClient pictureHttpClient() => HttpClient()
  ..connectionTimeout = const Duration(seconds: 15)
  ..userAgent = 'Niman';

/// The staging folder's pictures.
final class HtmlPictureStore {
  /// A store writing into `<staging>/<attachments>/`.
  new({
    required this.staging,
    required this.attachments,
    required this.fetch,
    this.maxDownloads = maxCapturedPictures,
  });

  /// The hidden folder everything is written in first, absolute.
  final String staging;

  /// The library's attachments folder's name.
  final String attachments;

  /// How a web picture comes.
  final PictureFetcher fetch;

  /// The most web pictures the store downloads: a page's is the capture's
  /// own limit, a folder of pages' (#1295) is its own.
  final int maxDownloads;

  int _downloads = 0;
  bool _closed = false;

  /// The pictures that landed in the store, by their paths.
  final Set<String> _kept = {};

  /// Ends the store's writing: a picture still on its way is dropped when
  /// it arrives, so nothing lands in a folder that is being deleted.
  void close() => _closed = true;

  /// How many pictures the store holds.
  int get length => _kept.length;

  /// Keeps the picture at [source]; answers where, relative to the folder
  /// [staging] stands for (`assets/<sha256>.png`), or null when it could
  /// not be had: a file that is not there or not a picture, a `data:`
  /// address that is not valid, a web picture that does not come.
  Future<String?> keep(PictureSource source) async {
    final FetchedPicture? picture;
    try {
      picture = switch (source.kind) {
        PictureKind.local => await _local(source.address),
        PictureKind.data => decodeDataPicture(source.address),
        PictureKind.web => await _web(source.address),
      };
    } on Object {
      // Left out: the note keeps a web picture's address, and drops the rest.
      return null;
    }
    if (picture == null || _closed) return null;
    final name = '${sha256.convert(picture.bytes)}${picture.extension}';
    final file = File(p.join(staging, attachments, name));
    if (!file.existsSync()) {
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(picture.bytes);
    }
    _kept.add(name);
    return '$attachments/$name';
  }

  Future<FetchedPicture?> _local(String path) async {
    final extension = pictureExtension(null, p.basename(path));
    final file = File(path);
    if (extension == null ||
        !file.existsSync() ||
        file.lengthSync() > maxCapturedPictureBytes) {
      return null;
    }
    return (bytes: await file.readAsBytes(), extension: extension);
  }

  Future<FetchedPicture?> _web(String url) {
    if (_downloads >= maxDownloads) return Future.value();
    _downloads++;
    return fetch(url);
  }
}
