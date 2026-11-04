import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/note_semantics.dart';
import 'package:niman/src/markdown/source_buffer.dart';

/// The source view's note as the platform's accessibility sees it: one
/// multiline text field, whose value is the note around the caret and whose
/// selection is the note's, with the moves and the clipboard a screen
/// reader asks for.
///
/// The lines under it are excluded: each is a `Text`, and a reader would
/// otherwise read the note twice — as a field, and as the lines inside it.
/// It follows [tick], which moves on with every caret move, without the
/// note being rebuilt.
final class SourceSemantics extends StatelessWidget {
  /// [child], the note's lines, read as one field over [buffer].
  const new({
    required this.tick,
    required this.buffer,
    required this.selection,
    required this.focused,
    required this.onTap,
    required this.onSelect,
    required this.onMove,
    required this.onCopy,
    required this.onCut,
    required this.onPaste,
    required this.child,
    super.key,
  });

  /// How much of the note, around the caret, a screen reader is given: the
  /// note itself can be megabytes, and the semantics tree is sent whole to
  /// the platform on every change.
  static const int _semanticsReach = 4000;

  /// Ticks on every caret move.
  final ValueListenable<int> tick;

  /// The note the view draws.
  final SourceBuffer buffer;

  /// The caret, read as the field is built.
  final SelectionModel Function() selection;

  /// Whether the note has the keyboard focus, read as the field is built.
  final bool Function() focused;

  /// A tap on the field: the keyboard asked for.
  final VoidCallback onTap;

  /// A selection the reader set, in the note's offsets.
  final ValueChanged<SelectionModel> onSelect;

  /// A move the reader asked for.
  final void Function(CaretMotion motion, {required bool extend}) onMove;

  /// Copies the selection.
  final Future<void> Function() onCopy;

  /// Cuts the selection.
  final Future<void> Function() onCut;

  /// Pastes the clipboard at the caret.
  final Future<void> Function() onPaste;

  /// The note's lines.
  final Widget child;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: tick,
    child: ExcludeSemantics(child: child),
    builder: (context, _, child) {
      if (!SemanticsBinding.instance.semanticsEnabled) return child!;
      final selection = this.selection().clampTo(buffer.length);
      final start = math.max(0, selection.start - _semanticsReach);
      final end = math.min(buffer.length, selection.end + _semanticsReach);
      int local(int offset) => (offset - start).clamp(0, end - start);
      return NoteSemantics(
        value: buffer.substring(start, end),
        selection: TextSelection(
          baseOffset: local(selection.anchor),
          extentOffset: local(selection.extent),
        ),
        focused: focused(),
        onTap: onTap,
        onSetSelection: (next) => onSelect(
          SelectionModel(
            anchor: start + next.baseOffset,
            extent: start + next.extentOffset,
          ),
        ),
        onMove: onMove,
        onCopy: selection.isCollapsed ? null : () => unawaited(onCopy()),
        onCut: selection.isCollapsed ? null : () => unawaited(onCut()),
        onPaste: () => unawaited(onPaste()),
        child: child,
      );
    },
  );
}
