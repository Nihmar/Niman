import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/ui/kinds/slides/slide_frame.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slides_overview.dart';
import 'package:niman/src/ui/kinds/slides/slides_present_bar.dart';
import 'package:niman/src/ui/kinds/slides/slides_presenter_view.dart';
import 'package:niman/src/ui/strings.dart';

/// A deck presented (#534): the slide alone on the whole screen, or the
/// presenter view, one switch away from each other.
///
/// The slide on screen is [place]'s: the slide view started there, and
/// finds the talk where it stopped.
final class SlidesPresentScreen extends StatefulWidget {
  /// Presents [slides] from [place].
  const new({
    required this.slides,
    required this.place,
    required this.resolveEmbed,
    this.presenter = false,
    this.touch = false,
    this.exitWhenUpright = false,
    super.key,
  });

  /// The deck.
  final List<Slide> slides;

  /// The slide on screen, shared with the slide view.
  final ValueNotifier<int> place;

  /// Resolves a picture's target.
  final Future<String?> Function(String target) resolveEmbed;

  /// Whether to open on the presenter view.
  final bool presenter;

  /// A touch screen: taps on the sides move, and a hint says so on entry.
  final bool touch;

  /// Whether turning the phone upright ends the talk: it began by
  /// turning the phone sideways.
  final bool exitWhenUpright;

  @override
  State<SlidesPresentScreen> createState() => _SlidesPresentScreenState();
}

final class _SlidesPresentScreenState extends State<SlidesPresentScreen> {
  late bool _presenter = widget.presenter;
  bool _overview = false;
  int _ringed = 0;
  bool _black = false;
  bool _bar = false;
  late bool _hint = widget.touch;
  Timer? _barTimer;
  Timer? _hintTimer;
  bool _leaving = false;

  /// When the timer started, null until the first move; the time it had
  /// counted before a pause.
  DateTime? _started;
  Duration _counted = Duration.zero;
  bool _paused = false;

  int get _count => widget.slides.length;
  int get _index => widget.place.value.clamp(0, _count - 1);

