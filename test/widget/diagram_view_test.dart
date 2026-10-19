// A Mermaid fence in the read view (#530): drawn when it parses, and left
// as code with the error when it does not.
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:niman/src/diagrams/diagram_drawing.dart';
import 'package:niman/src/diagrams/diagram_painter.dart';
import 'package:niman/src/markdown/read_parser.dart';
import 'package:niman/src/markdown/render/diagram_fitted_viewer.dart';
import 'package:niman/src/markdown/render/diagram_view.dart';
import 'package:niman/src/markdown/render/markdown_read_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/preview/math_cache.dart';

Future<void> _pump(WidgetTester tester, String document) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MarkdownReadView(
          buffer: SourceBuffer.fromText(document),
          parser: ReadParser(),
          mathCache: MathCache(),
        ),
      ),
    ),
  );
  await tester.pump();
}

Iterable<DiagramPainter> _painters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<DiagramPainter>();

const _small = '```mermaid\nflowchart TD\nA --> B\n```\n';

/// Wider than a phone, and taller than it is wide: the case of the report.
const _large =
    '```mermaid\nsequenceDiagram\n'
    'participant Alice\nparticipant Bob\nparticipant Carol\n'
    'Alice->>Bob: A first message long enough to widen the diagram\n'
    'Bob-->>Alice: A reply that is also long enough to widen it\n'
    'Carol->>Alice: A third message that goes on and on for a while\n```\n';

/// Wide and short, like a Gantt chart.
const _wideShort =
    '```mermaid\nflowchart LR\n'
    'A[First step] --> B[Second step] --> C[Third step] --> D[Fourth step]'
    ' --> E[Fifth step] --> F[Sixth step] --> G[Seventh step]\n```\n';

