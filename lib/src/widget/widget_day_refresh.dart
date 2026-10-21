/// The todo widget's re-push at a day boundary (#1018).
///
/// A todo payload is a snapshot bucketed against the day of its push
/// ("Overdue" / "Today" / "Next 7 days", and a Today row's dropped date),
/// so a widget left overnight would keep yesterday's headings until the
/// next todo change. The native day-change receiver fires this op once
/// per placed todo widget when the local day turns over; it re-reads the
/// library's todo files and pushes the payload against the new day, in
/// the headless isolate, with the app closed.
///
/// The target rides a `niman://todo-refresh?id=&library=` URI carrying the
/// payload's theme (`td/bg/fg/fs/ac/er`) and language (`lg`), the same
/// params the row taps carry, so the re-push wears what the widget wears.
library;

import 'dart:io';

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_theme.dart';
import 'package:niman/src/widget/widget_todo_payload.dart';
import 'package:niman/src/widget/widget_updater.dart';

/// The URI host of the day-change refresh of one todo widget.
const String widgetTodoRefreshHost = 'todo-refresh';

/// Parses a `niman://todo-refresh?id=&library=` URI, or null when it
/// names no widget to refresh.
({int id, String library, WidgetTheme? theme, String? language})?
parseTodoRefreshUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme != 'niman' || uri.host != widgetTodoRefreshHost) return null;
  final params = uri.queryParameters;
  final id = int.tryParse(params['id'] ?? '');
  final library = params['library'];
  if (id == null || id < 0 || library == null || library.isEmpty) return null;
  final language = params[widgetLanguageParam];
  return (
    id: id,
    library: library,
    theme: widgetThemeFromUri(uri),
    language: language == null || language.isEmpty ? null : language,
  );
}

/// Re-reads the todo files of the widget [uri] names and pushes its
/// payload against [today] (now by default).
///
/// True when the widget was re-pushed; false (quiet) on a URI that names
/// nothing, a library that is gone (the widget keeps what it shows rather
/// than blanking), or a read that failed — the next app refresh converges
/// the widget anyway. [storeFactory] and [updater] are injected in tests.
Future<bool> refreshWidgetTodoForNewDay(
  Uri? uri, {
  TodoStore Function({required String root})? storeFactory,
  WidgetUpdater? updater,
  DateTime? today,
}) async {
  final target = parseTodoRefreshUri(uri);
  if (target == null) {
    const AppLogger(name: 'widgets').warning('day refresh without a target');
    return false;
  }
  try {
    if (!await Directory(target.library).exists()) return false;
    final store = (storeFactory ?? TodoStore.new)(root: target.library);
    final snapshot = await store.load();
    applyWidgetLanguage(target.language);
    final payload = buildTodoWidgetPayload(
      snapshot,
      libraryPath: target.library,
      theme: target.theme ?? resolveWidgetTheme(),
      today: today,
    );
    await (updater ?? WidgetUpdater()).push(
      provider: WidgetProvider.todo,
      androidWidgetId: target.id,
      payload: payload,
    );
    return true;
  } on Object catch (error) {
    const AppLogger(name: 'widgets').warning('day refresh failed ($error)');
    return false;
  }
}
