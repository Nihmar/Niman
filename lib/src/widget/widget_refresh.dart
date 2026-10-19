/// Keeps the todo widgets showing the open library's todos (issue 6).
///
/// The shell calls [refreshTodoWidgets] whenever the todo snapshot moves;
/// the native providers only render the last payload pushed, so a library
/// with no todo widgets configured costs one cheap registry read and no
/// launcher traffic.
library;

import 'package:niman/src/core/logging.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_host.dart';
import 'package:niman/src/widget/widget_note_ops.dart';
import 'package:niman/src/widget/widget_off.dart';
import 'package:niman/src/widget/widget_pin.dart';
import 'package:niman/src/widget/widget_placement.dart';
import 'package:niman/src/widget/widget_reconcile.dart';
import 'package:niman/src/widget/widget_theme.dart';
import 'package:niman/src/widget/widget_todo_payload.dart';
import 'package:niman/src/widget/widget_updater.dart';

/// Pushes [snapshot]'s open todos to every todo widget configured for the
/// session's library.
///
/// [host] lists the placed instances; unknown ones adopt their config
/// choice ([WidgetPlacementStore]) when present, else the open library —
/// a fresh instance without a choice follows the library open when it
/// was placed. No-ops without an open library, without todo widgets, or
/// before the first snapshot loads (that load notifies too, so it pushes
/// through the same path).
Future<void> refreshTodoWidgets({
  required LibrarySession session,
  required TodoSnapshot? snapshot,
  WidgetUpdater? updater,
  WidgetHostService? host,
  WidgetPlacementStore? placement,
}) async {
  final root = session.root;
  final off = widgetOffFeature(WidgetProvider.todo, session.features.value);
  // A widget that is off needs no snapshot: it is sent the off payload.
  if (root == null || (snapshot == null && off == null)) return;
  final ids = await reconcilePlacedWidgets(
    session: session,
    root: root,
    provider: WidgetProvider.todo,
    placed: host?.todoWidgetIds,
    chosenLibrary: (id) async =>
        (await placement?.consumeTodoConfig(id))?.library,
    adopt: session.adoptTodoWidget,
  );
  if (ids.isEmpty) return;
  final payload = off != null
      ? widgetOffPayload(
          feature: off,
          libraryPath: root,
          theme: resolveWidgetTheme(),
        )
      : buildTodoWidgetPayload(
          snapshot!,
          libraryPath: root,
          theme: resolveWidgetTheme(),
        );
  await pushToWidgets(
    provider: WidgetProvider.todo,
    ids: ids,
    payload: payload,
    updater: updater,
  );
}

/// Reads the text of the note file at [notePath] in [root] (null when
/// missing or unreadable).
typedef ReadNoteFile = Future<String?> Function(String root, String notePath);

/// Pushes the pinned notes to every note widget configured for the
/// session's library.
///
/// Unknown placed instances adopt in priority order: their config choice
/// ([WidgetPlacementStore]), then the pending pin ([WidgetPinStore]) when
/// it names the open library. A pin for another library is put back for
/// that library's refresh. A pinned note that is gone pushes a `missing`
/// payload instead of going quiet. No-ops without an open library or
/// without note widgets.
Future<void> refreshNoteWidgets({
  required LibrarySession session,
  WidgetUpdater? updater,
  WidgetHostService? host,
  WidgetPinStore? pinStore,
  WidgetPlacementStore? placement,
  Future<bool> Function({
    required String libraryPath,
    required String notePath,
  })?
  restorePin,
  ReadNoteFile? readNote,
}) async {
  final root = session.root;
  if (root == null) return;
  if (host != null) {
    final placed = await host.noteWidgetIds();
    const AppLogger(name: 'widgets').debug('note refresh: placed=$placed');
    if (placed.isNotEmpty) {
      final known = {
        for (final config in await session.widgetConfigsFor(root))
          config.androidWidgetId,
      };
      final restore = restorePin ?? saveWidgetPin;
      for (final id in placed) {
        if (known.contains(id)) continue;
        final choice = await placement?.consumeNoteConfig(id);
        if (choice != null &&
            choice.library.isNotEmpty &&
            choice.note.isNotEmpty) {
          await session.adoptNoteWidget(id, choice.library, choice.note);
          const AppLogger(name: 'widgets').debug(
            'note refresh: adopted $id -> ${choice.library} / ${choice.note} '
            '(choice)',
          );
          continue;
        }
        final pin = await pinStore?.consumePin();
        if (pin == null) continue;
        if (pin.libraryPath != root) {
          // Another library's pin: put it back for its own refresh.
          await restore(libraryPath: pin.libraryPath, notePath: pin.notePath);
          continue;
        }
        await session.adoptNoteWidget(id, root, pin.notePath);
        const AppLogger(
          name: 'widgets',
        ).debug('note refresh: adopted $id -> $root / ${pin.notePath} (pin)');
      }
      // The removed instances' rows are reaped here: the native
      // onDeleted cannot reach the database (the engine may be dead),
      // and a stale row pushes on every refresh — and every push
      // re-broadcasts the update to the instances still placed.
      await session.pruneWidgetConfigs(
        libraryPath: root,
        provider: WidgetProvider.note,
        placedIds: placed.toSet(),
      );
    }
  }
  final off = widgetOffFeature(WidgetProvider.note, session.features.value);
  final notes = <({int id, String notePath})>[
    for (final config in await session.widgetConfigsFor(root))
      if (config.provider == WidgetProvider.note.name &&
          config.notePath != null)
        (id: config.androidWidgetId, notePath: config.notePath!),
  ];
  if (notes.isEmpty) return;
  final push = updater ?? WidgetUpdater();
  final read = readNote ?? readNoteText;
  final theme = resolveWidgetTheme();
  for (final note in notes) {
    // Off: the note is not even read (#1109).
    final payload = off != null
        ? widgetOffPayload(feature: off, libraryPath: root, theme: theme)
        : await _notePayload(read, root, note.notePath, theme);
    await push.push(
      provider: WidgetProvider.note,
      androidWidgetId: note.id,
      payload: payload,
    );
    const AppLogger(name: 'widgets').debug(
      'note refresh: pushed ${note.id} ${note.notePath} '
      '(${payload.length} chars)',
    );
  }
}

/// The payload for the note at [notePath] in [root]: excerpt, checklist
/// rows or `missing` when the file is gone.
Future<String> _notePayload(
  ReadNoteFile read,
  String root,
  String notePath,
  WidgetTheme theme,
) async {
  return await notePayloadFor(
    root,
    notePath,
    await read(root, notePath),
    theme: theme,
  );
}
