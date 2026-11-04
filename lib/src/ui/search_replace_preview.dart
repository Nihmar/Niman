import 'package:flutter/material.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/ui/strings.dart';

/// The preview list shown in replace mode (T-M3-10): one row per matching
/// note with its occurrence count and the before → after samples.
final class SearchReplacePreview extends StatelessWidget {
  /// Creates the preview of [notes] for replacing [term] with
  /// [replacement].
  const new({
    required this.notes,
    required this.busy,
    required this.term,
    required this.onlyPath,
    required this.replacement,
    super.key,
  });

  /// The notes the scan found matches in.
  final List<ReplaceMatchNote> notes;

  /// Whether a scan is running: with nothing found yet, a spinner shows.
  final bool busy;

  /// The term being replaced, as the empty state names it.
  final String term;

  /// The one note the replace is limited to, or null for every match.
  final String? onlyPath;

  /// The replacement text the samples' after lines show.
  final String replacement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (busy && notes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notes.isEmpty) {
      return Center(
        child: Text(
          AppStrings.replacePreviewEmpty(term, onlyPath),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ListView.builder(
      key: const Key('replace-preview'),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          key: Key('replace-note-${note.path}'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    '${note.occurrences} '
                    'occurrence${note.occurrences == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              for (final sample in note.samples) _samplePreview(theme, sample),
            ],
          ),
        );
      },
    );
  }

  /// One sample's before → after lines: the context with the matched term
  /// highlighted, then the same context with the replacement text.
  Widget _samplePreview(ThemeData theme, ReplaceSample sample) {
    final body = theme.textTheme.bodySmall ?? const TextStyle();
    final matchStyle = body.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    TextSpan context(String matchText) => TextSpan(
      style: body,
      children: [
        TextSpan(text: sample.before),
        TextSpan(text: matchText, style: matchStyle),
        TextSpan(text: sample.after),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            context(sample.match),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '→ ', style: matchStyle),
                context(replacement.isEmpty ? ' ' : replacement),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
