/// Capturing a web page as a note (#531), every step off the UI isolate:
/// the page downloaded, decoded and read, its pictures downloaded into the
/// attachments folder, and its note written out as text — for the caller
/// to create in the library.
///
/// When the download has too little text, the page is read as it is; the
/// browser that runs the page's scripts and reads it again comes with the
/// fallback (#531, part two).
library;

import 'dart:isolate';

import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/capture_pictures.dart';
import 'package:niman/src/capture/fetch/page_charset.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;

/// A page captured: its note, whether an article was found in it, and how
/// many of its pictures are now in the library.
typedef WebCapture = ({CapturedNote note, bool readable, int pictures});

/// Captures the page at [url] for the library at [libraryRoot].
///
/// [downloadPictures] puts the article's pictures in [attachmentsFolder];
/// without it the note points at them on the web. [unreadableNotice] is
/// the Markdown a page with no article gets; [tags], [linkType] and
/// [captured] are the note's. Throws a [PageFetchException] when the page
/// cannot be downloaded.
Future<WebCapture> captureWebPage(
  Uri url, {
  required String libraryRoot,
  required String attachmentsFolder,
  required String unreadableNotice,
  required DateTime captured,
  bool downloadPictures = true,
  List<String> tags = const [],
  LinkType linkType = LinkType.wikilink,
  PageFetchLimits limits = const PageFetchLimits(),
}) => Isolate.run(() async {
  final fetched = await fetchPage(url, limits: limits);
  final page = readPage(
    decodePage(fetched.bytes, contentType: fetched.contentType),
    fetched.url,
  );
  final pictures = downloadPictures
      ? await downloadPicturesOf(page, libraryRoot, attachmentsFolder)
      : const <String, String>{};
  return (
    note: captureNote(
      page,
      captured: captured,
      unreadableNotice: unreadableNotice,
      pictures: pictures,
      tags: tags,
      linkType: linkType,
    ),
    readable: page.readable,
    pictures: pictures.length,
  );
});

/// Downloads the pictures [page]'s note shows into the attachments folder.
Future<Map<String, String>> downloadPicturesOf(
  PageReading page,
  String libraryRoot,
  String attachmentsFolder,
) => downloadPictures(
  picturesOf(page),
  libraryRoot: libraryRoot,
  attachmentsFolder: attachmentsFolder,
);