  @override
  void initState() {
    super.initState();
    widget.place.addListener(_moved);
    if (_hint) {
      _hintTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _hint = false);
      });
    }
  }

  @override
  void dispose() {
    widget.place.removeListener(_moved);
    _barTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  void _moved() {
    if (mounted) setState(() {});
  }

  void _go(int index) {
    // The talk's clock starts on its first move, not on opening.
    if (_started == null && !_paused) _started = DateTime.now();
    widget.place.value = index.clamp(0, _count - 1);
    if (_hint) setState(() => _hint = false);
  }

  void _exit() {
    if (_leaving) return;
    _leaving = true;
    Navigator.of(context).pop();
  }

  /// The time the talk has run.
  Duration get elapsed {
    final started = _started;
    return _counted +
        (started == null ? Duration.zero : DateTime.now().difference(started));
  }

  void _togglePause() => setState(() {
    final started = _started;
    if (started != null) {
      _counted += DateTime.now().difference(started);
      _started = null;
      _paused = true;
    } else {
      _started = DateTime.now();
      _paused = false;
    }
  });

  void _restartClock() => setState(() {
    _counted = Duration.zero;
    _started = null;
    _paused = false;
  });

  void _openOverview() => setState(() {
    _overview = true;
    _ringed = _index;
  });

  void _pick(int index) {
    setState(() => _overview = false);
    _go(index);
  }

  /// The mouse moved: the bar and the cursor show, and go after 2 s.
  void _poke() {
    _barTimer?.cancel();
    _barTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _bar = false);
    });
    if (!_bar) setState(() => _bar = true);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (_overview) return _overviewKey(key);
    if (key == LogicalKeyboardKey.escape) {
      _exit();
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageDown ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.enter) {
      _go(_index + 1);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.backspace) {
      _go(_index - 1);
    } else if (key == LogicalKeyboardKey.home) {
      _go(0);
    } else if (key == LogicalKeyboardKey.end) {
      _go(_count - 1);
    } else if (key == LogicalKeyboardKey.keyO) {
      _openOverview();
    } else if (key == LogicalKeyboardKey.keyB) {
      setState(() => _black = !_black);
    } else if (key == LogicalKeyboardKey.f5) {
      final presenter = HardwareKeyboard.instance.isAltPressed;
      setState(() => _presenter = presenter);
    } else if (_presenter && key == LogicalKeyboardKey.keyP) {
      _togglePause();
    } else if (_presenter && key == LogicalKeyboardKey.keyR) {
      _restartClock();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  KeyEventResult _overviewKey(LogicalKeyboardKey key) {
    final perRow = SlidesOverview.columnsFor(MediaQuery.sizeOf(context).width);
    final moves = {
      LogicalKeyboardKey.arrowRight: 1,
      LogicalKeyboardKey.arrowLeft: -1,
      LogicalKeyboardKey.arrowDown: perRow,
      LogicalKeyboardKey.arrowUp: -perRow,
    };
    if (moves[key] case final step?) {
      setState(() => _ringed = (_ringed + step).clamp(0, _count - 1));
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space) {
      _pick(_ringed);
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.keyO) {
      setState(() => _overview = false);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _tap(TapUpDetails details) {
    if (!widget.touch) return _go(_index + 1);
    final width = MediaQuery.sizeOf(context).width;
    final x = details.localPosition.dx;
    if (x < width / 3) {
      _go(_index - 1);
    } else if (x > width * 2 / 3) {
      _go(_index + 1);
    } else if (_hint) {
      setState(() => _hint = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exitWhenUpright &&
        MediaQuery.orientationOf(context) == Orientation.portrait) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _exit());
    }
    final Widget body;
    if (_overview) {
      body = SlidesOverview(
        slides: widget.slides,
        selected: _ringed,
        resolveEmbed: widget.resolveEmbed,
        onPick: _pick,
      );
    } else if (_presenter) {
      body = SlidesPresenterView(
        slides: widget.slides,
        index: _index,
        resolveEmbed: widget.resolveEmbed,
        elapsed: () => elapsed,
        paused: _paused,
        onGo: _go,
        onOverview: _openOverview,
        onSlideOnly: () => setState(() => _presenter = false),
        onExit: _exit,
        onPause: _togglePause,
        onRestart: _restartClock,
      );
    } else {
      body = _slideAlone(context);
    }
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Material(color: Colors.black, child: body),
    );
  }

  Widget _slideAlone(BuildContext context) {
    final slide = widget.slides[_index];
    return MouseRegion(
      cursor: _bar ? MouseCursor.defer : SystemMouseCursors.none,
      onHover: (_) => _poke(),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('slides-present'),
              behavior: HitTestBehavior.opaque,
              onTapUp: _tap,
              onHorizontalDragEnd: (details) {
                final speed = details.primaryVelocity ?? 0;
                if (speed < -300) _go(_index + 1);
                if (speed > 300) _go(_index - 1);
              },
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 300) _exit();
              },
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: SlideFrame(
                    key: ValueKey(_index),
                    markdown: slide.markdown,
                    resolveEmbed: widget.resolveEmbed,
                    live: false,
                  ),
                ),
              ),
            ),
          ),
          if (_black)
            const Positioned.fill(
              child: IgnorePointer(child: ColoredBox(color: Colors.black)),
            ),
          if (widget.touch)
            Positioned(
              right: 14,
              bottom: 10,
              child: Text(
                '${_index + 1} / $_count',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: IgnorePointer(
                ignoring: !_bar,
                child: AnimatedOpacity(
                  opacity: _bar ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Center(
                    child: SlidesPresentBar(
                      index: _index,
                      count: _count,
                      onPrevious: () => _go(_index - 1),
                      onNext: () => _go(_index + 1),
                      onOverview: _openOverview,
                      onNotes: () => setState(() => _presenter = true),
                      onExit: _exit,
                    ),
                  ),
                ),
              ),
            ),
          if (_hint) const Positioned.fill(child: _TapHint()),
        ],
      ),
    );
  }
}

/// Where to tap, over the slide when a phone starts presenting.
final class _TapHint extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: Colors.white, fontSize: 13);
    Widget zone(IconData icon, String label) => Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 6),
          Text(label, style: style, textAlign: TextAlign.center),
        ],
      ),
    );
    return IgnorePointer(
      child: ColoredBox(
        key: const Key('slides-tap-hint'),
        color: Colors.black.withValues(alpha: 0.6),
        child: Row(
          children: [
            zone(Icons.chevron_left, AppStrings.slidesPrevious),
            zone(Icons.arrow_downward, AppStrings.slidesSwipeToExit),
            zone(Icons.chevron_right, AppStrings.slidesNext),
          ],
        ),
      ),
    );
  }
}
