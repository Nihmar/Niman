import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/markdown/active_formats.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/caret_spot.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/source_caret_rect.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The source view's caret as its lines and the shell's toolbar are told
/// it: which line holds it and the run it is in ([spot]), its rectangle in
/// that line's paragraph ([rect]) and how far the piece it is drawn in
/// stands from the line's box ([shift]), and the formats on at it.
///
/// The view owns it and asks it to [measure] whenever the caret moved or
/// its line was laid out anew; it reads the view's layout through the
/// narrow callbacks it is handed.
final class SourceCaret {
  /// The caret of the view's [_buffer] and [_selection].
  new({
    required this._buffer,
    required this._selection,
    required this._mounted,
    required this._fragmentAt,
    required this._width,
    required this._caretOnLine,
    required this._activeItems,
    required this._tokensOf,
    required this._measured,
  });

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// Whether the view is still mounted.
  final bool Function() _mounted;

  /// The piece of a line a caret at an offset local to it is drawn in, and
  /// its paragraph when a frame has built it.
  final (SourcePiece?, RenderParagraph?) Function(int line, int local)
  _fragmentAt;

  /// How wide the caret is drawn.
  final double Function() _width;

  /// Tells the brackets typed in pairs which line the caret is on.
  final void Function(int line) _caretOnLine;

  /// The shell's toolbar's formats, or null.
  final ValueNotifier<Set<ToolbarItem>>? Function() _activeItems;

  /// The runs on a line, for the formats on at the caret.
  final List<Token> Function(int line) _tokensOf;

  /// The caret was measured and has a rectangle: the platform is told.
  final VoidCallback _measured;

  /// The caret rectangle in the caret line's coordinates, recomputed after the
  /// frame that laid that line out. A notifier rather than `setState`: neither
  /// the blink nor the measurement may rebuild the note.
  final ValueNotifier<Rect?> rect = ValueNotifier<Rect?>(null);

  /// Where the caret's fragment sits in the line's box, beyond the indent
  /// the painter knows about: a wrapped table row draws its cells away from
  /// the line's left edge and below its first visual line, so the caret
  /// rectangle — measured in the fragment's own paragraph — is shifted by
  /// this before it is painted.
  final ValueNotifier<Offset> shift = ValueNotifier<Offset>(Offset.zero);

  /// Where the caret is, as the lines that draw it care: which line holds it,
  /// and the run of non-whitespace it sits in on that line.
  ///
  /// One value rather than two notifiers, so a caret move that crosses a word
  /// boundary repaints the two lines involved at once and a move *inside* a
  /// run repaints nothing: a `ValueNotifier` whose new value compares equal
  /// does not notify, and a run's own coordinates do not change while the
  /// caret stays in it. That is what keeps the per-word reveal off the frame
  /// budget — a keystroke inside a word tells no line anything.
  final ValueNotifier<CaretSpot> spot = ValueNotifier<CaretSpot>(
    const CaretSpot(0, 0, 0),
  );

  /// How many times the caret was measured.
  int get measures => _measures;
  int _measures = 0;

  int get _lineCount => _buffer().lineCount;

  /// The line the caret sits on, or -1.
  int get line {
    final line = _buffer().lineOf(_selection().extent);
    return line < 0 || line >= _lineCount ? -1 : line;
  }

  /// The caret's line and the run of non-whitespace it is in on that line, as
  /// the lines are told it ([CaretSpot]).
  ///
  /// [offset] is the caret asked about, defaulting to the selection's own end.
  /// It is passed explicitly where the caller already knows where the caret is
  /// going — a move publishes the *destination*, and the widget's own
  /// selection may still be the old one until the shell that owns it rebuilds.
  ///
  /// The run is read from the line's own text rather than off the styled
  /// tokens: the reveal compares a *marker* against it, and the markers belong
  /// to the run (`runAround`), so the two agree by construction.
  CaretSpot spotOf([int? offset]) {
    final buffer = _buffer();
    final at = offset ?? _selection().extent;
    final line = buffer.lineOf(at);
    if (line < 0 || line >= _lineCount) return const CaretSpot(-1, 0, 0);
    final text = buffer.lineAt(line);
    final column = (at - buffer.offsetOfLine(line)).clamp(0, text.length);
    final (from, to) = runAround(text, column);
    return CaretSpot(line, from, to);
  }

  /// Where the caret is, from the caret line's own layout.
  void measure() {
    _measures++;
    final line = this.line;
    // Every selection change comes through here, so this is the one place the
    // lines hear which of them holds the caret and which of its words, and the
    // toolbar hears which formats are on at it.
    final spot = spotOf();
    this.spot.value = spot;
    // A closing bracket a pair wrote is stepped over only on its own line.
    _caretOnLine(line);
    publishActive(spot);
    if (line < 0) {
      rect.value = null;
      shift.value = Offset.zero;
      return;
    }
    final local = _selection().extent - _buffer().offsetOfLine(line);
    // A table row laid out in fitted columns is drawn as one paragraph per
    // piece: the caret is measured in — and drawn at — the piece it is in,
    // and the painter is told how far that piece stands from the line's box.
    final (piece, paragraph) = _fragmentAt(line, local);
    if (paragraph == null || piece == null) {
      rect.value = null;
      shift.value = Offset.zero;
      return;
    }
    shift.value = Offset(piece.x, piece.y);
    final length = paragraph.text.toPlainText().length;
    final position = TextPosition(
      offset: (local - piece.start).clamp(0, length),
    );
    rect.value = sourceCaretRectIn(paragraph, position, length, _width());
    _measured();
  }

  /// Publishes the formats on at [spot] to the shell's toolbar (#246).
  ///
  /// The answer is read off the caret's line — the same tokens the colours are
  /// drawn from — and written into the shell's notifier, which is the shape the
  /// legacy WYSIWYG published through, so the toolbar reads one thing whichever
  /// engine draws the pane (`active_formats.dart`).
  ///
  /// Deferred out of a build: the toolbar is not a descendant of this surface,
  /// so notifying it while the framework is building is a `markNeedsBuild` it
  /// refuses. The answer is the same one frame later, and the caret's own value
  /// is read again then rather than carried.
  void publishActive(CaretSpot spot) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_mounted()) _publishActiveNow(this.spot.value);
      });
      return;
    }
    _publishActiveNow(spot);
  }

  void _publishActiveNow(CaretSpot spot) {
    final notifier = _activeItems();
    if (notifier == null) return;
    final active = spot.line < 0 || spot.line >= _lineCount
        ? const <ToolbarItem>{}
        : activeFormatsOf(
            text: _buffer().lineAt(spot.line),
            tokens: _tokensOf(spot.line),
            run: (spot.runStart, spot.runEnd),
          );
    // Equal sets are not a change: the toolbar is not told to rebuild when the
    // caret moves inside a run whose formats are the same.
    if (setEquals(active, notifier.value)) return;
    notifier.value = active;
  }

  /// Lets the notifiers go.
  void dispose() {
    rect.dispose();
    shift.dispose();
    spot.dispose();
  }
}
