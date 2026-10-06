/// Laying a sequence diagram out (#530): participant columns, message rows,
/// notes and the frames a block draws.
///
/// The columns come first. Two neighbours start a fixed gap apart, and every
/// message, message to itself and note beside a lifeline widens the gaps it
/// spans until its text fits — widening only ever grows a gap, so one pass
/// leaves every one of them room. Then the items are laid down a row at a
/// time, a block's frame drawn round what it holds. Last, everything moves
/// right far enough that nothing — a note left of the first lifeline, a
/// frame's padding — reaches past the margin. Linear in the diagram, bar
/// the widening, which is a message's span of columns: the read view lays
/// a diagram out in build.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_metrics.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/sequence_geometry.dart';
import 'package:niman/src/diagrams/sequence_model.dart';
import 'package:niman/src/diagrams/sequence_text.dart';

const double _margin = 12;
const double _participantGap = 40;
const double _padX = 12;
const double _padY = 7;
const double _headMaxWidth = 150;
const double _messageMaxWidth = 220;
const double _noteMaxWidth = 180;
const double _textPad = 12;
const double _noteOffset = 10;
const double _topGap = 24;
const double _rowGap = 18;
const double _noteGap = 12;
const double _framePad = 10;
const double _blockGap = 10;
const double _loopWidth = 34;
const double _loopHeight = 22;

/// What a run of items reaches across, and where it ends down the page.
typedef _Extent = ({double bottom, double left, double right});

/// Lays [diagram] out with [style].
SequenceLayout layoutSequence(SequenceDiagram diagram, DiagramStyle style) =>
    _SequenceLayouter(diagram, style).run();

final class _SequenceLayouter {
  new(this.diagram, this.style);

  final SequenceDiagram diagram;
  final DiagramStyle style;
  final Map<String, int> _index = {};
  final List<LaidOutMessage> _messages = [];
  final List<LaidOutNote> _notes = [];
  final List<LaidOutFrame> _frames = [];
  final List<double> _widths = [];
  final List<double> _gaps = [];
  final List<double> _centers = [];

  double get _line => style.fontSize * style.lineHeight;

  SequenceLayout run() {
    if (diagram.participants.isEmpty) {
      return const SequenceLayout(
        size: Size.zero,
        participants: [],
        messages: [],
        notes: [],
        frames: [],
      );
    }
    final labels = [
      for (final participant in diagram.participants)
        wrapLabel(participant.label, _headMaxWidth, style.fontSize),
    ];
    var headHeight = 0.0;
    for (var i = 0; i < labels.length; i++) {
      _index[diagram.participants[i].id] = i;
      _widths.add(
        math.max(widestLine(labels[i], style.fontSize) + 2 * _padX, 60),
      );
      headHeight = math.max(headHeight, labels[i].length * _line + 2 * _padY);
    }
    for (var i = 0; i + 1 < _widths.length; i++) {
      _gaps.add((_widths[i] + _widths[i + 1]) / 2 + _participantGap);
    }
    _widen(diagram.items);
    var x = 0.0;
    for (var i = 0; i < _widths.length; i++) {
      _centers.add(x);
      if (i < _gaps.length) x += _gaps[i];
    }

    final top = _margin + headHeight + _topGap;
    final body = _lay(diagram.items, top);
    final footTop = body.bottom + _topGap / 2;
    final participants = [
      for (var i = 0; i < labels.length; i++)
        LaidOutParticipant(
          participant: diagram.participants[i],
          head: _column(i, _margin, headHeight),
          foot: _column(i, footTop, headHeight),
          lines: labels[i],
        ),
    ];
    return _placed(participants, footTop + headHeight + _margin);
  }

  /// Participant [i]'s box, its top at [y].
  Rect _column(int i, double y, double height) =>
      Rect.fromLTWH(_centers[i] - _widths[i] / 2, y, _widths[i], height);

