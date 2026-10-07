import 'package:niman/src/ocr/ocr_queue.dart';
import 'package:niman/src/ui/attachment_view.dart' show pictureExtensions;
import 'package:path/path.dart' as p;

/// What a file's view needs for text recognition (#594): the jobs, the
/// library they write into, and the shell's Recognize text, which asks
/// how and queues the job.
final class OcrFileActions {
  /// The actions over [queue], for the library at [root].
  const new({required this.queue, required this.root, required this.recognize});

  /// The recognition jobs.
  final OcrQueue queue;

  /// The library's root, absolute.
  final String root;

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
