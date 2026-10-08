/// Capturing a web page as a note (#531), every step off the UI isolate:
/// the page downloaded, decoded and read, its pictures downloaded into the
/// attachments folder, and its note written out as text — for the caller
/// to create in the library.
///
/// When the download has too little text — no article, or a charset only a
/// browser decodes — the page is run in a browser ([PageBrowser]) and read
/// again; with no browser, or none that does better, the note is the page
/// as downloaded.
library;

import 'dart:isolate';

import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/capture_pictures.dart';
import 'package:niman/src/capture/fetch/page_charset.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;

/// A page captured: its note, whether an article was found in it, whether
/// a browser had to run the page for it, and how many of its pictures are
/// now in the library.
typedef WebCapture = ({
  CapturedNote note,
  bool readable,
  bool ranBrowser,
  int pictures,
});

/// Captures the page at [url] for the library at [libraryRoot].
///
/// [downloadPictures] puts the article's pictures in [attachmentsFolder];
/// without it the note points at them on the web. [unreadableNotice] is
/// the Markdown a page with no article gets; [tags], [linkType] and
/// [captured] are the note's. [browser] runs a page that has too little
/// text as downloaded ([findPageBrowser], on the UI isolate); null reads
/// such a page as it is. Throws a [PageFetchException] when the page cannot
/// be downloaded.
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
  PageBrowser? browser,
}) => Isolate.run(() async {
  final fetched = await fetchPage(url, limits: limits);
  var page = readPage(
    decodePage(fetched.bytes, contentType: fetched.contentType),
    fetched.url,
  );
  var ranBrowser = false;
  if (!page.readable && browser != null) {
    final dom = await browser.read(fetched.url);
    if (dom != null) {
      final again = readPage(dom, fetched.url);
      ranBrowser = again.readable;
      if (again.readable) page = again;
    }
  }
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
    ranBrowser: ranBrowser,
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
