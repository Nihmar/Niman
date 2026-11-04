import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/render/block_height_map.dart';
import 'package:niman/src/markdown/render/live_hosts.dart';
import 'package:niman/src/markdown/render/source_geometry.dart';
import 'package:niman/src/markdown/render/source_paragraphs.dart';
import 'package:niman/src/markdown/render/source_pieces.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// Where a point over the source view lands in the note: asked of the lines
/// a frame drew — their paragraphs know where they were painted — and, for
/// a point no drawn line is under, of the height map.
///
/// A tap lands through the same paragraph's `getPositionForOffset` the
/// caret's rectangle comes from, so the two agree by construction.
final class SourceHitTest {
  /// The hit test of [_buffer]'s lines, drawn in [_paragraphs].
  new({
    required this._buffer,
    required this._hosts,
    required this._noteBox,
    required this._scroll,
    required this._heights,
    required this._paragraphs,
    required this._pieces,
    required this._geometry,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The blocks drawn side by side at the pane's width.
  final LiveHosts _hosts;

  /// The box the note is drawn in.
  final RenderBox? Function() _noteBox;

  /// The note's scroll.
  final ScrollController Function() _scroll;

  /// The heights the rows are placed with.
  final BlockHeightMap Function() _heights;

  /// The paragraphs the lines are drawn in.
  final SourceParagraphs _paragraphs;

  /// The pieces a line is drawn in.
  final SourcePieces _pieces;

  /// Where the lines are drawn.
  final SourceGeometry _geometry;

  /// The offset a tap at [global] lands on, or null when it lands outside a
  /// line.
  int? offsetAt(Offset global) =>
      paintedOffsetAt(global) ?? mappedOffsetAt(global);

  /// The offset under [global] on a line a frame has drawn, asked of the lines
  /// themselves — their paragraphs know where they were painted, so no map
  /// has to agree with them — or null when no drawn line is under it.
  int? paintedOffsetAt(Offset global) {
    final buffer = _buffer();
    final x = _hosts.layouts.isEmpty
        ? null
        : _noteBox()?.globalToLocal(global).dx;
    for (final line in _paragraphs.lines) {
      if (line >= buffer.lineCount) continue;
      // Side by side, two columns' lines hold the same height: a line of a
      // column holds a point only across its column (#729).
      if (x != null && !_geometry.inColumnOf(line, x)) continue;
      final pieces = _pieces.of(line);
      if (pieces.length == 1) {
        final object = SourceParagraphs.renderOf(pieces.first.key);
        if (object == null) continue;
        final local = object.globalToLocal(global);
        if (local.dy < 0 || local.dy >= object.size.height) continue;
        return buffer.offsetOfLine(line) +
            pieces.first.start +
            object.getPositionForOffset(local).offset;
      }
      // A wrapped table row: the piece the point is in, which of the row's
      // several paragraphs it is. A point in none of them — the room
      // between the columns, or below the row — is not this line's: the
      // next one is asked, and the height map answers for a point no drawn
      // line holds at all.
      final hit = SourceParagraphs.pieceAt(pieces, global);
      if (hit == null) continue;
      return buffer.offsetOfLine(line) +
          hit.piece.start +
          hit.paragraph.getPositionForOffset(hit.local).offset;
    }
    return null;
  }

  /// The offset under [global] as the height map places the lines: for a
  /// point no drawn line is under — above the first, below the last.
  int? mappedOffsetAt(Offset global) {
    final box = _noteBox();
    if (box == null || _heights().length == 0) return null;
    final buffer = _buffer();
    // The map says which line a y falls in — above the first line is the
    // first, below the last is the last, so a tap under a short note puts the
    // caret at its end rather than nowhere.
    final point = box.globalToLocal(global);
    final line = _geometry.lineAtY(point.dy + _scroll().offset, point.dx);
    final pieces = _pieces.of(line);
    // The point in the *paragraph's own* coordinates, from its own transform:
    // the insets, the gutter and a live-mode indent are all in that transform,
    // so none of them has to be subtracted by hand. (Doing it by hand
    // subtracted the gutter twice, and the caret landed a gutter's width left
    // of the finger.)
    if (pieces.length > 1) {
      final hit = SourceParagraphs.pieceUnder(pieces, global);
      if (hit == null) return null;
      return buffer.offsetOfLine(line) +
          hit.piece.start +
          hit.paragraph.getPositionForOffset(hit.local).offset;
    }
    final paragraph = SourceParagraphs.renderOf(pieces.first.key);
    if (paragraph == null || !paragraph.attached) return null;
    final position = paragraph.getPositionForOffset(
      paragraph.globalToLocal(global),
    );
    return buffer.offsetOfLine(line) + pieces.first.start + position.offset;
  }
}
