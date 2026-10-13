/// Which of the open note's links name nothing (#847), kept current while the
/// note is edited and the library changes.
///
/// Nothing here is on the drawing's path. The links are resolved against the
/// index in one batch ([resolveDeadLinks]) when the note loads, a pause after
/// an edit, and a pause after the library's index moves — a note made,
/// renamed or deleted can turn a link live or dead — and the editor and the
/// read view only ask the answer. A resolution that was overtaken by a newer
/// one is dropped.
///
/// The note is read for its links only when its text may have changed (it
/// loaded, or was edited): a move of the index resolves again the links
/// already read, so a library busy elsewhere never re-reads a long note.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/links/dead_link_checker.dart';
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/links/parser.dart';

/// The open note's dead links, as a value the drawing listens to.
final class DeadLinkWatcher extends ChangeNotifier
    implements ValueListenable<DeadLinks> {
  /// Watches the links of a note: `source` is the library to resolve them
  /// against (null while it is not ready: nothing is dead then), `links`
  /// reads the note's links now (null when it has none to give), `notePath`
  /// is the note's library-relative path, and `delay` is how long to wait
  /// after an edit or an index change before resolving again.
  new({
    required this._source,
    required this._links,
    required this._notePath,
    required this._delay,
  });

  final DeadLinkSource? Function() _source;
  final Future<List<ParsedLink>?> Function() _links;
  final String? Function() _notePath;
  final Duration Function() _delay;

  static const AppLogger _log = AppLogger(name: 'links');

  DeadLinks _value = DeadLinks.none;

  /// The note's links as last read, or null when the text changed since and
  /// they are to be read again.
  List<ParsedLink>? _read;

  /// Moves with every change of the note's text: a read that started before
  /// one is not kept.
  int _text = 0;
  Timer? _timer;
  StreamSubscription<void>? _changes;
  DeadLinkSource? _watched;
  int _run = 0;
  bool _disposed = false;

  @override
  DeadLinks get value => _value;

  /// The library to resolve against was replaced (it opened, or another one
  /// did): its announcements are the ones listened to from now on.
  void sourceChanged() {
    final source = _source();
    if (identical(source, _watched)) return;
    unawaited(_changes?.cancel());
    _watched = source;
    _changes = source?.changes.listen((_) => _later());
  }

  /// Forgets what the previous note's links resolved to: another note is
  /// being opened, and none of its links is known dead yet.
  void clear() {
    _timer?.cancel();
    _run++;
    _textChanged();
    _set(DeadLinks.none);
  }

  /// The note was edited: its links are read and resolved again once it has
  /// been quiet for a moment.
  void edited() {
    if (_disposed) return;
    _textChanged();
    _later();
  }

  /// Reads the note's links and resolves them now: the note (re)loaded, or
  /// the library it is resolved against changed. Only the newest resolution
  /// lands.
  void refresh() {
    if (_disposed) return;
    _textChanged();
    _resolveNow();
  }

  void _textChanged() {
    _text++;
    _read = null;
  }

  /// Resolves once things have been quiet for a moment: the links already
  /// read, unless an edit asked for them to be read again.
  void _later() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(_delay(), _resolveNow);
  }

  void _resolveNow() {
    if (_disposed) return;
    _timer?.cancel();
    sourceChanged();
    unawaited(_resolve(++_run));
  }

  Future<void> _resolve(int run) async {
    final source = _source();
    if (source == null) {
      _set(DeadLinks.none);
      return;
    }
    try {
      var links = _read;
      if (links == null) {
        final text = _text;
        links = await _links();
        if (links == null) {
          if (run == _run) _set(DeadLinks.none);
          return;
        }
        if (text == _text) _read = links;
      }
      final dead = await resolveDeadLinks(source, links, from: _notePath());
      if (run == _run) _set(dead);
    } on Object catch (error) {
      // A note that cannot be read for its links, or an index that is closing
      // under the question: the links stay as they were drawn.
      _log.debug('dead links not resolved: $error');
    }
  }

  void _set(DeadLinks next) {
    if (_disposed || next == _value) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_changes?.cancel());
    super.dispose();
  }
}
