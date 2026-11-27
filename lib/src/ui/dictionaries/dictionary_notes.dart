import 'package:flutter/material.dart';
import 'package:niman/src/ui/settings_area.dart';
import 'package:niman/src/ui/settings_keys.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// What the Dictionaries page says below its lists: how a PDF's language is
/// chosen, and where the dictionaries live and what they are made of.
final class DictionaryNotes extends StatelessWidget {
  /// Creates the notes.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A PDF says nothing of its language (decision 10): this is the one
        // place the rule is written down for a reader.
        HighlightRow(
          key: SettingsKeys.dictionaryPdfLanguage,
          child: SettingsRowFrame(
            title: AppStrings.dictionaryPdfLanguageTitle,
            description: AppStrings.dictionaryPdfLanguageNote,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: settingsRowMaxWidth),
              child: DecoratedBox(
                key: const Key('dictionary-notice'),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${AppStrings.dictionaryNotice}\n'
                    '${AppStrings.dictionaryLicense}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
