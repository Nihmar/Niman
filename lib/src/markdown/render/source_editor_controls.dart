import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/buffer_block_anchors.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_shortcuts.dart';
import 'package:niman/src/markdown/render/focus_return.dart';
import 'package:niman/src/markdown/render/live_blocks.dart';
import 'package:niman/src/markdown/render/source_caret_blink.dart';
import 'package:niman/src/markdown/render/source_code_copies.dart';
import 'package:niman/src/markdown/render/source_context_menu.dart';
import 'package:niman/src/markdown/render/source_editor.dart';
import 'package:niman/src/markdown/render/source_live_lines.dart';
import 'package:niman/src/markdown/render/source_menu_keys.dart';
import 'package:niman/src/markdown/render/source_pointer.dart';
import 'package:niman/src/markdown/render/source_table_hover.dart';
import 'package:niman/src/markdown/render/source_table_keys.dart';
import 'package:niman/src/markdown/render/source_task_boxes.dart';
import 'package:niman/src/markdown/render/source_template_hint.dart';
import 'package:niman/src/markdown/render/source_touch.dart';
import 'package:niman/src/markdown/render/source_view_config.dart';
import 'package:niman/src/markdown/render/todo_block_scope.dart';
import 'package:niman/src/markdown/render/wikilink_suggest.dart';
import 'package:niman/src/ui/window_visibility.dart';

/// How the writer reaches the source editor's note (#1261): the keyboard's
/// focus, the mouse and the finger, the context menu and the touch toolbar,
/// the table handles, the copy buttons, the template hints and the wikilink
/// panel — and the services whose answers draw the note again. The input
/// part of [SourceEditor], which edits through it.
final class SourceEditorControls {
  /// The controls of [editor]'s note, focused through [focusNode] when the
  /// caller owns one.
  new(this.editor, {FocusNode? focusNode})
    : focus = focusNode ?? FocusNode(),
      _ownsFocus = focusNode == null;

  /// The editor these controls edit.
  final SourceEditor editor;

  /// The keyboard focus: the caller's, or one of its own.
  final FocusNode focus;
  final bool _ownsFocus;

  /// Whether the caret is drawn, and the blink that turns it on and off:
  /// only the focused note's, in a window someone can see (#512).
  late final SourceCaretBlink blink = SourceCaretBlink(
    focused: () => focus.hasFocus,
  );

  /// The selection by touch (#291): its handles, its toolbar, and the
  /// gestures that bring them. Listened to from [start]: the note rebuilds
  /// when they come or go.
  late final SourceTouchSelection touch = SourceTouchSelection(
    buffer: () => editor.buffer,
    selection: () => editor.selection,
    select: editor.select,
    offsetAt: editor.layout.offsetAt,
    requestKeyboard: requestKeyboard,
    caretRectAt: editor.layout.caretRectAt,
    followsLastClick: (global) =>
        pointer.followsLastClick(global, DateTime.now()),
    clipboardItems: (dismiss) => menu.clipboardItems(dismiss, touch: true),
    spellingItems: (dismiss) => menu.spellingItems(dismiss),
    formats: _menuFormats,
    structure: () => editor.actions.editorMenu?.call(),
    table: () => tableKeys.commands()?.menu(),
  );

  /// The mouse's press, drag and hover over the note, the taps a click
  /// counts, and the cursor it shows.
  late final SourcePointer pointer = SourcePointer(
    buffer: () => editor.buffer,
    selection: () => editor.selection,
    live: () => editor.look.hideMarkers,
    mounted: () => editor.mounted,
    touch: touch,
    offsetAt: editor.layout.offsetAt,
    onScrollbar: editor.layout.onScrollbar,
    hoverTable: handles.hoverAt,
    leaveTable: handles.leave,
    taskBoxAt: (global) => taskBoxes.at(global) != null,
    overTaskBox: taskBoxes.over,
    toggleTaskAt: taskBoxes.toggleAt,
    linkAt: editor.linkAt,
    openLink: () => editor.actions.onOpenLink,
    linkHover: () => editor.actions.onLinkHover,
    requestKeyboard: requestKeyboard,
    secondaryClick: _secondaryClick,
    placeCaret: editor.placeCaret,
    extendTo: (offset) => editor.layout.motion.moveTo(offset, extend: true),
    select: editor.selectRange,
    inCell: (offset) => editor.layout.motion.inCell(offset, 0),
    holdSync: ({required hold}) => editor.input.holdSync = hold,
  );

