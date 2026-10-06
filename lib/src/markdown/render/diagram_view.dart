/// A Mermaid fence drawn as a diagram in the read view (#530).
///
/// The block is still a fenced code block; this is the branch that draws it
/// when its language is `mermaid`. A source that does not parse is shown as
/// code, with the offending line underlined and the message under it, so a
/// syntax error is a note the reader can fix, not a blank block.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/diagrams/diagram_cache.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_painter.dart';
import 'package:niman/src/diagrams/diagram_result.dart';
import 'package:niman/src/diagrams/diagram_style.dart';
import 'package:niman/src/diagrams/mermaid_error.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/ui/strings.dart' show AppStrings;

/// Draws one diagram block, or its source when it does not parse.
final class BlockDiagramView extends StatelessWidget {
  /// Creates a view of [source] (the fence's content).
  const new({
    required this.source,
    required this.theme,
    this.onTapSource,
    this.fullScreen = true,
    super.key,
  });

  /// The diagram's Mermaid source, the fence lines stripped.
  final String source;

  /// The typography and colours it is drawn with.
  final MarkdownTheme theme;

  /// Called with a line of the diagram's own source (1-based) to show the
  /// source again: the whole diagram on a tap, the offending line on an
  /// error.
  final void Function(int line)? onTapSource;

  /// Whether the diagram carries the button that opens it alone; an export
  /// draws it without.
  final bool fullScreen;

  /// The style the diagram is drawn with, from the note's theme.
  DiagramStyle styleFor(BuildContext context) => DiagramStyle(
    fontSize: theme.body.fontSize ?? 14,
    fontFamily: theme.body.fontFamily,
    palette: DiagramPalette.of(Theme.of(context).brightness),
  );

  @override
  Widget build(BuildContext context) {
    final style = styleFor(context);
    final result = diagramCache.resolve(source, style);
    return switch (result) {
      DiagramReady(:final drawing) => _diagram(context, drawing, style),
      DiagramFailed(:final error) => _error(context, error),
    };
  }

  Widget _diagram(
    BuildContext context,
    DiagramDrawing drawing,
    DiagramStyle style,
  ) {
    // A diagram wider than the pane is shrunk to fit it, never cut: the
    // full screen view is where it is read at its own size.
    final canvas = GestureDetector(
      onTap: onTapSource == null ? null : () => onTapSource!(1),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: CustomPaint(
          size: drawing.size,
          painter: DiagramPainter(drawing: drawing, style: style),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.blockSpacing / 2),
      child: Center(
        child: Stack(
          children: [
            canvas,
            if (fullScreen)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  key: const Key('diagram-full-screen'),
                  tooltip: AppStrings.diagramFullScreen,
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () => _openFullScreen(context, drawing, style),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _error(BuildContext context, MermaidParseException error) {
    final lines = source.split('\n');
    final troubled = (error.line - 1).clamp(0, lines.length - 1);
    final spans = <TextSpan>[];
    for (var i = 0; i < lines.length; i++) {
      spans.add(
        TextSpan(
          text: lines[i],
          style: i == troubled
              ? const TextStyle(decoration: TextDecoration.underline)
              : null,
        ),
      );
      if (i != lines.length - 1) spans.add(const TextSpan(text: '\n'));
    }
    final errorColor = Theme.of(context).colorScheme.error;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.blockSpacing / 2),
      child: GestureDetector(
        onTap: onTapSource == null ? null : () => onTapSource!(error.line),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.codeBackground,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.all(theme.codePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(style: theme.code, children: spans)),
              const SizedBox(height: 6),
              Text(
                error.toString(),
                style: theme.code.copyWith(color: errorColor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFullScreen(
    BuildContext context,
    DiagramDrawing drawing,
    DiagramStyle style,
  ) {
    unawaited(
      showDialog<void>(
        context: context,
        // The view is opaque and keeps to the safe area itself, so it
        // covers the whole screen rather than leaving the barrier's bars.
        useSafeArea: false,
        barrierLabel: AppStrings.diagramTitle,
        builder: (context) =>
            _DiagramFullScreen(drawing: drawing, style: style),
      ),
    );
  }
}

/// The diagram alone, to pinch and drag.
final class _DiagramFullScreen extends StatelessWidget {
  const new({required this.drawing, required this.style});

  final DiagramDrawing drawing;
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
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.4,
                  maxScale: 8,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: SizedBox.fromSize(
                    size: drawing.size,
                    child: CustomPaint(
                      painter: DiagramPainter(drawing: drawing, style: style),
                    ),
                  ),
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
