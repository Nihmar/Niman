import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/core/frame_cost.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/editor/highlighting.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/markdown/background_scan.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_scanner.dart';
import 'package:niman/src/markdown/edit/caret_motion.dart';
import 'package:niman/src/markdown/edit/edit_history.dart';
import 'package:niman/src/markdown/edit/line_prefix.dart';
import 'package:niman/src/markdown/edit/selection_model.dart';
import 'package:niman/src/markdown/edit/source_input.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/render/link_run.dart';
import 'package:niman/src/markdown/render/source_editor_controls.dart';
import 'package:niman/src/markdown/render/source_editor_layout.dart';
import 'package:niman/src/markdown/render/source_folds.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/source_rows.dart';
import 'package:niman/src/markdown/render/source_sections.dart';
import 'package:niman/src/markdown/render/source_styling.dart';
import 'package:niman/src/markdown/render/source_typing.dart';
import 'package:niman/src/markdown/render/source_view_config.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/markdown/source_edit.dart';
import 'package:niman/src/markdown/source_styler.dart';
import 'package:niman/src/templates/template_commands.dart';

/// The source editor itself (#1261): the note's text, its caret, its
/// history, its colours and its folds, and every edit made to them — the
/// keyboard's, the shell's, an undo's.
///
/// It owns the collaborators the editor is made of and wires them to each
/// other directly: the text side here, the geometry in [layout], the
/// pointer, the menus and the overlays in [controls]. The view that shows
/// it (`MarkdownSourceView`) builds it, hands it the configuration on every
/// update, and lays it out; it is told to draw again by this notifier.
///
/// It is built and driven without a widget: an edit, a caret motion and a
/// fold need no frame. What needs the view's place in the tree — the
/// platform view the keyboard attaches to, the insets — asks [context].
final class SourceEditor extends ChangeNotifier {
  /// The editor of [buffer], drawn as [look] says.
  new({
    required SourceBuffer buffer,
    required this.look,
    required this.context,
    this.behaviour = const SourceBehaviour(),
    this.services = const SourceServices(),
    this.actions = const SourceActions(),
    SelectionModel? selection,
    SelectionModel initialSelection = const SelectionModel.at(0),
    this.onSelection,
    this.onChanged,
    EditHistory? history,
    ScrollController? controller,
    FocusNode? focusNode,
  }) : _buffer = buffer,
       _controlled = selection,
       _ownSelection = initialSelection,
       _history = history ?? EditHistory(),
       _seenRevision = buffer.revision {
    layout = SourceEditorLayout(this, controller: controller);
    controls = SourceEditorControls(this, focusNode: focusNode);
  }

  /// The note's geometry: the rows, the caret's rectangle, the scroll.
  late final SourceEditorLayout layout;

  /// The pointer, the touch selection, the menus and the overlays.
  late final SourceEditorControls controls;

  /// Where the view stands in the tree, for what asks the platform view.
  final BuildContext Function() context;

  /// The text on screen.
  SourceBuffer get buffer => _buffer;
  SourceBuffer _buffer;

  /// How the note is drawn.
  SourceLook look;

  /// How the note is edited.
  SourceBehaviour behaviour;

  /// What the note is checked and drawn with.
  SourceServices services;

  /// What the note asks of its owner.
  SourceActions actions;

  /// Told when the caret moves; see `MarkdownSourceView.onSelection`.
  ValueChanged<SelectionModel>? onSelection;

  /// Told after every edit; see `MarkdownSourceView.onChanged`.
  ValueChanged<SourceEdit>? onChanged;

  bool _disposed = false;

  /// Whether the editor is still in use: false once its view let it go.
  bool get mounted => !_disposed;

  /// Asks the view to draw the note again.
  void rebuild() {
    if (!_disposed) notifyListeners();
  }

