/// Find & replace on the unified source surface (#245, phase 3).
///
/// The legacy editor's find was re_editor's own; the WYSIWYG's walks the Quill
/// document. This one walks the surface's buffer, and is driven by the same
/// bar (`FindBar`) as the WYSIWYG's.
///
/// Three decisions:
///
/// * **Literal, whole-note, on this isolate.** `String.indexOf` over the note
///   is a native scan; the 22 MB stress note is searched in tens of
///   milliseconds, and a note past a megabyte is searched a moment
///   after the query stops changing rather than on every character.
/// * **The current match is the selection.** Going to a match selects it in
///   the note, so Escape leaves it selected and the next keystroke replaces it
///   — what every editor does — and the view has one thing to bring into view.
/// * **An edit does not move the caret.** A note edited while the bar is open
///   is searched again a moment later without selecting anything: the writer
///   is typing in the note, and the bar follows.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/find_bar.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';

/// The matches a view paints, line by line.
abstract interface class SourceMatches implements Listenable {
  /// Whether the bar is open: the caret it moves is followed as the writer's
  /// is.
  bool get visible;

  /// The matches overlapping `[start, end)` of the note, clipped to it and
  /// made local to [start], each with whether it is the current one.
  Iterable<(int, int, bool)> within(int start, int end);
}

