import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/editor/context_menu_items.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/toolbar_item.dart';
import 'package:niman/src/links/dead_links.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/markdown/buffer_block_anchors.dart';
import 'package:niman/src/markdown/edit/source_find.dart';
import 'package:niman/src/markdown/render/markdown_theme.dart';
import 'package:niman/src/markdown/render/source_pointer.dart';
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/templates/check_state.dart';

/// A link the writer Ctrl+clicked: its token's kind (a wikilink or a Markdown
/// link), its text as written, brackets and all, and — for a Markdown link —
/// the target its parse resolved (a reference link's, too), or null for a
/// wikilink.
typedef SourceLinkTap = void Function(TokenKind kind, String raw, String? href);

/// How the source view draws the note (#1261): its type, its colours, its
/// margins and its gutter. Compared by value: a copy of the same values is
/// the same look, and moves no caret (#789).
@immutable
final class SourceLook {
  /// The look of a note styled with [theme].
  const new({
    required this.theme,
    this.syntax,
    this.dark = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.column = NoteColumn.off,
    this.showLineNumbers = true,
    this.hideMarkers = false,
    this.caretWidth,
    this.lineTokens,
  });

  /// The typography: the read view's theme, in monospace.
  final MarkdownTheme theme;

  /// The token palette; null takes it from the ambient theme.
  final SyntaxColors? syntax;

  /// Whether bold is drawn a step lighter (the palette's own rule).
  final bool dark;

  /// The page margins.
  final EdgeInsets padding;

  /// Where the note's text sits across the pane.
  ///
  /// The shell's note column, the same object the read mode and the legacy
  /// editor use, so switching panes does not move the text sideways — and it
  /// is the *text* that moves, not the pane: the side space is padding inside
  /// the scroll view, which keeps one coordinate system for the caret and the
  /// hit test.
  final NoteColumn column;

  /// Whether the gutter shows line numbers.
  final bool showLineNumbers;

  /// Whether the structural markers are hidden.
  ///
  /// Hidden **by style**, never removed: the runs stay in the layout with their
  /// advance, so an offset in the text is an offset on the screen and the
  /// caret, the hit test and the selection need to know nothing about what is
  /// invisible. That is the whole reason `live` mode (phase 4) can be this
  /// surface with a flag rather than a second renderer — the marker's width is
  /// paid for, and what it buys is that every offset stays true.
  final bool hideMarkers;

  /// The caret's width; null keeps the surface's own (Zen mode, #69,
  /// thickens it).
  final double? caretWidth;

  /// The colours of a line of a file that is not Markdown, by its text —
  /// a todo.txt's (`todoTxtTokens`) — or null for the Markdown engine's.
  final List<Token> Function(String line)? lineTokens;

  /// Whether the caret's line is drawn another way under [other]: another
  /// mode, type, gutter or width — what the caret is measured again for.
  bool redraws(SourceLook other) =>
      hideMarkers != other.hideMarkers ||
      theme != other.theme ||
      showLineNumbers != other.showLineNumbers ||
      column != other.column ||
      padding != other.padding;

  @override
  bool operator ==(Object other) =>
      other is SourceLook &&
      other.theme == theme &&
      other.syntax == syntax &&
      other.dark == dark &&
      other.padding == padding &&
      other.column == column &&
      other.showLineNumbers == showLineNumbers &&
      other.hideMarkers == hideMarkers &&
      other.caretWidth == caretWidth &&
      other.lineTokens == lineTokens;

  @override
  int get hashCode => Object.hash(
    theme,
    syntax,
    dark,
    padding,
    column,
    showLineNumbers,
    hideMarkers,
    caretWidth,
    lineTokens,
  );
}

/// How the source view edits the note (#1261): Tab's width, the checklist's
/// cascade, typewriter mode, whether the note is a template, and whether it
/// is the pane on stage.
@immutable
final class SourceBehaviour {
  /// The behaviour of a plain note.
  const new({
    this.indentWidth = 2,
    this.typewriter = false,
    this.cascadeChecklist = true,
    this.templateCommands = false,
    this.autofocus = false,
    this.onStage = true,
  });

  /// How many spaces Tab indents by (the library's own setting).
  final int indentWidth;

  /// Typewriter mode (#70): the row being written keeps to the middle of the
  /// pane, lit faintly, and the note leaves room below its last line so that
  /// row can reach the middle there too.
  final bool typewriter;

  /// Whether ticking a checklist item ticks the tasks nested under it
  /// (#326).
  final bool cascadeChecklist;

  /// Whether the note is a template, whose commands (`{{date}}`) are
  /// coloured apart from the Markdown they stand in: a note of the
  /// library's template folder. Elsewhere a `{{…}}` is text like any.
  final bool templateCommands;

  /// Whether the note takes the focus — and the keyboard — as it opens (the
  /// keyboard-on-open setting, and a template's `{{cursor}}`).
  final bool autofocus;

  /// Whether this pane is the one on stage.
  ///
  /// Off stage the view keeps everything it has — the parent keeps it
  /// mounted for that — but its overlay children must not paint: an
  /// `Offstage` ancestor hides the pane's own painting, not an
  /// `OverlayPortal`'s child, which lives in the app's overlay and would
  /// draw the code blocks' copy buttons over the pane that is on stage.
  final bool onStage;

