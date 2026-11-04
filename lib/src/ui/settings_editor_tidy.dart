import 'dart:async';

import 'package:flutter/material.dart';
import 'package:niman/src/lint/lint_rule.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Editor area's tidy rows: whether a note is tidied when it closes,
/// and the rules a tidy applies (#72).
final class SettingsEditorTidy extends StatelessWidget {
  /// Creates the rows for the current [tidyOnClose] and [lintRulesOff].
  const new({
    required this.tidyOnClose,
    required this.lintRulesOff,
    required this.onTidyOnClose,
    required this.onLintRulesOff,
    super.key,
  });

  /// Whether a note closed after an edit is tidied.
  final bool tidyOnClose;

  /// The ids of the rules a tidy skips.
  final Set<String> lintRulesOff;

  /// Persists the tidy-on-close switch.
  final ValueChanged<bool> onTidyOnClose;

  /// Persists the rules a tidy skips, once the dialog saves them.
  final ValueChanged<Set<String>> onLintRulesOff;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HighlightRow(
          key: SettingsKeys.tidyOnClose,
          child: SettingsSwitchRow(
            title: AppStrings.tidyOnCloseTitle,
            description: AppStrings.tidyOnCloseSubtitle,
            value: tidyOnClose,
            onChanged: onTidyOnClose,
          ),
        ),
        // The rules that tidy applies (#72): the switch above is the
        // master, this chooses what it settles.
        HighlightRow(
          key: SettingsKeys.lintRules,
          child: SettingsValueRow(
            title: AppStrings.lintRulesTitle,
            subtitle: AppStrings.lintRulesSubtitle,
            value: AppStrings.lintRulesValue(
              LintRule.values.length - lintRulesOff.length,
              LintRule.values.length,
            ),
            onTap: () => unawaited(_chooseLintRules(context)),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseLintRules(BuildContext context) async {
    final choice = await showLintRulesDialog(context, lintRulesOff);
    if (choice != null) onLintRulesOff(choice);
  }
}

/// Asks for the rules a tidy applies (#72), from [lintRulesOff], the ones
/// it skips now; null when the dialog is cancelled.
///
/// The dialog edits the *off* set, the way the settings file stores it: a
/// rule added in a later build then runs with no migration.
Future<Set<String>?> showLintRulesDialog(
  BuildContext context,
  Set<String> lintRulesOff,
) {
  final off = <String>{...lintRulesOff};
  return showDialog<Set<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        key: const Key('lint-rules-dialog'),
        scrollable: true,
        title: Text(AppStrings.lintRulesTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.lintRulesSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            for (final rule in LintRule.values)
              CheckboxListTile(
                key: Key('lint-rule-${rule.id}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(lintRuleLabel(rule)),
                value: !off.contains(rule.id),
                onChanged: (value) => setDialogState(() {
                  if (value ?? false) {
                    off.remove(rule.id);
                  } else {
                    off.add(rule.id);
                  }
                }),
              ),
          ],
        ),
        actions: [
          TextButton(
            key: const Key('lint-rules-reset'),
            onPressed: () => setDialogState(off.clear),
            child: Text(AppStrings.lintRulesReset),
          ),
          TextButton(
            key: const Key('lint-rules-cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppStrings.actionCancel),
          ),
          FilledButton(
            key: const Key('lint-rules-save'),
            onPressed: () => Navigator.of(context).pop(off),
            child: Text(AppStrings.actionSave),
          ),
        ],
      ),
    ),
  );
}

/// The settings row's name for [rule].
String lintRuleLabel(LintRule rule) => switch (rule) {
  LintRule.tightLists => AppStrings.lintRuleTightLists,
  LintRule.taskMarker => AppStrings.lintRuleTaskMarker,
  LintRule.listSpacing => AppStrings.lintRuleListSpacing,
  LintRule.closingFence => AppStrings.lintRuleClosingFence,
  LintRule.fenceLanguage => AppStrings.lintRuleFenceLanguage,
  LintRule.joinWrappedItems => AppStrings.lintRuleJoinWrappedItems,
  LintRule.joinParagraphLines => AppStrings.lintRuleJoinParagraphLines,
};
