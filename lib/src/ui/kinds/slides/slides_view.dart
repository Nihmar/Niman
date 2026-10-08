import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/core/settings/library_settings.dart'
    show wideBreakpoint;
import 'package:niman/src/frontmatter/note_kind.dart';
import 'package:niman/src/ui/kinds/slides/slide_frame.dart';
import 'package:niman/src/ui/kinds/slides/slide_place.dart';
import 'package:niman/src/ui/kinds/slides/slide_split.dart';
import 'package:niman/src/ui/kinds/slides/slides_parts.dart';
import 'package:niman/src/ui/kinds/slides/slides_present.dart';
import 'package:niman/src/ui/strings.dart';

/// The slides kind's body (#534): the slide on screen large, its speaker
/// notes under it, and the others as thumbnails — a row of them on a wide
/// window, a swipe and dots on a phone.
///
/// The view only reads the note; the slides are edited in the raw editor.
final class SlidesNoteView extends StatefulWidget {
  /// Shows the slides of [text], the note [host] holds.
  const new({required this.text, required this.host, super.key});

  /// The full note text.
  final String text;

  /// The note's window: its path, pictures and links.
  final NoteKindHost host;

  @override
  State<SlidesNoteView> createState() => _SlidesNoteViewState();
}

final class _SlidesNoteViewState extends State<SlidesNoteView> {
  late List<Slide> _slides = splitSlides(widget.text);
  late String _path = widget.host.notePath;
  late ValueNotifier<int> _place = slidePlaceOf(_path);
  late final PageController _pages = PageController(initialPage: _index);
  final ScrollController _strip = ScrollController();

  static const double _thumbGap = 10;

  int get _index => _place.value.clamp(0, _slides.length - 1);

  @override
  void initState() {
    super.initState();
    _place.addListener(_placeMoved);
  }

  @override
  void didUpdateWidget(covariant SlidesNoteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _slides = splitSlides(widget.text);
    if (widget.host.notePath != _path) {
      _place.removeListener(_placeMoved);
      _path = widget.host.notePath;
      _place = slidePlaceOf(_path)..addListener(_placeMoved);
    }
  }

  @override
  void dispose() {
    _place.removeListener(_placeMoved);
    _pages.dispose();
    _strip.dispose();
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
          index * (slideThumbWidth + _thumbGap) -
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

  void _present({bool presenter = false, bool lockLandscape = false}) =>
      unawaited(
        presentSlides(
          context,
          text: widget.text,
          notePath: _path,
          resolveEmbed: widget.host.resolveEmbed,
          presenter: presenter,
          lockLandscape: lockLandscape,
        ),
      );

  /// Turning a phone sideways while its slides are on screen presents
  /// them; turning it upright again ends that (the presenting screen's).
  void _watchTurn(BuildContext context) {
    if (!isSlidesPhone(context)) return;
    final now = MediaQuery.orientationOf(context);
    if (_held == Orientation.portrait && now == Orientation.landscape) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _present();
      });
    }
    _held = now;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
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
    } else if (key == LogicalKeyboardKey.f5) {
      _present(presenter: HardwareKeyboard.instance.isAltPressed);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  SlideFrame _frame(Slide slide, {bool live = true}) => SlideFrame(
    markdown: slide.markdown,
    resolveEmbed: widget.host.resolveEmbed,
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
      child: wide ? _wide(context) : _narrow(context),
    );
  }

  Widget _wide(BuildContext context) {
    final slide = _slides[_index];
    final notes = slide.notes;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
            child: LayoutBuilder(
              builder: (context, box) {
                const notesHeight = 120.0;
                final room = box.maxHeight - (notes == null ? 0 : notesHeight);
                final width = math.min(box.maxWidth, room * 16 / 9);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: width,
                      height: width * 9 / 16,
                      child: SlideStage(child: _frame(slide)),
                    ),
                    if (notes != null)
                      SizedBox(
                        width: width,
                        height: notesHeight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SpeakerNotes(notes: notes),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant),
        SizedBox(
          height: 116,
          child: Row(
            children: [
              Expanded(
                child: ListView.separated(
                  key: const Key('slides-strip'),
                  controller: _strip,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _slides.length,
                  separatorBuilder: (_, _) => const SizedBox(width: _thumbGap),
                  itemBuilder: (context, index) => SlideThumbnail(
                    key: Key('slide-thumb-$index'),
                    number: index + 1,
                    selected: index == _index,
                    onTap: () => _go(index),
                    child: _frame(_slides[index], live: false),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${_index + 1} / ${_slides.length}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
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
                onPressed: () => _present(lockLandscape: true),
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