  /// The desktop context menu, and the clipboard's and the spelling's
  /// entries it shares with the touch toolbar. Listened to from [start]:
  /// the note rebuilds when it opens or closes.
  late final SourceContextMenu menu = SourceContextMenu(
    buffer: () => editor.buffer,
    selection: () => editor.selection,
    grouped: () => editor.actions.editorMenu != null,
    caretRect: () => editor.layout.caretRect,
    offsetAt: editor.layout.offsetAt,
    linkAt: editor.linkAt,
    openLink: (kind, raw, href) =>
        editor.actions.onOpenLink?.call(kind, raw, href),
    hideTouch: () => touch.hide(),
    showTouch: ({required toolbar}) => touch.show(toolbar: toolbar),
    cut: editor.typing.cutSelection,
    copy: editor.typing.copySelection,
    paste: editor.typing.paste,
    selectAll: editor.selectAll,
    replace: editor.replaceRange,
    spellCheck: () => editor.services.spellCheck,
    spellRanges: editor.layout.marks.spellRanges,
    formats: _menuFormats,
    table: () => tableKeys.commands()?.menu(),
    structure: () => editor.actions.editorMenu?.call(),
  );

  /// The toolbar's formats a menu offers: none when the editor gives it a
  /// grouped menu of its own, which holds them.
  List<FormatMenuEntry> _menuFormats() => editor.actions.editorMenu != null
      ? const <FormatMenuEntry>[]
      : editor.actions.formatMenu?.call() ?? const <FormatMenuEntry>[];

  /// The task boxes `live` draws: the one under a point, and its tick.
  late final SourceTaskBoxes taskBoxes = SourceTaskBoxes(
    buffer: () => editor.buffer,
    live: () => editor.look.hideMarkers,
    caretLine: () => editor.layout.caret.spot.value.line,
    paragraphs: editor.layout.paragraphs,
    lineAt: editor.lineAt,
    blockOf: (line) => editor.styler?.blockOf(line),
    blocks: () => editor.styler?.blocks,
    quotes: editor.layout.quotes,
    theme: () => editor.look.theme,
    cascade: () => editor.behaviour.cascadeChecklist,
    selection: () => editor.selection,
    seal: () => editor.history.seal(),
    replace: (start, end, text, caret) =>
        editor.replaceRange(start, end, text, caret: caret, follow: false),
  );

  /// The `+` handles of the table in play (#261): the one under the mouse
  /// on the desktop, the caret's on a phone.
  late final SourceTableHover handles = SourceTableHover(
    buffer: () => editor.buffer,
    live: () => editor.look.hideMarkers,
    mounted: () => editor.mounted,
    blockOf: (line) => editor.styler?.blockOf(line),
    caretSpot: editor.layout.caret.spot,
    noteBox: () => editor.layout.noteBox,
    scroll: () => editor.layout.scroll,
    tableRowAt: (line, block, at) =>
        editor.layout.pieces.tableRowAt(line, block, at),
    piecesOf: editor.layout.pieces.of,
    lineBox: editor.layout.geometry.lineBox,
    drawnHeightOf: editor.layout.pieces.drawnHeightOf,
    theme: () => editor.look.theme,
    replace: (start, end, text, caret) =>
        editor.replaceRange(start, end, text, caret: SelectionModel.at(caret)),
  );

  /// The copy buttons of the code blocks on screen in `live` (#541).
  late final SourceCodeCopies codeCopies = SourceCodeCopies(
    buffer: () => editor.buffer,
    live: () => editor.look.hideMarkers,
    drawsTodo: () => TodoBlockScope.of(editor.context()) != null,
    styler: () => editor.styler,
    noteBox: () => editor.layout.noteBox,
    scroll: () => editor.layout.scroll,
    heights: () => editor.layout.heights,
    folds: editor.folds,
    padding: () => editor.look.padding,
    lineBox: editor.layout.geometry.lineBox,
    columnOfLine: editor.layout.geometry.columnOfLine,
    rightInset: () => editor.layout.metrics.rightInset,
    columnsLeft: editor.layout.metrics.columnsLeft,
    gap: () => editor.layout.metrics.gap,
  );

