/// Opening what a mark on a file stands for (#285): its annotation, or,
/// where several annotate the same place, the one picked.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/annotations/annotation_mark.dart';
import 'package:niman/src/annotations/annotation_mark_source.dart';
import 'package:niman/src/ui/action_sheet.dart';
import 'package:path/path.dart' as p;

/// Opens the annotation [marks] stand for, through [source]; asks which
/// when there are several.
Future<void> openAnnotationMarks(
  BuildContext context,
  List<AnnotationMark> marks,
  AnnotationMarkSource source,
) async {
  if (marks.isEmpty) return;
  if (marks.length == 1) return source.open(marks.single);
  final picked = await showActionSheet<AnnotationMark>(
    context,
    sheetKey: const Key('annotation-marks'),
    items: (context) => [
      for (final (index, mark) in marks.indexed)
        ListTile(
          key: Key('annotation-mark-$index'),
          leading: const Icon(Icons.sticky_note_2_outlined),
          title: Text(
            mark.title ?? p.url.basenameWithoutExtension(mark.note),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            mark.note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => Navigator.of(context).pop(mark),
        ),
    ],
  );
  if (picked != null) source.open(picked);
}
