/// Highlighting a passage (#626), and what a highlight offers when it is
/// tapped: its four colours, the current one ringed, then Annotate, Copy,
/// Copy link to this place and Remove highlight — in the action sheet every
/// menu of the app opens as.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niman/src/annotations/annotation.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/annotations/annotation_mark_source.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/markdown/render/mark_highlight.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/annotation_sheet.dart';
import 'package:niman/src/ui/place_link_button.dart';
import 'package:niman/src/ui/strings.dart';

/// What the highlight menu was closed with.
sealed class _Choice {
  const new();
}

final class _Colour extends _Choice {
  const new(this.colour);
  final HighlightColour colour;
}

enum _Act implements _Choice { annotate, copy, link, remove }

/// Highlights [annotation]'s passage through [source] (#626), in the colour
/// last chosen; one that cannot be written says so.
Future<void> highlightPassage(
  BuildContext context,
  AnnotationMarkSource source,
  Annotation annotation,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await source.highlight(annotation);
  } on Object {
    messenger.showSnackBar(SnackBar(content: Text(AppStrings.highlightFailed)));
  }
}

/// The name of [colour], as a swatch says it.
String highlightColourName(HighlightColour colour) => switch (colour) {
  HighlightColour.yellow => AppStrings.highlightYellow,
  HighlightColour.green => AppStrings.highlightGreen,
  HighlightColour.blue => AppStrings.highlightBlue,
  HighlightColour.pink => AppStrings.highlightPink,
};

/// Opens the menu of the highlight [mark] of the file at [path], and does
/// what is chosen through [source]; [linkType] is how a copied link is
/// written. A change that fails says so.
Future<void> showHighlightMenu(
  BuildContext context,
  AnnotationMark mark,
  AnnotationMarkSource source, {
  required String path,
  required LinkType linkType,
}) async {
  final choice = await showActionSheet<_Choice>(
    context,
    sheetKey: const Key('highlight-menu'),
    items: (context) => [
      if (mark.quote.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            '“${mark.quote}”',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      _Swatches(current: mark.highlight),
      ListTile(
        key: const Key('highlight-annotate'),
        leading: const Icon(Icons.edit_note),
        title: Text(AppStrings.annotateAction),
        onTap: () => Navigator.pop(context, _Act.annotate),
      ),
      ListTile(
        key: const Key('highlight-copy'),
        leading: const Icon(Icons.copy_outlined),
        title: Text(AppStrings.highlightCopy),
        onTap: () => Navigator.pop(context, _Act.copy),
      ),
      ListTile(
        key: const Key('highlight-link'),
        leading: const Icon(Icons.link),
        title: Text(AppStrings.copyPlaceLink),
        onTap: () => Navigator.pop(context, _Act.link),
      ),
      ListTile(
        key: const Key('highlight-remove'),
        leading: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(
          AppStrings.highlightRemove,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        onTap: () => Navigator.pop(context, _Act.remove),
      ),
    ],
  );
  if (choice == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    switch (choice) {
      case _Colour(:final colour):
        if (colour != mark.highlight) await source.recolour(mark, colour);
      case _Act.annotate:
        final comment = await showAnnotationSheet(
          context,
          label: mark.label ?? AppStrings.highlightMark,
          quote: mark.quote,
        );
        if (comment != null) await source.annotateHighlight(mark, comment);
      case _Act.copy:
        await Clipboard.setData(ClipboardData(text: mark.quote));
      case _Act.link:
        if (!context.mounted) return;
        await copyPlaceLink(context, (
          path: path,
          place: mark.place,
          label: mark.label ?? AppStrings.highlightMark,
        ), linkType);
      case _Act.remove:
        await source.removeHighlight(mark);
    }
  } on Object {
    messenger.showSnackBar(SnackBar(content: Text(AppStrings.highlightFailed)));
  }
}

/// The four colours, the current one ringed; a tap closes the menu with
/// the colour.
final class _Swatches extends StatelessWidget {
  const new({required this.current});

  final HighlightColour? current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          for (final colour in HighlightColour.values)
            IconButton(
              key: Key('highlight-colour-${colour.id}'),
              tooltip: highlightColourName(colour),
              onPressed: () => Navigator.pop(context, _Colour(colour)),
              // Filled when it is the highlight's colour: the state on.
              isSelected: colour == current,
              icon: _Swatch(colour.tint(dark: dark), on: false),
              selectedIcon: _Swatch(
                colour.tint(dark: dark),
                on: true,
                ring: theme.colorScheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

final class _Swatch extends StatelessWidget {
  const new(this.color, {required this.on, this.ring});

  final Color color;
  final bool on;
  final Color? ring;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 1),
      border: on ? Border.all(color: ring!, width: 3) : null,
    ),
  );
}
