/// The pictures of the web an exported EPUB carries (#1309): downloaded when
/// the container is written, as the PDF's browser engine fetches them while
/// printing, and stored inside the book.
///
/// EPUB 3 holds its pictures in the container, so a picture on the web is
/// either in the book or not drawn as a picture at all. This downloads each
/// address once, with the capture's own download and limits
/// (`capture_pictures.dart`): at most [maxCapturedPictures] pictures a book,
/// each under [maxCapturedPictureBytes], [parallelPictureDownloads] at a
/// time, each given `timeout`. What came is kept in a scratch folder, named
/// by its bytes' SHA-256, and handed to the book as a file; the type is read
/// from the bytes, so a server's wrong `Content-Type` makes no wrong entry.
///
/// A picture that does not come — offline, an error status, too large, not a
/// type an EPUB carries — is simply absent from the answer: the page draws
/// it as its alt text, linked (`ExportHooks.image`).
///
/// It runs where the container is written, on the export's isolate; a stop
/// is looked for before each picture and, so that it does not wait for the
/// slowest download, every [_poll] while they run.
library;

import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:niman/src/capture/capture_pictures.dart';
import 'package:niman/src/epub/epub_picture_type.dart';
import 'package:niman/src/export/epub_book.dart';
import 'package:niman/src/export/picture_mime.dart';
import 'package:path/path.dart' as p;

const Duration _poll = Duration(milliseconds: 25);

/// An address a browser fetches over HTTP: what a book downloads.
final RegExp _web = RegExp('^https?://', caseSensitive: false);

/// The export was stopped while its pictures were being downloaded.
final class EpubPicturesStopped implements Exception {
  /// Creates the stop.
  const new();

  /// What a log line reads.
  @override
  String toString() => 'EPUB picture download stopped';
}

/// One book's downloads: each address once, within the capture's bounds.
final class EpubWebPictures {
  /// Downloads for one book. [isCancelled] is the export's stop flag; [_fetch]
  /// is how a picture comes (the capture's own download, but in a test);
  /// [maxDownloads] is the most addresses the book tries.
  new({
    required this.isCancelled,
    this._fetch,
    this.maxDownloads = maxCapturedPictures,
    this.timeout = const Duration(seconds: 30),
  });

  /// Whether the export was stopped.
  final bool Function() isCancelled;

  /// The most addresses one book tries; the rest stay links.
  final int maxDownloads;

  /// How long one picture may take.
  final Duration timeout;

  final PictureFetcher? _fetch;
  HttpClient? _client;
  Future<Directory>? _scratch;
  final Map<String, Future<void>> _written = <String, Future<void>>{};
  final Map<String, Future<String?>> _paths = <String, Future<String?>>{};

  /// The addresses among [targets] a book downloads: web pictures, as the
  /// note wrote them. A local file, a `data:` address or an `ftp:` one is
  /// not one.
  static List<String> webTargets(Iterable<String> targets) => [
    for (final target in targets)
      if (_web.hasMatch(target.trim())) target,
  ];

  /// Downloads the web pictures among [targets] and puts the ones that came
  /// into [book], as seen from a chapter in [fromDir]: the container
  /// address of each, by the target as written.
  ///
  /// Throws [EpubPicturesStopped] when the export is stopped.
  Future<Map<String, String>> carry(
    EpubBook book,
    String fromDir,
    Iterable<String> targets,
  ) async {
    final urls = webTargets(targets).toSet().toList();
    final files = <String, String>{};
    var next = 0;
    Future<void> worker() async {
      while (next < urls.length) {
        final url = urls[next++];
        final path = await _pathOf(url);
        if (path != null) files[url] = path;
      }
    }

    await Future.wait([
      for (var i = 0; i < parallelPictureDownloads; i++) worker(),
    ]);
    // Added in the note's order: the book numbers its pictures as they come.
    final images = <String, String>{};
    for (final url in urls) {
      final path = files[url];
      if (path == null) continue;
      final href = await book.imageHref(fromDir, path);
      if (href != null) images[url] = href;
    }
    return images;
  }

  /// Ends the downloads: a connection still open is dropped and the scratch
  /// folder is deleted.
  Future<void> close() async {
    _client?.close(force: true);
    final scratch = _scratch;
    if (scratch == null) return;
    try {
      await (await scratch).delete(recursive: true);
    } on Object {
      // A temp folder left behind is not the export's failure.
    }
  }

  Future<String?> _pathOf(String url) {
    if (isCancelled()) throw const EpubPicturesStopped();
    return _paths[url] ??= _paths.length >= maxDownloads
        ? Future<String?>.value()
        : _download(url);
  }

  Future<String?> _download(String url) async {
    final FetchedPicture? picture;
    try {
      picture = await _stoppable(
        (_fetch ?? httpPictureFetcher(_client ??= pictureHttpClient()))(url),
      );
    } on EpubPicturesStopped {
      rethrow;
    } on Object {
      // Left out: the page links to where the picture is.
      return null;
    }
    if (picture == null) return null;
    final extension = epubPictureExtension('', picture.bytes);
    if (epubPictureMime(extension) == null) return null;
    final scratch = await (_scratch ??= Directory.systemTemp.createTemp(
      'niman-epub-web-',
    ));
    final file = File(
      p.join(scratch.path, '${sha256.convert(picture.bytes)}$extension'),
    );
    // Downloads run side by side: the same bytes from two addresses are
    // written once, and the second waits for the first.
    await (_written[file.path] ??= file.writeAsBytes(picture.bytes));
    return file.path;
  }

  /// [download]'s answer, or [EpubPicturesStopped] as soon as the export is
  /// stopped: a stop does not wait for the slowest picture.
  Future<FetchedPicture?> _stoppable(Future<FetchedPicture?> download) async {
    final stopped = Completer<FetchedPicture?>();
    final timer = Timer.periodic(_poll, (_) {
      if (isCancelled() && !stopped.isCompleted) {
        stopped.completeError(const EpubPicturesStopped());
      }
    });
    try {
      return await Future.any([download, stopped.future]);
    } finally {
      timer.cancel();
    }
  }
}
