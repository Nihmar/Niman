// The app's language (T-L10N-01): what `ui/strings.dart` answers in.
//
// Deliberately a small global rather than an inherited widget: the labels
// are read from services and dialogs that have no BuildContext, and the
// whole point of keeping every string in one file is that a call site
// never has to ask for a translation.

import 'dart:ui';

import 'package:flutter/foundation.dart';

/// A language the app speaks, plus the "follow the system" choice.
enum AppLanguage {
  /// Follow the OS language, falling back to English.
  system('system'),

  /// English.
  english('en'),

  /// French.
  french('fr'),

  /// German.
  german('de'),

  /// Spanish.
  spanish('es'),

  /// Portuguese.
  portuguese('pt'),

  /// Chinese (Simplified).
  chinese('zh'),

  /// Japanese.
  japanese('ja'),

  /// Hindi.
  hindi('hi'),

  /// Italian.
  italian('it'),

  /// Dutch.
  dutch('nl');

  new(this.id);

  /// The persisted id (also the locale code for the real languages).
  final String id;

  /// The language with this [id]; anything unknown is [system].
  static AppLanguage fromId(String? id) {
    for (final language in AppLanguage.values) {
      if (language.id == id) return language;
    }
    return AppLanguage.system;
  }
}

/// The active language: the user's choice, resolved against the OS.
final class AppLanguages {
  const new _();

  /// The languages the app ships, in menu order.
  static const List<AppLanguage> supported = [
    AppLanguage.english,
    AppLanguage.french,
    AppLanguage.german,
    AppLanguage.spanish,
    AppLanguage.portuguese,
    AppLanguage.chinese,
    AppLanguage.japanese,
    AppLanguage.hindi,
    AppLanguage.italian,
    AppLanguage.dutch,
  ];

  /// Bumped whenever [resolved] changes; the app root listens to it and
  /// rebuilds, so a language change reaches every screen at once.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static AppLanguage _choice = AppLanguage.system;
  static AppLanguage _system = AppLanguage.english;

  /// What the user picked in the settings.
  static AppLanguage get choice => _choice;

  static set choice(AppLanguage value) {
    if (_choice == value) return;
    final before = resolved;
    _choice = value;
    if (resolved != before) revision.value++;
  }

  /// What [AppLanguage.system] currently means; the app keeps this in
  /// step with the platform locale.
  static AppLanguage get system => _system;

  static set system(AppLanguage value) {
    if (_system == value) return;
    final before = resolved;
    _system = value;
    if (resolved != before) revision.value++;
  }

  /// The language actually in use.
  static AppLanguage get resolved =>
      _choice == AppLanguage.system ? _system : _choice;

  /// The locale to hand `MaterialApp`, so Flutter's own dialogs (dates,
  /// times, text selection) follow the app.
  static Locale get locale => Locale(resolved.id);

  /// The language [locales] asks for: the first supported match, else
  /// English. Only the language code is considered, so any variant of a
  /// supported language (pt-BR, zh-Hans, …) counts.
  static AppLanguage fromLocales(List<Locale>? locales) {
    for (final locale in locales ?? const <Locale>[]) {
      for (final language in supported) {
        if (locale.languageCode == language.id) return language;
      }
    }
    return AppLanguage.english;
  }

  /// Test hook: puts the language back to its start-up state.
  @visibleForTesting
  static void reset() {
    _choice = AppLanguage.system;
    _system = AppLanguage.english;
  }
}
