import 'package:flutter/material.dart';
import 'package:niman/src/editor/outline.dart';
import 'package:niman/src/ui/note_view_handle.dart';
import 'package:niman/src/ui/strings.dart';

/// The dock's outline (#175): the note's headings, indented by level; a
/// click takes the caret to one. It follows the note as it is edited.
final class OutlineDockPane extends StatelessWidget {
  /// The outline of [note]; null when no note is open.
  const new({required this.note, super.key});

  /// The note shown beside.
  final NoteViewHandle? note;

  @override
  Widget build(BuildContext context) {
    final note = this.note;
    if (note == null) return const SizedBox.shrink();
    return ValueListenableBuilder<List<OutlineEntry>>(
      valueListenable: note.outline,
      builder: (context, entries, _) {
        final theme = Theme.of(context);
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppStrings.outlineNoHeadings,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final body = theme.textTheme.bodyMedium;
        final title = body?.copyWith(fontWeight: FontWeight.w600);
        // Built as the list scrolls to them, not all at once: an outline
        // follows the note, and the 246 MB stress note has 22 260 headings
        // — a row each, built on every outline the note published.
        return ListView.builder(
          key: const Key('dock-outline'),
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            return InkWell(
              key: Key('dock-outline-${entry.line}'),
              onTap: () => note.jumpToHeading(entry.line),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  12.0 + 14 * (entry.level - 1),
                  6,
                  12,
                  6,
                ),
                child: Text(
                  entry.text.isEmpty ? AppStrings.outlineNoTitle : entry.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: entry.level == 1 ? title : body,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
