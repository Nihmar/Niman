/// Laying a packet diagram out (#530): its bits in rows of 32, each field
/// a box as wide as its bits with its name inside and its first and last
/// bit's numbers over it.
///
/// A field that runs past the end of a row goes on in the next, a box on
/// each row and its name in each, as Mermaid draws it. Every bit is as wide
/// as the narrowest box needs for the longest word of its name and for its
/// bit numbers side by side — between a
/// floor that keeps a row from shrinking to nothing and a ceiling past
/// which a name wraps instead — so the rows line up bit for bit.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/packet_model.dart';
import 'package:niman/src/diagrams/sequence_text.dart';

/// Bits on a row, Mermaid's default.
const int packetBitsPerRow = 32;

const double _margin = 12;

/// The room between a box's edge and its name.
const double _pad = 4;

/// The narrowest and the widest a bit is drawn.
const double _minBit = 18;
const double _maxBit = 40;

/// The space between one row's boxes and the next row's bit numbers.
const double _rowGap = 6;

/// One box: a field, or the part of it on one row, with its name wrapped
/// to the box.
typedef PacketBox = ({Rect rect, List<String> lines});

/// A bit's number over a box.
typedef PacketNumber = ({String text, Rect box});

/// A packet diagram with every part placed.
typedef PacketLayout = ({
  Size size,
  List<PacketBox> boxes,
  List<PacketNumber> numbers,
  Rect? titleBox,
  String? title,
});

/// Lays [chart] out with [style].
PacketLayout layoutPacket(PacketChart chart, DiagramStyle style) {
  final fontSize = style.fontSize;
  final line = fontSize * style.lineHeight;
  final small = numberFontSize(style);
  final numberHeight = small * style.lineHeight;

  // Each field cut at the ends of the rows it crosses: (field, first bit,
  // last bit) of every piece.
  final pieces = <(PacketField, int, int)>[];
  for (final field in chart.fields) {
    var from = field.start;
    while (from <= field.end) {
      final rowEnd = (from ~/ packetBitsPerRow + 1) * packetBitsPerRow - 1;
      final to = math.min(field.end, rowEnd);
      pieces.add((field, from, to));
      from = to + 1;
    }
  }

  var bit = _minBit;
  for (final (field, from, to) in pieces) {
    var word = 0.0;
    for (final part in field.label.split(RegExp(r'\s+'))) {
      word = math.max(word, DiagramMetrics.textWidth(part, fontSize));
    }
    // Its bit numbers side by side over it, clear of each other and of the
    // next box's.
    final numbers = from == to
        ? _numberWidth(from, small) + 4
        : _numberWidth(from, small) + _numberWidth(to, small) + 8;
    bit = math.max(bit, math.max(word + 2 * _pad, numbers) / (to - from + 1));
  }
  bit = math.min(bit, _maxBit);

  final wrapped = [
    for (final (field, from, to) in pieces)
      wrapLabel(field.label, (to - from + 1) * bit - 2 * _pad, fontSize),
  ];
  final boxHeight = math.max<double>(
    32,
    wrapped.fold<int>(0, (most, lines) => math.max(most, lines.length)) * line +
        2 * _pad,
  );

  final title = chart.title;
  final titleSize = fontSize * 1.2;
  final titleHeight = title == null ? 0.0 : titleSize * style.lineHeight + 12;
  final rowWidth = packetBitsPerRow * bit;
  final width = math.max(
    rowWidth,
    title == null ? 0.0 : DiagramMetrics.textWidth(title, titleSize),
  );
  final left = _margin + (width - rowWidth) / 2;
  final top = _margin + titleHeight;
  final rowHeight = numberHeight + boxHeight + _rowGap;

  final boxes = <PacketBox>[];
  final numbers = <PacketNumber>[];
  for (var i = 0; i < pieces.length; i++) {
    final (_, from, to) = pieces[i];
    final row = from ~/ packetBitsPerRow;
    final rect = Rect.fromLTWH(
      left + (from % packetBitsPerRow) * bit,
      top + row * rowHeight + numberHeight,
      (to - from + 1) * bit,
      boxHeight,
    );
    boxes.add((rect: rect, lines: wrapped[i]));
    // The first bit's number at the box's left, the last's at its right.
    PacketNumber number(int value, {required bool atLeft}) {
      final text = '$value';
      final w = _numberWidth(value, small);
      return (
        text: text,
        box: Rect.fromLTWH(
          atLeft ? rect.left + 2 : rect.right - 2 - w,
          rect.top - numberHeight,
          w,
          numberHeight,
        ),
      );
    }

    numbers.add(number(from, atLeft: true));
    if (to != from) numbers.add(number(to, atLeft: false));
  }

  final rows = pieces.last.$3 ~/ packetBitsPerRow + 1;
  return (
    size: Size(width + 2 * _margin, top + rows * rowHeight - _rowGap + _margin),
    boxes: boxes,
    numbers: numbers,
    titleBox: title == null
        ? null
        : Rect.fromCenter(
            center: Offset(
              _margin + width / 2,
              _margin + (titleHeight - 12) / 2,
            ),
            width: DiagramMetrics.textWidth(title, titleSize),
            height: titleHeight - 12,
          ),
    title: title,
  );
}

/// The size the bit numbers are written at.
double numberFontSize(DiagramStyle style) => style.fontSize * 0.75;

double _numberWidth(int bit, double fontSize) =>
    DiagramMetrics.textWidth('$bit', fontSize);
