import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/table/markdown_table.dart';

/// A piece of a line a point is in — or nearest — the paragraph that draws
/// it, and the point in that paragraph's own coordinates.
typedef SourcePieceHit = ({
  SourcePiece piece,
  RenderParagraph paragraph,
  Offset local,
});

/// The paragraphs the source view's lines are drawn in, by line: what a tap
/// asks where an offset is, and the caret asks for its rectangle.
///
/// Only mounted lines keep a key: a long scroll forgets the lines it left,
/// which is what keeps this from growing with the note.
final class SourceParagraphs {
  /// The paragraph of each line a frame has built, so a tap can ask the line
  /// it landed on where an offset is, and the caret can ask its own line for
  /// the rectangle.
  final Map<int, GlobalKey> _lineKeys = <int, GlobalKey>{};

  /// The keys of a wrapped table row's fragments past its first, by line and
  /// fragment: a row laid out in fitted columns is several paragraphs, and
  /// the caret and a tap have to find the one they are in.
  final Map<(int, int), GlobalKey> _fragmentKeys = <(int, int), GlobalKey>{};

  /// The lines that hold a key: the ones a frame built, less the ones a
  /// long scroll made it forget.
  Iterable<int> get lines => _lineKeys.keys;

  /// The paragraph of line [line], when a frame has built it.
  RenderParagraph? paragraphAt(int line) {
    final object = _lineKeys[line]?.currentContext?.findRenderObject();
    return object is RenderParagraph ? object : null;
  }

  /// The key of line `index`'s paragraph, created on first use.
  GlobalKey keyFor(int index) {
    final key = _lineKeys.putIfAbsent(index, GlobalKey.new);
    if (_lineKeys.length > 512) {
      _lineKeys.removeWhere((_, key) => key.currentContext == null);
    }
    return key;
  }

  /// The key of fragment [at] of line [line] — the line's own paragraph for
  /// its first, and one per fragment of a table row laid out in fitted
  /// columns — created on first use.
  GlobalKey fragmentKey(int line, int at) {
    if (at == 0) return keyFor(line);
    final key = _fragmentKeys.putIfAbsent((line, at), GlobalKey.new);
    if (_fragmentKeys.length > 512) {
      _fragmentKeys.removeWhere((_, key) => key.currentContext == null);
    }
    return key;
  }

  /// The paragraph [key] draws, when a frame has laid it out.
  static RenderParagraph? renderOf(GlobalKey key) {
    final object = key.currentContext?.findRenderObject();
    return object is RenderParagraph && object.attached && object.hasSize
        ? object
        : null;
  }

  /// The piece of a line a caret at [local] is drawn in: the one whose
  /// source holds it. A wrapped row's pieces hold only its
  /// cells' text, so an offset in the room round them — a pipe, the spaces
  /// by it — is its cell's, on its side of the pipe
  /// (`MarkdownTable.cellRangesOf`), and drawn at that cell's nearer edge:
  /// the room before a pipe at the end of the cell on its left, the room
  /// after it at the start of the one on its right. That is the side an
  /// unwrapped row draws it on, the room's characters spread evenly between
  /// the two cells' text. [text] reads the line's text, asked only for an
  /// offset in that room.
  static SourcePiece? pieceHolding(
    List<SourcePiece> pieces,
    String Function() text,
    int local,
  ) {
    for (final piece in pieces) {
      if (local >= piece.start && local <= piece.end) return piece;
    }
    if (pieces.isEmpty) return null;
    final cells = MarkdownTable.cellRangesOf(text());
    var (from, to) = local < cells.first.$1 ? cells.first : cells.last;
    for (final (start, end) in cells) {
      if (local >= start && local <= end) {
        (from, to) = (start, end);
        break;
      }
    }
    // The cell's pieces are contiguous and none holds [local]: it is before
    // all of them or past all of them.
    SourcePiece? before;
    SourcePiece? after;
    for (final piece in pieces) {
      if (piece.start < from || piece.end > to) continue;
      if (piece.end < local && (before == null || piece.end > before.end)) {
        before = piece;
      }
      if (piece.start > local && (after == null || piece.start < after.start)) {
        after = piece;
      }
    }
    return before ?? after ?? pieces.first;
  }

  /// The piece of a wrapped row [global] is *in*, and where in it the point
  /// lands, or null when it is in none of them: the room between two columns
  /// is nobody's, and a point outside the row belongs to a line the caller
  /// has not asked yet.
  static SourcePieceHit? pieceAt(List<SourcePiece> pieces, Offset global) {
    for (final piece in pieces) {
      final paragraph = renderOf(piece.key);
      if (paragraph == null) continue;
      final local = paragraph.globalToLocal(global);
      if (local.dx < 0 ||
          local.dx >= paragraph.size.width ||
          local.dy < 0 ||
          local.dy >= paragraph.size.height) {
        continue;
      }
      return (piece: piece, paragraph: paragraph, local: local);
    }
    return null;
  }

  /// The fragment of a wrapped row under [global], and where in it the point
  /// lands: the piece whose box holds it, or — under none, in the padding
  /// between two columns or below the last line — the nearest one, the
  /// vertical distance weighing more than the horizontal.
  static SourcePieceHit? pieceUnder(List<SourcePiece> pieces, Offset global) {
    SourcePieceHit? best;
    var bestDistance = double.infinity;
    for (final piece in pieces) {
      final paragraph = renderOf(piece.key);
      if (paragraph == null) continue;
      final local = paragraph.globalToLocal(global);
      final dx = local.dx < 0
          ? -local.dx
          : (local.dx > paragraph.size.width
                ? local.dx - paragraph.size.width
                : 0.0);
      final dy = local.dy < 0
          ? -local.dy
          : (local.dy > paragraph.size.height
                ? local.dy - paragraph.size.height
                : 0.0);
      if (dx == 0 && dy == 0) {
        return (piece: piece, paragraph: paragraph, local: local);
      }
      final distance = dx + dy * 8;
      if (distance >= bestDistance) continue;
      bestDistance = distance;
      best = (
        piece: piece,
        paragraph: paragraph,
        local: Offset(
          local.dx.clamp(0, paragraph.size.width),
          local.dy.clamp(0, paragraph.size.height),
        ),
      );
    }
    return best;
  }
}
