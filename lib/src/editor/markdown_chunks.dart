import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:re_editor/re_editor.dart';

/// Heading-based code chunks (T-M2-07): re_editor's fold model over the
/// tokenizer's outline.
///
/// A chunk covers a heading's section: lines `[headingLine, terminus)` where
/// terminus is the next same-or-higher heading (or the end of the document).
/// re_editor draws its fold indicator for each chunk and handles the
/// collapse/expand itself; taps land through [DefaultCodeChunkIndicator].
///
/// The analysis runs in re_editor's isolate per buffer change using Niman's
/// tokenizer (the same one the highlight and the outline use), so a `#`
/// inside a code fence, a math block or frontmatter is never a fold anchor.
/// Above [lineLimit] the analyzer is a no-op: the whole-document tokenize
/// (~80 ms at 931K, per keystroke, background) is not worth it for fold
/// markers on monster notes — the outline panel still works (the highlight
/// is incremental; only folding is capped).
final class MarkdownChunkAnalyzer implements CodeChunkAnalyzer {
  /// Creates the analyzer.
  const new({this.lineLimit = 20000});

  /// Lines above which the analyzer returns no chunks.
  final int lineLimit;

  @override
  List<CodeChunk> run(CodeLines codeLines) {
    if (codeLines.length > lineLimit) return const [];
    final document = HighlightDocument.fromText(
      codeLines.asString(TextLineBreak.lf, false),
    );
    final outline = outlineOf(document.lines);
    final chunks = <CodeChunk>[];
    for (var i = 0; i < outline.length; i++) {
      final heading = outline[i];
      var terminus = codeLines.length;
      for (var j = i + 1; j < outline.length; j++) {
        if (outline[j].level <= heading.level) {
          terminus = outline[j].line;
          break;
        }
      }
      // A section with no real content cannot fold — only blank lines
      // between the headings is not a section body.
      if (terminus - heading.line - 1 >= 2) {
        chunks.add(CodeChunk(heading.line, terminus));
      }
    }
    return chunks;
  }
}
