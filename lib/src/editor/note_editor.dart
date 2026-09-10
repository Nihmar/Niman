import 'dart:async';

import 'package:copist/src/core/settings/library_config.dart';
import 'package:copist/src/editor/markdown_chunks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

/// The note source editor: a thin wrapper over re_editor's [CodeEditor].
///
/// This replaces the custom line-based widget stack (hand-built caret,
/// selection, IME bridge, gestures and virtualized view). Caret, selection,
/// IME/composition, selection handles, scrolling and accessibility now come
/// from the package; Copist keeps ownership of load/save and of the
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

  /// The find bar builder (the owner supplies `CopistFindPanel`).
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

  @override
  Widget build(BuildContext context) {
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
        if (!showLineNumbers) return const SizedBox.shrink();
        return Row(
          children: [
            DefaultCodeLineNumber(controller: editing, notifier: notifier),
            DefaultCodeChunkIndicator(
              width: 20,
              controller: chunkController,
              notifier: notifier,
            ),
          ],
        );
      },
      // Heading-section folds (the tokenizer's outline — fences/math/
      // frontmatter are never anchors), not `{}`/`[]`.
      chunkAnalyzer: const MarkdownChunkAnalyzer(),
      scrollController: scrollController,
      findController: findController,
      findBuilder: findBuilder,
      shortcutsActivatorsBuilder: shortcutsActivators,
      // PageUp/PageDown: bound by Copist's activators, moved here because
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
      toolbarController: _toolbarController(),
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
  SelectionToolbarController _toolbarController() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return MobileSelectionToolbarController(builder: _selectionMenu);
    }
    return _DesktopSelectionToolbar(builder: _selectionMenu);
  }

  /// Cut/copy/paste/select all for the current selection.
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
    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: anchors,
      buttonItems: items,
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
/// leaves the closing to the editor, which on the desktop never asks:
/// re_editor calls `hideToolbar` from its mobile gestures only, so a menu
/// opened by a right-click stayed up through every click after it
/// (2026-09-10 device report). The barrier is the menu's own: one click
/// anywhere else takes it down, and that click does nothing else, which
/// is how a context menu behaves everywhere.
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
