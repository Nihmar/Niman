// Where the caret is drawn, and where a tap lands, for a block laid out from
// the real engine. This is the seam a hand-built editor gets wrong: the
// rectangle has to come from the painter, and in the modes that hide a
// marker the positions inside it have to stay out of reach.
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/edit/caret_geometry.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/visible_text.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// 16 px characters under the test font, with the strut the design's line
/// height comes from.
const TextStyle _body = TextStyle(fontSize: 16);
const StrutStyle _strut = StrutStyle(fontSize: 16, height: 1.2);

/// A marker run styled the way `live` mode hides it (§8.6.0).
const TextStyle _hiddenStyle = TextStyle(fontSize: 0, color: Color(0x00000000));

/// The caret's full height for that strut, measured in
/// `test/unit/caret_rectangle_test.dart`.
const double _fullHeight = 19.2;

/// [text] with the [hidden] ranges styled away: the string does not change,
/// only the style of the markers.
TextSpan _hiddenMarkers(String text, List<(int, int)> hidden) {
  final runs = <TextSpan>[];
  var at = 0;
  for (final (start, end) in hidden) {
    if (start > at) runs.add(TextSpan(text: text.substring(at, start)));
    runs.add(TextSpan(text: text.substring(start, end), style: _hiddenStyle));
    at = end;
  }
  runs.add(TextSpan(text: text.substring(at)));
  return TextSpan(children: runs, style: _body);
}

/// The geometry of the first block of [document], laid out [maxWidth] wide and
/// placed at document offset 0.
///
/// With [hideMarkers] the block is laid out the way `live` mode lays it out —
/// markers at zero size, `hiddenRangesOf` the ranges that vanish — and without
/// it the way `source` mode does, which hides nothing at all.
CaretGeometry _geometry(
  String document, {
  SelectionModel selection = const SelectionModel.at(0),
  bool ownsTrailingEdge = false,
  double maxWidth = double.infinity,
  bool hideMarkers = false,
}) {
  final buffer = SourceBuffer.fromText(document);
  final scanner = BlockScanner(buffer);
  final parsed = BlockParser().parse(scanner.index.blocks.first, buffer);
  final hidden = hideMarkers ? hiddenRangesOf(parsed) : const <(int, int)>[];
  final painter = TextPainter(
    text: hideMarkers
        ? _hiddenMarkers(parsed.text, hidden)
        : TextSpan(text: parsed.text, style: _body),
    textDirection: TextDirection.ltr,
    strutStyle: _strut,
  )..layout(maxWidth: maxWidth);
  return CaretGeometry(
    painter: painter,
    sourceStart: 0,
    selection: selection,
    hidden: hidden,
    ownsTrailingEdge: ownsTrailingEdge,
  );
}

