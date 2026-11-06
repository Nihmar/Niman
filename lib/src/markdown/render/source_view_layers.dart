import 'package:flutter/material.dart';
import 'package:niman/src/core/theme_tokens.dart';
import 'package:niman/src/editor/typewriter_scroll.dart';
import 'package:niman/src/markdown/block.dart';
import 'package:niman/src/markdown/block_parser.dart';
import 'package:niman/src/markdown/edit/source_shortcuts.dart';
import 'package:niman/src/markdown/live_inlines.dart';
import 'package:niman/src/markdown/render/content_clamp_physics.dart';
import 'package:niman/src/markdown/render/footnote_list.dart';
import 'package:niman/src/markdown/render/live_decorations.dart';
import 'package:niman/src/markdown/render/source_editor.dart';
import 'package:niman/src/markdown/render/source_line.dart';
import 'package:niman/src/markdown/render/source_live_lines.dart';
import 'package:niman/src/markdown/render/source_overlays.dart';
import 'package:niman/src/markdown/render/source_row_slivers.dart';
import 'package:niman/src/markdown/render/source_semantics.dart';

/// The source editor laid out (#1261), in its layers: the note's rows in
/// their scroll view, under the pointer's gestures and the keys' focus;
/// the semantics over them; and the overlays above everything. Each layer
/// reads the [editor] it draws.
final class SourceViewLayers {
  /// The layers [editor] is drawn in.
  const new(this.editor);

  /// The editor drawn.
  final SourceEditor editor;

  /// The note, its semantics and its overlays.
  Widget build(BuildContext context) {
    final layout = editor.layout;
    final controls = editor.controls;
    layout.metrics.syntax = editor.look.syntax ?? SyntaxColors.of(context);
    layout.metrics.scaler = MediaQuery.textScalerOf(context);
    // The touch selection draws above everything, handles and toolbar alike,
    // and follows the note as it scrolls; the desktop's menu stays where the
    // click was.
    final note = SourceSemantics(
      tick: layout.semanticsTick,
      buffer: editor.buffer,
      selection: () => editor.selection,
      focused: () => controls.focus.hasFocus,
      onTap: controls.requestKeyboard,
      onSelect: editor.select,
      onMove: layout.moveCaretBy,
      onCopy: editor.typing.copySelection,
      onCut: editor.typing.cutSelection,
      onPaste: editor.typing.paste,
      child: _keys(_gestures),
    );
    return SourceOverlays(
      scroll: layout.scroll,
      caretSpot: layout.caret.spot,
      menu: controls.menu,
      touch: controls.touch,
      tables: controls.handles,
      hints: controls.hints,
      suggest: controls.suggest,
      codeCopies: controls.codeCopies,
      child: note,
    );
  }

  /// [child] under the note's focus and the keys it answers itself.
  ///
  /// The shortcuts wrap the focus, not the other way round: a
  /// `CallbackShortcuts` only sees a key that travels through it on the way
  /// to the focused node, so one *below* the `Focus` it belongs to never
  /// fires.
  Widget _keys(Widget child) {
    final controls = editor.controls;
    return CallbackShortcuts(
      bindings: sourceShortcuts(controls.keyActions),
      child: Focus(
        focusNode: controls.focus,
        autofocus: editor.behaviour.autofocus,
        onKeyEvent: controls.menuKeys.handle,
        onFocusChange: (hasFocus) => controls.focusChanged(hasFocus: hasFocus),
        child: child,
      ),
    );
  }