  /// The colours: read in place or in the background, moved along by
  /// every edit, and their scan carried on when an edit left it owed.
  late final SourceStyling styling = SourceStyling(
    buffer: () => buffer,
    mounted: () => mounted,
    readsInBackground: readsInBackground,
    progressiveLines: () => progressiveLines,
    landed: () {
      rebuild();
      // The colours landing is also the formats landing: until they are
      // read, the caret's line has no tokens and the toolbar would show
      // every button dark on a note whose syntax the writer is inside.
      layout.caret.publishActive(layout.caret.spot.value);
      // And it is the caret's line landing: a heading, or a formula, is
      // drawn at another height than the plain line the caret was measured
      // over. The reading came in outside any edit, so nothing else asks
      // for the caret to be measured again.
      layout.measureCaretAfterFrame();
    },
    settled: () {
      // A layout that found the scan owed drew the `columns` blocks
      // stacked (#729): settled, it lays them out side by side.
      if (layout.rows.runsOwed) rebuild();
    },
  );

  /// The colours ([SourceStyling.styler]): null while a long note is read
  /// in the background, its lines drawn plain until it lands.
  SourceStyler? get styler => styling.styler;

  /// The folded heading sections; the rows are the lines they leave.
  final SourceFolds folds = SourceFolds();

  /// Where the sections those folds hide end, kept for the buffer's
  /// revision: the tokenizer's question, as far as it has been asked.
  late final SourceSections sections = SourceSections(
    buffer: () => buffer,
    blockOf: (line) => blockAt?.call(line),
    tokensOf: (line) => lineAt(line).tokens,
  );

  /// The keyboard, wired to the buffer this editor holds.
  late SourceInput input;

  /// The edits that made the note what it is, and the way back.
  EditHistory get history => _history;
  EditHistory _history;

  /// Where the caret is when the caller does not hold one — an uncontrolled
  /// view, which is what a test and a quick screen both are.
  SelectionModel _ownSelection;

  /// The caller's caret, when it holds one.
  SelectionModel? _controlled;

  /// Where the caret is, and what it has selected: the caller's when it
  /// holds one.
  SelectionModel get selection => _controlled ?? _ownSelection;

  /// The buffer revision this editor last drew or edited, so an edit made
  /// behind its back is seen. (Comparing the old widget's buffer with the new
  /// one's could not see it: it is the same object.)
  int _seenRevision;

  /// What the frame the view is drawing costs it, in parts (#316); see
  /// [FrameCost]. Held to half of 60 Hz ([FrameCost.frameBarMicros]), so the
  /// line appears while the rest of the app still has room in the frame;
  /// written as `[edit] frame: …`, the logger naming the view.
  final FrameCost cost = FrameCost(
    label: '',
    log: const AppLogger(name: 'edit'),
  );

  /// From how many lines on a note's colours are read in the background.
  ///
  /// Below it the reading costs a frame or less and is done in place, so
  /// the first frame is already coloured.
  @visibleForTesting
  static int backgroundLines = 50000;

  /// Whether [buffer] is a long note: one whose colours are read in the
  /// background ([backgroundLines]), and whose scan keeps its tags and links
  /// block by block ([references]) — so what follows it as it is edited
  /// reads those rather than its text.
  static bool readsInBackground(SourceBuffer buffer) =>
      buffer.lineCount >= backgroundLines;

  /// From how many lines on a note read in place reads the blocks of its top
  /// alone before its first frame, and the rest a slice at a time after it
  /// (`SourceStyling`).
  ///
  /// The whole scan of a 16 000-line note was most of the 20 ms frame that
  /// opened it on a tablet (device log, 2026-10-20), for a frame that draws
  /// a screen of it. Below this the scan is a few milliseconds, and a note
  /// read whole has its outline at once.
  @visibleForTesting
  static int progressiveLines = BlockScanner.defaultBudget;

  /// Reads the note, wires the keyboard to it and starts listening: what
  /// the view's first frame needs.
  void start() {
    styling.restyle();
    layout.rows.rebuild();
    input = _makeInput();
    controls.start();
    layout.scheduleCaret();
  }

