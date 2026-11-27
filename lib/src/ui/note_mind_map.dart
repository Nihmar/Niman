import 'package:flutter/material.dart';
import 'package:niman/src/editor/list_to_mindmap.dart' as mindmap;
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/ui/strings.dart';

/// The open note's list-to-mind-map conversion: what the command palette and
/// the Tools sheet run.
///
/// The list at the caret becomes a mind map in one undoable edit through the
/// editor surface's own door; the note view owns this and hands it the
/// surface and its source pane, each through a callback read when a command
/// runs.
final class NoteMindMap {
  /// The conversion over the note [surface] holds.
  ///
  /// [canInsert] says whether the note takes an edit from outside the editor,
  /// [context] is the note view's, for the message that says why nothing
  /// happened, [focus] gives the editor the keyboard back, and [sourceView]
  /// is the source pane's state, when it is built.
  new({
    required this.surface,
    required this.canInsert,
    required this.context,
    required this.focus,
    required this.sourceView,
  });

  /// The note on the editor surface, or null before one is open.
  final MarkdownSurfaceController? Function() surface;

  /// Whether the note takes an edit from outside the editor.
  final bool Function() canInsert;

  /// The note view's context.
  final BuildContext Function() context;

  /// Gives the editor the focus back.
  final VoidCallback focus;

  /// The source pane's state, when it is built.
  final MarkdownSourceViewState? Function() sourceView;

  /// Converts the list at the caret into a mind map, or says why it could
  /// not: the palette offers the command anywhere.
  void convert() {
    if (!canInsert()) return;
    final surface = this.surface();
    if (surface == null) return;
    final map = caretList<mindmap.ListMindMap?>(mindmap.listToMindMap);
    if (map == null) {
      // The palette offers the command anywhere: say why it did nothing.
      final messenger = ScaffoldMessenger.maybeOf(context());
      final reason = SnackBar(content: Text(AppStrings.toolMindMapNeedsList));
      messenger?.showSnackBar(reason);
      return;
    }
    // Only the list's lines are replaced: one undo step, and the note is
    // never copied whole to make it.
    final buffer = surface.buffer;
    final last = map.endLine - 1;
    final terminator = buffer.terminatorAt(map.startLine);
    surface.applyEdit(
      map.fence.join(terminator.isEmpty ? '\n' : terminator),
      const TextSelection.collapsed(offset: 0),
      start: buffer.offsetOfLine(map.startLine),
      end: buffer.offsetOfLine(last) + buffer.lineLengthAt(last),
    );
    focus();
  }

  /// Whether the caret stands in a list, so the mind-map tool can run.
  /// One block read, not the conversion: the sheet only asks.
  bool get listAtCaret => caretList(mindmap.hasListAt) ?? false;

  /// [read] of the list at the caret, or null without a note: the caret's
  /// line, and the pane's own scan when it draws this buffer — a scan as far
  /// as the list otherwise.
  T? caretList<T>(
    T Function({
      required SourceBuffer buffer,
      required int line,
      Block? Function(int line)? blockAt,
    })
    read,
  ) {
    final surface = this.surface();
    if (surface == null) return null;
    final buffer = surface.buffer;
    final view = sourceView();
    return read(
      buffer: buffer,
      line: buffer.lineOf(surface.selection.extent),
      blockAt: identical(view?.widget.buffer, buffer) ? view?.blockAt : null,
    );
  }
}
