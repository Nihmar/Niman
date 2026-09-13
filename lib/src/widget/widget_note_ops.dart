/// Background note-row ops for the list widget (issue 6).
///
/// The list widget's row taps and "+" button fire `home_widget`
/// background intents carrying `niman://note-row-toggle` /
/// `niman://note-row-add` URIs; these ops edit the note file off the UI
/// isolate and re-push the widget payload — no activity comes to the
/// foreground, and it works with the app closed. No Drift, no UI: the
/// background isolate owns plain file I/O, like the todo toggle.
///
/// Known limitation: an edit here is an external file edit — a note open
/// in the editor converges like any other disk change.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:niman/src/core/files.dart';
import 'package:niman/src/core/logging.dart';
import 'package:niman/src/ui/kinds/list_parser.dart';
import 'package:niman/src/widget/note_excerpt.dart';
import 'package:niman/src/widget/widget_configs.dart';
import 'package:niman/src/widget/widget_payload.dart';
import 'package:niman/src/widget/widget_updater.dart';
import 'package:path/path.dart' as p;

/// The text of the note file at [notePath] in [root], read off the UI
/// isolate (the Android FUSE rule), BOM stripped and decoded leniently;
/// null when the file is missing or unreadable.
Future<String?> readNoteText(String root, String notePath) async {
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

/// Writes [content] to the note file at [notePath] in [root] atomically.
Future<void> writeNoteText(String root, String notePath, String content) async {
  await writeFileAtomically(File(p.join(root, notePath)), utf8.encode(content));
}

/// The payload for the note at [notePath] in [root] from [content]
/// (excerpt, checklist rows or `missing` when the file is gone).
Future<String> notePayloadFor(
  String root,
  String notePath,
  String? content,
) async {
  if (content == null) {
    return noteWidgetPayload(
      libraryPath: root,
      notePath: notePath,
      title: noteWidgetTitle(notePath),
      kind: 'missing',
      truncated: false,
    );
  }
  if (isListNoteContent(content)) {
    final list = checklistRows(content);
    return noteWidgetPayload(
      libraryPath: root,
      notePath: notePath,
      title: noteWidgetTitle(notePath),
      kind: 'list',
      rows: list.rows,
      truncated: list.truncated,
    );
  }
  final excerpt = noteExcerpt(content);
  return noteWidgetPayload(
    libraryPath: root,
    notePath: notePath,
    title: noteWidgetTitle(notePath),
    kind: 'note',
    body: excerpt.text,
    truncated: excerpt.truncated,
  );
}

/// Parses a `niman://note-row-toggle?id=&library=&note=&line=` URI, or
/// null when it carries nothing toggleable.
({int id, String library, String note, int line})? parseNoteRowToggleUri(
  Uri? uri,
) {
  if (uri == null) return null;
  if (uri.scheme != 'niman' || uri.host != 'note-row-toggle') return null;
  final params = uri.queryParameters;
  final id = int.tryParse(params['id'] ?? '');
  final line = int.tryParse(params['line'] ?? '');
  final library = params['library'];
  final note = params['note'];
  if (id == null ||
      id < 0 ||
      line == null ||
      line < 0 ||
      library == null ||
      library.isEmpty ||
      note == null ||
      note.isEmpty) {
    return null;
  }
  return (id: id, library: library, note: note, line: line);
}

/// Parses a `niman://note-row-add?id=&library=&note=` URI, or null when
/// it carries nothing addable.
({int id, String library, String note})? parseNoteRowAddUri(Uri? uri) {
  if (uri == null) return null;
  if (uri.scheme != 'niman' || uri.host != 'note-row-add') return null;
  final params = uri.queryParameters;
  final id = int.tryParse(params['id'] ?? '');
  final library = params['library'];
  final note = params['note'];
  if (id == null ||
      id < 0 ||
      library == null ||
      library.isEmpty ||
      note == null ||
      note.isEmpty) {
    return null;
  }
  return (id: id, library: library, note: note);
}

/// Flips the task box of the note's target line and re-pushes the
/// widget.
///
/// True when the flip landed; false (quiet) on a stale tap — the note
/// missing or the line no longer a task box since the push — the next
/// refresh converges the widget anyway. [readNote]/[writeNote] and
/// [updater] are injected in tests.
Future<bool> toggleWidgetNoteRow(
  Uri? uri, {
  Future<String?> Function(String root, String notePath)? readNote,
  Future<void> Function(String root, String notePath, String content)?
  writeNote,
  WidgetUpdater? updater,
}) async {
  final target = parseNoteRowToggleUri(uri);
  if (target == null) {
    const AppLogger(name: 'widgets')
        .warning('note-row toggle without a target');
    return false;
  }
  try {
    final read = readNote ?? readNoteText;
    final content = await read(target.library, target.note);
    if (content == null) {
      const AppLogger(name: 'widgets').warning('note-row toggle: note missing');
      return false;
    }
    ListItem? item;
    for (final it in parseListItems(content)) {
      if (it.line == target.line) {
        item = it;
        break;
      }
    }
    if (item == null) {
      const AppLogger(name: 'widgets')
          .warning('note-row toggle: line ${target.line} is no longer an item');
      return false;
    }
    final updated = flipListItem(content, item);
    final write = writeNote ?? writeNoteText;
    await write(target.library, target.note, updated);
    await _pushNoteWidget(
      target.id,
      target.library,
      target.note,
      updated,
      updater,
    );
    return true;
  } on Object catch (error) {
    // A note edited or moved since the push: the widget converges on the
    // next refresh.
    const AppLogger(name: 'widgets').warning('note-row toggle failed ($error)');
    return false;
  }
}

/// Appends a new empty item to the note and re-pushes the widget.
///
/// True when the item landed; false (quiet) when the note is missing or
/// is no longer a list note (a `+` for a note whose kind drifted off
/// `list`), the next refresh converging the widget either way.
/// [readNote]/[writeNote] and [updater] are injected in tests.
Future<bool> addWidgetNoteRow(
  Uri? uri, {
  Future<String?> Function(String root, String notePath)? readNote,
  Future<void> Function(String root, String notePath, String content)?
  writeNote,
  WidgetUpdater? updater,
}) async {
  final target = parseNoteRowAddUri(uri);
  if (target == null) {
    const AppLogger(name: 'widgets').warning('note-row add without a target');
    return false;
  }
  try {
    final read = readNote ?? readNoteText;
    final content = await read(target.library, target.note);
    if (content == null || !isListNoteContent(content)) {
      const AppLogger(name: 'widgets').warning('note-row add: no list note');
      return false;
    }
    final updated = appendListItem(content, '');
    final write = writeNote ?? writeNoteText;
    await write(target.library, target.note, updated);
    await _pushNoteWidget(
      target.id,
      target.library,
      target.note,
      updated,
      updater,
    );
    return true;
  } on Object catch (error) {
    const AppLogger(name: 'widgets').warning('note-row add failed ($error)');
    return false;
  }
}

/// Re-pushes the note widget of [id] from [content].
Future<void> _pushNoteWidget(
  int id,
  String library,
  String note,
  String content,
  WidgetUpdater? updater,
) async {
  final payload = await notePayloadFor(library, note, content);
  final push = updater ?? WidgetUpdater();
  await push.push(
    provider: WidgetProvider.note,
    androidWidgetId: id,
    payload: payload,
  );
  const AppLogger(name: 'widgets')
      .debug('note-row op: pushed $id $note (${payload.length} chars)');
}
