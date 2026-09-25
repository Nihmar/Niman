/// A book's row, under it in the note pane (#280): its name, how the books
/// look, its contents, a link to the place being read (#282), and on
/// desktop the system's application.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
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
    this.here,
    super.key,
  });

  /// The book's absolute path.
  final String path;

  /// The OS seam behind the button to the system's application.
  final OsLauncher launcher;

  /// How the library writes links.
  final LinkType linkType;

  /// Opens the sheet that sets how the books look.
  final VoidCallback? onEditLook;

  /// Opens the book's contents.
  final VoidCallback? onContents;

  /// The place being read, for the link to it.
  final PlaceToLink? Function()? here;

  @override
  Widget build(BuildContext context) => AttachmentBar(
    path: path,
    launcher: launcher,
    actions: [
      IconButton(
        key: const Key('epub-look-button'),
        tooltip: AppStrings.epubLookTitle,
        icon: const Icon(Icons.format_size),
        visualDensity: VisualDensity.compact,
        onPressed: onEditLook,
      ),
      IconButton(
        key: const Key('epub-contents-button'),
        tooltip: AppStrings.outlineTooltip,
        icon: const Icon(Icons.toc),
        visualDensity: VisualDensity.compact,
        onPressed: onContents,
      ),
      PlaceLinkButton(here: here, linkType: linkType),
    ],
  );
}
