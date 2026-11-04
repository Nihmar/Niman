import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:niman/src/markdown/edit/caret_spot.dart';
import 'package:niman/src/markdown/render/source_code_copies.dart';
import 'package:niman/src/markdown/render/source_context_menu.dart';
import 'package:niman/src/markdown/render/source_table_hover.dart';
import 'package:niman/src/markdown/render/source_template_hint.dart';
import 'package:niman/src/markdown/render/source_touch.dart';
import 'package:niman/src/markdown/render/wikilink_suggest.dart';

/// What the source view draws over its note, each in an overlay of its own,
/// from the top down: the desktop's context menu, which stays where the
/// click was; the touch selection's handles and toolbar; the table's `+`
/// handles; the template checker's hint; the wikilink suggester's panel;
/// and the code blocks' copy buttons. The ones that point at the text
/// follow it as it scrolls.
final class SourceOverlays extends StatelessWidget {
  /// [child], the note, with the overlays above it.
  const new({
    required this.scroll,
    required this.caretSpot,
    required this.menu,
    required this.touch,
    required this.tables,
    required this.hints,
    required this.suggest,
    required this.codeCopies,
    required this.child,
    super.key,
  });

  /// The note's scroll, which the overlays pointing at the text follow.
  final ScrollController scroll;

  /// Where the caret is, which the table's handles and the copy buttons
  /// follow.
  final ValueListenable<CaretSpot> caretSpot;

  /// The desktop context menu.
  final SourceContextMenu menu;

  /// The selection by touch.
  final SourceTouchSelection touch;

  /// The table's handles.
  final SourceTableHover tables;

  /// The template checker's hint.
  final TemplateHintController hints;

  /// The wikilink suggester.
  final WikilinkSuggestController suggest;

  /// The code blocks' copy buttons.
  final SourceCodeCopies codeCopies;

  /// The note.
  final Widget child;

  @override
  Widget build(BuildContext context) => OverlayPortal(
    controller: menu.overlay,
    overlayChildBuilder: menu.buildOverlay,
    child: OverlayPortal(
      controller: touch.overlay,
      overlayChildBuilder: (context) => ListenableBuilder(
        listenable: Listenable.merge([scroll, touch.tick]),
        builder: (context, _) => touch.buildOverlay(),
      ),
      child: OverlayPortal(
        controller: tables.overlay,
        overlayChildBuilder: (context) => ListenableBuilder(
          listenable: Listenable.merge([
            scroll,
            tables.hover,
            caretSpot,
            tables.settled,
          ]),
          builder: (context, _) => tables.buildHandles(context),
        ),
        child: OverlayPortal(
          // The checker's hint draws nearest the note — over the text it
          // points at, under the handles, the toolbar and the menu.
          controller: hints.overlay,
          overlayChildBuilder: (context) => ListenableBuilder(
            listenable: scroll,
            builder: (context, _) => hints.buildOverlay(context),
          ),
          child: OverlayPortal(
            controller: suggest.overlay,
            overlayChildBuilder: suggest.buildOverlay,
            child: OverlayPortal(
              // The code blocks' copy buttons ride the scroll, under all
              // of the above.
              controller: codeCopies.overlay,
              overlayChildBuilder: (context) => ListenableBuilder(
                listenable: Listenable.merge([scroll, caretSpot]),
                builder: (context, _) => codeCopies.build(context),
              ),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
