/// The template checker's state for the live surface (T-TPL-09): what
/// `checkTemplateSyntax` last found in the template on screen, kept off
/// the keystroke path.
///
/// The checker is a pure function of the whole note, so it cannot answer a
/// line at a time the way the spelling does — it is **debounced** instead.
/// `schedule` arms a timer and reads the note when it fires, so a burst of
/// keystrokes costs one pass, never one per key (#316). Nothing joins or
/// checks the note on the keystroke itself: the caller hands in a reader,
/// and only the debounce calls it.
///
/// The state is a [ChangeNotifier] so the surface can repaint what it marks
/// and the status row can show the count — the same seam `EditorSpellCheck`
/// keeps for the spelling.
library;

import 'dart:async';
import 'dart:ui' show TextRange;

import 'package:flutter/foundation.dart';
import 'package:niman/src/templates/checker.dart';

/// The problems a template has, as [checkTemplateSyntax] last reported them.
final class TemplateCheck extends ChangeNotifier {
  /// Creates the state, debounced by [debounce].
  new({this.debounce = const Duration(milliseconds: 250)});

  /// How long the note must be quiet before it is checked.
  final Duration debounce;

  Timer? _timer;
  List<TemplateSyntaxError> _errors = const <TemplateSyntaxError>[];
  String? _checked;

  /// The problems, in reading order.
  List<TemplateSyntaxError> get errors => List.unmodifiable(_errors);

  /// How many problems the note has.
  int get problemCount => _errors.length;

  /// Whether the note has any problem at all.
  bool get hasProblems => _errors.isNotEmpty;

  /// Arms the debounce: [read] is called when it fires and the text it
  /// answers is checked. Every call replaces the one before it, so a burst
  /// of keystrokes is one pass.
  ///
  /// [read] is a function rather than the text so the caller does not join
  /// the note on the keystroke that led here.
  void schedule(String Function() read) {
    _timer?.cancel();
    _timer = Timer(debounce, () => _run(read()));
  }

  /// Checks [source] now, without waiting: the first paint, and a test.
  void run(String source) {
    _timer?.cancel();
    _run(source);
  }

  void _run(String source) {
    if (_checked == source) return;
    final errors = checkTemplateSyntax(source);
    _checked = source;
    if (listEquals(_errors, errors)) return;
    _errors = errors;
    notifyListeners();
  }

  /// The problems whose span overlaps `[start], [end)` of the note, each
  /// with its offsets made local to that window.
  ///
  /// What a line asks for: [TextRange]s local to the line, and the error
  /// behind each so the hint has its message and its fix.
  List<(TextRange, TemplateSyntaxError)> inRange(int start, int end) {
    final out = <(TextRange, TemplateSyntaxError)>[];
    for (final error in _errors) {
      if (error.end <= start || error.offset >= end) continue;
      final from = error.offset < start ? start : error.offset;
      final to = error.end > end ? end : error.end;
      out.add((TextRange(start: from - start, end: to - start), error));
    }
    return out;
  }

  /// The problem whose span holds [offset] in the note, or null — the
  /// question the caret asks of the problems on screen.
  ///
  /// A span holds its own offsets; the one it ends on belongs to the problem
  /// that starts there, if any. A caret one past the end of a span is on it
  /// too, which is where the caret rests after a placeholder is typed:
  /// nothing else holds that offset, so the mistake just written answers.
  TemplateSyntaxError? at(int offset) {
    for (final error in _errors) {
      if (offset >= error.offset && offset < error.end) return error;
    }
    for (final error in _errors) {
      if (offset == error.end) return error;
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
