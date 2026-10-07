import 'package:niman/src/library/session.dart';
import 'package:niman/src/ocr/ocr_language.dart';
import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/attachment_view.dart' show pictureExtensions;
import 'package:path/path.dart' as p;

/// What a file's view needs for text recognition (#594): the jobs, the
/// library they write into, and the shell's Recognize text, which asks
/// how and queues the job.
final class OcrFileActions {
  /// The actions over [queue], for the library at [root].
  const new({
    required this.queue,
    required this.root,
    required this.ops,
    required this.recognize,
    required this.openNote,
    required this.recognizeAgain,
  });

  /// The recognition jobs.
  final OcrQueue queue;

  /// The library's root, absolute.
  final String root;

  /// The library's operations, which read a file's sidecar (#595).
  final NoteOperations ops;

  /// Opens a note (the sidecar, as a note).
  final void Function(String path) openNote;

  /// Reads `page` of the file at `path` (library-relative) again in
  /// `languages`, asking nothing: the sidecar's lines there lost their
  /// places (#596).
  final void Function(String path, int page, List<OcrLanguage> languages)
  recognizeAgain;

  /// Recognizes a file (library-relative): a PDF with its page count and
  /// the page read, or a picture.
  final void Function(String path, {int? page, int? pageCount}) recognize;

  /// [absolute] relative to [root], with `/` between its segments as the
  /// library writes paths.
  String relative(String absolute) =>
      p.split(p.relative(absolute, from: root)).join('/');
}

/// Whether the file at [path] can be recognized: a PDF, or a picture.
bool isRecognizableFile(String path) {
  final extension = p.extension(path).toLowerCase();
  return extension == '.pdf' || pictureExtensions.contains(extension);
}
