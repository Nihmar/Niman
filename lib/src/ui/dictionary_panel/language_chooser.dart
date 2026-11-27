import 'package:flutter/material.dart';
import 'package:niman/src/core/language.dart';
import 'package:niman/src/dictionary/dictionary_language.dart';
import 'package:niman/src/ui/dictionaries/dictionary_names.dart';
import 'package:niman/src/ui/strings.dart';

/// The language codes the chooser lists: the app's languages, those with a
/// dictionary on the device first, each group in the app's own order.
/// [installed] holds the languages the packs serve, a Serbo-Croatian pack
/// being Croatian, Serbian and Bosnian at once.
///
/// A language the look-up is already in that the app does not speak (a
/// book tagged `nn`) is listed too, last, so the chip can name it and the
/// reader can see what is chosen.
List<String> lookupLanguageChoices({
  required Set<String> installed,
  required String current,
}) {
  final all = [for (final language in AppLanguages.supported) language.id];
  final have = [
    for (final code in all)
      if (installed.contains(code)) code,
  ];
  final rest = [
    for (final code in all)
      if (!have.contains(code)) code,
  ];
  final here = DictionaryLanguage.normalise(current) ?? current;
  return [...have, ...rest, if (!all.contains(here)) here];
}

/// Which language to look up in, listed in the panel's body in place of the
/// answer: the chosen code goes to [onChosen].
///
/// It is the panel's own and not a dialog: the desktop's panel is an entry
/// of the window's overlay, which a route pushed over it would sit under,
/// and a click on that route would close the panel.
final class LookupLanguageList extends StatelessWidget {
  /// Lists the languages, the one [current] marked.
  const new({
    required this.installed,
    required this.current,
    required this.onChosen,
    super.key,
  });

  /// The languages the dictionaries on the device serve.
  final Set<String> installed;

  /// The language of the look-up now.
  final String current;

  /// Takes the language the reader picked.
  final ValueChanged<String> onChosen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final here = DictionaryLanguage.normalise(current) ?? current;
    final choices = lookupLanguageChoices(
      installed: installed,
      current: current,
    );
    return Column(
      key: const Key('lookup-language-list'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            AppStrings.lookUpLanguageTitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final code in choices)
          ListTile(
            key: Key('lookup-language-$code'),
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(DictionaryNames.native(code)),
            trailing: code == here ? const Icon(Icons.check) : null,
            onTap: () => onChosen(code),
          ),
      ],
    );
  }
}
