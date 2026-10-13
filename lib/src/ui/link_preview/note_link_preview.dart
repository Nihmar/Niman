import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/editor/highlighting.dart' show TokenKind;
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/links/link_preview.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/render/dead_link_ranges.dart'
    show inlineHrefOf;
import 'package:niman/src/markdown/render/inline_spans.dart'
    show LinkPreviewHooks;
import 'package:niman/src/markdown/render/source_view.dart'
    show SourceLinkHover;
import 'package:niman/src/preview/math_cache.dart';
import 'package:niman/src/ui/link_preview/link_preview_controller.dart';
import 'package:niman/src/ui/link_preview/link_preview_host.dart';
import 'package:niman/src/ui/link_preview/link_preview_sheet.dart';
import 'package:niman/src/ui/note_links.dart';

/// The link preview of one open note (#846): the card a hovered link opens
/// over the note, the sheet a long press opens on a touch screen, and what
/// the editor and the read view tell them.
///
/// The note view owns one, for as long as it is mounted, and hands it the
/// pointer's news; this keeps the rest — which card is up, how a link in
/// the editor is read, how a sheet's Open follows the link.
final class NoteLinkPreview {
  /// The preview of the links of the note at the library-relative path
  /// `notePath`, resolved and read in `source`, while `enabled` says the
  /// setting is on; its notes are typeset through [_mathCache], and a sheet's
  /// Open follows a link through `targets`.
  new({
    required LibraryLinks? Function() source,
    required String? Function() notePath,
    required bool Function() enabled,
    required this._mathCache,
    required this._targets,
  }) : controller = LinkPreviewController(
         source: source,
         notePath: notePath,
         enabled: enabled,
       );

  /// Which card is up, and when one opens and closes.
  final LinkPreviewController controller;

  final MathCache _mathCache;
  final NoteLinkTargets Function() _targets;

  /// Closes the card: the note changed under it.
  void close() => controller.close();

  /// Lets go of the controller.
  void dispose() => controller.dispose();

  /// The card over [child], closed by anything [closeOn] announces (the
  /// note's scrolls).
  Widget host({required Listenable closeOn, required Widget child}) {
    return LinkPreviewHost(
      controller: controller,
      mathCache: _mathCache,
      closeOn: closeOn,
      child: child,
    );
  }

  /// The pointer is on a link in the editor with the opening modifier held,
  /// or it left: the card opens at once (the modifier is the intent) or goes.
  void editorHover(SourceLinkHover? hover) {
    if (hover == null) {
      controller.leave();
      return;
    }
    final raw = hover.raw;
    final PreviewLink link;
    if (hover.kind == TokenKind.wikilink) {
      if (raw.length < 4 || !raw.startsWith('[[') || !raw.endsWith(']]')) {
        return;
      }
      link = PreviewLink.wiki(raw.substring(2, raw.length - 2));
    } else {
      final href = hover.href ?? inlineHrefOf(raw);
      if (href == null) return;
      link = PreviewLink.markdown(href);
    }
    controller.enter(link, hover.position, delay: Duration.zero);
  }

  /// What the read view's links tell the preview: a pointer on one, off it,
  /// and — only on a touch screen — a long press.
  LinkPreviewHooks hooks(BuildContext context) {
    final touch = switch (Theme.of(context).platform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
    return (
      onEnter: controller.enter,
      onExit: controller.leave,
      onLongPress: touch ? (link) => unawaited(_sheet(context, link)) : null,
    );
  }

  /// A long press on a link in the read view: the card, as a sheet with an
  /// Open action. Nothing for a link that points at nothing.
  Future<void> _sheet(BuildContext context, PreviewLink link) async {
    if (!controller.enabled) return;
    final preview = await controller.read(link);
    if (preview == null || !context.mounted) return;
    await showLinkPreviewSheet(
      context,
      preview: preview,
      mathCache: _mathCache,
      onOpen: () => unawaited(
        link.wiki
            ? openWiki(context, parseWikiRef(link.text), _targets())
            : openHref(context, link.text, _targets()),
      ),
    );
  }
}
