import 'package:niman/src/ocr/ocr_language.dart';

/// Where a recognition stands.
enum OcrJobPhase {
  /// Waiting for the job before it.
  queued,

  /// Fetching the engine or a language first.
  downloading,

  /// Reading the pages.
  recognizing,

  /// Writing the sidecar.
  writing,

  /// The sidecar is written.
  done,

  /// It stopped on an error.
  failed,

  /// Cancelled.
  cancelled,
}

/// One file to recognize (#594), and how far it got.
final class OcrJob {
  /// The job recognizing [path] (library-relative) in [languages], the
  /// pages [pages] (1-based; null for all of them).
  new({
    required this.id,
    required this.path,
    required this.languages,
    this.pages,
  });

  /// The queue's id for it.
  final int id;

  /// The file, relative to the library.
  final String path;

  /// What it is read in, the default language first.
  final List<OcrLanguage> languages;

  /// The pages asked for; null for every page.
  final List<int>? pages;

  /// Where it stands.
  OcrJobPhase phase = OcrJobPhase.queued;

  /// Pages read so far.
  int pagesDone = 0;

  /// Pages to read, once the file is open; 0 before.
  int pagesTotal = 0;

  /// The sidecar written, library-relative, once [OcrJobPhase.done].
  String? sidecar;

  /// Words recognized, once done.
  int words = 0;

  /// Why it failed, short and loggable.
  String? error;

  /// Whether it is over, one way or another.
  bool get finished => switch (phase) {
    OcrJobPhase.done || OcrJobPhase.failed || OcrJobPhase.cancelled => true,
    _ => false,
  };

  /// The page being read, 1-based among those asked for.
  int get currentPage => pagesDone + 1;

  /// Progress in 0..1.
  double get fraction => pagesTotal == 0 ? 0 : pagesDone / pagesTotal;

  /// The `+`-joined codes Tesseract loads (`ita+eng`).
  String get languageCodes => languages.map((l) => l.code).join('+');

  @override
  String toString() => 'ocr#$id $path [$languageCodes] ${phase.name}';
}
