import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/editor/editor_context_menu.dart';
import 'package:niman/src/editor/markdown_chunks.dart';
import 'package:niman/src/editor/note_column.dart';
import 'package:niman/src/editor/typewriter_scroll.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:re_editor/re_editor.dart';

/// The caret's width in Zen mode (#69): the package's is 2.
const double zenCaretWidth = 3;

/// The note source editor: a thin wrapper over re_editor's [CodeEditor].
///
/// This replaces the custom line-based widget stack (hand-built caret,
/// selection, IME bridge, gestures and virtualized view). Caret, selection,
/// IME/composition, selection handles, scrolling and accessibility now come
/// from the package; Niman keeps ownership of load/save and of the
/// Markdown language knowledge (`highlighting.dart`, `folding.dart`,
/// `outline.dart`).
///
/// [controller] owns the text. It is created by the owner (the `NoteView`)
/// so the save path can read `controller.text` without a full string
/// crossing the widget tree per keystroke; the owner also listens to the
/// controller (it is a `ValueNotifier`) for changes — through the
/// controller, not a widget callback, so changes made before this widget
/// exists (the note load) are still seen. [focusNode] shows/hides the IME
/// and lets the owner save on focus loss. [showLineNumbers] hides the
/// row-number column (the settings toggle); [autofocus] shows the keyboard
/// on open (the keyboard-on-open settings toggle, default off — the
/// keyboard appears on the first tap). [scrollController] lets the shell
/// attach to the editor's vertical scroll (scroll sync, T-M2-06).
///
/// [findController] + [findBuilder] wire the in-editor find & replace
/// (the owner's [CodeFindController] and its bar); [shortcutsActivators]
/// extends the package's default editor shortcuts (Ctrl+H = replace).
///
/// [column] centres the text (issue #171): see [NoteColumn].
final class NoteEditor extends StatelessWidget {
  /// Creates the editor over [controller].
  const new({
    required this.controller,
    required this.focusNode,
    this.showLineNumbers = true,
    this.autofocus = false,
    this.fontSize = baseNoteFontSize,
    this.scrollController,
    this.findController,
    this.findBuilder,
    this.shortcutsActivators,
    this.onIndicator,
    this.spellCheck,
    this.column = NoteColumn.off,
    this.formatMenu,
    this.caretWidth,
    this.typewriter = false,
    super.key,
  });

  /// The text + selection model the editor edits.
  final CodeLineEditingController controller;

  /// The focus node; the IME shows on focus and hides on blur.
  final FocusNode focusNode;

  /// Whether the row-number column is shown (the settings toggle).
  final bool showLineNumbers;

  /// Whether the editor focuses (shows the keyboard) on open.
  final bool autofocus;

  /// The source text's size in logical pixels (the note text-size
  /// setting, T-M6-12).
  ///
  /// It is a size and not a scale because the editor never sees one:
  /// re_editor paints its own text and reads no `textScaler`, which is
  /// also why the interface slider leaves this widget alone.
  final double fontSize;

  /// The editor's scroll controllers (vertical is the sync side).
  final CodeScrollController? scrollController;

  /// The note's find state; when null the editor makes its own.
  final CodeFindController? findController;

  /// The find bar builder (the owner supplies `NimanFindPanel`).
  final CodeFindBuilder? findBuilder;

  /// Editor shortcut activators (defaults + Ctrl+H replace).
  final CodeShortcutsActivatorsBuilder? shortcutsActivators;

  /// Receives the editor's indicator notifier — the source lines it has
  /// laid out, republished on every layout — as soon as the package builds
  /// it. The scroll sync reads the top visible line from it (T-M2-06):
  /// the editor's `maxScrollExtent` counts every line below the viewport
  /// as a single row, so it grows as wrapped lines scroll in and a
  /// fraction of it cannot say which line is on screen.
  final ValueChanged<CodeIndicatorValueNotifier>? onIndicator;

  /// The editor's spelling state (issue #60): the context menu's
  /// Add-to-dictionary entry. Null (tests, or a platform without hunspell)
  /// offers none.
  final EditorSpellCheck? spellCheck;

  /// Where the text sits across the editor (issue #171).
  final NoteColumn column;

  /// The toolbar's formatting actions for the context menu (#174); null
  /// offers the clipboard alone.
  final FormatMenuBuilder? formatMenu;

  /// The caret's width; null keeps the package's own (Zen mode, #69,
  /// thickens it).
  final double? caretWidth;

