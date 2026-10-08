/// What the capture sheet closes with (#531): a page to capture in the
/// background, or a quote to keep.
library;

import 'package:niman/src/capture/shared_page.dart';
import 'package:niman/src/ui/capture/background_capture.dart';
import 'package:niman/src/ui/capture/capture_reading_task.dart';

/// What the sheet was closed with.
sealed class CaptureSheetResult {
  const new();
}

/// A page to capture: its reading, under way or done, and the choices.
final class CapturePageChosen extends CaptureSheetResult {
  /// The page [reading] reads, saved as [chosen].
  const new(this.reading, this.chosen);

  /// The page's reading; the capture's from here on.
  final CaptureReadingTask reading;

  /// Where and how the note is made.
  final CaptureChosen chosen;
}

/// A quote to keep: appended to [appendTo], or else a new note in
/// [folder] with [tags].
final class CaptureQuoteChosen extends CaptureSheetResult {
  /// [quote], kept as chosen.
  const new(
    this.quote, {
    required this.folder,
    required this.tags,
    this.appendTo,
  });

  /// What was shared.
  final SharedQuote quote;

  /// The note the quote is appended to, library-relative; null makes a
  /// new note.
  final String? appendTo;

  /// The folder a new note goes in.
  final String folder;

  /// A new note's tags.
  final List<String> tags;
}
