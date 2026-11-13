/// A book's row, under it in the note pane (#280): its name, how the books
/// look, its contents, converting it into notes (#1138), a link to the
/// place being read (#282), annotating it (#284), full screen (#621), how far
/// it has been read (#1275), reading it aloud on Android (#1276), and on
/// desktop the system's application.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/attachment_bar.dart';
import 'package:niman/src/ui/file_tree_context.dart';
import 'package:niman/src/ui/place_link_button.dart';
import 'package:niman/src/ui/strings.dart';

/// The row of the book at [path].
///
/// Every button keeps its place while the book is read, and when it has
/// no contents: a null callback disables it, so the row does not move
/// under a thumb.
final class EpubBar extends StatelessWidget {
  /// The row of the book at [path], an absolute path.
  const new({
    required this.path,
    required this.launcher,
    required this.linkType,
    this.onEditLook,
    this.onContents,
    this.onConvert,
    this.here,
    this.onAnnotate,
    this.fullScreen = false,
    this.onFullScreen,
    this.progress,
    this.readsAloud = false,
    this.onReadAloud,
    super.key,
  });

  /// Below this width the progress line sits over the row, as wide as the
  /// pane; from it, in the row beside the book's name.
  static const double inlineProgressWidth = 600;

  /// The book's absolute path.
  final String path;

  /// The OS seam behind the button to the system's application.
  final OsLauncher launcher;

  /// How the library writes links.
  final LinkType linkType;

  /// Opens the sheet that sets how the books look; a pointer's menu
  /// grows from the button's place, handed over.
  final ValueChanged<Rect?>? onEditLook;

  /// Opens the book's contents, from the button's place, as
  /// [onEditLook].
  final ValueChanged<Rect?>? onContents;

  /// Converts the book into notes (#1138); null while it is read, or
  /// where there is no library to convert it into.
  final VoidCallback? onConvert;

  /// The place being read, for the link to it.
  final PlaceToLink? Function()? here;

  /// Annotates the paragraph being read.
  final VoidCallback? onAnnotate;

  /// Whether the book is read in full screen.
  final bool fullScreen;

  /// Enters full screen, or leaves it.
  final VoidCallback? onFullScreen;

  /// The book's progress line, in the row when `inline`, over it when
  /// not; null while the book is read, or when it has no text.
  final Widget Function({required bool inline})? progress;

  /// Whether the platform reads books aloud (#1276): Android, for now; the
  /// button is not on the row elsewhere.
  final bool readsAloud;

  /// Reads the book aloud from the paragraph at the top of the view; null
  /// while it is read.
  final VoidCallback? onReadAloud;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    if (progress == null) return _row(null);
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < inlineProgressWidth
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [progress(inline: false), _row(null)],
            )
          : _row(progress(inline: true)),
    );
  }

  Widget _row(Widget? beside) => AttachmentBar(
    path: path,
    launcher: launcher,
    beside: beside,
    actions: [
      Builder(
        builder: (context) => IconButton(
          key: const Key('epub-look-button'),
          tooltip: AppStrings.epubLookTitle,
          icon: const Icon(Icons.format_size),
          visualDensity: VisualDensity.compact,
          onPressed: switch (onEditLook) {
            final edit? => () => edit(menuAnchorOf(context)),
            null => null,
          },
        ),
      ),
      Builder(
        builder: (context) => IconButton(
          key: const Key('epub-contents-button'),
          tooltip: AppStrings.outlineTooltip,
          icon: const Icon(Icons.toc),
          visualDensity: VisualDensity.compact,
          onPressed: switch (onContents) {
            final open? => () => open(menuAnchorOf(context)),
            null => null,
          },
        ),
      ),
      IconButton(
        key: const Key('epub-convert-button'),
        tooltip: AppStrings.epubConvertAction,
        icon: const Icon(Icons.note_add_outlined),
        visualDensity: VisualDensity.compact,
        onPressed: onConvert,
      ),
      PlaceLinkButton(here: here, linkType: linkType),
      if (readsAloud)
        IconButton(
          key: const Key('read-aloud-button'),
          tooltip: AppStrings.readAloud,
          icon: const Icon(Icons.record_voice_over_outlined),
          visualDensity: VisualDensity.compact,
          onPressed: onReadAloud,
        ),
      IconButton(
        key: const Key('annotate-button'),
        tooltip: AppStrings.annotateAction,
        icon: const Icon(Icons.edit_note),
        visualDensity: VisualDensity.compact,
        onPressed: onAnnotate,
      ),
      IconButton(
        key: const Key('epub-full-screen-button'),
        tooltip: AppStrings.fullScreen,
        isSelected: fullScreen,
        icon: const Icon(Icons.fullscreen),
        selectedIcon: const Icon(Icons.fullscreen_exit),
        visualDensity: VisualDensity.compact,
        onPressed: onFullScreen,
      ),
    ],
  );
}
