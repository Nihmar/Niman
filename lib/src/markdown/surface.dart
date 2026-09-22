/// The one surface, and the modes it has (#245, #246).
///
/// The design's claim is that there are not three surfaces but one, in three
/// modes, and this is where that claim is made concrete: `source` and `live`
/// are
/// **the same widget with one flag between them**, because hiding a marker by
/// style leaves every text offset exactly where it was. The caret, the hit
/// test,
/// the selection, the keyboard, the undo history and the windowing are the same
/// code in both; what changes is whether the markers are drawn and whether a
/// line
/// takes the size its kind asks for.
///
/// The third mode — `read` — is `MarkdownReadView` today, and deliberately not
/// folded in here yet: it takes a parser and a maths cache and has no editing,
/// so
/// the honest thing is to say so rather than to pretend one widget already
/// covers
/// all three. Phase 5 is where the two meet, once `live` renders what `read`
/// renders.
library;

import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/theme/tokens.dart';

/// What the surface is showing.
enum MarkdownSurfaceMode {
  /// The note as written: every marker where it was typed, one size throughout.
  ///
  /// The degenerate case, and the one an editing bug can be seen in: the
  /// rendered
  /// text *is* the source text, so an offset on screen is an offset in the file
  /// with nothing in between.
  source,

  /// The note as it reads, with the editing still on it.
  ///
  /// The markers are hidden **by style** — invisible, and taking no room — so
  /// the
  /// text under the caret is still the text in the file, character for
  /// character.
  live,
}

/// The note, in one of the surface's modes.
final class MarkdownSurface extends StatelessWidget {
  /// Shows [buffer] in [mode].
  const new({
    required this.buffer,
    required this.mode,
    required this.theme,
    this.selection,
    this.onSelection,
    this.column = NoteColumn.off,
    this.onChanged,
    this.focusNode,
    this.controller,
    this.history,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showLineNumbers = true,
    this.indentWidth = 2,
    this.syntax,
    this.dark = false,
    super.key,
  });

  /// The note.
  final SourceBuffer buffer;

  /// Which mode to show it in.
  final MarkdownSurfaceMode mode;

  /// The typography: the read view's theme, in monospace for `source`.
  final MarkdownTheme theme;

  /// Where the caret is, when the caller holds it.
  final SelectionModel? selection;

  /// Called when a tap, a key or the platform moves the caret.
  final ValueChanged<SelectionModel>? onSelection;

  /// Called after every edit, so the shell can save the note.
  final VoidCallback? onChanged;

  /// The keyboard focus, when the caller owns it.
  final FocusNode? focusNode;

  /// The scroll position, when the caller owns one.
  final ScrollController? controller;

  /// The undo history, when the caller keeps it per note.
  final EditHistory? history;

  /// Where the note's text sits across the pane.
  final NoteColumn column;

  /// The page margins.
  final EdgeInsets padding;

  /// Whether the gutter shows line numbers.
  final bool showLineNumbers;

  /// How many spaces Tab indents by.
  final int indentWidth;

  /// The token palette; null takes it from the ambient theme.
  final SyntaxColors? syntax;

  /// Whether bold is drawn a step lighter.
  final bool dark;

  /// Whether this mode draws the note as it reads.
  bool get hidesMarkers => mode == MarkdownSurfaceMode.live;

  /// The typography this mode is set in: `source` is monospace, `live` is the
  /// note's own theme, because that is the difference between reading the file
  /// and
  /// reading the note.
  MarkdownTheme get effectiveTheme =>
      mode == MarkdownSurfaceMode.source ? monospaceTheme(theme) : theme;

  @override
  Widget build(BuildContext context) => MarkdownSourceView(
    buffer: buffer,
    theme: effectiveTheme,
    selection: selection,
    onSelection: onSelection,
    onChanged: onChanged,
    focusNode: focusNode,
    controller: controller,
    history: history,
    column: column,
    padding: padding,
    showLineNumbers: showLineNumbers,
    indentWidth: indentWidth,
    syntax: syntax,
    dark: dark,
    hideMarkers: hidesMarkers,
  );
}