void _surface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps [document] and opens its first diagram full screen.
Future<void> _openFullScreen(WidgetTester tester, String document) async {
  await _pump(tester, document);
  final button = find.byKey(const Key('diagram-full-screen'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  // On the button's upper part: beside a short diagram, the block is a few
  // pixels high, and the rest of the button hangs outside the block's box,
  // where a hit test does not reach it.
  await tester.tapAt(tester.getRect(button).topCenter + const Offset(0, 6));
  await tester.pumpAndSettle();
}

/// The drawing the full screen view paints.
Finder get _fullScreenPaint => find.descendant(
  of: find.byType(InteractiveViewer),
  matching: find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is DiagramPainter,
  ),
);

/// The drawing's own size, as the painter holds it.
Size _drawingSize(WidgetTester tester) =>
    (tester.widget<CustomPaint>(_fullScreenPaint).painter! as DiagramPainter)
        .drawing
        .size;

/// The drawing as it stands on the screen, scale and pan applied.
Rect _shown(WidgetTester tester) {
  final box = tester.renderObject<RenderBox>(_fullScreenPaint);
  return MatrixUtils.transformRect(
    box.getTransformTo(null),
    Offset.zero & box.size,
  );
}

/// Equal to within a thousandth of a pixel: the matrices are products.
Matcher _near(double value) => moreOrLessEquals(value, epsilon: 1e-3);

/// The zoom, as a multiple of the drawing's own size.
double _scale(WidgetTester tester) => tester
    .renderObject<RenderBox>(_fullScreenPaint)
    .getTransformTo(null)
    .getMaxScaleOnAxis();

Rect _viewport(WidgetTester tester) =>
    tester.getRect(find.byType(InteractiveViewer));

TransformationController _matrix(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!;

/// A mouse wheel turn at [at]: negative [dy] zooms in, positive zooms out.
Future<void> _wheel(WidgetTester tester, Offset at, double dy) async {
  final pointer = TestPointer(1, PointerDeviceKind.mouse);
  await tester.sendEventToBinding(pointer.hover(at));
  await tester.sendEventToBinding(pointer.scroll(Offset(0, dy)));
  await tester.pump();
}

/// Zooms to [target] in one wheel turn: the viewer scales by `exp(-dy / 200)`.
Future<void> _zoomTo(WidgetTester tester, Offset at, double target) =>
    _wheel(tester, at, -200 * math.log(target / _scale(tester)));

void main() {
  testWidgets('a mermaid fence is drawn as a diagram', (tester) async {
    await _pump(
      tester,
      'Before.\n\n```mermaid\n'
      'flowchart TD\nA[Start] --> B{Ok?}\nB --> C\n```\n',
    );
    expect(_painters(tester), isNotEmpty);
    expect(find.byKey(const Key('diagram-full-screen')), findsOneWidget);
  });

  testWidgets("the full screen button keeps the block's top right corner", (
    tester,
  ) async {
    // On a narrow diagram it sat on the diagram's own corner, mid-page.
    await _pump(tester, '```mermaid\nflowchart TD\nA --> B\n```\n');
    final block = tester.getRect(find.byType(BlockDiagramView));
    final button = tester.getRect(find.byKey(const Key('diagram-full-screen')));
    final diagram = tester.getRect(
      find
          .descendant(
            of: find.byType(BlockDiagramView),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    expect(diagram.width, lessThan(block.width / 2));
    expect(diagram.center.dx, moreOrLessEquals(block.center.dx));
    expect(button.right, moreOrLessEquals(block.right));
  });

  testWidgets('a fence in a list item is drawn from its code, the indent off', (
    tester,
  ) async {
    // The export took the fence's indent off; the read view kept it.
    await _pump(
      tester,
      '- item\n\n  ```mermaid\n  flowchart TD\n  A --> B\n  ```\n',
    );
    final view = tester.widget<BlockDiagramView>(find.byType(BlockDiagramView));
    expect(view.source, 'flowchart TD\nA --> B');
  });

  testWidgets('a sequence fence is drawn as a sequence', (tester) async {
    await _pump(
      tester,
      '```mermaid\nsequenceDiagram\n'
      'Alice->>Bob: Hello\nBob-->>Alice: Hi\n```\n',
    );
    expect(
      _painters(tester).map((painter) => painter.drawing),
      everyElement(isA<SequenceDrawing>()),
    );
    expect(_painters(tester), isNotEmpty);
  });

  testWidgets('the full screen button opens the diagram alone', (tester) async {
    await _pump(tester, '```mermaid\nflowchart TD\nA --> B\n```\n');
    await tester.tap(find.byKey(const Key('diagram-full-screen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diagram-full-screen-close')), findsOneWidget);
  });

  group('full screen', () {
    testWidgets('a small diagram opens at its own size, centred', (
      tester,
    ) async {
      _surface(tester, const Size(800, 600));
      await _openFullScreen(tester, _small);

      final viewport = _viewport(tester);
      final shown = _shown(tester);
      expect(_scale(tester), _near(1), reason: 'never enlarged');
      expect(shown.size, _drawingSize(tester));
      expect(shown.center.dx, _near(viewport.center.dx));
      expect(shown.center.dy, _near(viewport.center.dy));
    });

    testWidgets('a small diagram zooms in and back out, centred', (
      tester,
    ) async {
      _surface(tester, const Size(800, 600));
      await _openFullScreen(tester, _small);
      final centre = _viewport(tester).center;

      // The first turn of the wheel used to snap it to the scale at which
      // the viewport fits the boundary, and there was no way back.
      await _wheel(tester, centre, -200 * math.log(2));
      expect(_scale(tester), _near(2));
      await _wheel(tester, centre, 200 * math.log(2));
      expect(_scale(tester), _near(1));
      await _wheel(tester, centre, 2000);
      expect(_scale(tester), _near(1), reason: 'whole is the floor');
      expect(_shown(tester).center.dx, _near(centre.dx));
      expect(_shown(tester).center.dy, _near(centre.dy));
    });

    testWidgets('a large diagram opens whole, centred, on a phone', (
      tester,
    ) async {
      _surface(tester, const Size(360, 640));
      await _openFullScreen(tester, _large);

      final drawing = _drawingSize(tester);
      final viewport = _viewport(tester);
      final shown = _shown(tester);
      expect(drawing.width, greaterThan(viewport.width), reason: 'wider');
      expect(_scale(tester), lessThan(1));
      expect(shown.width, _near(drawing.width * _scale(tester)));
      expect(shown.height, _near(drawing.height * _scale(tester)));
      expect(viewport.contains(shown.topLeft), isTrue);
      expect(viewport.contains(shown.bottomRight), isTrue);
      expect(shown.center.dx, _near(viewport.center.dx));
      expect(shown.center.dy, _near(viewport.center.dy));
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .constrained,
        isFalse,
        reason: 'the child keeps its size',
      );
      expect(tester.getSize(_fullScreenPaint), drawing, reason: 'not clamped');
    });

    testWidgets('a large diagram pans to every edge at its own size', (
      tester,
    ) async {
      _surface(tester, const Size(360, 640));
      await _openFullScreen(tester, _large);

      final viewport = _viewport(tester);
      final drawing = _drawingSize(tester);
      final fit = DiagramFittedViewer.fitScale(drawing, viewport.size);
      final scene = viewport.size / fit;
      await _zoomTo(tester, viewport.center, 1);
      expect(_scale(tester), _near(1));
      expect(_shown(tester).width, greaterThan(viewport.width));

      // Dragged far past the far corner, the view stops at the scene's edge,
      // which is the viewport's own, the drawing a margin or more inside it.
      for (var i = 0; i < 3; i++) {
        await tester.drag(
          find.byType(InteractiveViewer),
          const Offset(-900, -900),
        );
        await tester.pumpAndSettle();
      }
      final far = _matrix(tester).value.getTranslation();
      expect(far.x, _near(viewport.width - scene.width));
      expect(far.y, _near(viewport.height - scene.height));
      final atFar = _shown(tester);
      expect(
        atFar.right,
        lessThanOrEqualTo(viewport.right - DiagramFittedViewer.margin),
      );
      expect(
        atFar.bottom,
        lessThanOrEqualTo(viewport.bottom - DiagramFittedViewer.margin),
      );

      for (var i = 0; i < 3; i++) {
        await tester.drag(
          find.byType(InteractiveViewer),
          const Offset(900, 900),
        );
        await tester.pumpAndSettle();
      }
      final near = _matrix(tester).value.getTranslation();
      expect(near.x, _near(0));
      expect(near.y, _near(0));
      final atNear = _shown(tester);
      expect(
        atNear.left,
        greaterThanOrEqualTo(viewport.left + DiagramFittedViewer.margin),
      );
      expect(
        atNear.top,
        greaterThanOrEqualTo(viewport.top + DiagramFittedViewer.margin),
      );
    });

    testWidgets('a wide, short diagram zooms out to the whole of it', (
      tester,
    ) async {
      _surface(tester, const Size(360, 640));
      await _openFullScreen(tester, _wideShort);

      final drawing = _drawingSize(tester);
      final viewport = _viewport(tester);
      expect(drawing.width, greaterThan(viewport.width));
      expect(drawing.height, lessThan(viewport.height / 2), reason: 'short');
      final fit = _scale(tester);
      expect(fit, lessThan(1));
      expect(_shown(tester).width, lessThanOrEqualTo(viewport.width));

      // Zoomed in to read it, then out again: the floor is the fit, not the
      // scale at which the viewport covers a boundary.
      await _zoomTo(tester, viewport.center, 1);
      expect(_scale(tester), _near(1));
      await _wheel(tester, viewport.center, 5000);
      expect(_scale(tester), _near(fit));
      final shown = _shown(tester);
      expect(shown.left, greaterThanOrEqualTo(viewport.left));
      expect(shown.right, lessThanOrEqualTo(viewport.right));
      expect(shown.center.dy, _near(viewport.center.dy));
    });

    testWidgets('a viewport with no area shows nothing, then fits', (
      tester,
    ) async {
      _surface(tester, const Size(360, 640));
      await _openFullScreen(tester, _large);

      // A collapsed window: the fit would divide by zero.
      tester.view.physicalSize = Size.zero;
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(
        find.byKey(const Key('diagram-full-screen-close')),
        findsOneWidget,
      );

      tester.view.physicalSize = const Size(360, 640);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final viewport = _viewport(tester);
      expect(
        _scale(tester),
        _near(
          DiagramFittedViewer.fitScale(_drawingSize(tester), viewport.size),
        ),
      );
    });

    testWidgets('a resize fits the diagram again', (tester) async {
      _surface(tester, const Size(360, 640));
      await _openFullScreen(tester, _large);
      await _zoomTo(tester, _viewport(tester).center, 1);

      tester.view.physicalSize = const Size(640, 360);
      await tester.pumpAndSettle();

      final viewport = _viewport(tester);
      final shown = _shown(tester);
      expect(viewport.size, const Size(640, 360));
      expect(
        _scale(tester),
        _near(
          DiagramFittedViewer.fitScale(_drawingSize(tester), viewport.size),
        ),
      );
      expect(viewport.contains(shown.topLeft), isTrue);
      expect(viewport.contains(shown.bottomRight), isTrue);
      expect(shown.center.dx, _near(viewport.center.dx));
      expect(shown.center.dy, _near(viewport.center.dy));
    });

    testWidgets('a double tap toggles the whole diagram and its own size', (
      tester,
    ) async {
      _surface(tester, const Size(360, 640));
      await _openFullScreen(tester, _large);
      final fit = _scale(tester);
      expect(fit, lessThan(1));
      final at = _viewport(tester).center;

      await tester.tapAt(at);
      await tester.pump(kDoubleTapMinTime);
      await tester.tapAt(at);
      await tester.pumpAndSettle();
      expect(_scale(tester), _near(1));
      expect(_shown(tester).contains(at), isTrue, reason: 'under the finger');

      await tester.tapAt(at);
      await tester.pump(kDoubleTapMinTime);
      await tester.tapAt(at);
      await tester.pumpAndSettle();
      expect(_scale(tester), _near(fit));
    });

    testWidgets('the close button closes it', (tester) async {
      _surface(tester, const Size(360, 640));
      await _openFullScreen(tester, _large);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      await tester.tap(find.byKey(const Key('diagram-full-screen-close')));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.byKey(const Key('diagram-full-screen-close')), findsNothing);
    });
  });

  testWidgets('a diagram wider than the pane is scaled to fit it whole', (
    tester,
  ) async {
    const width = 240.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: MarkdownReadView(
                buffer: SourceBuffer.fromText(
                  '```mermaid\nflowchart LR\n'
                  'A[First step] --> B[Second step] --> C[Third step]'
                  ' --> D[Fourth step]\n```\n',
                ),
                parser: ReadParser(),
                mathCache: MathCache(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final paint = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is DiagramPainter,
    );
    final painter = tester.widget<CustomPaint>(paint).painter!;
    final drawing = (painter as DiagramPainter).drawing.size;
    expect(drawing.width, greaterThan(width));
    // Painted at its own size — not cut to the pane's — and shrunk inside it.
    expect(tester.getSize(paint), drawing);
    expect(tester.getRect(paint).right, lessThanOrEqualTo(width + 0.01));
  });

  testWidgets('the full screen view is drawn on the theme surface', (
    tester,
  ) async {
    await _pump(tester, '```mermaid\nflowchart TD\nA --> B\n```\n');
    await tester.tap(find.byKey(const Key('diagram-full-screen')));
    await tester.pumpAndSettle();
    final context = tester.element(
      find.byKey(const Key('diagram-full-screen-close')),
    );
    final scaffold = tester.widget<Scaffold>(
      find
          .ancestor(
            of: find.byKey(const Key('diagram-full-screen-close')),
            matching: find.byType(Scaffold),
          )
          .first,
    );
    // The diagram's dark lines are drawn for the theme's own surface, not
    // over the near-black barrier, where they would vanish.
    expect(scaffold.backgroundColor, Theme.of(context).colorScheme.surface);
  });

  testWidgets('a syntax error stays source, with the line and message', (
    tester,
  ) async {
    await _pump(tester, '```mermaid\nflowchart TD\nA -- B\n```\n');
    expect(_painters(tester), isEmpty);
    expect(find.textContaining('Line 2:'), findsOneWidget);
    expect(find.textContaining('after "--"'), findsOneWidget);
  });

  testWidgets('a non-mermaid fence stays code', (tester) async {
    await _pump(tester, '```dart\nvoid main() {}\n```\n');
    expect(_painters(tester), isEmpty);
    expect(find.byKey(const Key('diagram-full-screen')), findsNothing);
  });
}
