/// The todo widget payload of a snapshot, in the app's language (#1003).
///
/// The one place that joins the sections of `widgetTodoSections` with
/// their localized headings (`todoSectionLabel`) and stamps the language
/// into the payload; the refresh and the background toggle both push
/// through it, so they can never word a header differently.
library;

import 'package:niman/src/core/language.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/todo/widget_todos.dart';
import 'package:niman/src/ui/todo_section_label.dart';
import 'package:niman/src/widget/widget_payload.dart';
import 'package:niman/src/widget/widget_theme.dart';

/// The tap-URI query key carrying the language id the payload's labels
/// were written in (`lg`), so the background re-push words them the same.
const String widgetLanguageParam = 'lg';

/// The payload of [snapshot] for the widget of the library at
/// [libraryPath].
///
/// Headings are written in the language in use ([AppLanguages.resolved]);
/// the background isolate that re-pushes after a toggle does not start
/// the app, so it first adopts the language the tap carried
/// ([applyWidgetLanguage]). [today] is injected in tests.
String buildTodoWidgetPayload(
  TodoSnapshot snapshot, {
  required String libraryPath,
  WidgetTheme? theme,
  DateTime? today,
}) {
  return todoWidgetPayload(
    widgetTodoSections(snapshot, labelOf: todoSectionLabel, today: today),
    libraryPath: libraryPath,
    total: widgetTodoTotal(snapshot),
    theme: theme,
    language: AppLanguages.resolved.id,
  );
}

/// Adopts the language [id] a widget tap carried, for the headings of the
/// payload this isolate is about to push.
///
/// The background isolate of a widget tap starts with the defaults, not
/// the user's choice; the payload the widget shows names the language its
/// labels were written in and the native row hands it back on the tap.
/// An absent or unknown id leaves the language as it is.
void applyWidgetLanguage(String? id) {
  if (id == null) return;
  final language = AppLanguage.fromId(id);
  if (language == AppLanguage.system) return;
  AppLanguages.choice = language;
}
