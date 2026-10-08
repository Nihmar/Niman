/// Opening what a mark on a file stands for (#285): its annotation, or,
/// where several mark the same place, the one picked. A highlight (#626)
/// opens its menu rather than a note.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/annotations/annotation_mark_source.dart';
import 'package:niman/src/core/settings/library_settings.dart' show LinkType;
import 'package:niman/src/ui/action_sheet.dart';
import 'package:niman/src/ui/highlight_menu.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

/// Opens what [marks] of the file at [path] stand for, through [source];
/// asks which when there are several. [linkType] is how a highlight's link
/// is copied.
Future<void> openAnnotationMarks(
  BuildContext context,
  List<AnnotationMark> marks,
  AnnotationMarkSource source, {
  required String path,
  required LinkType linkType,
}) async {
  if (marks.isEmpty) return;
  final picked = marks.length == 1
      ? marks.single
      : await showActionSheet<AnnotationMark>(
          context,
          sheetKey: const Key('annotation-marks'),
          items: (context) => [
            for (final (index, mark) in marks.indexed)
              _MarkRow(
                key: Key('annotation-mark-$index'),
                mark: mark,
                onTap: () => Navigator.of(context).pop(mark),
              ),
          ],
        );
  if (picked == null || !context.mounted) return;
  if (picked.isHighlight) {
    await showHighlightMenu(
      context,
      picked,
      source,
      path: path,
      linkType: linkType,
    );
  } else {
    source.open(picked);
  }
}

/// One mark of those asked between: a highlight by its colour and its
/// words, an annotation by its heading and its note.
final class _MarkRow extends StatelessWidget {
  const new({required this.mark, required this.onTap, super.key});

  final AnnotationMark mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final highlight = mark.highlight;
    if (highlight != null) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      return ListTile(
        leading: Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlight.tint(dark: dark).withValues(alpha: 1),
          ),
        ),
        title: Text(AppStrings.highlightMark),
        subtitle: Text(
          mark.quote,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      );
    }
    return ListTile(
      leading: const Icon(Icons.sticky_note_2_outlined),
      title: Text(
        mark.title ?? p.url.basenameWithoutExtension(mark.note),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(mark.note, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}
