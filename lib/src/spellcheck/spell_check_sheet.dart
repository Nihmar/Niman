/// The spelling review panel (T-PP-09).
///
/// Lists the note's misspellings with hunspell's suggestions; tapping a
/// suggestion replaces the word in place through the editor's controller and
/// the list re-scans. Built over two closures so it owns no editor state.
library;

import 'package:flutter/material.dart';
import 'package:niman/src/spellcheck/spell_issue.dart';
import 'package:niman/src/ui/strings.dart';

/// A bottom sheet over the open note listing its spelling issues.
final class SpellCheckSheet extends StatefulWidget {
  /// Creates the panel over [scan] and [apply].
  const new({
    required this.scan,
    required this.apply,
    required this.available,
    super.key,
  });

  /// Re-reads the note's issues (on open and after every fix).
  final List<SpellIssue> Function() scan;

  /// Replaces `issue`'s word with `replacement` in the editor.
  final void Function(SpellIssue issue, String replacement) apply;

  /// Whether hunspell loaded; false shows the platform note.
  final bool available;

  @override
  State<SpellCheckSheet> createState() => _SpellCheckSheetState();
}

final class _SpellCheckSheetState extends State<SpellCheckSheet> {
  late List<SpellIssue> _issues;

  @override
  void initState() {
    super.initState();
    _rescan();
  }

  void _rescan() {
    _issues = widget.available ? widget.scan() : const <SpellIssue>[];
  }

  void _replace(SpellIssue issue, String replacement) {
    widget.apply(issue, replacement);
    setState(_rescan);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context),
            const Divider(height: 1),
            Flexible(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppStrings.spellCheckTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          if (_issues.isNotEmpty)
            Text(
              AppStrings.spellCheckCount(_issues.length),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          IconButton(
            key: const Key('spell-check-close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (!widget.available) {
      return _message(context, AppStrings.spellCheckUnavailable);
    }
    if (_issues.isEmpty) {
      return _message(context, AppStrings.spellCheckEmpty);
    }
    return ListView.separated(
      key: const Key('spell-check-list'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _issues.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _issueTile(context, _issues[index]),
    );
  }

  Widget _message(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.all(24),
    child: Text(text, textAlign: TextAlign.center),
  );

  Widget _issueTile(BuildContext context, SpellIssue issue) {
    final theme = Theme.of(context);
    return Padding(
      key: Key('spell-issue-${issue.line}-${issue.start}'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                issue.word,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.spellCheckLine(issue.line + 1),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (issue.suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                AppStrings.spellCheckNoSuggestions,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final suggestion in issue.suggestions.take(4))
                    ActionChip(
                      key: Key('suggest-$suggestion'),
                      label: Text(suggestion),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _replace(issue, suggestion),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