  /// The template checker (T-TPL-09): the check run and armed on the note,
  /// the problems on a line, and the hint under the span the caret is on.
  late final TemplateHintController hints = TemplateHintController(
    buffer: () => editor.buffer,
    selection: () => editor.selection,
    check: () => editor.services.templateCheck,
    isTemplate: () => editor.behaviour.templateCommands,
    replace: editor.replaceRange,
    spanRect: editor.layout.templateSpanRect,
  );

  /// The wikilink suggester (#475): the panel a `[[link]]` being typed opens,
  /// its keys, and the edit that completes the link. Listened to from
  /// [start]: the note rebuilds when the panel changes.
  late final WikilinkSuggestController suggest = WikilinkSuggestController(
    buffer: () => editor.buffer,
    selection: () => editor.selection,
    suggester: () => editor.services.wikilinkSuggester,
    lineRead: (line) => editor.tokensAt(line) != null,
    inCodeAt: editor.typing.inCodeAt,
    headings: () => editor.headings,
    blocks: () => _blockAnchors.read(),
    notePath: () => editor.services.notePath,
    replace: (start, end, text, caret) =>
        editor.replaceRange(start, end, text, caret: caret),
    ensureCaretVisible: editor.layout.reveal.ensureCaretVisible,
    caretRect: () =>
        editor.layout.caretRectAt(editor.selection.extent) ??
        editor.layout.caretRect,
    noteBox: () => editor.layout.noteBox,
    caretMoves: () =>
        Listenable.merge([editor.layout.scroll, editor.layout.caret.rect]),
  );

  /// The note's block anchors, for a `[[#^` link to the note being edited
  /// (#844): walked when the panel asks, kept for the revision — or the
  /// owner's, when it handed in the one it reads (#869).
  late final BufferBlockAnchors _blockAnchors =
      editor.services.blockAnchors ?? BufferBlockAnchors(() => editor.buffer);

  /// The keys in a table `live` draws, and the commands on the caret's
  /// table its menus offer (#261).
  late final SourceTableKeys tableKeys = SourceTableKeys(
    buffer: () => editor.buffer,
    selection: () => editor.selection,
    live: () => editor.look.hideMarkers,
    blockOf: (line) => editor.styler?.blockOf(line),
    select: (next) => editor.applySelection(next, reveal: true),
    replace: (start, end, text, caret) =>
        editor.replaceRange(start, end, text, caret: caret),
    indent: ({required outdent}) =>
        outdent ? editor.typing.outdent() : editor.typing.indent(),
  );

  /// The keys the note answers on its focus, before its shortcuts: the
  /// wikilink panel's, Escape, the way out of a table, the menu key.
  late final SourceMenuKeys menuKeys = SourceMenuKeys(
    menu: menu,
    touch: touch,
    suggest: suggest,
    selection: () => editor.selection,
    placeCaret: editor.placeCaret,
    tableExit: () => tableKeys.exit(),
  );

  /// What the surface's own keys do ([sourceShortcuts]).
  late final SourceKeyActions keyActions = SourceKeyActions(
    moveVertically: editor.layout.moveCaretVertically,
    moveBy: editor.layout.moveCaretBy,
    downOutOfTable: tableKeys.downOut,
    page: editor.layout.motion.page,
    tab: tableKeys.tab,
    copy: editor.typing.copySelection,
    cut: editor.typing.cutSelection,
    paste: editor.typing.paste,
    selectAll: editor.selectAll,
    deleteBackward: editor.deleteBackward,
    deleteForward: editor.deleteForward,
    undo: editor.undo,
    redo: editor.redo,
  );

  /// The keys given back to the note when its window comes back to the
  /// front (#539).
  late final FocusReturn _focusReturn = FocusReturn(
    focus: () => focus,
    restore: () {
      if (!editor.mounted) return;
      if (focus.hasFocus) {
        // The focus came back on its own: the connection may not have.
        editor.input
          ..detach()
          ..attach(viewId: View.of(editor.context()).viewId);
      } else {
        focus.requestFocus();
      }
    },
  );