  @override
  bool operator ==(Object other) =>
      other is SourceBehaviour &&
      other.indentWidth == indentWidth &&
      other.typewriter == typewriter &&
      other.cascadeChecklist == cascadeChecklist &&
      other.templateCommands == templateCommands &&
      other.autofocus == autofocus &&
      other.onStage == onStage;

  @override
  int get hashCode => Object.hash(
    indentWidth,
    typewriter,
    cascadeChecklist,
    templateCommands,
    autofocus,
    onStage,
  );
}

/// What the source view reads of the library and the note's owner (#1261):
/// the spelling, the template check, the find bar, the maths, the pictures,
/// the links. Each is the owner's object, compared by identity; null reads
/// nothing.
@immutable
final class SourceServices {
  /// The services a note is checked and drawn with.
  const new({
    this.spellCheck,
    this.templateCheck,
    this.findMatches,
    this.mathCache,
    this.embedResolver,
    this.wikilinkSuggester,
    this.notePath,
    this.blockAnchors,
    this.deadLinks,
    this.activeItems,
  });

  /// The note's spelling: the words it underlines, and the context menu's
  /// suggestions and Add to dictionary. Null checks nothing.
  final EditorSpellCheck? spellCheck;

  /// The note's template syntax check (T-TPL-09): the problems it marks with
  /// a wavy underline and offers to fix. Only read when
  /// [SourceBehaviour.templateCommands] is set — a note that is not a
  /// template is checked by nothing.
  final TemplateCheck? templateCheck;

  /// What the find bar found, painted over the lines; null finds nothing.
  final SourceMatches? findMatches;

  /// The typeset formulas, for `live` mode's display maths; without it a
  /// formula stays its source.
  final MathCache? mathCache;

  /// Where an embed's target is on disk, for `live` mode's pictures; without
  /// it a picture stays its source.
  final Future<String?> Function(String target)? embedResolver;

  /// The library the wikilink suggester panel reads (#475): the notes, aliases
  /// and headings, and the books' place forms. Null (a surface with no
  /// library) draws no panel.
  final WikilinkSuggester? wikilinkSuggester;

  /// The note's library-relative path, or null for a note outside a library:
  /// what the wikilink panel tells the note's own headings and blocks from
  /// the rest of the library's when it completes a link (#845).
  final String? notePath;

  /// The note's block anchors (#869), when its owner already reads them for
  /// the same buffer: the panel then shares that walk instead of making its
  /// own. Null reads them here.
  final BufferBlockAnchors? blockAnchors;

  /// The links of the note that name nothing (#847), resolved apart from the
  /// drawing and handed in as they arrive: drawn in the muted colour of a
  /// link that is not there yet. Null draws every link as a live one.
  final ValueListenable<DeadLinks>? deadLinks;

  /// Which formats are on at the caret, for the toolbar's pressed state
  /// (#246). The surface owns the answer — it has the tokens — and writes it
  /// here, so the shell reads one notifier whichever engine draws the pane.
  final ValueNotifier<Set<ToolbarItem>>? activeItems;

  @override
  bool operator ==(Object other) =>
      other is SourceServices &&
      identical(other.spellCheck, spellCheck) &&
      identical(other.templateCheck, templateCheck) &&
      identical(other.findMatches, findMatches) &&
      identical(other.mathCache, mathCache) &&
      other.embedResolver == embedResolver &&
      identical(other.wikilinkSuggester, wikilinkSuggester) &&
      other.notePath == notePath &&
      identical(other.blockAnchors, blockAnchors) &&
      identical(other.deadLinks, deadLinks) &&
      identical(other.activeItems, activeItems);

  @override
  int get hashCode => Object.hash(
    spellCheck,
    templateCheck,
    findMatches,
    mathCache,
    embedResolver,
    wikilinkSuggester,
    notePath,
    blockAnchors,
    deadLinks,
    activeItems,
  );
}

/// What the source view asks of the note's owner (#1261): the menus it
/// offers, and what a link clicked, a link hovered and a paste do. Read
/// when they happen, never compared.
@immutable
final class SourceActions {
  /// The actions of a note; null offers or does nothing.
  const new({
    this.formatMenu,
    this.editorMenu,
    this.onOpenLink,
    this.onLinkHover,
    this.onPaste,
  });

  /// The toolbar's formatting actions, for the context menu (#174); null
  /// offers the clipboard alone.
  final FormatMenuBuilder? formatMenu;

  /// The context menu grouped by what the writer is doing (#260): the
  /// links, then Format, Paragraph and Insert. With it the menu shows this
  /// rather than [formatMenu], and the clipboard last.
  final ContextMenuPart Function()? editorMenu;

  /// Called when a link is Ctrl+clicked (Cmd+clicked on a Mac); null leaves
  /// the click a click.
  final SourceLinkTap? onOpenLink;

  /// Told when the pointer comes onto a link with the opening modifier held
  /// (Ctrl, ⌘ on a Mac), and with null when it leaves it or the modifier goes
  /// up: what the link preview opens its card from (#846). Null (the
  /// default, and every touch screen) reports nothing.
  final void Function(SourceLinkHover? hover)? onLinkHover;

  /// Asked first by every paste — Ctrl/⌘+V, the context menu's Paste, the
  /// accessibility action: true when it took the clipboard itself (files to
  /// attach, cells that become a table, #1248, #1249), false to let the view
  /// paste the clipboard's text as it is. Null pastes text.
  final Future<bool> Function()? onPaste;
}