  /// The layout, moved right so its leftmost part sits on the margin.
  SequenceLayout _placed(List<LaidOutParticipant> participants, double h) {
    var left = double.infinity;
    var right = double.negativeInfinity;
    void reach(Rect rect) {
      left = math.min(left, rect.left);
      right = math.max(right, rect.right);
    }

    for (final participant in participants) {
      reach(participant.head);
    }
    for (final message in _messages) {
      reach(message.textBox);
      if (message.loop != null) reach(message.loop!);
    }
    for (final note in _notes) {
      reach(note.rect);
    }
    for (final frame in _frames) {
      reach(frame.rect);
    }
    final dx = _margin - left;
    return SequenceLayout(
      size: Size(right - left + 2 * _margin, h),
      participants: [for (final p in participants) p.moved(dx)],
      messages: [for (final m in _messages) m.moved(dx)],
      notes: [for (final n in _notes) n.moved(dx)],
      // Frames are found inner first; the outer ones are painted first.
      frames: [for (final f in _frames.reversed) f.moved(dx)],
    );
  }

  // -- columns -------------------------------------------------------------

  /// Widens the gaps [items] need to fit their text.
  void _widen(List<SequenceItem> items) {
    for (final item in items) {
      switch (item) {
        case SequenceMessage(:final from, :final to, :final text):
          final i = _index[from]!;
          final j = _index[to]!;
          final width = widestLine(
            wrapLabel(text, _messageMaxWidth, style.fontSize),
            style.fontSize,
          );
          if (i == j) {
            final need = _loopWidth + 6 + width + _textPad;
            if (i + 1 < _widths.length) {
              _span(i, i + 1, need + _widths[i + 1] / 2);
            }
          } else {
            _span(math.min(i, j), math.max(i, j), width + 2 * _textPad);
          }
        case SequenceNote(:final placement, :final participants, :final text):
          final i = _index[participants.first]!;
          final need =
              widestLine(
                wrapLabel(text, _noteMaxWidth, style.fontSize),
                style.fontSize,
              ) +
              2 * _padX +
              2 * _noteOffset;
          if (placement == SequenceNotePlacement.rightOf &&
              i + 1 < _widths.length) {
            _span(i, i + 1, need);
          } else if (placement == SequenceNotePlacement.leftOf && i > 0) {
            _span(i - 1, i, need);
          }
        case SequenceBlock(:final sections):
          for (final section in sections) {
            _widen(section.items);
          }
      }
    }
  }

  /// Widens the gaps between columns [i] and [j] evenly until their
  /// centres are at least [need] apart.
  void _span(int i, int j, double need) {
    var have = 0.0;
    for (var k = i; k < j; k++) {
      have += _gaps[k];
    }
    if (have >= need) return;
    final share = (need - have) / (j - i);
    for (var k = i; k < j; k++) {
      _gaps[k] += share;
    }
  }

  // -- rows ----------------------------------------------------------------

  /// Lays [items] down from [y]; what they reach across and where they end.
  _Extent _lay(List<SequenceItem> items, double y) {
    var bottom = y;
    var left = double.infinity;
    var right = double.negativeInfinity;
    for (final item in items) {
      final placed = switch (item) {
        SequenceMessage() => _message(item, bottom),
        SequenceNote() => _note(item, bottom),
        SequenceBlock() => _block(item, bottom),
      };
      bottom = placed.bottom;
      left = math.min(left, placed.left);
      right = math.max(right, placed.right);
    }
    return (bottom: bottom, left: left, right: right);
  }