void main() {
  group('the caret is the painter', () {
    test('a plain block puts it after the characters before it', () {
      final geometry = _geometry(
        'hello',
        selection: const SelectionModel.at(3),
      );
      final rect = geometry.caretRect()!;
      // Three 16 px characters, then the caret.
      expect(rect.left, 48);
      expect(rect.top, 0);
      expect(rect.width, 1.5);
      expect(rect.height, closeTo(_fullHeight, 0.01));
    });

    test('the block end belongs to the last block, and its own end is not', () {
      const atEnd = SelectionModel.at(5);
      expect(_geometry('hello', selection: atEnd).caretRect(), isNull);
      expect(
        _geometry(
          'hello',
          selection: atEnd,
          ownsTrailingEdge: true,
        ).caretRect()!.left,
        80,
      );
    });

    test('a caret outside the block, or a selection, is not its business', () {
      expect(
        _geometry('hello', selection: const SelectionModel.at(9)).caretRect(),
        isNull,
      );
      expect(
        _geometry(
          'hello',
          selection: const SelectionModel(anchor: 1, extent: 4),
        ).caretRect(),
        isNull,
      );
    });

    test('an empty block still has a caret with a height', () {
      // The trap from the spike: an empty paragraph has no line metrics at all,
      // and a caret of the full height all the same.
      final painter = TextPainter(
        text: const TextSpan(text: '', style: _body),
        textDirection: TextDirection.ltr,
        strutStyle: _strut,
      )..layout();
      final geometry = CaretGeometry(
        painter: painter,
        sourceStart: 0,
        selection: const SelectionModel.at(0),
        ownsTrailingEdge: true,
      );
      expect(painter.computeLineMetrics(), isEmpty);
      final rect = geometry.caretRect()!;
      expect(rect.height, closeTo(_fullHeight, 0.01));
      expect(rect.left, 0);
    });

    test('a wrapped line puts it at the start of the next one', () {
      final geometry = _geometry(
        'aaaaaaaa',
        selection: const SelectionModel.at(4),
        maxWidth: 64,
      );
      final rect = geometry.caretRect()!;
      expect(rect.left, 0);
      // The advance the painter steps by is 19 while the caret's own height is
      // 19.2: two numbers it reports differently, and a surface that assumes
      // they are one drifts.
      expect(rect.top, 19);
      expect(rect.height, closeTo(_fullHeight, 0.01));
    });

    test('a right-to-left character carries the caret on the other side', () {
      // The prototype's width is folded into the offset here and nowhere else,
      // so the geometry does have to know how wide the caret is drawn.
      const selection = SelectionModel.at(0);
      final geometry = _geometry('אבג');
      final narrow = geometry.caretRect()!;
      final wide = CaretGeometry(
        painter: geometry.painter,
        sourceStart: 0,
        selection: selection,
        caretWidth: 3,
      ).caretRect()!;
      expect(narrow.left, closeTo(48 - 1.5, 0.01));
      expect(wide.left, closeTo(48 - 3, 0.01));
    });
  });

  group('the positions inside a hidden marker', () {
    // `a **bold** word`, laid out the way `live` mode lays it out: the markers
    // at 2..4 and 8..10 take no width.
    const source = 'a **bold** word';

    test('collapse to one place on screen', () {
      Rect? at(int offset) => _geometry(
        source,
        selection: SelectionModel.at(offset),
        hideMarkers: true,
      ).caretRect();
      // 'a ' is 32 px, the marker adds nothing, and `b` follows at the same
      // place: the offsets inside and around it are one position.
      expect(at(2)!.left, 32);
      expect(at(3)!.left, at(2)!.left);
      expect(at(4)!.left, at(2)!.left);
      // And the text either side still advances.
      expect(at(1)!.left, lessThan(at(2)!.left));
      expect(at(4)!.left, lessThan(at(5)!.left));
    });

    test('a tap never lands in one', () {
      final geometry = _geometry(source, hideMarkers: true);
      for (var x = 0.0; x <= 140; x += 4) {
        final at = geometry.offsetAt(Offset(x, 5));
        final inside = geometry.hidden.any((run) => at > run.$1 && at < run.$2);
        expect(
          inside,
          isFalse,
          reason: 'a tap at x=$x landed at $at, inside a hidden marker',
        );
      }
      // Tapping at the first marker's second character leaves by its nearer
      // edge, which is the rule the arrow keys use too.
      expect(geometry.offsetAt(const Offset(36, 5)), anyOf(2, 4));
    });

    test('source mode hides nothing, so nothing snaps', () {
      // The identity render map: with the markers drawn like any other
      // character there is no invisible place to trap a caret, and a tap inside
      // `**` is an ordinary offset.
      final geometry = _geometry(source);
      expect(geometry.hidden, isEmpty);
      expect(geometry.offsetAt(const Offset(36, 5)), 2);
      // And every offset has its own place on screen, in order.
      for (var offset = 0; offset < 4; offset++) {
        final left = _geometry(
          source,
          selection: SelectionModel.at(offset),
        ).caretRect()!.left;
        expect(left, offset * 16.0);
      }
    });
  });

  group('the selection this block paints', () {
    test('is its own part of a wider one', () {
      final geometry = _geometry(
        'hello',
        selection: const SelectionModel(anchor: 3, extent: 99),
      );
      expect(geometry.selectionLocal(), (3, 5));
      final box = geometry.selectionBoxes().single;
      expect(box.left, 48);
      expect(box.right, 80);
    });

    test('is nothing when the two do not meet', () {
      final geometry = _geometry(
        'hello',
        selection: const SelectionModel(anchor: 40, extent: 50),
      );
      expect(geometry.selectionLocal(), isNull);
      expect(geometry.selectionBoxes(), isEmpty);
    });

    test('is a block-local range when the block does not start at zero', () {
      final painter = _geometry('hello').painter;
      final geometry = CaretGeometry(
        painter: painter,
        sourceStart: 10,
        selection: const SelectionModel(anchor: 12, extent: 14),
      );
      expect(geometry.selectionLocal(), (2, 4));
      final box = geometry.selectionBoxes().single;
      expect(box.left, 32);
      expect(box.right, 64);
      // And the caret that belongs to it is the local one too.
      final caret = CaretGeometry(
        painter: painter,
        sourceStart: 10,
        selection: const SelectionModel.at(13),
      ).caretRect()!;
      expect(caret.left, 48);
    });
  });
}
