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
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_view.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/surface_controller.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';

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
    this.surface,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showLineNumbers = true,
    this.indentWidth = 2,
    this.syntax,
    this.dark = false,
    this.formatMenu,
    this.editorMenu,
    this.spellCheck,
    this.findMatches,
    this.onOpenLink,
    this.activeItems,
    this.mathCache,
    this.embedResolver,
    this.caretWidth,
    this.typewriter = false,
    this.autofocus = false,
    this.viewKey,
    this.lineTokens,
    this.templateCommands = false,
    super.key,
  });

  /// See [MarkdownSourceView.lineTokens].
  final List<Token> Function(String line)? lineTokens;

  /// See [MarkdownSourceView.templateCommands].
  final bool templateCommands;

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

  /// Called after every edit with the edit itself, so the shell can save the
  /// note and count its words without re-reading the text.
  final ValueChanged<SourceEdit>? onChanged;

  /// The keyboard focus, when the caller owns it.
  final FocusNode? focusNode;

  /// The scroll position, when the caller owns one.
  final ScrollController? controller;

  /// The undo history, when the caller keeps it per note.
  final EditHistory? history;

  /// The shell's hold on the note (its commands, its history, the caret to
  /// start with).
  final MarkdownSurfaceController? surface;

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

  /// The toolbar's formatting actions, for the context menu.
  final FormatMenuBuilder? formatMenu;

  /// The context menu grouped by what the writer is doing (#260); with it
  /// the menu shows this rather than [formatMenu].
  final ContextMenuPart Function()? editorMenu;

  /// The note's spelling: its underline and its menu entries.
  final EditorSpellCheck? spellCheck;

  /// What the find bar found, painted over the lines.
  final SourceMatches? findMatches;

  /// Called when a link is Ctrl+clicked.
  final SourceLinkTap? onOpenLink;

  /// Which formats are on at the caret, written by the surface for the
  /// toolbar's pressed state (#246). The same notifier the legacy WYSIWYG
  /// published through, so the shell reads one thing in either mode.
  final ValueNotifier<Set<ToolbarItem>>? activeItems;

  /// The typeset formulas `live` draws in place of `$$` blocks.
  final MathCache? mathCache;

  /// Where an embed's target is on disk, for the pictures `live` draws.
  final Future<String?> Function(String target)? embedResolver;

  /// The caret's width; null keeps the surface's own.
  final double? caretWidth;

  /// Typewriter mode: the row being written keeps to the middle.
  final bool typewriter;

  /// Whether the note takes the focus as it opens.
  final bool autofocus;

  /// The key of the [MarkdownSourceView] this builds.
  ///
  /// A caller that wants the view's state — its blocks, its headings — keys
  /// the view and not this widget: this one is stateless, so a
  /// `GlobalKey<MarkdownSourceViewState>` on it has no state to answer with.
  final GlobalKey<MarkdownSourceViewState>? viewKey;

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
    key: viewKey,
    buffer: buffer,
    theme: effectiveTheme,
    selection: selection,
    onSelection: onSelection,
    onChanged: onChanged,
    focusNode: focusNode,
    controller: controller,
    history: history,
    surface: surface,
    column: column,
    padding: padding,
    showLineNumbers: showLineNumbers,
    indentWidth: indentWidth,
    syntax: syntax,
    dark: dark,
    hideMarkers: hidesMarkers,
    formatMenu: formatMenu,
    editorMenu: editorMenu,
    spellCheck: spellCheck,
    findMatches: findMatches,
    onOpenLink: onOpenLink,
    activeItems: activeItems,
    mathCache: mathCache,
    embedResolver: embedResolver,
    caretWidth: caretWidth,
    typewriter: typewriter,
    autofocus: autofocus,
    lineTokens: lineTokens,
    templateCommands: templateCommands,
  );
}