  /// Typewriter mode (#70): room below the last line, so the caret can
  /// reach the middle there too. The owner does the centring.
  final bool typewriter;

  /// re_editor's own padding around the text: what the editor had before
  /// the column, kept wherever there is no side space.
  static const double _fieldInset = 5;

  @override
  Widget build(BuildContext context) {
    if (!column.enabled && !typewriter) return _editor(0, 0);
    return LayoutBuilder(
      builder: (context, constraints) => _editor(
        column.enabled ? column.sideSpaceIn(constraints.maxWidth) : 0,
        typewriter ? typewriterSlack(constraints.maxHeight) : 0,
      ),
    );
  }

  /// The editor with [side] logical pixels of column space on each side,
  /// and [slack] of room below the last line (typewriter mode).
  ///
  /// The left side space is the row-number column's to take: the numbers
  /// sit at its right end, against the text, and the text starts at
  /// `side + NoteColumn.textInset` like the WYSIWYG's — so switching
  /// editors does not move the text sideways. Both sides stay inside the
  /// editor's scroll view, so the scrollbar keeps to the pane's edge and
  /// the wheel scrolls from the margins too.
  Widget _editor(double side, double slack) {
    final gutter = side == 0 ? 0.0 : side + NoteColumn.textInset - _fieldInset;
    return CodeEditor(
      controller: controller,
      focusNode: focusNode,
      // The keyboard appears on an explicit tap only by default; the
      // keyboard-on-open settings toggle switches this to focus-on-open.
      autofocus: autofocus,
      // Prose wraps at the viewport; horizontal scrolling is for code.
      wordWrap: true,
      // Monospace source text: the `monospace` generic resolves on Android
      // (minikin) and Linux (fontconfig); the fallbacks cover Windows,
      // where no generic alias exists. Highlighting is NOT the package's
      // codeTheme engine (it re-highlights the whole buffer on every edit —
      // multi-second on novel-length notes); the controller's spanBuilder
      // (wired by `NoteView`) styles each line from the incremental
      // tokenizer instead.
      style: CodeEditorStyle(
        fontSize: fontSize,
        cursorWidth: caretWidth,
        fontFamily: 'monospace',
        fontFamilyFallback: const [
          'Consolas',
          'DejaVu Sans Mono',
          'Roboto Mono',
        ],
      ),
      // The row-number column + fold markers (settings + T-M2-07): heading
      // chunks come from MarkdownChunkAnalyzer (the header folds), not the
      // default brace folding.
      // Always built, even with the row numbers off: it is the only place
      // the package hands out the notifier the scroll sync needs, and an
      // empty indicator takes no room.
      indicatorBuilder: (context, editing, chunkController, notifier) {
        onIndicator?.call(notifier);
        if (!showLineNumbers) return SizedBox(width: gutter);
        final numbers = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DefaultCodeLineNumber(controller: editing, notifier: notifier),
            DefaultCodeChunkIndicator(
              width: 20,
              controller: chunkController,
              notifier: notifier,
            ),
          ],
        );
        if (gutter == 0) return numbers;
        // Never narrower than the numbers: a pane just wide enough for
        // the column lets them push the text rather than overlap it.
        return ConstrainedBox(
          constraints: BoxConstraints(minWidth: gutter),
          child: Align(
            alignment: Alignment.topRight,
            widthFactor: 1,
            child: numbers,
          ),
        );
      },
      padding: side == 0 && slack == 0
          ? null
          : EdgeInsets.fromLTRB(
              _fieldInset,
              _fieldInset,
              side == 0 ? _fieldInset : side + NoteColumn.textInset,
              _fieldInset + slack,
            ),
      // Heading-section folds (the tokenizer's outline — fences/math/
      // frontmatter are never anchors), not `{}`/`[]`.
      chunkAnalyzer: const MarkdownChunkAnalyzer(),
      scrollController: scrollController,
      findController: findController,
      findBuilder: findBuilder,
      shortcutsActivatorsBuilder: shortcutsActivators,
      // PageUp/PageDown: bound by Niman's activators, moved here because
      // the package's controller methods are `// TODO` stubs.
      shortcutOverrideActions: {
        CodeShortcutCursorMovePageIntent:
            CallbackAction<CodeShortcutCursorMovePageIntent>(
              onInvoke: (intent) {
                _moveByPage(forward: intent.forward);
                return null;
              },
            ),
      },
      toolbarController: _stableToolbar(),
    );
  }

  /// The selection toolbar, of the kind the platform actually has.
  ///
  /// re_editor picks its overlay controller by platform, and the desktop
  /// one shows the toolbar with no `renderRect` — which the package's
  /// mobile toolbar controller dereferences with `!`, so a right-click on
  /// Windows or Linux took the app down (2026-09-10 crash report). The
  /// desktop gets a controller of our own instead: the same menu, placed
  /// at the click and dismissed by the next one.
  SelectionToolbarController _toolbarController(ToolbarMenuBuilder builder) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return MobileSelectionToolbarController(builder: builder);
    }
    return _DesktopSelectionToolbar(builder: builder);
  }

  /// One toolbar controller per editing controller, for as long as the
  /// note is open.
  ///
  /// re_editor shows the toolbar through the controller it was built with
  /// and hides it through the one it has now. Built anew on every build,
  /// the one asked to hide had never shown anything, and the menu stayed
  /// on screen — on the phone after any rebuild, and since the note
  /// column (#171) the editor is rebuilt whenever the keyboard comes or
  /// goes (0.0.8 test round). The controller stays; its menu is built by
  /// the latest editor, with the latest spelling and format actions.
  SelectionToolbarController _stableToolbar() {
    _latest[controller] = this;
    final key = controller;
    return _toolbars[key] ??= _toolbarController(
      ({
        required context,
        required anchors,
        required controller,
        required onDismiss,
        required onRefresh,
      }) => _latest[key]!._selectionMenu(
        context: context,
        anchors: anchors,
        controller: controller,
        onDismiss: onDismiss,
        onRefresh: onRefresh,
      ),
    );
  }

  static final Expando<SelectionToolbarController> _toolbars = Expando(
    'selection toolbar',
  );
  static final Expando<NoteEditor> _latest = Expando('latest editor');

  /// Cut/copy/paste/select all for the current selection, then the
  /// toolbar's formatting actions (#174), then Add to dictionary.
  Widget _selectionMenu({
    required BuildContext context,
    required TextSelectionToolbarAnchors anchors,
    required CodeLineEditingController controller,
    required VoidCallback onDismiss,
    required VoidCallback onRefresh,
  }) {
    final items = <ContextMenuButtonItem>[
      // Cut/copy of a collapsed caret would eat the whole line, so they
      // are offered for a real selection only.
      if (!controller.selection.isCollapsed)
        ContextMenuButtonItem(
          type: ContextMenuButtonType.cut,
          onPressed: () {
            controller.cut();
            onDismiss();
          },
        ),
      if (!controller.selection.isCollapsed)
        ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          onPressed: () {
            unawaited(controller.copy());
            onDismiss();
          },
        ),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.paste,
        onPressed: () {
          controller.paste();
          onDismiss();
        },
      ),
      ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () {
          controller.selectAll();
          onDismiss();
        },
      ),
    ];
    final extras = <ContextMenuButtonItem>[];
    // The word under the caret (or the selection, when it is one word),
    // in the line's own coordinates: multi-line selections name no word.
    final spell = spellCheck;
    final selection = controller.selection;
    if (spell != null) {
      final lines = controller.codeLines;
      String? text;
      var start = 0;
      var end = 0;
      if (selection.isCollapsed) {
        text = lines[selection.extentIndex].text;
        start = end = selection.extentOffset;
      } else if (selection.baseIndex == selection.extentIndex) {
        text = lines[selection.baseIndex].text;
        start = selection.baseOffset;
        end = selection.extentOffset;
      }
      if (text != null) {
        final item = addToDictionaryItem(
          spell: spell,
          text: text,
          start: start,
          end: end,
          onDismiss: onDismiss,
        );
        if (item != null) extras.add(item);
      }
    }
    // Part of the editor, for unfocus purposes (#161).
    //
    // re_editor wraps the text area in a `CodeEditorTapRegion` whose
    // `onTapOutside` unfocuses the editor (`_code_editable.dart:266`), and
    // losing focus makes it hide the selection toolbar
    // (`_code_editable.dart:329`). This menu lives in the root overlay, so
    // without the region a click on it is a tap *outside*: the editor
    // unfocuses on pointer **down**, the overlay entry is removed, and the
    // button is gone before its `onTap` — every item silently did nothing,
    // Select all included (device report, 2026-09-18).
    //
    // `CodeEditorTapRegion` is the package's own answer to this, and the
    // WYSIWYG menu already has Flutter's equivalent (`TextFieldTapRegion`).
    return CodeEditorTapRegion(
      child: EditorContextMenu(
        anchors: anchors,
        clipboard: items,
        formats: formatMenu?.call() ?? const [],
        extras: extras,
        onDismiss: onDismiss,
      ),
    );
  }

  /// Moves a page: the caret first, the scroll following it.
  ///
  /// re_editor 0.10.0 declares the page intents but implements
  /// `moveCursorToPageUp/Down` as empty stubs, so the move lives here.
  /// Lines per page come from the document's own pixels-per-line average
  /// ([ScrollPosition.maxScrollExtent] over the line count): no theme
  /// internals, and word-wrapped lines are averaged in rather than
  /// missed.
  void _moveByPage({required bool forward}) {
    final lines = controller.codeLines.length;
    if (lines < 2) return;
    final scroller = scrollController?.verticalScroller;
    final position = scroller != null && scroller.hasClients
        ? scroller.position
        : null;
    final perPage = pageLineStep(
      lineCount: lines,
      extent: position?.maxScrollExtent ?? 0,
      viewport: position?.viewportDimension ?? 0,
    );
    if (perPage == 0) return;
    final current = controller.selection.extentIndex.clamp(0, lines - 1);
    final target = (current + (forward ? perPage : -perPage)).clamp(
      0,
      lines - 1,
    );
    if (target == current) return;
    controller.selection = CodeLineSelection.collapsed(
      index: target,
      offset: 0,
    );
    scrollController?.makeVisible(CodeLinePosition(index: target, offset: 0));
  }
}

