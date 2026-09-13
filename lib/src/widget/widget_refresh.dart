/// Keeps the todo widgets showing the open library's todos (issue 6).
///
/// The shell calls [refreshTodoWidgets] whenever the todo snapshot moves;
/// the native providers only render the last payload pushed, so a library
/// with no todo widgets configured costs one cheap registry read and no
/// launcher traffic.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/library/session.dart';
import 'package:niman/src/todo/todo_store.dart';
import 'package:niman/src/todo/widget_todos.dart';
import 'package:niman/src/widget/note_excerpt.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_host.dart';
import 'package:niman/src/widget/widget_payload.dart';
import 'package:niman/src/widget/widget_pin.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

/// Pushes [snapshot]'s open todos to every todo widget configured for the
/// session's library.
///
/// [host] lists the placed instances so unknown ones adopt the open
/// library before the push (a fresh instance follows the library open
/// when it was placed). No-ops without an open library, without todo
/// widgets, or before the first snapshot loads (that load notifies too,
/// so it pushes through the same path).
Future<void> refreshTodoWidgets({
  required LibrarySession session,
  required TodoSnapshot? snapshot,
  WidgetUpdater? updater,
  WidgetHostService? host,
}) async {
  final root = session.root;
  if (root == null || snapshot == null) return;
  if (host != null) {
    final placed = await host.todoWidgetIds();
    if (placed.isNotEmpty) {
      final known = {
        for (final config in await session.widgetConfigsFor(root))
          config.androidWidgetId,
      };
      for (final id in placed) {
        if (!known.contains(id)) {
          await session.adoptTodoWidget(id, root);
        }
      }
    }
  }
  final ids = <int>[
    for (final config in await session.widgetConfigsFor(root))
      if (config.provider == WidgetProvider.todo.name) config.androidWidgetId,
  ];
  if (ids.isEmpty) return;
  final payload = todoWidgetPayload(
    sortTodosForWidget(snapshot),
    libraryPath: root,
  );
  final push = updater ?? WidgetUpdater();
  for (final id in ids) {
    await push.push(
      provider: WidgetProvider.todo,
      androidWidgetId: id,
      payload: payload,
    );
  }
}

/// Reads the text of the note file at [notePath] in [root] (null when
/// missing or unreadable).
typedef ReadNoteFile = Future<String?> Function(String root, String notePath);

/// Pushes the pinned notes to every note widget configured for the
/// session's library.
///
/// Unknown placed instances adopt the pending pin ([WidgetPinStore])
/// when it names the open library; a pin for another library is put
/// back for that library's refresh. A pinned note that is gone pushes a
/// `missing` payload instead of going quiet. No-ops without an open
/// library or without note widgets.
Future<void> refreshNoteWidgets({
  required LibrarySession session,
  WidgetUpdater? updater,
  WidgetHostService? host,
  WidgetPinStore? pinStore,
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
    if (placed.isNotEmpty) {
      final known = {
        for (final config in await session.widgetConfigsFor(root))
          config.androidWidgetId,
      };
      final restore = restorePin ?? saveWidgetPin;
      for (final id in placed) {
        if (known.contains(id)) continue;
        final pin = await pinStore?.consumePin();
        if (pin == null) continue;
        if (pin.libraryPath != root) {
          // Another library's pin: put it back for its own refresh.
          await restore(libraryPath: pin.libraryPath, notePath: pin.notePath);
          continue;
        }
        await session.adoptNoteWidget(id, root, pin.notePath);
      }
    }
  }
  final notes = <({int id, String notePath})>[
    for (final config in await session.widgetConfigsFor(root))
      if (config.provider == WidgetProvider.note.name &&
          config.notePath != null)
        (id: config.androidWidgetId, notePath: config.notePath!),
  ];
  if (notes.isEmpty) return;
  final push = updater ?? WidgetUpdater();
  final read = readNote ?? _readNoteFile;
  for (final note in notes) {
    await push.push(
      provider: WidgetProvider.note,
      androidWidgetId: note.id,
      payload: await _notePayload(read, root, note.notePath),
    );
  }
}

/// The payload for the note at [notePath] in [root]: excerpt, checklist
/// or `missing` when the file is gone.
Future<String> _notePayload(
  ReadNoteFile read,
  String root,
  String notePath,
) async {
  final content = await read(root, notePath);
  if (content == null) {
    return noteWidgetPayload(
      libraryPath: root,
      title: noteWidgetTitle(notePath),
      kind: 'missing',
      body: '',
      truncated: false,
    );
  }
  if (isListNoteContent(content)) {
    final list = checklistExcerpt(content);
    return noteWidgetPayload(
      libraryPath: root,
      title: noteWidgetTitle(notePath),
      kind: 'list',
      body: list.text,
      truncated: list.truncated,
    );
  }
  final excerpt = noteExcerpt(content);
  return noteWidgetPayload(
    libraryPath: root,
    title: noteWidgetTitle(notePath),
    kind: 'note',
    body: excerpt.text,
    truncated: excerpt.truncated,
  );
}

/// The text of the note file, read off the UI isolate (the Android FUSE
/// rule), decoded leniently like [NoteOperations.readNote]; null when
/// the file is missing or unreadable.
Future<String?> _readNoteFile(String root, String notePath) async {
  try {
    final bytes = await Isolate.run(() {
      final file = File(p.join(root, notePath));
      if (!file.existsSync()) return null;
      return file.readAsBytesSync();
    });
    if (bytes == null) return null;
    final text = utf8.decode(bytes, allowMalformed: true);
    return text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF
        ? text.substring(1)
        : text;
  } on Object {
    return null;
  }
}