  _Extent _message(SequenceMessage message, double y) {
    final lines = message.text.isEmpty
        ? const <String>[]
        : wrapLabel(message.text, _messageMaxWidth, style.fontSize);
    final textHeight = lines.length * _line;
    final width = widestLine(lines, style.fontSize);
    final from = _centers[_index[message.from]!];
    final to = _centers[_index[message.to]!];
    if (message.from == message.to) {
      final height = math.max(_loopHeight, textHeight);
      final loop = Rect.fromLTWH(from, y, _loopWidth, _loopHeight);
      final box = Rect.fromLTWH(
        loop.right + 6,
        loop.center.dy - textHeight / 2,
        width,
        textHeight,
      );
      _messages.add(
        LaidOutMessage(
          message: message,
          y: y,
          fromX: from,
          toX: from,
          textBox: box,
          text: lines,
          loop: loop,
        ),
      );
      return (bottom: y + height + _rowGap, left: from, right: box.right);
    }
    final box = Rect.fromCenter(
      center: Offset((from + to) / 2, y + textHeight / 2),
      width: width,
      height: textHeight,
    );
    final arrowY = y + textHeight + 4;
    _messages.add(
      LaidOutMessage(
        message: message,
        y: arrowY,
        fromX: from,
        toX: to,
        textBox: box,
        text: lines,
      ),
    );
    return (
      bottom: arrowY + _rowGap,
      left: math.min(math.min(from, to), box.left),
      right: math.max(math.max(from, to), box.right),
    );
  }

  _Extent _note(SequenceNote note, double y) {
    final lines = wrapLabel(note.text, _noteMaxWidth, style.fontSize);
    final width = widestLine(lines, style.fontSize) + 2 * _padX;
    final height = lines.length * _line + 2 * _padY;
    final first = _centers[_index[note.participants.first]!];
    final last = _centers[_index[note.participants.last]!];
    final rect = switch (note.placement) {
      SequenceNotePlacement.leftOf => Rect.fromLTWH(
        first - _noteOffset - width,
        y,
        width,
        height,
      ),
      SequenceNotePlacement.rightOf => Rect.fromLTWH(
        first + _noteOffset,
        y,
        width,
        height,
      ),
      // Over one lifeline, or reaching past both of two.
      SequenceNotePlacement.over => Rect.fromCenter(
        center: Offset((first + last) / 2, y + height / 2),
        width: math.max(width, (last - first).abs() + 2 * _textPad),
        height: height,
      ),
    };
    _notes.add(LaidOutNote(note: note, rect: rect, lines: lines));
    return (bottom: rect.bottom + _noteGap, left: rect.left, right: rect.right);
  }

  _Extent _block(SequenceBlock block, double y) {
    final tabHeight = _line + 6;
    final title = block.kind.title;
    final first = block.sections.first.label;
    final label = first.isEmpty ? '' : '[$first]';
    var cursor = y + tabHeight + 8;
    var left = double.infinity;
    var right = double.negativeInfinity;
    // The widest text the frame's top and its separators carry.
    var text = DiagramMetrics.textWidth(label, style.fontSize);
    final separators = <({double y, String label})>[];
    for (var i = 0; i < block.sections.length; i++) {
      final section = block.sections[i];
      if (i > 0) {
        final caption = section.label.isEmpty ? '' : '[${section.label}]';
        separators.add((y: cursor, label: caption));
        text = math.max(
          text,
          DiagramMetrics.textWidth(caption, style.fontSize),
        );
        cursor += _line + 8;
      }
      final placed = _lay(section.items, cursor);
      cursor = placed.bottom;
      left = math.min(left, placed.left);
      right = math.max(right, placed.right);
    }
    if (left > right) {
      // An empty block: a frame round nothing, at the first column.
      left = _centers.first;
      right = _centers.first;
    }
    final tabWidth = math.max<double>(
      DiagramMetrics.textWidth(title, style.fontSize) + 2 * _padX,
      44,
    );
    left -= _framePad;
    right = math.max(right + _framePad, left + tabWidth + text + 2 * _padX);
    final rect = Rect.fromLTRB(left, y, right, cursor);
    _frames.add(
      LaidOutFrame(
        kind: block.kind,
        rect: rect,
        tab: Rect.fromLTWH(left, y, tabWidth, tabHeight),
        label: label,
        separators: separators,
      ),
    );
    return (bottom: rect.bottom + _blockGap, left: left, right: right);
  }
}