  /// Starts listening: to the panel, the touch selection and the menu that
  /// draw over the note, to the services whose answers draw it again, to
  /// the modifier keys and to the window.
  void start() {
    // Always up: they draw nothing while nothing is in play (#261).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!editor.mounted) return;
      handles.overlay.show();
      hints.overlay.show();
      // The copy buttons ride the note's paint: off stage the pane hides,
      // and they go with it rather than drawing over the pane that is on.
      codeCopies.sync(onStage: editor.behaviour.onStage);
      // The first check, off the build: the problem marks are on the note the
      // frame after it opens, and nothing waited for them (#316).
      hints
        ..refresh()
        ..run();
    });
    suggest.addListener(editor.rebuild);
    touch.addListener(editor.rebuild);
    menu.addListener(editor.rebuild);
    _listen(editor.services);
    // The hand over a Ctrl-clickable link appears when the modifier goes
    // down, and goes when it comes up, without waiting for a move (#725).
    HardwareKeyboard.instance.addHandler(pointer.modifierChanged);
    // A window hidden to the tray draws nothing (#512): the caret blink is
    // its own frame source and stops while it is off screen.
    WindowVisibility.shown.addListener(_onWindowShown);
    _focusReturn.start();
  }

  /// Lets go of everything [start] listened to, and of what it holds.
  void dispose() {
    handles.dispose();
    pointer.dispose();
    _unlisten(editor.services);
    hints.dispose();
    suggest
      ..removeListener(editor.rebuild)
      ..dispose();
    if (_ownsFocus) focus.dispose();
    WindowVisibility.shown.removeListener(_onWindowShown);
    _focusReturn.dispose();
    blink.dispose();
    touch
      ..removeListener(editor.rebuild)
      ..dispose();
    menu
      ..removeListener(editor.rebuild)
      ..dispose();
    HardwareKeyboard.instance.removeHandler(pointer.modifierChanged);
  }

  void _listen(SourceServices services) {
    services.spellCheck?.addListener(_onSpellingChanged);
    services.templateCheck?.addListener(_onSpellingChanged);
    services.findMatches?.addListener(_onSpellingChanged);
    services.deadLinks?.addListener(_onDeadLinksChanged);
    services.mathCache?.addListener(_onMathTypeset);
  }

  void _unlisten(SourceServices services) {
    services.spellCheck?.removeListener(_onSpellingChanged);
    services.templateCheck?.removeListener(_onSpellingChanged);
    services.findMatches?.removeListener(_onSpellingChanged);
    services.deadLinks?.removeListener(_onDeadLinksChanged);
    services.mathCache?.removeListener(_onMathTypeset);
  }

  /// The behaviour changed: the pane came on or off stage, or the note
  /// became a template or stopped being one.
  void behaviourChanged(SourceBehaviour old) {
    final behaviour = editor.behaviour;
    if (old.onStage != behaviour.onStage) {
      // Show and hide are a rebuild of the overlay portal, and the portal
      // refuses one during a build: the pane's frame is enough to wait.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (editor.mounted) codeCopies.sync(onStage: editor.behaviour.onStage);
      });
    }
    // The note became a template, or stopped being one: its lines are
    // coloured again at the build this update is part of, and a template is
    // checked off the build (the answer notifies listeners outside this one).
    if (old.templateCommands != behaviour.templateCommands) {
      editor.rebuild();
      _checkAfterFrame();
    }
  }

  /// The services changed: each one the view listens to is listened to
  /// anew.
  void servicesChanged(SourceServices old) {
    final services = editor.services;
    if (!identical(old.spellCheck, services.spellCheck)) {
      old.spellCheck?.removeListener(_onSpellingChanged);
      services.spellCheck?.addListener(_onSpellingChanged);
    }
    if (!identical(old.templateCheck, services.templateCheck)) {
      old.templateCheck?.removeListener(_onSpellingChanged);
      services.templateCheck?.addListener(_onSpellingChanged);
      // A check attached now (the note became a template, its folder having
      // been read): the problems are worked out at once, not on the next
      // keystroke. Off the build: the answer notifies listeners outside this
      // view too, and one of them may be the widget now rebuilding it.
      _checkAfterFrame();
    }
    if (!identical(old.findMatches, services.findMatches)) {
      old.findMatches?.removeListener(_onSpellingChanged);
      services.findMatches?.addListener(_onSpellingChanged);
    }
    if (!identical(old.deadLinks, services.deadLinks)) {
      old.deadLinks?.removeListener(_onDeadLinksChanged);
      services.deadLinks?.addListener(_onDeadLinksChanged);
    }
    if (!identical(old.mathCache, services.mathCache)) {
      old.mathCache?.removeListener(_onMathTypeset);
      services.mathCache?.addListener(_onMathTypeset);
    }
  }

  /// Runs the template check, and reads the hint off it, after this frame.
  void _checkAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!editor.mounted) return;
      hints
        ..run()
        ..refresh();
    });
  }

  /// The spelling changed its mind (a dictionary loaded, a word added, the
  /// underline switched off), the template checker found something else, or
  /// the find bar found something else: the lines on screen are drawn again,
  /// and the hint is read off the problems as they now stand.
  void _onSpellingChanged() {
    if (!editor.mounted) return;
    hints.refresh();
    editor.rebuild();
  }

  /// The note's dead links were resolved again (#847): its links are drawn
  /// again, in the colours the answer gives them.
  void _onDeadLinksChanged() {
    if (editor.mounted) editor.rebuild();
  }

  /// A formula was typeset, or failed to be: the lines that concealed their
  /// source for it are laid out again.
  ///
  /// The line the caret is on is one of them, and it is taller or shorter
  /// now — the spacer takes the formula's room. Nothing about the caret
  /// changed, so no edit came through the caret's scheduling: the
  /// measurement has to be asked for by the relayout itself. Post-frame, so
  /// a notification that lands while a frame is building asks for the next
  /// one rather than setting state here.
  void _onMathTypeset() {
    if (editor.mounted) editor.layout.measureCaretAfterFrame();
  }

  /// The window was hidden or shown again: the blink stops drawing while it
  /// is hidden and starts over when it is back (#512).
  void _onWindowShown() => blink.restart();

  /// The note's focus came or went.
  void focusChanged({required bool hasFocus}) {
    _focusReturn.focusChanged(hasFocus: hasFocus);
    // Only the focused note blinks (#512): an editor the keys are not
    // going to keeps its caret, steady, and draws no frame for it.
    blink.restart();
    if (hasFocus) {
      editor.input.attach(viewId: View.of(editor.context()).viewId);
    } else {
      editor.input.detach();
      touch.hide();
      menu.hide();
    }
  }

  /// Takes the focus, or — when the surface has it — opens the connection
  /// again if the platform closed it, and asks for the keyboard either way.
  void requestKeyboard() {
    editor.layout.reveal.keyboardAsked();
    if (!focus.hasFocus) {
      // The focus change attaches (see `onFocusChange`).
      focus.requestFocus();
      return;
    }
    editor.input.attach(viewId: View.of(editor.context()).viewId);
  }

  /// A right click at [global]: the caret goes there unless the click is on
  /// the selection — which is what the menu is about to act on — and the
  /// menu opens at the click.
  void _secondaryClick(Offset global) {
    final offset = editor.layout.offsetAt(global);
    final selection = editor.selection;
    final onSelection =
        offset != null &&
        !selection.isCollapsed &&
        offset >= selection.start &&
        offset <= selection.end;
    // On a table's room, the menu is the nearer cell's (#261).
    if (offset != null && !onSelection) {
      editor.placeCaret(editor.layout.motion.inCell(offset, 0));
    }
    menu.show(global);
  }

  /// Puts the caret at the start of [footnote]'s definition, which shows
  /// it: a tap on the footnote, at the end of the note, is the way to a
  /// definition `live` hides where it stands.
  void toDefinition(Footnote footnote) {
    final line = editor.styler?.definitionLineOf(footnote.label);
    if (line == null) return;
    final offset = editor.buffer.offsetOfLine(line);
    focus.requestFocus();
    editor.applySelection(
      SelectionModel.at(offset),
      rebuild: true,
      reveal: true,
      suggest: false,
    );
  }

  /// A tap on a diagram `live` draws, or on its parse error: the caret on
  /// note line [line] — the block's first, or the one the error names — and
  /// the block's source shown again (#530).
  void openDiagramLine(int line) {
    if (line < 0 || line >= editor.buffer.lineCount) return;
    requestKeyboard();
    editor.placeCaret(editor.buffer.offsetOfLine(line));
  }

  /// The Mermaid block — or, where the note's tasks are at hand
  /// ([TodoBlockScope], asked of the view), the `todo` fence — line
  /// [index] is part of, for `live` to draw in its lines' place
  /// ([liveDiagramOf]).
  LiveDiagram? diagramOf(int index) => liveDiagramOf(
    index,
    editor.styler?.blockOf(index),
    editor.buffer,
    drawsTodo: () => TodoBlockScope.of(editor.context()) != null,
  );
}
