/// A browser that runs a captured page's scripts and gives the tree it ends
/// with (#531): what the capture asks when the download has too little
/// text — a page that builds itself with scripts, or a charset only a
/// browser decodes.
///
/// On the desktop it is the engine the PDF export already finds
/// ([findPdfEngine]: Edge on Windows, a Chromium on `PATH` on Linux), run
/// headless with `--dump-dom` in a throwaway profile, so nothing of the
/// user's own browser — profile, sign-ins, cookies — is ever used. On
/// Android it is a WebView of the app's own ([WebViewPageBrowser]).
library;

import 'dart:io';

import 'package:niman/src/capture/browser/webview_page_browser.dart';
import 'package:niman/src/core/process_run.dart';
import 'package:niman/src/export/pdf_printer.dart';

/// Runs a page and gives its DOM.
abstract interface class PageBrowser {
  /// The DOM of the page at [url] once its scripts have run, as HTML; null
  /// when the browser could not give one.
  Future<String?> read(Uri url);
}

/// The most a browser's DOM may weigh, in characters.
const int maxBrowserDomCharacters = 20 * 1024 * 1024;

/// How long a browser may take over one page.
const Duration browserReadTimeout = Duration(seconds: 45);

/// A desktop engine, run headless.
final class EnginePageBrowser implements PageBrowser {
  /// Reads pages with the engine at [engine], running it with [run].
  const new(this.engine, {this.run = runProcess});

  /// The engine's executable.
  final String engine;

  /// Runs the engine's process: the real one, or a test's.
  final ProcessRunner run;

  /// The flags [url] is read with, in [profile].
  static List<String> flags(Uri url, String profile) => <String>[
    '--headless=new',
    '--disable-gpu',
    '--user-data-dir=$profile',
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-extensions',
    '--mute-audio',
    // The text is what is read; the pictures are downloaded afterwards,
    // from the addresses the DOM names.
    '--blink-settings=imagesEnabled=false',
    // The page's timers are run forward, up to this much page time, before
    // the DOM is dumped.
    '--virtual-time-budget=10000',
    '--dump-dom',
    url.toString(),
  ];

  @override
  Future<String?> read(Uri url) async {
    if (!(url.isScheme('http') || url.isScheme('https'))) return null;
    final profile = await Directory.systemTemp.createTemp('niman-capture-');
    try {
      final answer = await run(
        engine,
        flags(url, profile.path),
        timeout: browserReadTimeout,
        outputLimit: maxBrowserDomCharacters,
      );
      if (answer.exit != 0 || answer.stdout.trim().isEmpty) return null;
      return answer.stdout;
    } on Object {
      // A refused start, or a page past its time: no DOM.
      return null;
    } finally {
      try {
        await profile.delete(recursive: true);
      } on FileSystemException {
        // A file the engine still holds: the temp folder's to clear.
      }
    }
  }
}

/// The browser this machine reads pages with, or null when it has none —
/// a Linux desktop without a Chromium. Call it on the UI isolate: the
/// WebView's channel needs its token.
Future<PageBrowser?> findPageBrowser() async {
  if (Platform.isAndroid) return WebViewPageBrowser.forThisIsolate();
  final engine = await findPdfEngine();
  return engine == null ? null : EnginePageBrowser(engine);
}
