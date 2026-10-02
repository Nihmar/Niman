/// A laid-out diagram of one of the kinds the engine draws (#530).
///
/// A flowchart (and a mind map, which is the same model) and a sequence
/// lay out to different geometry; the painter and the SVG export dispatch
/// on this one type, so the engine grows a kind at a time and no call site
/// learns about each.
library;

import 'package:flutter/painting.dart';
import 'package:niman/src/diagrams/diagram_layout.dart';
import 'package:niman/src/diagrams/sequence_geometry.dart';

/// A laid-out diagram.
sealed class DiagramDrawing {
  /// Const for subclasses.
  const new();

  /// The drawing's size.
  Size get size;
}

/// A flowchart or a mind map.
final class FlowDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed chart.
  final DiagramLayout layout;

  @override
  Size get size => layout.size;
}

/// A sequence diagram.
final class SequenceDrawing extends DiagramDrawing {
  /// Wraps a [layout].
  const new(this.layout);

  /// The placed sequence.
  final SequenceLayout layout;

  @override
  Size get size => layout.size;
}