/// The lines a PageUp/PageDown covers on a document of [lineCount] lines
/// with scroll [extent] and [viewport] pixels.
///
/// The viewport's share of the document's own pixels-per-line average
/// (content height over line count), not a theme line height: word-wrapped
/// lines are then counted in instead of missed. Clamped to at least one
/// line and at most the document.
int pageLineStep({
  required int lineCount,
  required double extent,
  required double viewport,
}) {
  if (lineCount < 2) return 0;
  final content = extent + viewport;
  if (content <= 0 || viewport <= 0) return lineCount - 1;
  return (viewport * lineCount / content).floor().clamp(1, lineCount - 1);
}

/// The desktop selection toolbar: [builder]'s menu in an overlay entry,
/// anchored where the click was, over a barrier that closes it.
///
/// The package ships only a mobile implementation, and that one positions
/// itself against a `renderRect` the desktop path never provides. It also
/// leaves the closing to the editor, and on the desktop the editor only
/// asks on focus loss: re_editor's gesture code calls `hideToolbar` from
/// its mobile paths only, so a menu opened by a right-click stayed up
/// through every click after it (2026-09-10 device report). The barrier is
/// the menu's own: one click anywhere else takes it down, and that click
/// does nothing else, which is how a context menu behaves everywhere.
///
/// That one remaining caller — the focus one — is why the menu has to sit
/// inside the editor's tap region (#161, see `_selectionMenu`). A click on
/// the menu that unfocuses the editor removes this entry on pointer down,
/// and the item never gets its tap.
final class _DesktopSelectionToolbar implements SelectionToolbarController {
  new({required this.builder});

  /// Builds the menu itself; shared with the mobile controller.
  final ToolbarMenuBuilder builder;

  OverlayEntry? _entry;

  @override
  void hide(BuildContext context) {
    _entry?.remove();
    _entry = null;
  }

  @override
  void show({
    required BuildContext context,
    required CodeLineEditingController controller,
    required TextSelectionToolbarAnchors anchors,
    required LayerLink layerLink,
    required ValueNotifier<bool> visibility,
    Rect? renderRect,
  }) {
    hide(context);
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              key: const Key('editor-menu-barrier'),
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => hide(context),
            ),
          ),
          // Full-screen constraints on purpose: the toolbar places itself
          // from the anchors inside the box it is given, and a loose one
          // would leave it in the corner.
          Positioned.fill(
            child: builder(
              context: context,
              anchors: anchors,
              controller: controller,
              onDismiss: () => hide(context),
              onRefresh: () => show(
                context: context,
                controller: controller,
                anchors: anchors,
                layerLink: layerLink,
                visibility: visibility,
                renderRect: renderRect,
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(entry);
    _entry = entry;
  }
}
