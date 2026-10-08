/// Capturing a web page as a note (#531), in two steps the capture's
/// screens stand between: [readWebPage] downloads and reads the page —
/// running it in a browser when the download has too little text — and
/// says each step as it happens; [saveWebCapture] downloads its pictures
/// into the attachments folder and writes its note, with the title, the
/// tags and the choice of pictures the user made. The caller creates the
/// note in the library.
///
/// The download, the reading and the pictures run off the UI isolate; the
/// browser is a process (desktop) or a platform view (Android), awaited.
library;

import 'dart:isolate';

import 'package:niman/src/capture/browser/page_browser.dart';
import 'package:niman/src/capture/capture_note.dart';
import 'package:niman/src/capture/capture_pictures.dart';
import 'package:niman/src/capture/fetch/page_charset.dart';
import 'package:niman/src/capture/fetch/page_fetch.dart';
import 'package:niman/src/capture/page_reading.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;

/// Where the reading of a page is.
enum CaptureStage {
  /// The page is downloading.
  downloading,

  /// The download had too little text: the page runs in a browser.
  runningBrowser,
}

/// A step of reading, as the dialog and the notification say it: the
/// stage, and what the download gave so far — its bytes and the words
/// found in it.
typedef CaptureProgress = ({CaptureStage stage, int bytes, int words});

/// A page read, ready to save: what it was read to, how many bytes the
/// download had, and whether a browser had to run it.
typedef WebReading = ({PageReading page, int bytes, bool ranBrowser});

/// Reads the page at [url]. [browser] runs a page with too little text
/// ([findPageBrowser]); null reads it as downloaded. [onProgress] hears
/// each step. Throws a [PageFetchException] when the page cannot be
/// downloaded.
Future<WebReading> readWebPage(
  Uri url, {
  PageBrowser? browser,
  void Function(CaptureProgress progress)? onProgress,
  PageFetchLimits limits = const PageFetchLimits(),
}) async {
  onProgress?.call((stage: CaptureStage.downloading, bytes: 0, words: 0));
  final first = await Isolate.run(() async {
    final fetched = await fetchPage(url, limits: limits);
    final text = decodePage(fetched.bytes, contentType: fetched.contentType);
    return (
      page: readPage(text, fetched.url),
      bytes: fetched.bytes.length,
      words: text == null ? 0 : _textWords(text),
    );
  });
  if (first.page.readable || browser == null) {
    return (page: first.page, bytes: first.bytes, ranBrowser: false);
  }
  onProgress?.call((
    stage: CaptureStage.runningBrowser,
    bytes: first.bytes,
    words: first.words,
  ));
  final pageUrl = first.page.url;
  final dom = await browser.read(pageUrl);
  if (dom != null) {
    final again = await Isolate.run(() => readPage(dom, pageUrl));
    if (again.readable) {
      return (page: again, bytes: first.bytes, ranBrowser: true);
    }
  }
  return (page: first.page, bytes: first.bytes, ranBrowser: false);
}

/// The words a page's text shows, its markup left out: what "only 40
/// words found" counts.
int _textWords(String html) => RegExp(r'\S+')
    .allMatches(
      html
          .replaceAll(
            RegExp(
              r'<(script|style)\b[^>]*>.*?</\1>',
              caseSensitive: false,
              dotAll: true,
            ),
            ' ',
          )
          .replaceAll(RegExp('<[^>]*>'), ' '),
    )
    .length;

/// Writes the note of [page] for the library at [libraryRoot]: its
/// pictures downloaded into [attachmentsFolder] unless [downloadPictures]
/// is off, under [title] when one is given. [unreadableNotice] is the
/// Markdown a page with no article gets; [tags], [linkType] and
/// [captured] are the note's.
Future<({CapturedNote note, int pictures})> saveWebCapture(
  PageReading page, {
  required String libraryRoot,
  required String attachmentsFolder,
  required String unreadableNotice,
  required DateTime captured,
  String? title,
  bool downloadPictures = true,
  List<String> tags = const [],
  LinkType linkType = LinkType.wikilink,
}) {
  final named = title == null || title.trim().isEmpty
      ? page
      : page.withTitle(title.trim());
  return Isolate.run(() async {
    final pictures = downloadPictures
        ? await downloadPicturesOf(named, libraryRoot, attachmentsFolder)
        : const <String, String>{};
    return (
      note: captureNote(
        named,
        captured: captured,
        unreadableNotice: unreadableNotice,
        pictures: pictures,
        tags: tags,
        linkType: linkType,
      ),
      pictures: pictures.length,
    );
  });
}

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
