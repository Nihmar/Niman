/// What every refresh of a provider's home-screen widgets does the same way
/// (#952): adopt the instances the launcher placed that the library does not
/// know yet, drop the rows of the ones it removed, and push one payload to
/// those left.
///
/// The task list's and the Study widgets differ in what they push and in
/// where an instance's library choice and placed ids come from; the rest is
/// here once, so a fix to adoption or pruning is made once.
library;

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_updater.dart';

const AppLogger _log = AppLogger(name: 'widgets');

/// Brings the widget configs of [provider] for the library at [root] in line
/// with the instances the launcher has placed, and returns the ids to push
/// to: the provider's configs for this library afterwards.
///
/// [placed] lists the instances the launcher has; null (no host) adopts and
/// prunes nothing. An instance with no config yet takes the library its
/// config screen chose ([chosenLibrary]), else the open library, and is
/// stored by [adopt]. When any instance is placed, the rows of the removed
/// ones are reaped: the native `onDeleted` cannot reach the database (the
/// engine may be dead), and a stale row pushes on every refresh — and every
/// push re-broadcasts the update to the instances still placed.
Future<List<int>> reconcilePlacedWidgets({
  required LibrarySession session,
  required String root,
  required WidgetProvider provider,
  required Future<List<int>> Function()? placed,
  required Future<String?> Function(int id) chosenLibrary,
  required Future<void> Function(int id, String library) adopt,
}) async {
  final ids = await placed?.call() ?? const <int>[];
  _log.debug('${provider.name} refresh: placed=$ids');
  if (ids.isNotEmpty) {
    final known = {
      for (final config in await session.widgetConfigsFor(root))
        config.androidWidgetId,
    };
    for (final id in ids) {
      if (known.contains(id)) continue;
      final choice = await chosenLibrary(id);
      final library = choice == null || choice.isEmpty ? root : choice;
      await adopt(id, library);
      _log.debug(
        '${provider.name} refresh: adopted $id -> $library '
        '(${library == root ? 'open library' : 'choice'})',
      );
    }
    await session.pruneWidgetConfigs(
      libraryPath: root,
      provider: provider,
      placedIds: ids.toSet(),
    );
  }
  return [
    for (final config in await session.widgetConfigsFor(root))
      if (config.provider == provider.name) config.androidWidgetId,
  ];
}

/// Pushes [payload] to each of the instances [ids] of [provider].
Future<void> pushToWidgets({
  required WidgetProvider provider,
  required List<int> ids,
  required String payload,
  WidgetUpdater? updater,
}) async {
  final push = updater ?? WidgetUpdater();
  for (final id in ids) {
    await push.push(provider: provider, androidWidgetId: id, payload: payload);
    _log.debug(
      '${provider.name} refresh: pushed $id (${payload.length} chars)',
    );
  }
}
