/// The source mode of the unified surface: the note's own text, styled by the
/// engine's tokenizer, editable (#245, phase 3).
///
/// This is the **degenerate case** of the surface and the reason the phase
/// starts here: the rendered text *is* the source text, so a selection offset
/// is
/// a source offset, and no render map can hide an editing bug. `live` mode then
/// adds the marker hiding on top of this.
///
/// Three decisions worth naming:
///
/// * **A source line is the unit of layout**, drawn by one `Text.rich` of the
///   tokenizer's runs, wrapping like prose (`re_editor` wrapped, and a note's
///   paragraphs are one long line each — a source view that did not wrap would
///   need horizontal scrolling to read a sentence).
/// * **The caret comes from this surface's own layout**, never from a metric
///   computed beside it: the line that holds the caret hands out its
///   `RenderParagraph` and the rectangle is `getOffsetForCaret`, which is the
///   quantity `EditableText` computes for you and a surface that paints its own
///   text has to compute itself (phase 3's own exit criterion, and the reason a
///   previous attempt at this surface went). A tap lands through the same
/// paragraph's `getPositionForOffset`, so the rectangle and the hit test agree
///   by construction.
/// * **The windowing is the read view's**: the same `SliverMarkdownBlocks` and
///   the same height map. A note is a note whether it is being read or written.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/caret_spot.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/render/scroll_anchor.dart';
import 'package:niman/src/markdown/render/source_caret_motion.dart';
import 'package:niman/src/markdown/render/source_editor.dart';
import 'package:niman/src/markdown/render/source_editor_layout.dart';
import 'package:niman/src/markdown/render/source_typing.dart';
import 'package:niman/src/markdown/render/source_view_config.dart';
import 'package:niman/src/markdown/render/source_view_layers.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/source_styler.dart';
import 'package:niman/src/markdown/surface_controller.dart';

export 'package:niman/src/markdown/render/source_editor.dart' show SourceEditor;
export 'package:niman/src/markdown/render/source_pointer.dart'
    show SourceLinkHover;
export 'package:niman/src/markdown/render/source_view_config.dart';

/// The source surface: the note's text, its caret, and where a tap lands.
final class MarkdownSourceView extends StatefulWidget {
  /// Shows [buffer] with [selection], drawn as [look] says.
  const new({
    required this.buffer,
    required this.look,
    this.behaviour = const SourceBehaviour(),
    this.services = const SourceServices(),
    this.actions = const SourceActions(),
    this.selection,
    this.onSelection,
    this.onChanged,
    this.focusNode,
    this.controller,
    this.history,
    this.surface,
    super.key,
  });

  /// The text on screen.
  final SourceBuffer buffer;

  /// How the note is drawn: its type, colours, margins and gutter.
  final SourceLook look;

  /// How the note is edited: Tab, the checklist, typewriter mode, templates.
  final SourceBehaviour behaviour;

  /// What the note is checked and drawn with: spelling, maths, links.
  final SourceServices services;

  /// What the note asks of its owner: the menus, a link, a paste.
  final SourceActions actions;

  /// Where the caret is, and what it has selected.
  final SelectionModel? selection;

  /// Called when a tap, or the platform, moves the caret — and when an edit
  /// moves it for them.
  final ValueChanged<SelectionModel>? onSelection;

  /// Called after every edit, so the shell can save the note — and with
  /// nothing else: the debounce, the memento, the statistics and the preview
  /// all belong to whoever owns the note.
  ///
  /// It does not carry the text: joining the note is O(n), and the shell
  /// needs the text only when its debounce fires, not at every keystroke. The
  /// buffer is the shell's own object; it reads the text from it then.
  final ValueChanged<SourceEdit>? onChanged;

  /// The keyboard focus, when the caller owns it (the shell does).
  final FocusNode? focusNode;

  /// The scroll position, when the caller owns one (an anchor jump does).
  final ScrollController? controller;

