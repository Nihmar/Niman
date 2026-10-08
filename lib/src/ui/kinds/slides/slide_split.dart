import 'package:meta/meta.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// One slide of a `type: slides` note (#534): what it shows and what the
/// presenter says over it.
@immutable
final class Slide {
  /// Creates a slide from its Markdown and its speaker notes.
  const new({required this.markdown, this.notes});

  /// The slide's own Markdown: the lines between two breaks, the speaker
  /// notes left out.
  final String markdown;

  /// The speaker notes, `Note:` taken off, or null when the slide has none.
  final String? notes;

  @override
  bool operator ==(Object other) =>
      other is Slide && other.markdown == markdown && other.notes == notes;

  @override
  int get hashCode => Object.hash(markdown, notes);

  @override
  String toString() => 'Slide($markdown | $notes)';
}

/// The `Note:` that opens a slide's speaker notes (reveal.js's word).
final RegExp _notesLead = RegExp(r'^note:\s?', caseSensitive: false);

/// Splits a slides note's [text] into its slides.
///
/// A slide break is a thematic break as CommonMark reads one, taken from
/// the block scan the read view makes: a `---` in a code fence stays code,
/// `Text` over `---` stays a heading, and a break inside a list or a quote
/// belongs to it. The frontmatter is no slide. The speaker notes are the
/// top-level paragraph that starts with `Note:` and everything after it up
/// to the next break. A note without a break is one slide; two breaks in a
/// row make an empty one.
List<Slide> splitSlides(String text) {
  final buffer = SourceBuffer.fromText(text);
  final blocks = DocumentScan.of(buffer).blocks;
  final slides = <Slide>[];
  var start = 0;
  int? notes;
  void close(int end) {
    String lines(int from, int to) =>
        [for (var line = from; line < to; line++) buffer.lineAt(line)]
            .join('\n')
            .trim();
    final notesStart = notes;
    slides.add(
      Slide(
        markdown: lines(start, notesStart ?? end),
        notes: notesStart == null
            ? null
            : lines(notesStart, end).replaceFirst(_notesLead, ''),
      ),
    );
  }

  for (final block in blocks) {
    final topLevel = block.quoteDepth == 0 && block.listDepth < 0;
    if (block.kind == BlockKind.frontmatter) {
      start = block.endLine;
    } else if (block.kind == BlockKind.thematicBreak && topLevel) {
      close(block.startLine);
      start = block.endLine;
      notes = null;
    } else if (block.kind == BlockKind.paragraph &&
        topLevel &&
        notes == null &&
        _notesLead.hasMatch(buffer.lineAt(block.startLine))) {
      notes = block.startLine;
    }
  }
  close(buffer.lineCount);
  return slides;
}
