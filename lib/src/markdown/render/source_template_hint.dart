import 'package:flutter/material.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/template_hint.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/templates/check_state.dart';
import 'package:niman/src/templates/checker.dart';

/// The problem the template checker's hint shows: the span the caret is in,
/// and what is wrong there.
typedef TemplateHintSpot = ({int start, int end, TemplateSyntaxError error});

/// The template checker in the source view (T-TPL-09): the check run on the
/// note and armed as it is written, the problems on a line, and the hint
/// under the span the caret is on, with the fix it offers.
///
/// Its value is the problem the hint is showing, or null. A notifier rather
/// than a rebuild of the note: moving onto a problem must repaint the
/// overlay alone. Nothing runs, and nothing is shown, on a note that is not
/// a template — a `{{…}}` in an ordinary note is text.
final class TemplateHintController extends ValueNotifier<TemplateHintSpot?> {
  /// The checker over the view's [_buffer] and [_selection], while
  /// [_isTemplate] says the note is one.
  new({
    required this._buffer,
    required this._selection,
    required this._check,
    required this._isTemplate,
    required this._replace,
    required this._spanRect,
  }) : super(null);

  /// The note the view draws.
  final SourceBuffer Function() _buffer;

  /// The caret.
  final SelectionModel Function() _selection;

  /// The checker's answers, or null for a surface given none.
  final TemplateCheck? Function() _check;

  /// Whether the note is a template.
  final bool Function() _isTemplate;

  /// Replaces a range of the note as one undoable edit.
  final void Function(int start, int end, String text) _replace;

  /// The rectangle a span covers, in global coordinates, or null while the
  /// line that holds it is not built.
  final Rect? Function(int start, int end) _spanRect;

  /// The overlay the hint is drawn in.
  ///
  /// Always up, like the table's handles: it draws nothing while the caret is
  /// not on a problem.
  final OverlayPortalController overlay = OverlayPortalController();

  /// The checker's problems on line [index], as offsets local to it.
  ///
  /// Empty unless the note is a template — a `{{…}}` in an ordinary note is
  /// text, and the checker never sees it (T-TPL-09).
  List<TextRange> problemsIn(int index) {
    final check = _check();
    if (check == null || !_isTemplate()) return const <TextRange>[];
    final buffer = _buffer();
    final start = buffer.offsetOfLine(index);
    final end = start + buffer.lineLengthAt(index);
    return <TextRange>[
      for (final (range, _) in check.inRange(start, end)) range,
    ];
  }

  /// Runs the template check on the note as it stands, now.
  ///
  /// Nothing runs on a note that is not a template: its `{{…}}` are text.
  void run() {
    final check = _check();
    if (check == null || !_isTemplate()) return;
    check.run(_buffer().text);
  }

  /// Arms the template check's debounce: the note is read and checked once
  /// the writer pauses, never on the keystroke itself (#316).
  void schedule() {
    if (!_isTemplate()) return;
    _check()?.schedule(() => _buffer().text);
  }

  /// Reads the hint off the caret: the problem whose span holds it, or none.
  ///
  /// Only a collapsed caret points at a span; a selection is not a place.
  void refresh() {
    final check = _check();
    final selection = _selection();
    if (check == null || !_isTemplate() || !selection.isCollapsed) {
      value = null;
      return;
    }
    final error = check.at(selection.extent);
    value = error == null
        ? null
        : (start: error.offset, end: error.end, error: error);
  }

  /// Applies the fix the checker offered for [error], as one undoable edit.
  ///
  /// The checker answers about the text it was given, which is a debounce
  /// behind the note: the fix is matched again against what is written now,
  /// so it lands on the span it was offered for and nowhere else.
  void _applyFix(TemplateSyntaxError error) {
    final text = _buffer().text;
    TemplateSyntaxError? target;
    for (final current in checkTemplateSyntax(text)) {
      if (current.suggestion == null) continue;
      if (current.offset <= error.offset && error.offset < current.end) {
        target = current;
        break;
      }
    }
    if (target == null || target.suggestion == null) return;
    _replace(target.offset, target.end, target.suggestion!);
  }

  /// The hint, drawn in its overlay under the span the caret is on, or
  /// nothing.
  Widget buildOverlay(BuildContext context) => ValueListenableBuilder(
    valueListenable: this,
    builder: (context, hint, _) {
      if (hint == null) return const SizedBox.shrink();
      final anchor = _spanRect(hint.start, hint.end);
      if (anchor == null) return const SizedBox.shrink();
      final overlay = Overlay.of(context).context.findRenderObject();
      final at = overlay is RenderBox && overlay.hasSize
          ? overlay.globalToLocal(anchor.topLeft)
          : anchor.topLeft;
      return Stack(
        children: [
          TemplateHint(
            anchor: Rect.fromLTWH(at.dx, at.dy, anchor.width, anchor.height),
            message: templateProblemSentence(hint.error),
            suggestion: hint.error.suggestion,
            onFix: () => _applyFix(hint.error),
            onDismiss: () => value = null,
          ),
        ],
      );
    },
  );
}