  /// The note at the pane's width, under the mouse's and the finger's
  /// gestures.
  Widget get _gestures => LayoutBuilder(
    builder: (context, constraints) {
      final layout = editor.layout;
      final pointer = editor.controls.pointer;
      // Another width or text size wraps the caret's line anew.
      if (layout.metrics.layOut(
        constraints.maxWidth,
        MediaQuery.textScalerOf(context),
      )) {
        layout.measureCaretAfterFrame();
      }
      // The `columns` blocks that sit side by side at this width.
      layout.rows.layOutHosts(layout.metrics.textWidth);
      return pointer.listen(
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: pointer.tapUp,
          // Selecting by touch: a long press takes the word under the
          // finger, moving it extends by words, and letting go brings
          // the toolbar up. A mouse has its drag instead.
          onLongPressStart: (details) =>
              pointer.longPressAt(details.globalPosition, start: true),
          onLongPressMoveUpdate: (details) =>
              pointer.longPressAt(details.globalPosition, start: false),
          onLongPressEnd: (_) => pointer.longPressEnd(),
          // The text's own pointer over the note; the gutter keeps the
          // arrow (`_Line`), and a drawn task box the hand (#505).
          child: ValueListenableBuilder<MouseCursor>(
            valueListenable: pointer.cursor,
            builder: (context, cursor, child) => MouseRegion(
              cursor: cursor,
              onExit: (_) => pointer.exit(),
              child: child,
            ),
            child: NotificationListener<ScrollMetricsNotification>(
              onNotification: layout.reveal.onScrollMetrics,
              child: NotificationListener<ScrollNotification>(
                onNotification: layout.reveal.onScroll,
                child: _scrollView(constraints.maxHeight),
              ),
            ),
          ),
        ),
      );
    },
  );

  /// The note's rows in their scroll view, and the footnotes `live` ends
  /// it with, in a pane [height] tall.
  Widget _scrollView(double height) {
    final layout = editor.layout;
    final metrics = layout.metrics;
    final look = editor.look;
    // Typewriter mode: room for the last row to reach the middle, under
    // whatever the note ends with.
    final slack = editor.behaviour.typewriter ? typewriterSlack(height) : 0.0;
    // The footnotes the read view ends the note with, which `live` ends it
    // with too: its definitions take no room where they stand.
    final footnotes = look.hideMarkers
        ? editor.styler?.footnotes ?? const <Footnote>[]
        : const <Footnote>[];
    return CustomScrollView(
      key: layout.scrollKey,
      controller: layout.scroll,
      physics: const ContentClampPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.only(
            left: metrics.leftInset,
            right: metrics.rightInset,
            top: look.padding.top,
            // Typewriter mode: room for the last row to reach the middle.
            bottom: look.padding.bottom + (footnotes.isEmpty ? slack : 0),
          ),
          sliver: sourceRowSlivers(
            width: metrics.textWidth,
            heights: layout.heights,
            folds: editor.folds,
            hosts: layout.hosts,
            look: (
              gutter: metrics.gutter,
              gap: metrics.gap,
              band: metrics.band,
              textWidth: metrics.textWidth,
              numbered: look.showLineNumbers,
              theme: look.theme,
              itemsIndent: metrics.itemsIndent,
            ),
            line: _line,
          ),
        ),
        if (footnotes.isNotEmpty)
          SliverPadding(
            // Where the read view puts its section: past the note's own
            // padding, the text's edges its edges.
            padding: EdgeInsets.only(
              left: metrics.leftInset + metrics.gutter,
              right: metrics.rightInset,
              top: look.padding.top,
              bottom: look.padding.bottom + slack,
            ),
            sliver: footnoteSliver(
              footnotes: footnotes,
              theme: look.theme,
              parser: layout.footnoteParser,
              mathCache: editor.services.mathCache ?? layout.footnoteMath,
              scope: editor.styler?.scope,
              onTap: editor.controls.toDefinition,
            ),
          ),
      ],
    );
  }

  /// Line [index] drawn [width] wide: a row of the note, or a line of a
  /// side-by-side column ([inColumn]), which has no gutter of its own.
  Widget _line(
    BuildContext context,
    int index, {
    required double width,
    bool inColumn = false,
    double outerIndent = 0,
    int outerQuotes = 0,
  }) {
    final layout = editor.layout;
    final controls = editor.controls;
    final look = editor.look;
    final services = editor.services;
    final buffer = editor.buffer;
    final live = look.hideMarkers;
    final styled = editor.lineAt(index);
    final block = editor.styler?.blockOf(index);
    final quoted = live ? layout.quotes.of(index, block, buffer) : null;
    final marks = layout.marks;
    return SourceLine(
      key: ValueKey<int>(index),
      fold: inColumn ? SourceFoldMark.none : editor.foldMarkOf(index),
      onFold: () => editor.toggleFold(index),
      onFoldDown: controls.pointer.controlPressed,
      onDiagramDown: controls.pointer.diagramDown,
      onDiagramLine: controls.openDiagramLine,
      paragraphKey: layout.paragraphs.keyFor(index),
      styled: styled,
      shape: live
          ? LineShape.of(
              styled,
              block,
              index,
              quoted: quoted,
              callout: liveCalloutLine(index, block, buffer, layout.quotes),
            )
          : LineShape.none,
      pictures: live && services.embedResolver != null
          ? editor.styler?.picturesOf(index) ?? const <LinePicture>[]
          : const <LinePicture>[],
      embedResolver: services.embedResolver,
      formula: live && services.mathCache != null
          ? liveFormulaOf(editor.styler?.blockOf(index), buffer)
          : null,
      mathCache: services.mathCache,
      diagram: live ? controls.diagramOf(index) : null,
      tableRow: live && block?.kind == BlockKind.table
          ? (at) => layout.pieces.tableRowAt(index, block!, at)
          : null,
      tableHeader: block?.kind == BlockKind.table && index == block!.startLine,
      pieceKey: block?.kind == BlockKind.table
          ? (at) => layout.paragraphs.fragmentKey(index, at)
          : null,
      pieceShift: layout.caret.shift,
      definition: live && block != null
          ? editor.styler?.definitionRunOf(block)
          : null,
      codeRuns: !live
          ? null
          : quoted != null
          ? layout.codeColors.ofQuoted(
              quoted,
              block!.startLine,
              buffer,
              look.theme.codeHighlight,
            )
          : layout.codeColors.of(
              index,
              block,
              buffer,
              look.theme.codeHighlight,
            ),
      number: look.showLineNumbers && !inColumn ? index + 1 : null,
      gutterWidth: inColumn ? 0 : layout.metrics.gutter,
      theme: look.theme,
      syntax: layout.metrics.syntax ?? SyntaxColors.of(context),
      dark: look.dark,
      hideMarkers: live,
      selected: marks.selectionIn(index),
      composing: marks.composingIn(index),
      misspelled: marks.misspelledIn(index),
      deadLinks: marks.deadLinksIn(index, styled),
      found: marks.foundIn(index),
      templateProblems: controls.hints.problemsIn(index),
      misspelledColor: Theme.of(context).colorScheme.error,
      width: width,
      index: index,
      spot: layout.caret.spot,
      caret: layout.caret.rect,
      caretOn: controls.blink.on,
      rowColor: editor.behaviour.typewriter
          ? typewriterLineColor(context)
          : null,
      fence: layout.fenceOf(index, block),
      outerIndent: outerIndent,
      outerQuotes: outerQuotes,
    );
  }
}
