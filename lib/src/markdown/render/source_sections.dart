import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Where the sections the source view folds end: a heading's, up to the next
/// heading of its level or above, and a `columns` block's (#729).
///
/// `SourceFolds` is the arithmetic of what is folded; where a section ends
/// is the view's question, because only its tokenizer knows what a heading
/// is — so the view hands in the buffer, the blocks and the lines' runs, and
/// this keeps the answers for the buffer's revision.
final class SourceSections {
  /// The sections of [_buffer]'s note, its lines' blocks [_blockOf] and runs
  /// [_tokensOf] read as the view reads them.
  new({required this._buffer, required this._blockOf, required this._tokensOf});

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The block holding a line, as the scan behind the colours has it, or
  /// null while there is no scan.
  final Block? Function(int line) _blockOf;

  /// The runs a line is drawn with.
  final List<Token> Function(int line) _tokensOf;

  /// Where each heading's section ends, as far as it has been asked, for the
  /// buffer revision [_endsRevision].
  final Map<int, int?> _ends = <int, int?>{};
  int _endsRevision = -1;

  /// The heading level of line [line], or null when it is not a heading.
  int? headingLevel(int line) {
    if (!_buffer().lineAt(line).startsWith('#')) return null;
    final tokens = _tokensOf(line);
    if (tokens.isEmpty ||
        tokens.first.kind != TokenKind.headingMarker ||
        tokens.first.start != 0) {
      return null;
    }
    // The outline's own rule (`outline.dart`): the marker's length.
    return tokens.first.end - tokens.first.start;
  }

  /// Where the section under the heading on [line] ends — the next heading
  /// of its level or above, or the note's end — or null when [line] is not a
  /// heading.
  int? endOf(int line) {
    final revision = _buffer().revision;
    if (revision != _endsRevision) {
      _ends.clear();
      _endsRevision = revision;
    }
    if (_ends.containsKey(line)) return _ends[line];
    final block = _blockOf(line);
    if (block?.divRole == DivRole.opensColumns) {
      return _ends[line] = _columnsEnd(line, block!.divDepth);
    }
    final level = headingLevel(line);
    int? end;
    if (level != null) {
      final count = _buffer().lineCount;
      // A heading in a column folds its section inside the column (#729):
      // a block in fewer divs ends it, and a heading in more does not.
      final depth = block?.divDepth ?? 0;
      end = count;
      for (var at = line + 1; at < count; at++) {
        final within = _blockOf(at)?.divDepth ?? 0;
        if (within < depth) {
          end = at;
          break;
        }
        final other = headingLevel(at);
        if (other != null && other <= level && within == depth) {
          end = at;
          break;
        }
      }
    }
    return _ends[line] = end;
  }

  /// Where the `columns` block opened on [line], [depth] divs in, ends
  /// (#729): past its closer, or at the first line outside it when its
  /// container ends it.
  int _columnsEnd(int line, int depth) {
    final count = _buffer().lineCount;
    var at = line + 1;
    while (at < count) {
      final block = _blockOf(at);
      if (block == null) break;
      if (block.divDepth <= depth) {
        return block.divRole == DivRole.closesColumns && block.divDepth == depth
            ? block.endLine
            : block.startLine;
      }
      at = block.endLine;
    }
    return count;
  }

  /// Where the heading on [line] would fold to, when it has a section worth
  /// folding: two lines or more under it, the legacy editor's rule.
  int? foldableEnd(int line) {
    final end = endOf(line);
    if (end == null || end - line - 1 < 2) return null;
    return end;
  }
}
