/// A diagram alone on the screen, to pinch and drag (#530, #1110).
library;

import 'package:flutter/material.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/markdown/render/diagram_fitted_viewer.dart';

/// The diagram alone, opened whole and centred, to pinch and drag.
final class DiagramFullScreen extends StatelessWidget {
  /// Creates the view of [drawing], painted with [style].
  const new({required this.drawing, required this.style, super.key});

  /// The diagram drawn.
  final DiagramDrawing drawing;

  /// How it is drawn.
  final DiagramStyle style;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // The theme's surface, which the diagram's palette is chosen for: over
    // the dark barrier a light theme's dark lines and labels would vanish.
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              // Keyed by the space it has: a rotation or a resize fits the
              // diagram again rather than keeping a view for another shape.
              child: LayoutBuilder(
                builder: (context, constraints) => DiagramFittedViewer(
                  key: ValueKey(constraints.biggest),
                  drawing: drawing,
                  style: style,
                  viewport: constraints.biggest,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                key: const Key('diagram-full-screen-close'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: Icon(Icons.close, color: colors.onSurface),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
