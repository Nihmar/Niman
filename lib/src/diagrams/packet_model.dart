/// The packet diagram model (#530): the fields of a packet, bit by bit.
///
/// Like the other models it carries no geometry; the layout places it and
/// the two drawings (canvas and SVG) share it.
library;

/// One field: the bits it takes, first to last, and its name.
final class PacketField {
  /// Creates a field.
  const new({required this.start, required this.end, required this.label});

  /// Its first bit.
  final int start;

  /// Its last bit, [start] for a field one bit wide.
  final int end;

  /// Its name.
  final String label;

  /// How many bits it takes.
  int get bits => end - start + 1;
}

/// A parsed packet diagram.
final class PacketChart {
  /// Creates a packet diagram.
  const new({required this.fields, this.title});

  /// The fields, one after another from bit 0.
  final List<PacketField> fields;

  /// The title, if any.
  final String? title;
}
