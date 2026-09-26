/// The guided tour on screen (#266): a dimmed app with a hole over the
/// control being talked about, and a card beside it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/ui/tour/tour_steps.dart';
import 'package:niman/src/ui/tour/tour_targets.dart';
import 'package:niman/src/ui/welcome/welcome_copy.dart';

/// What the tour needs from whoever starts it: the steps, where to keep
/// the progress, and what to do when a step acts.
final class TourRun {
  /// Creates a run.
  const new({
    required this.steps,
    required this.copy,
    required this.onStep,
    required this.onDone,
    required this.onAction,
    this.initialStep = 0,
  });

  /// The steps, in order.
  final List<TourStep> steps;

  /// The words.
  final WelcomeCopy copy;

  /// Where the step it is on, whenever it moves: the tour survives a
  /// close and a restart.
  final ValueChanged<int> onStep;

  /// The tour was taken to its end.
  final VoidCallback onDone;

  /// The step asked for something (the cheatsheet).
  final Future<void> Function(TourAction action) onAction;

  /// The step to open on (a resumed tour).
  final int initialStep;
}

/// Shows [run] over the app: a route above everything, so a step can
/// point at a settings screen or the cheatsheet as easily as at the tree.
Future<void> showTour(BuildContext context, TourRun run) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondary) => _TourOverlay(run: run),
    ),
  );
}

/// The overlay itself: scrim, hole and card.
final class _TourOverlay extends ConsumerStatefulWidget {
  const new({required this.run});

  final TourRun run;

  @override
  ConsumerState<_TourOverlay> createState() => _TourOverlayState();
}

final class _TourOverlayState extends ConsumerState<_TourOverlay> {
  late int _index = widget.run.initialStep.clamp(
    0,
    widget.run.steps.length - 1,
  );
  Rect? _hole;

  TourStep get _step => widget.run.steps[_index];
  bool get _last => _index == widget.run.steps.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // After the frame: the target has to be laid out before it can be
    // measured, and the first build of the route is not.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  /// Takes the target's rectangle, or moves on: a step whose control is
  /// not on screen (a hidden rail, a closed dock) is skipped rather than
  /// pointing at nothing.
  void _measure() {
    if (!mounted) return;
    final target = _step.target;
    if (target == null) {
      setState(() => _hole = null);
      return;
    }
    final rect = tourTargetRect(target);
    if (rect == null) {
      if (!_last) {
        setState(() => _index++);
        widget.run.onStep(_index);
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
      } else {
        _done();
      }
      return;
    }
    setState(() => _hole = rect);
  }

  void _go(int index) {
    setState(() {
      _index = index.clamp(0, widget.run.steps.length - 1);
      _hole = null;
    });
    widget.run.onStep(_index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  /// The tour is over (Done on the last step, or nothing left to show).
  void _done() {
    widget.run.onDone();
    Navigator.of(context).pop();
  }

  /// Left part-way: the palette's *Continue the tour* picks it up.
  void _skip() => Navigator.of(context).pop();

  /// Leaves the tour for what the step opens (the cheatsheet).
  Future<void> _act(TourAction action) async {
    widget.run.onStep(_index);
    Navigator.of(context).pop();
    await widget.run.onAction(action);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final hole = _hole;
    final width = size.width < 420 ? size.width - 32 : 420.0;
    final below = hole != null && hole.bottom + 220 < size.height;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              // The scrim swallows taps: the tour is watched, not typed
              // in, and no stray click edits a note behind it.
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _ScrimPainter(
                  hole: hole,
                  scrim: theme.colorScheme.scrim.withValues(alpha: 0.55),
                  edge: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          if (hole == null)
            Positioned.fill(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width),
                  child: _card(theme),
                ),
              ),
            )
          else
            Positioned(
              left: (hole.center.dx - width / 2).clamp(
                16.0,
                size.width - width - 16,
              ),
              top: below ? hole.bottom + 12 : null,
              bottom: below ? null : size.height - hole.top + 12,
              width: width,
              child: _card(theme),
            ),
        ],
      ),
    );
  }

  Widget _card(ThemeData theme) {
    return Card(
      key: const Key('tour-card'),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.run.copy.pageOf(_index + 1, widget.run.steps.length),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  key: const Key('tour-skip'),
                  onPressed: _skip,
                  child: Text(widget.run.copy.skip),
                ),
              ],
            ),
            Text(_step.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: SingleChildScrollView(
                child: Text(_step.body, style: theme.textTheme.bodyMedium),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_index > 0)
                  TextButton(
                    key: const Key('tour-back'),
                    onPressed: () => _go(_index - 1),
                    child: Text(widget.run.copy.back),
                  ),
                const SizedBox(width: 8),
                if (_step.action case final action?)
                  FilledButton(
                    key: const Key('tour-action'),
                    onPressed: () => _act(action),
                    child: Text(widget.run.copy.tourCheatsheetOpen),
                  )
                else if (!_last)
                  FilledButton(
                    key: const Key('tour-next'),
                    onPressed: () => _go(_index + 1),
                    child: Text(widget.run.copy.next),
                  )
                else
                  FilledButton(
                    key: const Key('tour-done'),
                    onPressed: _done,
                    child: Text(widget.run.copy.tourDone),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The dim, with a rounded hole where the step points.
final class _ScrimPainter extends CustomPainter {
  new({required this.hole, required this.scrim, required this.edge});

  final Rect? hole;
  final Color scrim;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final cut = hole;
    if (cut == null) {
      canvas.drawPath(full, Paint()..color = scrim);
      return;
    }
    final rounded = RRect.fromRectAndRadius(
      cut.inflate(6),
      const Radius.circular(12),
    );
    final holePath = Path()..addRRect(rounded);
    canvas
      ..drawPath(
        Path.combine(PathOperation.difference, full, holePath),
        Paint()..color = scrim,
      )
      ..drawRRect(
        rounded,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = edge,
      );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole || old.scrim != scrim || old.edge != edge;
}
