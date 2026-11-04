import 'package:flutter/material.dart';
import 'package:niman/src/search/replace.dart';
import 'package:niman/src/ui/app_switch.dart';
import 'package:niman/src/ui/strings.dart';

/// The inline replace panel under the query box (T-M3-10): replacement
/// text, the case toggle, the scope/occurrence summary, and the confirm
/// action.
final class SearchReplacePanel extends StatelessWidget {
  /// Creates the panel for replacing [term] across [notes].
  const new({
    required this.term,
    required this.onlyPath,
    required this.notes,
    required this.busy,
    required this.replacement,
    required this.caseSensitive,
    required this.onCaseChanged,
    required this.onClose,
    required this.onConfirm,
    super.key,
  });

  /// The term being replaced, the replacement field's hint.
  final String term;

  /// The one note the replace is limited to, or null for every match.
  final String? onlyPath;

  /// The notes the preview found matches in.
  final List<ReplaceMatchNote> notes;

  /// Whether a scan or the replace itself is running.
  final bool busy;

  /// The replacement text's field.
  final TextEditingController replacement;

  /// Whether the replace matches case.
  final bool caseSensitive;

  /// Called when the case toggle flips.
  final ValueChanged<bool> onCaseChanged;

  /// Leaves replace mode.
  final VoidCallback onClose;

  /// Runs the replace.
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final only = onlyPath;
    final occurrences = notes.fold<int>(
      0,
      (sum, note) => sum + note.occurrences,
    );
    final hasMatches = notes.isNotEmpty;
    final noteCount = notes.length;
    final String scope;
    if (only != null) {
      scope = AppStrings.replaceScopeNote(only);
    } else if (noteCount == 0) {
      scope = AppStrings.replaceScopeWholeLibrary;
    } else {
      scope = AppStrings.replaceScopeNotes(noteCount);
    }
    final confirmLabel = only != null
        ? AppStrings.replaceInThisNote
        : '${AppStrings.replaceConfirm} '
              '(${hasMatches ? '$occurrences' : '…'})';
    return Container(
      key: const Key('replace-panel'),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.find_replace,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('replace-with'),
                  controller: replacement,
                  decoration: InputDecoration(
                    labelText: AppStrings.replaceWithLabel,
                    hintText: term,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                key: const Key('replace-close'),
                tooltip: AppStrings.replaceCancel,
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                AppStrings.replaceCaseSensitive,
                style: theme.textTheme.bodySmall,
              ),
              AppSwitch(
                key: const Key('replace-case'),
                value: caseSensitive,
                onChanged: onCaseChanged,
              ),
              const Spacer(),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              FilledButton(
                key: const Key('replace-confirm'),
                onPressed: busy || !hasMatches ? null : onConfirm,
                child: Text(confirmLabel),
              ),
            ],
          ),
          Text(
            '$scope — ${AppStrings.replaceWholeWordsHint}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
