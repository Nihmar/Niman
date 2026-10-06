/// The sequence-diagram model (#530): participants, the messages between
/// them, notes and the frames a block draws.
///
/// Like the flowchart model it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// What a message's head is capped with.
enum SequenceArrow {
  /// A filled arrowhead (`->>`, `-->>`).
  filled,

  /// An open arrowhead (`-)`, `--)`).
  open,

  /// A cross (`-x`, `--x`).
  cross,

  /// No head (`->`, `-->`).
  none,
}

/// One participant in the exchange.
final class SequenceParticipant {
  /// Creates a participant.
  const new({required this.id, required this.label});

  /// The name messages refer to it by.
  final String id;

  /// The text in its box, its alias when one was declared.
  final String label;
}

/// One thing that happens down the diagram.
sealed class SequenceItem {
  /// Const for subclasses.
  const new();
}

/// A message from one participant to another.
final class SequenceMessage extends SequenceItem {
  /// Creates a message.
  const new({
    required this.from,
    required this.to,
    required this.text,
    this.dashed = false,
    this.twoWay = false,
    this.arrow = SequenceArrow.filled,
  });

  /// The sender's id.
  final String from;

  /// The receiver's id.
  final String to;

  /// The text on the arrow.
  final String text;

  /// Whether the line is dotted.
  final bool dashed;

  /// The head the arrow ends with.
  final SequenceArrow arrow;

  /// Whether its tail carries the same head (`<<->>`, `<<-->>`).
  final bool twoWay;
}

/// Where a note sits.
enum SequenceNotePlacement {
  /// Over the participant, or spanning two.
  over,

  /// To the left of the participant.
  leftOf,

  /// To the right of the participant.
  rightOf,
}

/// A note beside or over the lifelines.
final class SequenceNote extends SequenceItem {
  /// Creates a note.
  const new({
    required this.placement,
    required this.participants,
    required this.text,
  });

  /// Where it sits.
  final SequenceNotePlacement placement;

  /// The ids it is placed relative to.
  final List<String> participants;

  /// Its text.
  final String text;
}

/// The kind of frame a block draws.
enum SequenceBlockKind {
  /// `loop`.
  loop,

  /// `opt`.
  opt,

  /// `alt`.
  alt,

  /// `par`.
  par,

  /// `critical`.
  critical,

  /// `break` — a keyword in Dart, so the value is named for what the
  /// frame does: the exchange breaks out of the sequence there.
  breakOut;

  /// The word drawn on its tab.
  String get title => switch (this) {
    SequenceBlockKind.loop => 'loop',
    SequenceBlockKind.opt => 'opt',
    SequenceBlockKind.alt => 'alt',
    SequenceBlockKind.par => 'par',
    SequenceBlockKind.critical => 'critical',
    SequenceBlockKind.breakOut => 'break',
  };
}

/// One section of a block, split by `else`/`and`.
final class SequenceSection {
  /// Creates a section.
  const new({required this.label, required this.items});

  /// The text after `else`/`and`, or empty.
  final String label;

  /// What happens in it.
  final List<SequenceItem> items;
}

/// A frame around a run of items.
final class SequenceBlock extends SequenceItem {
  /// Creates a block.
  const new({required this.kind, required this.sections});

  /// The frame's kind.
  final SequenceBlockKind kind;

  /// Its sections, one unless split.
  final List<SequenceSection> sections;
}

/// A parsed sequence diagram.
final class SequenceDiagram {
  /// Creates a sequence diagram.
  const new({required this.participants, required this.items});

  /// Every participant, in the order they first appear.
  final List<SequenceParticipant> participants;

  /// The top-level items, in order.
  final List<SequenceItem> items;
}
