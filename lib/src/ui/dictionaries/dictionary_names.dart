import 'package:niman/src/core/language.dart';
import 'package:niman/src/dictionary/dictionary_language_names.dart';
import 'package:niman/src/ui/strings.dart';

/// How the settings name a dictionary and the languages it serves.
///
/// The names are the language's own, as the language picker writes them:
/// someone who landed in the wrong language has to find theirs. A pack that
/// serves several (`niman-sh`: Croatian, Serbian, Bosnian) is named after
/// what they share, and says which it serves.
final class DictionaryNames {
  const new _();

  /// What the Serbo-Croatian pack is called, in itself.
  static const String serboCroatian = 'Srpskohrvatski';

  /// [code]'s name in itself, or the code for a language the app does not
  /// know.
  static String native(String code) {
    if (code == serboCroatianCode) return serboCroatian;
    final language = AppLanguage.fromId(code);
    return language == AppLanguage.system
        ? code
        : AppStrings.languageName(language);
  }

  /// The pack's name: its one language's, or the name its languages share.
  static String title(List<String> languages) =>
      languages.length == 1 ? native(languages.first) : serboCroatian;

  /// The languages a pack that serves several is for, named in
  /// themselves; null for a pack of one language, whose title says it.
  static String? serves(List<String> languages) => languages.length < 2
      ? null
      : AppStrings.dictionaryServes(languages.map(native).join(', '));

  /// Whether a pack serving [languages] answers the search [query]: by
  /// either name of any of its languages, or its code.
  static bool matches(List<String> languages, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    final names = [
      title(languages),
      for (final code in languages) native(code),
      dictionaryEnglishNames(languages),
    ];
    return names.any((name) => name.toLowerCase().contains(needle)) ||
        languages.any((code) => code.startsWith(needle));
  }
}
