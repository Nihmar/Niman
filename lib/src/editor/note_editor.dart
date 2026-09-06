import 'dart:async';

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
final class NoteEditor extends StatelessWidget {
  /// Creates the editor over [controller].
  const NoteEditor({
    required this.controller,
    required this.focusNode,
    this.showLineNumbers = true,
    this.autofocus = false,
    this.scrollController,
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

  /// The editor's scroll controllers (vertical is the sync side).
  final CodeScrollController? scrollController;

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
      style: const CodeEditorStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: [
          'Consolas',
          'DejaVu Sans Mono',
          'Roboto Mono',
        ],
      ),
      // The row-number column (settings toggle). No chunk indicator: the
      // default analyzer folds `{}`/`[]` — wrong for Markdown — so it is
      // disabled below and heading folds (folding.dart) are re-introduced
      // through that hook.
      indicatorBuilder: showLineNumbers
          ? (context, editingController, chunkController, notifier) {
              return DefaultCodeLineNumber(
                controller: editingController,
                notifier: notifier,
              );
            }
          : null,
      scrollController: scrollController,
      // The default chunk analyzer folds `{}`/`[]` — wrong for Markdown.
      // Heading folds (folding.dart) are re-introduced through this hook.
      chunkAnalyzer: const NonCodeChunkAnalyzer(),
      toolbarController: MobileSelectionToolbarController(
        builder: ({
          required context,
          required anchors,
          required controller,
          required onDismiss,
          required onRefresh,
        }) {
          final items = <ContextMenuButtonItem>[
            // Cut/copy of a collapsed caret would eat the whole line, so
            // they are offered for a real selection only.
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
        },
      ),
    );
  }
}