  /// Takes the configuration of an update of the view: what changed in
  /// each group is passed on to the part that cares about it.
  void configure({
    required SourceBuffer buffer,
    required EditHistory Function() history,
    required SelectionModel Function() initialSelection,
    required SourceLook look,
    required SourceBehaviour behaviour,
    required SourceServices services,
    required SourceActions actions,
    required SelectionModel? selection,
    required ValueChanged<SelectionModel>? onSelection,
    required ValueChanged<SourceEdit>? onChanged,
    required ScrollController? controller,
  }) {
    final oldLook = this.look;
    final oldBehaviour = this.behaviour;
    final oldServices = this.services;
    final oldSelection = _controlled;
    this.look = look;
    this.behaviour = behaviour;
    this.services = services;
    this.actions = actions;
    this.onSelection = onSelection;
    this.onChanged = onChanged;
    _controlled = selection;
    if (oldBehaviour != behaviour) controls.behaviourChanged(oldBehaviour);
    if (oldServices != services) controls.servicesChanged(oldServices);
    if (!identical(buffer, _buffer)) {
      _showBuffer(buffer, history(), initialSelection());
    } else if (buffer.revision != _seenRevision) {
      _editedBehind();
    }
    if (oldSelection != selection || oldLook.caretWidth != look.caretWidth) {
      layout.scheduleCaret();
    } else if (look.redraws(oldLook)) {
      // By value (#789): source mode with a chosen face builds its theme
      // in every build (`surfaceThemeFor`), and a copy of the same values
      // moves no caret.
      //
      // The caret's line is drawn another way — source to live and back
      // above all — and the caret kept the place and the height it had.
      layout.measureCaretAfterFrame();
    }
    // Switched on while writing: the caret goes to the middle at once.
    if (behaviour.typewriter && !oldBehaviour.typewriter) layout.followCaret();
    layout.useController(controller);
  }

