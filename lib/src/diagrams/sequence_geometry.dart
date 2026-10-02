/// Where a sequence diagram's parts sit once laid out (#530).
///
/// Geometry only, in logical pixels: the canvas and the SVG both draw from
/// it, so neither keeps a measurement of its own. Every part can be moved
/// across, which is how the layout makes room for what reaches left of the
/// first participant.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/sequence_model.dart';

/// A sequence diagram with every part placed.
final class SequenceLayout {
  /// Creates a layout.
  const new({
    required this.size,
    required this.participants,
    required this.messages,
    required this.notes,
    required this.frames,
  });

  /// The drawing's size.
  final Size size;

  /// The participant boxes and lifelines.
  final List<LaidOutParticipant> participants;

  /// The messages.
  final List<LaidOutMessage> messages;

  /// The notes.
  final List<LaidOutNote> notes;

  /// The frames, outermost first, so they can be painted in order.
  final List<LaidOutFrame> frames;
}

/// One participant's boxes, at the top and the foot, and its lifeline.
final class LaidOutParticipant {
  /// Creates a placed participant.
  const new({
    required this.participant,
    required this.head,
    required this.foot,
    required this.lines,
  });

  /// The model.
  final SequenceParticipant participant;

  /// Its box at the top.
  final Rect head;

  /// The same box at the foot, where a long exchange is read back to.
  final Rect foot;

  /// Its label, wrapped.
  final List<String> lines;

  /// The x its lifeline and messages meet.
  double get centerX => head.center.dx;

  /// This, [dx] to the right.
  LaidOutParticipant moved(double dx) => LaidOutParticipant(
    participant: participant,
    head: head.translate(dx, 0),
    foot: foot.translate(dx, 0),
    lines: lines,
  );
}

/// One message's arrow and its text.
final class LaidOutMessage {
  /// Creates a placed message.
  const new({
    required this.message,
    required this.y,
    required this.fromX,
    required this.toX,
    required this.textBox,
    required this.text,
    this.loop,
  });

  /// The model.
  final SequenceMessage message;

  /// The arrow's y; for a message to itself, where its loop leaves.
  final double y;

  /// The tail's x.
  final double fromX;

  /// The head's x.
  final double toX;

  /// Where the text sits.
  final Rect textBox;

  /// The text, wrapped.
  final List<String> text;

  /// The box a message to its own sender loops round, or null.
  final Rect? loop;

  /// This, [dx] to the right.
  LaidOutMessage moved(double dx) => LaidOutMessage(
    message: message,
    y: y,
    fromX: fromX + dx,
    toX: toX + dx,
    textBox: textBox.translate(dx, 0),
    text: text,
    loop: loop?.translate(dx, 0),
  );
}

/// One note's box and text.
final class LaidOutNote {
  /// Creates a placed note.
  const new({required this.note, required this.rect, required this.lines});

  /// The model.
  final SequenceNote note;

  /// Its box.
  final Rect rect;

  /// Its text, wrapped.
  final List<String> lines;

  /// This, [dx] to the right.
  LaidOutNote moved(double dx) =>
      LaidOutNote(note: note, rect: rect.translate(dx, 0), lines: lines);
}

/// One frame, its tab and its section separators.
final class LaidOutFrame {
  /// Creates a placed frame.
  const new({
    required this.kind,
    required this.rect,
    required this.tab,
    required this.label,
    required this.separators,
  });

  /// The model kind.
  final SequenceBlockKind kind;

  /// The frame's box.
  final Rect rect;

  /// The tab its kind is written in, at the top left.
  final Rect tab;

  /// The text after the tab: the first section's condition.
  final String label;

  /// The separators, with the text on each.
  final List<({double y, String label})> separators;

  /// This, [dx] to the right.
  LaidOutFrame moved(double dx) => LaidOutFrame(
    kind: kind,
    rect: rect.translate(dx, 0),
    tab: tab.translate(dx, 0),
    label: label,
    separators: separators,
  );
}
