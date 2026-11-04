import 'package:flutter/material.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/spellcheck/hunspell_spell_checker.dart';
import 'package:niman/src/ui/settings_rows.dart';
import 'package:niman/src/ui/strings.dart';

/// The Editor area's spelling rows (T-PP-09): the switch that turns
/// checking on, and the dictionaries it checks against.
final class SettingsEditorSpelling extends StatelessWidget {
  /// Creates the rows for [spell], set to [dictionaries].
  const new({
    required this.spell,
    required this.dictionaries,
    required this.onEnabled,
    required this.onChooseDictionaries,
    super.key,
  });

  /// The editor's spelling state.
  final EditorSpellCheck spell;

  /// The dictionaries chosen; empty means the locale default.
  final List<String> dictionaries;

  /// Turns checking on or off.
  final ValueChanged<bool> onEnabled;

  /// Asks for the dictionaries, from the dictionary row's tap.
  final VoidCallback onChooseDictionaries;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: spell,
      // The rows are the spell state's, not this build's: keyed on
      // `offered` they survive the reload a dictionary pick starts
      // (and the switch that turns checking off) instead of
      // vanishing with `available` (#493).
      builder: (context, _) => !spell.offered
          ? const SizedBox.shrink()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SettingsSwitchRow(
                  key: const Key('spell-check-setting'),
                  title: AppStrings.settingsSpellCheckTitle,
                  description: AppStrings.settingsSpellCheckSubtitle,
                  value: spell.enabled,
                  onChanged: onEnabled,
                ),
                SettingsValueRow(
                  key: const Key('spell-dictionary-setting'),
                  title: AppStrings.spellCheckDictionaryTitle,
                  value: dictionaries.isEmpty
                      ? AppStrings.spellCheckDictionarySystem
                      : dictionaries.join(', '),
                  onTap: onChooseDictionaries,
                ),
              ],
            ),
    );
  }
}

/// Asks which dictionaries the editor should use (T-PP-09, revised): every
/// one found on the machine — Windows's languages there — any number of
/// them at once, starting from [current]; null when the dialog is
/// cancelled, or [context] is gone once the machine's list is read.
/// Choosing none means the locale default.
Future<List<String>?> showSpellDictionariesDialog(
  BuildContext context,
  List<String> current,
) async {
  final names = await availableSpellDictionaries();
  if (!context.mounted) return null;
  final selected = current.toSet();
  return await showDialog<List<String>>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('spell-dictionary-dialog'),
      scrollable: true,
      title: Text(AppStrings.spellCheckDictionaryChoiceTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.spellCheckDictionaryChoiceSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          if (names.isEmpty)
            Text(AppStrings.spellCheckNoDictionaries)
          else
            StatefulBuilder(
              builder: (context, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final name in names)
                    CheckboxListTile(
                      key: Key('spell-dictionary-$name'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(name),
                      value: selected.contains(name),
                      onChanged: (value) => setDialogState(() {
                        if (value ?? false) {
                          selected.add(name);
                        } else {
                          selected.remove(name);
                        }
                      }),
                    ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('spell-dictionary-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.actionCancel),
        ),
        FilledButton(
          key: const Key('spell-dictionary-save'),
          onPressed: () =>
              Navigator.of(context)
                  .pop(names.where(selected.contains).toList()),
          child: Text(AppStrings.actionSave),
        ),
      ],
    ),
  );
}
