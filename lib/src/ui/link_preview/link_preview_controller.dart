import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset;
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/links/preview_reader.dart';

/// A preview card being shown: what it previews, where the pointer was when
/// it opened.
@immutable
final class ShownPreview {
  /// The card for [link], holding [preview], opened with the pointer at
  /// [at] (global coordinates).
  const new({required this.link, required this.preview, required this.at});

  /// The link it was opened from.
  final PreviewLink link;

  /// What it shows.
  final LinkPreview preview;

  /// Where the pointer was.
  final Offset at;
}

/// When a link preview card opens and closes (#846).
///
/// A pointer on a link asks for a card ([enter]); a moment later — the
/// *intent* pause of a hover, nothing at all when the opening modifier is the
/// intent — the link is resolved and read, and the card is up if it names a
/// note. The pointer leaving the link ([leave]) closes it after a short grace
/// that lets the pointer cross onto the card, which stays open while the
/// pointer is on it (it scrolls); `Esc`, a scroll of the note, a press
/// anywhere and an edit close it at once ([close]). A link that names
/// nothing opens nothing, and a read already done is the library's to keep
/// (see `PreviewSource.previewText`).
final class LinkPreviewController extends ChangeNotifier {
  /// A controller that previews the links of the note at the library-relative
  /// path `notePath` in the library `source`, while `enabled` says the setting
  /// is on; a note `unsavedText` has a text for (by its library-relative
  /// path) is shown as that text, its open buffer, instead of its file. The
  /// pauses are the hover intent, and the grace of crossing from a link to
  /// its card.
  new({
    required this._source,
    required this._notePath,
    required this._enabled,
    String? Function(String path)? unsavedText,
    this.hoverDelay = const Duration(milliseconds: 400),
    this.leaveGrace = const Duration(milliseconds: 200),
  }) : _unsavedText = unsavedText;

  final LibraryLinks? Function() _source;
  final String? Function() _notePath;
  final bool Function() _enabled;
  final String? Function(String path)? _unsavedText;

  /// How long a pointer rests on a link, with no modifier, before its card
  /// opens: the pointer sweeping across a page opens nothing.
  final Duration hoverDelay;

  /// How long a card stays after the pointer left the link, for the pointer
  /// to reach the card.
  final Duration leaveGrace;

  ShownPreview? _shown;
  PreviewLink? _asked;
  Timer? _opening;
  Timer? _closing;
  int _run = 0;
  bool _disposed = false;

  /// The card up now, or null.
  ShownPreview? get shown => _shown;

  /// Whether previews are on.
  bool get enabled => _enabled();

  /// The pointer is on [link], at [at] (global): the card for it opens after
  /// [delay] (the controller's [hoverDelay] when null).
  void enter(PreviewLink link, Offset at, {Duration? delay}) {
    if (_disposed || !_enabled()) return;
    _closing?.cancel();
    if (_shown?.link == link) return;
    if (_asked == link) return;
    _opening?.cancel();
    _asked = link;
    final wait = delay ?? hoverDelay;
    if (wait == Duration.zero) {
      unawaited(_open(link, at, ++_run));
    } else {
      final run = ++_run;
      _opening = Timer(wait, () => unawaited(_open(link, at, run)));
    }
  }

  /// The pointer left the link: nothing opens for it any more, and the card,
  /// if one is up, goes unless the pointer reaches it ([cardEntered]).
  void leave() {
    _opening?.cancel();
    _asked = null;
    _run++;
    if (_shown != null) _later();
  }

  /// The pointer is on the card: it stays.
  void cardEntered() => _closing?.cancel();

  /// The pointer left the card: it goes.
  void cardLeft() => _later();

  void _later() {
    // The pointer's exit can be reported as the note goes: nothing is owed.
    if (_disposed) return;
    _closing?.cancel();
    _closing = Timer(leaveGrace, close);
  }

  /// Closes the card now and forgets any open under way.
  void close() {
    _opening?.cancel();
    _closing?.cancel();
    _asked = null;
    _run++;
    if (_shown == null) return;
    _shown = null;
    if (!_disposed) notifyListeners();
  }

  /// The preview of [link] now, for a surface that shows it its own way (the
  /// touch sheet); null when it points at nothing a card can show.
  Future<LinkPreview?> read(PreviewLink link) async {
    final source = _source();
    if (source == null || !_enabled()) return null;
    try {
      final unsaved = _unsavedText;
      final previews = unsaved == null
          ? source
          : UnsavedFirstPreviews(source, unsaved);
      return await previewOfLink(source, previews, link, from: _notePath());
    } on Object {
      return null;
    }
  }

  Future<void> _open(PreviewLink link, Offset at, int run) async {
    final preview = await read(link);
    if (_disposed || run != _run || preview == null) return;
    _shown = ShownPreview(link: link, preview: preview, at: at);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _opening?.cancel();
    _closing?.cancel();
    super.dispose();
  }
}