/// The find state of one note on the unified surface.
final class SourceFindController extends ChangeNotifier
    implements FindBarModel, SourceMatches {
  /// Finds in the note `surface` answers with; [onClose] takes the focus back
  /// to it.
  new({required this._surface, this.onClose});

  /// The note being searched, when there is one.
  final MarkdownSurfaceController? Function() _surface;

  /// Called when the bar closes, so the note has the keyboard again.
  final VoidCallback? onClose;

  @override
  final TextEditingController findInput = TextEditingController();

  @override
  final TextEditingController replaceInput = TextEditingController();

  /// The query field's focus: the bar takes it when it opens.
  @override
  final FocusNode findFocus = FocusNode(debugLabel: 'source find');

  /// The replacement field's focus: Tab goes there from the query.
  @override
  final FocusNode replaceFocus = FocusNode(debugLabel: 'source replace');

  bool _visible = false;
  bool _replaceMode = false;
  bool _caseSensitive = false;

  /// Where each match starts and ends, in note order.
  List<int> _starts = const <int>[];
  List<int> _ends = const <int>[];
  int _index = -1;

  /// The buffer and the revision the matches were found in.
  SourceBuffer? _buffer;
  int _revision = -1;

  /// The text they were found in, for Replace all.
  String _text = '';

  Timer? _debounce;

  /// A note up to this long is searched as the query is typed; a longer one
  /// once the query rests for [_rest].
  static const int _immediateLimit = 1 << 20;
  static const Duration _rest = Duration(milliseconds: 200);

  /// The most matches kept: past it, the bar counts no further.
  static const int _maxMatches = 100000;

  @override
  bool get visible => _visible;

  @override
  bool get replaceMode => _replaceMode;

  @override
  bool get caseSensitive => _caseSensitive;

  @override
  int get matchCount => _starts.length;

  @override
  int get matchIndex => _index;

  /// Opens the bar — with the replace row for [replace] — on the selection
  /// when it is a piece of one line, or on the query it had.
  void open({bool replace = false}) {
    final surface = _surface();
    if (surface != null) {
      final selection = surface.selection.clampTo(surface.buffer.length);
      if (!selection.isCollapsed &&
          selection.end - selection.start <= 200 &&
          surface.buffer.lineOf(selection.start) ==
              surface.buffer.lineOf(selection.end)) {
        findInput.text = surface.buffer.substring(
          selection.start,
          selection.end,
        );
      }
    }
    findInput.selection = TextSelection(
      baseOffset: 0,
      extentOffset: findInput.text.length,
    );
    _visible = true;
    _replaceMode = replace || _replaceMode;
    _run(reveal: true);
    findFocus.requestFocus();
  }

  /// Closes the bar and gives the note the keyboard back — unless
  /// [refocus] is false: the note itself is going (another note opens).
  @override
  void close({bool refocus = true}) {
    if (!_visible) return;
    _debounce?.cancel();
    _visible = false;
    _replaceMode = false;
    _clear();
    notifyListeners();
    if (refocus) onClose?.call();
  }

  @override
  void toggleMode() {
    _replaceMode = !_replaceMode;
    notifyListeners();
  }

  @override
  void toggleCaseSensitive() {
    _caseSensitive = !_caseSensitive;
    _run(reveal: true);
  }

  @override
  void search() {
    _debounce?.cancel();
    final length = _surface()?.buffer.length ?? 0;
    if (length <= _immediateLimit) {
      _run(reveal: true);
    } else {
      _debounce = Timer(_rest, () => _run(reveal: true));
    }
  }

  /// The note changed while the bar may be open: its matches are found again
  /// a moment later, without moving the caret.
  void noteEdited() {
    if (!_visible) return;
    _debounce?.cancel();
    _debounce = Timer(_rest, () => _run(reveal: false));
  }

  @override
  void nextMatch() => _step(1);

  @override
  void previousMatch() => _step(-1);

  void _step(int by) {
    _fresh();
    final count = _starts.length;
    if (count == 0) return;
    _index = _index < 0 ? 0 : (_index + by + count) % count;
    _select();
    notifyListeners();
  }

  @override
  void replaceMatch() {
    _fresh();
    final surface = _surface();
    if (surface == null || _index < 0 || _index >= _starts.length) return;
    final start = _starts[_index];
    final end = _ends[_index];
    final replacement = replaceInput.text;
    surface.replaceRange(
      start,
      end,
      replacement,
      caret: SelectionModel.at(start + replacement.length),
    );
    // The next match is the one after what was put in: a replacement that
    // contains the query is not found again under the caret.
    _run(reveal: true, from: start + replacement.length);
  }

  @override
  void replaceAllMatches() {
    _fresh();
    final surface = _surface();
    if (surface == null || _starts.isEmpty) return;
    final replacement = replaceInput.text;
    final text = _text;
    final out = StringBuffer();
    var at = 0;
    for (var match = 0; match < _starts.length; match++) {
      out
        ..write(text.substring(at, _starts[match]))
        ..write(replacement);
      at = _ends[match];
    }
    out.write(text.substring(at));
    final caret = _starts.first;
    // One edit, one undo step, however many matches there were.
    surface.applyEdit(out.toString(), TextSelection.collapsed(offset: caret));
    _run(reveal: false);
  }

  @override
  Iterable<(int, int, bool)> within(int start, int end) sync* {
    if (!_visible || _starts.isEmpty || end <= start) return;
    // The first match that ends after [start].
    var low = 0;
    var high = _ends.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_ends[mid] <= start) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    for (var match = low; match < _starts.length; match++) {
      final from = _starts[match];
      if (from >= end) break;
      final to = _ends[match];
      yield (
        (from < start ? start : from) - start,
        (to > end ? end : to) - start,
        match == _index,
      );
    }
  }

  /// Finds the query again when the note has changed since it was last
  /// searched, so a step or a replacement never acts on stale offsets.
  void _fresh() {
    final buffer = _surface()?.buffer;
    if (buffer == null) return;
    if (!identical(buffer, _buffer) || buffer.revision != _revision) {
      _debounce?.cancel();
      _run(reveal: false);
    }
  }

  /// Searches the note; the current match is the first at or after [from]
  /// (the selection's start by default), selected when [reveal].
  void _run({required bool reveal, int? from}) {
    final surface = _surface();
    final query = findInput.text;
    if (surface == null || query.isEmpty) {
      _clear();
      notifyListeners();
      return;
    }
    final buffer = surface.buffer;
    final text = buffer.text;
    final starts = <int>[];
    final ends = <int>[];
    if (_caseSensitive) {
      var at = text.indexOf(query);
      while (at >= 0 && starts.length < _maxMatches) {
        starts.add(at);
        ends.add(at + query.length);
        at = text.indexOf(query, at + query.length);
      }
    } else {
      // A pattern, not a lowered copy: lowering can change a string's length
      // (`İ`), and the offsets have to be the note's.
      final pattern = RegExp(
        RegExp.escape(query),
        caseSensitive: false,
        unicode: true,
      );
      for (final match in pattern.allMatches(text)) {
        if (match.end == match.start) continue;
        starts.add(match.start);
        ends.add(match.end);
        if (starts.length >= _maxMatches) break;
      }
    }
    _starts = starts;
    _ends = ends;
    _buffer = buffer;
    _revision = buffer.revision;
    _text = text;
    final anchor = from ?? surface.selection.clampTo(buffer.length).start;
    if (starts.isEmpty) {
      _index = -1;
    } else {
      final next = starts.indexWhere((start) => start >= anchor);
      _index = next < 0 ? 0 : next;
      if (reveal) _select();
    }
    notifyListeners();
  }

  void _select() {
    final surface = _surface();
    if (surface == null || _index < 0 || _index >= _starts.length) return;
    surface.select(
      SelectionModel(anchor: _starts[_index], extent: _ends[_index]),
    );
  }

  void _clear() {
    _starts = const <int>[];
    _ends = const <int>[];
    _index = -1;
    _buffer = null;
    _revision = -1;
    _text = '';
  }

  @override
  void dispose() {
    _debounce?.cancel();
    findInput.dispose();
    replaceInput.dispose();
    findFocus.dispose();
    replaceFocus.dispose();
    super.dispose();
  }
}
