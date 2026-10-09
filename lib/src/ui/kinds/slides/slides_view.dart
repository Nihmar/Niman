import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show wideBreakpoint;
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/kinds/slides/slide_dots.dart';
import 'package:niman/src/ui/kinds/slides/slide_frame.dart';
import 'package:niman/src/ui/kinds/slides/slide_place.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slide_stage.dart';
import 'package:niman/src/ui/kinds/slides/slide_thumbnail.dart';
import 'package:niman/src/ui/kinds/slides/slides_present.dart';
import 'package:niman/src/ui/kinds/slides/slides_wide_layout.dart';
import 'package:niman/src/ui/kinds/slides/speaker_notes.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/ui/window_controller.dart';

/// The slides kind's body (#534): the slide on screen large, its speaker
/// notes under it, and the others as thumbnails — a row of them on a wide
/// window, a swipe and dots on a phone.
///
/// The view only reads the note; the slides are edited in the raw editor.
final class SlidesNoteView extends ConsumerStatefulWidget {
  /// Shows the slides of [text], the note [host] holds.
  const new({required this.text, required this.host, super.key});

  /// The full note text.
  final String text;

  /// The note's window: its path, pictures and links.
  final NoteKindHost host;

  /// From this length on, an edit's split runs on a background isolate
  /// (#695): a scan of every block per keystroke is a long deck's jank.
  /// A short note splits in less than the hop costs.
  @visibleForTesting
  static const int isolateFrom = 64 * 1024;

  @override
  ConsumerState<SlidesNoteView> createState() => _SlidesNoteViewState();
}

final class _SlidesNoteViewState extends ConsumerState<SlidesNoteView> {
  late List<Slide> _slides = splitSlides(widget.text);
  late String _path = widget.host.notePath;
  late ValueNotifier<int> _place = slidePlaceOf(_path);
  late final PageController _pages = PageController(initialPage: _index);
  final ScrollController _strip = ScrollController();

  /// The deck's formulas, shared by the slide, the row and the swipe
  /// (#672).
  final MathCache _mathCache = MathCache();

  int get _index => _place.value.clamp(0, _slides.length - 1);

  /// Bumped by every split: a background one that lands after a later
  /// one is dropped.
  int _splits = 0;

  /// Splits [text], at once when it is short; otherwise the slides on
  /// screen stay until the background split lands.
  void _split(String text) {
    final at = ++_splits;
    if (text.length < SlidesNoteView.isolateFrom) {
      _slides = splitSlides(text);
      return;
    }
    unawaited(
      _splitOff(text).then((slides) {
        if (!mounted || at != _splits) return;
        setState(() => _slides = slides);
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    _live++;
    _place.addListener(_placeMoved);
  }

  @override
  void didUpdateWidget(covariant SlidesNoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _split(widget.text);
    if (widget.host.notePath != _path) {
      _place.removeListener(_placeMoved);
      _path = widget.host.notePath;
      _place = slidePlaceOf(_path)..addListener(_placeMoved);
      // The swipe and the row still show the old path's slide; they move
      // once this frame is built, not in the middle of it.
      WidgetsBinding.instance.addPostFrameCallback((_) => _placeMoved());
    }
  }

  @override
  void dispose() {
    // The view rebuilt in the other layout mounts before this one goes, so
    // the count drops to nothing only when the slides left the screen: a
    // phone turned elsewhere must not present them on their return.
    if (--_live == 0) _held = null;
    _place.removeListener(_placeMoved);
    _pages.dispose();
    _strip.dispose();
    _mathCache.dispose();
    super.dispose();
  }

  /// The slide moved, here or elsewhere (presenting stopped on another):
  /// the swipe and the thumbnail row follow.
  void _placeMoved() {
    if (!mounted) return;
    setState(() {});
    final index = _index;
    if (_pages.hasClients && _pages.page?.round() != index) {
      _pages.jumpToPage(index);
    }
    if (_strip.hasClients) {
      final position = _strip.position;
      final target =
          index * (slideThumbWidth + SlidesWideLayout.thumbGap) -
          (position.viewportDimension - slideThumbWidth) / 2;
      _strip.animateTo(
        target.clamp(0, position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _go(int index) => _place.value = index.clamp(0, _slides.length - 1);

  // ponytail: one orientation for the whole run, so a slide view rebuilt in
  // the other layout as the phone turns still knows how it was held.
  static Orientation? _held;
  static int _live = 0;

  void _present({bool presenter = false, bool byTurning = false}) => unawaited(
    presentSlides(
      context,
      text: widget.text,
      notePath: _path,
      resolveEmbed: widget.host.resolveEmbed,
      window: ref.read(windowControllerProvider),
      presenter: presenter,
      byTurning: byTurning,
    ),
  );

  /// Turning a phone sideways while its slides are on screen presents
  /// them; turning it upright again ends that (the presenting screen's).
  void _watchTurn(BuildContext context) {
    if (!isSlidesPhone(context)) return;
    final now = MediaQuery.orientationOf(context);
    if (_held == Orientation.portrait && now == Orientation.landscape) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _present(byTurning: true);
      });
    }
    _held = now;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (slidesPresentKey(event) case final presenter?) {
      _present(presenter: presenter);
      return KeyEventResult.handled;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.pageDown) {
      _go(_index + 1);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.pageUp) {
      _go(_index - 1);
    } else if (key == LogicalKeyboardKey.home) {
      _go(0);
    } else if (key == LogicalKeyboardKey.end) {
      _go(_slides.length - 1);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  SlideFrame _frame(Slide slide, {bool live = true}) => SlideFrame(
    markdown: slide.markdown,
    resolveEmbed: widget.host.resolveEmbed,
    mathCache: _mathCache,
    onTapLink: live ? (href) => widget.host.openLink(context, href) : null,
    onTapWikiLink: live
        ? (inner) => widget.host.openWikiLink(context, inner)
        : null,
    live: live,
  );

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    _watchTurn(context);
    return Focus(
      autofocus: wide,
      onKeyEvent: _onKey,
      child: wide
          ? SlidesWideLayout(
              slides: _slides,
              index: _index,
              strip: _strip,
              frame: _frame,
              onGo: _go,
            )
          : _narrow(context),
    );
  }

  Widget _narrow(BuildContext context) {
    final slide = _slides[_index];
    final notes = slide.notes;
    final scheme = Theme.of(context).colorScheme;
    final showMarkdown = widget.host.showMarkdown;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: SlideStage(
              child: PageView.builder(
                key: const Key('slides-pages'),
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: _go,
                itemBuilder: (context, index) => _frame(_slides[index]),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Text(
                '${_index + 1} / ${_slides.length}',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 16),
              // Dots say where in a short deck; a long one has the count.
              if (_slides.length <= 12)
                Expanded(
                  child: SlideDots(count: _slides.length, index: _index),
                )
              else
                const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
        ),
        Expanded(
          child: notes == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                  child: SpeakerNotes(notes: notes),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (showMarkdown != null)
                OutlinedButton.icon(
                  key: const Key('slides-markdown'),
                  onPressed: showMarkdown,
                  icon: const Icon(Icons.article_outlined),
                  label: Text(AppStrings.slidesMarkdown),
                ),
              const Spacer(),
              FilledButton.icon(
                key: const Key('slides-present-button'),
                onPressed: _present,
                icon: const Icon(Icons.open_in_full),
                label: Text(AppStrings.slidesPresent),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// [text] split on a background isolate. Top level: a closure made in the
/// state would carry the state, and the widget tree with it, to the
/// isolate.
Future<List<Slide>> _splitOff(String text) =>
    Isolate.run(() => splitSlides(text));
