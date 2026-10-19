/// The home-screen widgets of a feature that is off (#1109, Phone-4).
///
/// A widget whose feature -- or the Home-screen widgets switch itself -- is
/// off is sent one payload that says so and nothing else is written for it:
/// no rows, no decks counted, no note read. The provider draws the sentence
/// and an **Open Features** button; turning the feature back on pushes real
/// data over it, and nothing in the library was touched meanwhile.
///
/// The sentence and the button are written here, in the app's language,
/// like the section headings of the todo payload: the native side only
/// holds English and Italian, and the payload already carries what it shows.
///
/// The background ops of a widget (a toggle, a day refresh) run in an
/// isolate with no session, so they ask the library's `settings.json`
/// ([widgetUriAllowed]) instead.
library;

import 'dart:convert';

import 'package:niman/src/core/language.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/core/settings/library_config.dart';
import 'package:niman/src/core/settings/library_features.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_day_refresh.dart';
import 'package:niman/src/widget/widget_theme.dart';

/// The feature whose switch keeps [provider]'s widgets off in a library with
/// [features], or null when they show their data.
///
/// The widgets switch is the broader one and speaks first. The note widget
/// has no feature of its own: it shows a note whatever kind it is.
LibraryFeature? widgetOffFeature(WidgetProvider provider, Features features) {
  if (!features.isOn(LibraryFeature.widgets)) return LibraryFeature.widgets;
  final own = switch (provider) {
    WidgetProvider.todo => LibraryFeature.todo,
    WidgetProvider.study => LibraryFeature.kindFlashcards,
    WidgetProvider.note => null,
  };
  return own != null && !features.isOn(own) ? own : null;
}

/// The off payload for the widget of the library at [libraryPath]:
/// `{"library", "off": {"feature", "text", "action"}, "language", "theme"}`.
///
/// `text` is the sentence ("Todo is off in this library") and `action` the
/// button's label; the provider recognises the payload by `off`. The
/// library rides along so the header keeps naming it, and so the button
/// opens the app on that library. [theme] wears the app theme.
String widgetOffPayload({
  required LibraryFeature feature,
  required String libraryPath,
  WidgetTheme? theme,
}) {
  return jsonEncode({
    'library': libraryPath,
    'off': {
      'feature': feature.id,
      'text': _sentence(feature),
      'action': AppStrings.widgetOpenFeatures,
    },
    'language': AppLanguages.resolved.id,
    if (theme != null) 'theme': widgetThemeToMap(theme),
  });
}

String _sentence(LibraryFeature feature) => switch (feature) {
  LibraryFeature.todo => AppStrings.widgetOffTodo,
  LibraryFeature.kindFlashcards => AppStrings.widgetOffStudy,
  LibraryFeature.widgets => AppStrings.widgetOffWidgets,
  _ => throw ArgumentError.value(feature, 'feature', 'owns no widget'),
};

/// The features the library at [root] holds in its `settings.json`; every
/// one on when the file is missing or unreadable (the settings file's rule).
Future<Features> readWidgetFeatures(String root) async {
  try {
    return (await LibraryConfigStore(root).read()).features;
  } on Object catch (error) {
    const AppLogger(name: 'widgets').warning('features unreadable ($error)');
    return const Features();
  }
}

/// Whether the background op that [uri] asks for may touch its widget's
/// data: false when its widget is off, so nothing is read or written for it.
///
/// An op that names no library, or none this routes, is allowed: the op
/// itself refuses a URI it cannot use. [readFeatures] is injected in tests.
Future<bool> widgetUriAllowed(
  Uri? uri, {
  Future<Features> Function(String root)? readFeatures,
}) async {
  final provider = switch (uri?.host) {
    'todo-toggle' || widgetTodoRefreshHost => WidgetProvider.todo,
    'note-row-toggle' || 'note-row-add' => WidgetProvider.note,
    _ => null,
  };
  final library = uri?.queryParameters['library'];
  if (provider == null || library == null || library.isEmpty) return true;
  final features = await (readFeatures ?? readWidgetFeatures)(library);
  final off = widgetOffFeature(provider, features);
  if (off != null) {
    const AppLogger(name: 'widgets')
        .info('${uri!.host} ignored: ${off.id} is off in $library');
  }
  return off == null;
}
