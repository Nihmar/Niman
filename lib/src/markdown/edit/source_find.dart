/// Find & replace on the unified source surface (#245, phase 3).
///
/// The legacy editor's find was re_editor's own; the WYSIWYG's walks the Quill
/// document. This one walks the surface's buffer, and is driven by the same
/// bar (`FindBar`) as the WYSIWYG's.
///
/// Three decisions:
///
/// * **Literal, a line at a time, on this isolate.** The note is never joined
///   (#1047): each line is searched where the buffer keeps it, matches are
///   offsets, and a note past a megabyte is searched in slices of lines a
///   moment after the query stops changing rather than on every character.
///   Replace shifts the matches after it and reads again only its own line;
///   Replace all makes one edit over the span of the matches, built from the
///   buffer's pieces, as one undo step. A query that spans lines is the one
///   case that reads the note whole.
/// * **The current match is the selection.** Going to a match selects it in
///   the note, so Escape leaves it selected and the next keystroke replaces it
///   — what every editor does — and the view has one thing to bring into view.
/// * **An edit does not move the caret.** A note edited while the bar is open
///   is searched again a moment later without selecting anything: the writer
///   is typing in the note, and the bar follows.
library;

import 'dart:async';
import 'dart:math';

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

  /// Opens the bar on the first of [terms] the note holds, as the writer
  /// would have typed it: that match selected and in view, every other
  /// marked (#1045). A note that holds none opens as it was. The bar does
  /// not take the keyboard: the note keeps it.
  void openFinding(List<String> terms) {
    final surface = _surface();
    if (surface == null) return;
    final text = surface.buffer.text;
    String? best;
    var bestAt = -1;
    for (final term in terms) {
      if (term.isEmpty) continue;
      final found = RegExp(
        RegExp.escape(term),
        caseSensitive: false,
        unicode: true,
      ).firstMatch(text);
      if (found != null && (bestAt < 0 || found.start < bestAt)) {
        best = term;
        bestAt = found.start;
      }
    }
    if (best == null) return;
    findInput.text = best;
    _visible = true;
    _run(reveal: true, from: 0);
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
    final buffer = surface.buffer;
    surface.replaceRange(
      start,
      end,
      replacement,
      caret: SelectionModel.at(start + replacement.length),
    );
    if (buffer.revision != _revision + 1 ||
        !identical(buffer, _buffer) ||
        _hasBreak(findInput.text)) {
      // Not the edit alone (another edit got in): search again.
      _run(reveal: true, from: start + replacement.length);
      return;
    }
    // The matches after the one replaced move by what it changed; only the
    // line it was on is read again (#1047), not the note.
    _followReplacement(
      buffer,
      start,
      end,
      replacement.length,
      from: start + replacement.length,
    );
  }

  /// Keeps the matches after the replacement of `[start, end)` by `length`
  /// characters: the one replaced goes, those after it move, and the line the
  /// replacement is on is searched again — a replacement can make a match
  /// with its neighbours, or leave the query in itself.
  void _followReplacement(
    SourceBuffer buffer,
    int start,
    int end,
    int length, {
    required int from,
  }) {
    final delta = length - (end - start);
    final line = buffer.lineOf(start);
    final lineStart = buffer.offsetOfLine(line);
    final lineEnd = lineStart + buffer.lineLengthAt(line);
    final starts = <int>[];
    final ends = <int>[];
    var at = 0;
    // Before the line: unchanged.
    while (at < _starts.length && _ends[at] <= lineStart) {
      starts.add(_starts[at]);
      ends.add(_ends[at]);
      at++;
    }
    // Those on the replaced line are dropped, and the line read again.
    while (at < _starts.length && _starts[at] < end) {
      at++;
    }
    final query = findInput.text;
    final pattern = _pattern(query);
    _matchLine(buffer.lineAt(line), lineStart, query, pattern, starts, ends);
    // After it: moved. (A match on the same line that began after the one
    // replaced is found again with the line, so skip those.)
    while (at < _starts.length && _starts[at] < lineEnd - delta) {
      at++;
    }
    for (; at < _starts.length; at++) {
      starts.add(_starts[at] + delta);
      ends.add(_ends[at] + delta);
    }
    _starts = starts;
    _ends = ends;
    _revision = buffer.revision;
    if (starts.isEmpty) {
      _index = -1;
    } else {
      final next = starts.indexWhere((s) => s >= from);
      _index = next < 0 ? 0 : next;
      _select();
    }
    notifyListeners();
  }

  @override
  void replaceAllMatches() {
    _fresh();
    final surface = _surface();
    if (surface == null || _starts.isEmpty) return;
    final replacement = replaceInput.text;
    // The caret stays where the writer had it, moved by the matches before
    // it; the note is not scrolled to the first match.
    final buffer = surface.buffer;
    final was = surface.selection.clampTo(buffer.length);
    var caret = was.extent;
    for (var match = 0; match < _starts.length; match++) {
      if (_ends[match] <= was.extent) {
        caret += replacement.length - (_ends[match] - _starts[match]);
      }
    }
    // One edit over the span from the first match to the last, built from
    // the buffer's own pieces (the note is not joined), and so one undo step
    // however many matches there were; the history keeps only the lines that
    // changed (#1050).
    final first = _starts.first;
    final out = StringBuffer();
    var at = first;
    for (var match = 0; match < _starts.length; match++) {
      out
        ..write(buffer.substring(at, _starts[match]))
        ..write(replacement);
      at = _ends[match];
    }
    surface.replaceRange(
      first,
      at,
      out.toString(),
      caret: SelectionModel.at(caret),
    );
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
      // At once: the caller acts on the matches it asks for.
      _run(reveal: false, sync: true);
    }
  }

  /// Searches the note; the current match is the first at or after [from]
  /// (the selection's start by default), selected when [reveal].
  void _run({required bool reveal, int? from, bool sync = false}) {
    final surface = _surface();
    final query = findInput.text;
    if (surface == null || query.isEmpty) {
      _clear();
      notifyListeners();
      return;
    }
    final buffer = surface.buffer;
    _slice?.cancel();
    final scan = ++_scanId;
    final revision = buffer.revision;
    final pattern = _pattern(query);
    final starts = <int>[];
    final ends = <int>[];
    if (_hasBreak(query)) {
      // A query that spans lines cannot be found a line at a time: the one
      // case that reads the note whole.
      final text = buffer.text;
      _matchLine(text, 0, query, pattern, starts, ends);
      _finish(buffer, starts, ends, reveal: reveal, from: from);
      return;
    }
    var line = 0;
    var offset = 0;
    // A slice of lines, then the frame back: a long note's matches arrive
    // over several turns instead of one freeze.
    void slice() {
      if (scan != _scanId || buffer.revision != revision) return;
      slices++;
      final stop = sync || buffer.length <= _immediateLimit
          ? buffer.lineCount
          : min(buffer.lineCount, line + _sliceLines);
      for (; line < stop && starts.length < _maxMatches; line++) {
        linesRead++;
        final text = buffer.lineAt(line);
        _matchLine(text, offset, query, pattern, starts, ends);
        offset += text.length + buffer.terminatorAt(line).length;
      }
      if (line < buffer.lineCount && starts.length < _maxMatches) {
        _slice = Timer(Duration.zero, slice);
        return;
      }
      _finish(buffer, starts, ends, reveal: reveal, from: from);
    }

    slice();
  }

  /// Takes the matches a scan found as the bar's own.
  void _finish(
    SourceBuffer buffer,
    List<int> starts,
    List<int> ends, {
    required bool reveal,
    int? from,
  }) {
    _starts = starts;
    _ends = ends;
    _buffer = buffer;
    _revision = buffer.revision;
    final surface = _surface();
    final anchor = from ?? surface?.selection.clampTo(buffer.length).start ?? 0;
    if (starts.isEmpty) {
      _index = -1;
    } else {
      final next = starts.indexWhere((start) => start >= anchor);
      _index = next < 0 ? 0 : next;
      if (reveal) _select();
    }
    notifyListeners();
  }

  /// The case-insensitive pattern for [query], or null when the search is
  /// case sensitive. A pattern, not a lowered copy: lowering can change a
  /// string's length (`İ`), and the offsets have to be the note's.
  RegExp? _pattern(String query) => _caseSensitive
      ? null
      : RegExp(RegExp.escape(query), caseSensitive: false, unicode: true);

  /// Adds the matches of [query] in [text], which starts at [base] in the
  /// note, to [starts] and [ends].
  void _matchLine(
    String text,
    int base,
    String query,
    RegExp? pattern,
    List<int> starts,
    List<int> ends,
  ) {
    if (pattern == null) {
      var at = text.indexOf(query);
      while (at >= 0 && starts.length < _maxMatches) {
        starts.add(base + at);
        ends.add(base + at + query.length);
        at = text.indexOf(query, at + query.length);
      }
      return;
    }
    for (final match in pattern.allMatches(text)) {
      if (match.end == match.start) continue;
      starts.add(base + match.start);
      ends.add(base + match.end);
      if (starts.length >= _maxMatches) break;
    }
  }

  static bool _hasBreak(String query) =>
      query.contains('\n') || query.contains('\r');

  /// The scan in progress, and its turn.
  Timer? _slice;
  int _scanId = 0;

  /// How many lines a slice of a long note's scan reads.
  static const int _sliceLines = 20000;

  /// How many lines the scans have read, for a test to see that a
  /// replacement does not read the note again.
  @visibleForTesting
  int linesRead = 0;

  /// How many slices the scans have run: more than one for a long note.
  @visibleForTesting
  int slices = 0;

  void _select() {
    final surface = _surface();
    if (surface == null || _index < 0 || _index >= _starts.length) return;
    surface.select(
      SelectionModel(anchor: _starts[_index], extent: _ends[_index]),
    );
  }

  void _clear() {
    _slice?.cancel();
    _scanId++;
    _starts = const <int>[];
    _ends = const <int>[];
    _index = -1;
    _buffer = null;
    _revision = -1;
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