  /// Another note: the keyboard, the history and the caret were this one's.
  /// The panel too, and it is the one thing here that cannot be rebuilt
  /// from the new text: it holds the offsets of the link it was opened in
  /// and the rows that complete it, so `Enter` would write a note name
  /// into the note that took its place (#494).
  void _showBuffer(
    SourceBuffer next,
    EditHistory history,
    SelectionModel initial,
  ) {
    _buffer = next;
    controls.suggest.dropInUpdate();
    final attached = input.isAttached;
    input.detach();
    _history = history;
    _ownSelection = initial;
    input = _makeInput();
    typing.brackets.clear();
    styling.restyle();
    folds.clear();
    layout.rows.rebuild();
    _seenRevision = next.revision;
    // Another note to check: the first answer is read off it, not off the
    // one it replaced.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controls.hints.run();
    });
    if (attached) input.attach(viewId: View.of(context()).viewId);
  }

  /// An edit this editor did not make (a command, a revert): the colours are
  /// read again rather than adjusted, because there is no `SourceEdit` to
  /// follow. The link the panel stood in may be gone or moved — the caret
  /// is clamped into whatever replaced it — and its offsets are the ones
  /// read from the text that went, so the panel goes with them (#494).
  void _editedBehind() {
    controls.suggest.dropInUpdate();
    styling.restyle();
    folds.clear();
    layout.rows.rebuild();
    _seenRevision = buffer.revision;
    _ownSelection = _ownSelection.clampTo(buffer.length);
    controls.hints.schedule();
    // And the platform's copy is now of a note that is not there any more.
    input.sendSelection();
  }

  @override
  void dispose() {
    _disposed = true;
    // The keyboard's connection goes before the focus it was opened for.
    input.detach();
    controls.dispose();
    styling.dispose();
    layout.dispose();
    super.dispose();
  }

  /// The keyboard for the buffer this editor holds.
  SourceInput _makeInput() => SourceInput(
    buffer: buffer,
    reach: layout.inputReach,
    onRecord: _history.record,
    onNewline: typing.newline,
    onTyped: typing.typed,
    onTokenizer: (edit, buffer) {
      // The edit path's clock: opened here and closed by `onEdited`, the
      // two ends of the same `_replace` (#316) — and only when a profiling
      // round asked for the frame's parts (#362): a release build reads no
      // clock on the path it would be measuring.
      cost.startEdit();
      styling.edited(edit);
    },
    selection: () => selection,
    onSelection: (next) {
      _ownSelection = next;
      rebuild();
      onSelection?.call(next);
      layout.scheduleCaret();
      controls.suggest.refresh();
    },
    onEdited: (edit) {
      controls.touch.hide();
      _syncLines(edit);
      _ownSelection = _ownSelection.clampTo(buffer.length);
      rebuild();
      layout.scheduleCaret();
      layout.reveal.ensureCaretVisible();
      _notifyChanged(edit);
      cost.endEdit();
      controls.suggest.refresh(typed: true);
    },
  );

  /// Keeps the height map at the buffer's line count, after [edit]
  /// ([SourceRows.sync]), and the revision this editor has seen with it.
  void _syncLines([SourceEdit? edit]) {
    _seenRevision = buffer.revision;
    layout.rows.sync(edit);
  }

  /// The footnote labels the note cites or defines, as the scan behind the
  /// colours has them: what a new footnote's number must pass.
  Iterable<String> get footnoteLabels {
    final styler = this.styler;
    if (styler == null) return const <String>[];
    return {
      ...styler.scope.footnoteCounts.keys,
      for (final footnote in styler.footnotes) footnote.label,
    };
  }

  /// The note's headings, as the scan behind the colours has them, or null
  /// while there is no scan yet (a long note reads in the background, see
  /// [SourceStyling.restyle]).
  ///
  /// The outline the note view publishes, from an answer it already holds.
  List<OutlineEntry>? get headings => styler?.headings;

  /// Whether the note's blocks are all current: false while an edit that
  /// changed the rest of the note is still being scanned on, a slice at a
  /// time, and [headings] waits for it — and while a long note is still
  /// being read in the background, when there are no blocks at all.
  bool get scanSettled => styler?.settled ?? false;

  /// The note's tags and links as of the buffer's revision, when the scan
  /// behind the colours keeps them ([SourceStyler.references]): a long note's
  /// save hands them to the index, which then does not read the note for
  /// them. Null otherwise.
  NoteReferences? references() => styler?.references();

  /// The note's blocks, as the scan behind the colours has them, or null
  /// while there is no scan yet. O(blocks): [SourceStyler.blocks] copies the
  /// list.
  List<Block>? get blocks => styler?.blocks;

  /// The block holding a line, as the scan behind the colours has it —
  /// scanned up to the line when the scan still owes it — or null while
  /// there is no scan. O(log blocks) a line, never the note read.
  Block? Function(int line)? get blockAt => styler?.blockOf;

  /// The note's blocks and definitions as of the buffer's revision, with
  /// what changed since the last hand-over, or null while there is no whole,
  /// current scan of it ([SourceStyler.handOver]).
  DocumentScan? handOver() => styler?.handOver();

  /// Line [index] as the editor draws it: the **buffer's** text, with the
  /// tokenizer's runs when the two agree about that line.
  ///
  /// The buffer is the note; the tokenizer is a decoration of it. Drawing the
  /// buffer's lines and numbering them by index means a tokenizer that has
  /// fallen behind can make a line *plain*, and cannot make the numbers count
  /// something the note does not have — which is what a device showed when
  /// the two drifted.
  StyledLine lineAt(int index) =>
      StyledLine(buffer.lineAt(index), tokensAt(index) ?? const <Token>[]);

  /// Line [index]'s tokens, or null while they are **not known**: the line of
  /// a long note, before the background reading lands
  /// ([SourceStyling.restyle]).
  ///
  /// A null is not "this line has no tokens" — it is "nobody has read it
  /// yet", and the two must not be confused by a reader that takes tokens as
  /// the line's *structure*: the spelling's skip ranges are made of them
  /// (#373).
  List<Token>? tokensAt(int index) {
    final text = buffer.lineAt(index);
    final own = look.lineTokens;
    if (own != null) return own(text);
    final styler = this.styler;
    if (styler == null) return null;
    final tokens = styler.tokensOf(index);
    if (!behaviour.templateCommands) return tokens;
    final commands = templateCommandsIn(text);
    return commands.isEmpty
        ? tokens
        : overlayTokens(tokens, commands, TokenKind.templateCommand);
  }

  /// The runs on line [index], or none while a long note's colours are
  /// still being read — for the spelling's pass, which skips what is not
  /// prose.
  List<Token> tokensOf(int index) {
    if (index < 0 || index >= buffer.lineCount) return const <Token>[];
    return lineAt(index).tokens;
  }

  /// The quote marks before a verbatim line's text, null for a line with
  /// syntax of its own (#579). O(log blocks) a line.
  int? verbatimQuotes(int line) => verbatimQuotesOf(blockAt?.call(line));

  /// The wikilink or Markdown link under [offset] — its kind, its text as
  /// written, and a Markdown link's resolved target — or null. An offset on
  /// either edge of the link is on it: a click lands between characters, and a
  /// click on the first or the last one lands on the edge.
  (TokenKind, String, String?)? linkAt(int offset) {
    final line = buffer.lineOf(offset.clamp(0, buffer.length));
    final local = offset - buffer.offsetOfLine(line);
    final styled = lineAt(line);
    // A link comes as its markers and its text, one token each: the link
    // is the run of them, up to the marker that closes it (#971).
    for (final (:kind, :start, :end) in linkRuns(styled.tokens, styled.text)) {
      if (local >= start && local <= end) {
        final raw = styled.text.substring(start, end);
        // A reference link spells no `](href)`: its target has to come from
        // the parse the line was drawn from. An inline link keeps reading it
        // out of its own source, as it always has.
        final href = kind == TokenKind.link && !raw.contains('](')
            ? styler?.linkHrefAt(line, start)
            : null;
        return (kind, raw, href);
      }
    }
    return null;
  }

  /// Makes the note say [text] because it changed elsewhere (the disk, the
  /// WYSIWYG): the history goes, since undoing past it would write the old
  /// text back over the other change, and nothing is reported as an edit.
  void replaceAll(String text) {
    buffer.replaceRange(0, buffer.length, text);
    _history.clear();
    // The panel holds offsets into the text that went (#494).
    controls.suggest.close();
    styling.restyle();
    folds.clear();
    layout.rows.rebuild();
    _seenRevision = buffer.revision;
    _ownSelection = _ownSelection.clampTo(buffer.length);
    rebuild();
    input.sendSelection();
    controls.hints.run();
    layout.scheduleCaret();
  }

  /// Undoes the last edit, and says whether there was one.
  bool undo() => _applyHistory(_history.undo(buffer));

  /// Redoes the last undone edit, and says whether there was one.
  bool redo() => _applyHistory(_history.redo(buffer));

  /// Rebuilds what an undo or a redo changed, the same way a platform edit
  /// does; [caret] is where the history put the caret, null when it had
  /// nothing to do.
  bool _applyHistory(int? caret) {
    if (caret == null) return false;
    // An undo is an edit like any other: the buffer says which lines it
    // touched, and the tokenizer and the map follow those lines.
    final edit = _history.lastEdit;
    if (edit != null) {
      styling.edited(edit);
    } else {
      styling.restyle();
    }
    _syncLines(edit);
    // Undo puts the caret after what it restored (where it was before a
    // deletion, at the start of typing it took back); redo after what it did.
    _ownSelection = selection.collapsedTo(caret).clampTo(buffer.length);
    rebuild();
    onSelection?.call(_ownSelection);
    input.sendSelection();
    layout.scheduleCaret();
    layout.reveal.ensureCaretVisible();
    // An undo is an edit no keystroke made: the panel is read again off the
    // text it left — it follows a link still there and closes on one gone
    // (#494).
    controls.suggest.refresh();
    if (edit != null) _notifyChanged(edit);
    return true;
  }

  /// Replaces `[start, end)` with [text] because the *app* asked, not the
  /// platform: the history records it, the tokenizer follows it, and the
  /// platform is told where the caret went — [caret], or after what the note
  /// stored when none is given.
  ///
  /// With [verbatim] the text's own line endings are kept (see
  /// `SourceBuffer.replaceRange`). Without [follow] the note stays where it
  /// is on screen rather than going to the caret: an edit made somewhere the
  /// writer is looking, not where they are typing — a checkbox ticked.
  ///
  /// The last [closing] characters of [text] are closers written ahead of the
  /// caret — the `)` of a `(` — which the history keeps in the step of the
  /// typing inside the pair.
  void replaceRange(
    int start,
    int end,
    String text, {
    SelectionModel? caret,
    bool verbatim = false,
    bool follow = true,
    int closing = 0,
  }) {
    if (start < 0 || end < start || end > buffer.length) return;
    controls.touch.hide();
    final before = buffer.length;
    final removed = buffer.substring(start, end);
    final edit = buffer.replaceRange(start, end, text, verbatim: verbatim);
    final stored = buffer.length - before + (end - start);
    _history.record(
      EditRecord(
        start: start,
        removed: removed,
        inserted: buffer.substring(start, start + stored),
      ),
      closing: closing,
    );
    styling.edited(edit);
    final next = (caret ?? SelectionModel.at(start + stored)).clampTo(
      buffer.length,
    );
    _syncLines(edit);
    _ownSelection = next;
    rebuild();
    onSelection?.call(next);
    input.sendSelection();
    layout.scheduleCaret();
    if (follow) layout.reveal.ensureCaretVisible();
    // The shell saves and counts what it is told about: a cut, a paste or a
    // backspace is as much an edit as a keystroke, and the edit says which
    // lines moved so the word count pays for those and not for the note.
    _notifyChanged(edit);
    // An edit made where the writer is looking rather than typing — a box
    // ticked — types no link.
    controls.suggest.refresh(typed: follow);
  }

  /// The note changed, so the shell can save it.
  void _notifyChanged(SourceEdit edit) {
    // A template's problems are read off the text again, once the writer
    // pauses: the keystroke that led here pays for the timer alone (#316).
    controls.hints.schedule();
    onChanged?.call(edit);
  }

  /// What typing means beyond the characters typed: a bracket's pair, a
  /// list carried on by Enter, Tab's indent, the surface's own deletions
  /// and the clipboard.
  late final SourceTyping typing = SourceTyping(
    buffer: () => buffer,
    selection: () => selection,
    live: () => look.hideMarkers,
    mounted: () => mounted,
    indentWidth: () => behaviour.indentWidth,
    blockOf: (line) => styler?.blockOf(line),
    tokensOf: (line) => lineAt(line).tokens,
    verbatimQuotes: verbatimQuotes,
    replace: replaceRange,
    // Past a closing character the writer typed over: the typing goes on
    // in the undo step that wrote the pair (#1053).
    stepTo: (offset) {
      applySelection(
        selection.collapsedTo(offset),
        reveal: true,
        endStep: false,
      );
      _history.stepOver(offset);
    },
    swallowedBreak: () => controls.suggest.takeSwallowedBreak(),
    tableEnter: () => controls.tableKeys.enter(),
    onPaste: () => actions.onPaste,
  );

  /// Deletes the selection, or what is before the caret: one character, or a
  /// word with [word] ([SourceTyping.delete]).
  void deleteBackward({bool word = false}) =>
      typing.delete(word ? CaretMotion.wordLeft : CaretMotion.characterLeft);

  /// Deletes the selection, or what is after the caret.
  void deleteForward({bool word = false}) =>
      typing.delete(word ? CaretMotion.wordRight : CaretMotion.characterRight);

  /// Makes [next] the selection — clamped into the note — and tells whoever
  /// needs to know: the typing step ends, the shell and the platform hear of
  /// it, and the caret is measured where it went. Every move the writer
  /// makes comes through here; an edit's caret comes with the edit
  /// ([replaceRange], [undo]).
  ///
  /// Only what changed is repainted: a caret that stays collapsed moves no
  /// text, so the two lines involved — the one that lost it and the one that
  /// gained it — repaint through the caret and nothing else does, while a
  /// move that creates or clears a *range* rebuilds the note, a range being
  /// a background on the runs it covers. [rebuild] rebuilds it whatever
  /// moved.
  ///
  /// [reveal] scrolls the caret into view. [suggest] lets the wikilink panel
  /// follow the caret — or close behind it.
  void applySelection(
    SelectionModel next, {
    bool rebuild = false,
    bool reveal = false,
    bool suggest = true,
    bool endStep = true,
  }) {
    final clamped = next.clampTo(buffer.length);
    // A caret the writer moved ends the typing step: what is typed next is
    // undone on its own. Not so a caret that steps over a closer the step
    // wrote (`SourceTyping`).
    if (endStep) _history.seal();
    final wasRange = !selection.isCollapsed;
    _ownSelection = clamped;
    if (rebuild || !clamped.isCollapsed || wasRange) this.rebuild();
    layout.caret.spot.value = layout.caret.spotOf(clamped.extent);
    if (suggest) controls.suggest.refresh();
    onSelection?.call(clamped);
    input.sendSelection();
    layout.scheduleCaret();
    if (reveal) layout.reveal.ensureCaretVisible();
  }

  /// Selects [next], and tells whoever needs to know.
  void select(SelectionModel next) =>
      applySelection(next, rebuild: true, reveal: true);

  /// Puts the caret at [offset], tells the platform, and keeps it on screen.
  void placeCaret(int offset) =>
      applySelection(selection.collapsedTo(offset), reveal: true);

  /// Selects `[start, end)` by a click or a jump: the note rebuilt, and the
  /// wikilink panel left as it is.
  void selectRange(int start, int end) => applySelection(
    SelectionModel(anchor: start, extent: end),
    rebuild: true,
    suggest: false,
  );

  /// Selects everything.
  void selectAll() => selectRange(0, buffer.length);

  /// Notes longer than this fold nothing: finding where a section ends walks
  /// the lines after its heading, and the legacy editor drew no fold arrows
  /// past the same size either.
  static const int _foldLineLimit = 20000;

  /// Whether the gutter offers fold arrows.
  bool get _foldingEnabled =>
      look.showLineNumbers && buffer.lineCount <= _foldLineLimit;

  /// Folds the section under the heading on [line], or unfolds it.
  ///
  /// A caret inside the section goes to the heading's end: the caret is never
  /// on a line nobody can see.
  void toggleFold(int line) {
    if (line < 0 || line >= buffer.lineCount) return;
    final rows = layout.rows;
    if (folds.isFolded(line)) {
      rows.reshape(() {
        folds.unfold(line);
        return true;
      });
    } else {
      final end = sections.foldableEnd(line);
      if (end == null) return;
      rows.reshape(() {
        folds.fold(line, end);
        return true;
      });
      final caret = buffer.lineOf(selection.extent);
      if (folds.isHidden(caret)) {
        placeCaret(buffer.offsetOfLine(line) + buffer.lineLengthAt(line));
      }
    }
    rebuild();
  }

  /// Unfolds what hides the caret, when an edit, a find or a motion took it
  /// there.
  void revealCaret() {
    if (folds.isEmpty) return;
    final line = buffer.lineOf(selection.extent.clamp(0, buffer.length));
    var revealed = false;
    layout.rows.reshape(() => revealed = folds.reveal(line));
    if (revealed && mounted) rebuild();
  }

  /// What the gutter shows beside line [line].
  SourceFoldMark foldMarkOf(int line) {
    if (!_foldingEnabled) return SourceFoldMark.none;
    if (folds.isFolded(line)) return SourceFoldMark.closed;
    return sections.foldableEnd(line) == null
        ? SourceFoldMark.none
        : SourceFoldMark.open;
  }
}