  /// The undo history, when the caller owns one (the shell keeps it per note,
  /// so moving a note between tabs does not lose it). Null keeps one here.
  final EditHistory? history;

  /// The shell's hold on the note: its history, the selection to start with,
  /// and the door its commands come in through. Its buffer is [buffer].
  final MarkdownSurfaceController? surface;

  @override
  State<MarkdownSourceView> createState() => MarkdownSourceViewState();
}

/// The source view's state, so a caller can ask where the caret is.
///
/// A thin view of the [SourceEditor] it builds (#1261): it hands the editor
/// the widget's configuration on every update, lays it out
/// ([SourceViewLayers]) and draws again when the editor says so. Its
/// methods are the handle the note view and the tests hold through a
/// `GlobalKey<MarkdownSourceViewState>`; each one is the editor's.
final class MarkdownSourceViewState extends State<MarkdownSourceView> {
  /// The editor this view shows.
  SourceEditor get editor => _editor;
  late final SourceEditor _editor;

  late final SourceViewLayers _layers = SourceViewLayers(_editor);

  SourceEditorLayout get _layout => _editor.layout;

  @override
  void initState() {
    super.initState();
    final surface = widget.surface;
    _editor = SourceEditor(
      buffer: widget.buffer,
      look: widget.look,
      behaviour: widget.behaviour,
      services: widget.services,
      actions: widget.actions,
      selection: widget.selection,
      initialSelection: surface?.initialSelection ?? const SelectionModel.at(0),
      onSelection: widget.onSelection,
      onChanged: widget.onChanged,
      history: widget.history ?? surface?.history,
      controller: widget.controller,
      focusNode: widget.focusNode,
      context: () => context,
    )..addListener(_rebuild);
    _editor.start();
    surface?.attachView(this);
    final scroll = surface?.takePendingScroll();
    if (scroll != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) jumpToOffset(scroll);
      });
    }
  }

  void _rebuild() => setState(() {});

  @override
  void didUpdateWidget(MarkdownSourceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.surface, widget.surface)) {
      oldWidget.surface?.detachView(this);
      widget.surface?.attachView(this);
    }
    _editor.configure(
      buffer: widget.buffer,
      history: () => widget.history ?? widget.surface?.history ?? EditHistory(),
      initialSelection: () =>
          widget.surface?.initialSelection ?? const SelectionModel.at(0),
      look: widget.look,
      behaviour: widget.behaviour,
      services: widget.services,
      actions: widget.actions,
      selection: widget.selection,
      onSelection: widget.onSelection,
      onChanged: widget.onChanged,
      controller: widget.controller,
    );
  }

  @override
  void dispose() {
    widget.surface?.detachView(this);
    _editor
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  // Every frame the view builds is measured, for the report (#316) — when a
  // profiling round asked for it: what a frame costs is read off a
  // `Stopwatch` round the build and in the render object `timed` wraps it
  // in, on the very path the report is about, and a release build runs
  // neither (#362).
  @override
  Widget build(BuildContext context) =>
      _editor.cost.timed(() => _layers.build(context));

  /// How many lines the rows' estimates asked about, for the test that holds
  /// a note with a side-by-side block (#729) to the chunks a frame reaches.
  @visibleForTesting
  int get lineEstimates => _layout.rows.lineEstimates;

  /// Whether there is anything to undo, for a toolbar that shows it.
  bool get canUndo => _editor.history.canUndo;

  /// Whether there is anything to redo.
  bool get canRedo => _editor.history.canRedo;

  /// Where the caret is, and what it has selected.
  SelectionModel get selection => _editor.selection;

  /// The footnote labels the note cites or defines
  /// ([SourceEditor.footnoteLabels]).
  Iterable<String> get footnoteLabels => _editor.footnoteLabels;

  /// The note's headings ([SourceEditor.headings]).
  List<OutlineEntry>? get headings => _editor.headings;

  /// Whether the note's blocks are all current ([SourceEditor.scanSettled]).
  bool get scanSettled => _editor.scanSettled;

  /// How many lines the scan behind the colours has read, for the test that
  /// holds a tap on a task box to the work the tap may do: a tap on a note
  /// whose scan is owed must not finish it ([SourceStyler.scannedLines]).
  @visibleForTesting
  int get scanProgress => _editor.styler?.scannedLines ?? 0;

  /// The note's tags and links ([SourceEditor.references]).
  NoteReferences? references() => _editor.references();

  /// The note's blocks ([SourceEditor.blocks]).
  List<Block>? get blocks => _editor.blocks;

  /// The block holding a line ([SourceEditor.blockAt]).
  Block? Function(int line)? get blockAt => _editor.blockAt;

  /// The note's scan, for the read pane ([SourceEditor.handOver]).
  DocumentScan? handOver() => _editor.handOver();

  /// How many source lines the note has.
  int get lineCount => _editor.buffer.lineCount;

  /// The runs on line [index] ([SourceEditor.tokensOf]).
  List<Token> tokensOf(int index) => _editor.tokensOf(index);

  /// The keyboard focus, for a shell that wants to raise the keyboard.
  FocusNode get focusNode => _editor.controls.focus;

  /// Whether the platform is attached to this surface (the keyboard is up).
  bool get isKeyboardAttached => _editor.input.isAttached;

  /// How many updates arrived as deltas, and how many of those arrived with an
  /// `oldText` that disagreed with the buffer.
  int get deltaCount => _editor.input.deltaCount;

  /// How many times the platform's copy had to be told the note again.
  int get resyncs => _editor.input.resyncs;

  /// Where the platform's window of the note starts: it holds the note from
  /// here, as long as its own text is.
  int get platformWindowStart => _editor.input.windowStart;

  /// The caret's rectangle ([SourceEditorLayout.caretRect]).
  Rect? get caretRect => _layout.caretRect;

  /// The offset a tap at [global] lands on, or null when it lands outside a
  /// line.
  int? offsetAt(Offset global) => _layout.offsetAt(global);

  /// Scrolls so [line] is at the top, as far as the map knows.
  void jumpToLine(int line) => _layout.jumpToLine(line);

  /// How far the note is scrolled, for a memento.
  double get scrollOffset => _layout.scrollOffset;

  /// Scrolls to [offset], as far as the note reaches.
  void jumpToOffset(double offset) => _layout.jumpToOffset(offset);

  /// Replaces `[start, end)` with [text] for the shell — a command, an image,
  /// a spelling fixed — as one undoable edit, caret at [caret] or after it.
  /// Without [follow] the note stays where it is scrolled, for an edit made
  /// somewhere the caret is not.
  void replaceText(
    int start,
    int end,
    String text, {
    SelectionModel? caret,
    bool follow = true,
  }) => _editor.replaceRange(start, end, text, caret: caret, follow: follow);

  /// Makes the note say [text] because it changed elsewhere
  /// ([SourceEditor.replaceAll]).
  void replaceAll(String text) => _editor.replaceAll(text);

  /// Selects [next], and tells whoever needs to know.
  void select(SelectionModel next) => _editor.select(next);

  /// Undoes the last edit, and says whether there was one.
  bool undo() => _editor.undo();

  /// Redoes the last undone edit, and says whether there was one.
  bool redo() => _editor.redo();

  /// Moves the caret by [motion], the logical motions the key table calls.
  void moveCaretBy(CaretMotion motion, {bool extend = false}) =>
      _layout.moveCaretBy(motion, extend: extend);

  /// Moves the caret [rows] visual rows up (negative) or down
  /// ([SourceCaretMotion.moveVertically]).
  void moveCaretVertically(int rows, {bool extend = false}) =>
      _layout.moveCaretVertically(rows, extend: extend);

  /// The source line at the top of the view ([SourceEditorLayout.topAnchor]).
  ScrollAnchor? get topAnchor => _layout.topAnchor;

  /// Whether the view has the note drawn to show an anchor in.
  bool get acceptsAnchor => _layout.acceptsAnchor;

  /// Scrolls the view so [anchor]'s line is at its top
  /// ([SourceEditorLayout.showAnchor]).
  void showAnchor(ScrollAnchor anchor, {int attempt = 0}) =>
      _layout.showAnchor(anchor, attempt: attempt);

  /// The selected text, or null when the selection is a caret.
  String? get selectedText => _editor.typing.selectedText;

  /// Copies the selection to the platform's clipboard.
  Future<void> copySelection() => _editor.typing.copySelection();

  /// Copies the selection and removes it, in one undo step with the removal.
  Future<void> cutSelection() => _editor.typing.cutSelection();

  /// Inserts the clipboard's text at the caret, replacing the selection —
  /// unless [SourceActions.onPaste] takes the clipboard first.
  Future<void> paste() => _editor.typing.paste();

  /// Whether the caret is in code: a fenced or indented block, display
  /// maths, an inline span — where a paste stays text.
  bool get caretInCode => _editor.typing.caretInCode;

  /// Tab ([SourceTyping.indent]).
  void indent() => _editor.typing.indent();

  /// Shift+Tab ([SourceTyping.outdent]).
  void outdent() => _editor.typing.outdent();

  /// Deletes the selection, or what is before the caret: one character, or a
  /// word with [word].
  ///
  /// The surface's own key, not the platform's: the Linux embedder leaves
  /// Backspace and Delete to the framework (`fl_text_input_handler.cc`:
  /// "already handled inside the framework"), which is `EditableText`'s job and
  /// therefore this surface's. An IME's own delete key still arrives as a
  /// deletion delta.
  void deleteBackward({bool word = false}) =>
      _editor.deleteBackward(word: word);

  /// Deletes the selection, or what is after the caret.
  void deleteForward({bool word = false}) => _editor.deleteForward(word: word);

  /// Whether the heading on [line] is folded.
  bool isFolded(int line) => _editor.folds.isFolded(line);

  /// Folds the section under the heading on [line], or unfolds it
  /// ([SourceEditor.toggleFold]).
  void toggleFold(int line) => _editor.toggleFold(line);

  /// Selects everything.
  void selectAll() => _editor.selectAll();

  /// The wikilink or Markdown link under [offset] ([SourceEditor.linkAt]).
  (TokenKind, String, String?)? linkAt(int offset) => _editor.linkAt(offset);

  /// Puts the caret at [offset], tells the platform, and keeps it on screen.
  void placeCaret(int offset) => _editor.placeCaret(offset);

  /// The caret's spot, exposed so a test can hold that a move inside a run
  /// tells no line anything. Exposed as a listenable rather than as a value
  /// because *not* notifying is the property.
  @visibleForTesting
  ValueListenable<CaretSpot> get caretSpot => _layout.caret.spot;

  /// Completes when the reading of the note under way has landed — at once
  /// when none is: what a reader of the same lines waits for rather than
  /// reading them again (#1199), and then asks [handOver] for.
  Future<void> get readingLanded => _editor.styling.readingLanded;

  /// Whether the caret is blinking right now, for the test that holds the
  /// blink to the window's visibility (#512).
  @visibleForTesting
  bool get caretBlinking => _editor.controls.blink.blinking;

  /// How many times the caret was measured, for the test that holds a
  /// rebuild with a theme of the same values to measuring nothing (#789).
  @visibleForTesting
  int get caretMeasures => _layout.caret.measures;

  /// Opens the context menu at [global], or at the caret without one (the
  /// menu key, Shift+F10).
  void showContextMenu([Offset? global]) => _editor.controls.menu.show(global);

  /// Whether the context menu is up.
  bool get isContextMenuShown => _editor.controls.menu.isShown;

  /// Closes the context menu.
  void hideContextMenu() => _editor.controls.menu.hide();

  /// Whether the suggester panel is up, for the shell's tour and the tests.
  bool get isSuggesterShown => _editor.controls.suggest.isShown;
}
