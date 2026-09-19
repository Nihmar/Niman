/// The commands pinned in the palette (#208).
///
/// Pinned ones head the palette before anything is typed, above the ones
/// used lately: the handful someone reaches for every day, in one place,
/// without typing. They belong to the device, like the key map — a pin is
/// about how this machine is used, not about a library's notes.
///
/// Commands only. Notes have their pins in the tree, and the palette
/// already opens on the notes opened lately.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/ui/app_shortcuts.dart';

/// The pins in force, in pinning order, for the palette to read.
///
/// Read at start from the device's settings and written on every change,
/// like the key map: a notifier so a palette on screen follows a pin.
final class PinnedCommands {
  const new _();

  /// The pinned commands, oldest pin first.
  static final ValueNotifier<List<AppCommand>> current = ValueNotifier(
    const [],
  );

  /// Loads the pins kept on this device.
  static Future<void> load(LibrarySession session) async {
    current.value = decode(await session.pinnedCommands);
  }

  /// Pins [command] (at the end), or unpins it if it is pinned already,
  /// and keeps the result.
  static Future<void> toggle(LibrarySession session, AppCommand command) {
    final pinned = current.value;
    final next = pinned.contains(command)
        ? [
            for (final other in pinned)
              if (other != command) other,
          ]
        : [...pinned, command];
    return _keep(session, next);
  }

  /// Whether [command] is pinned.
  static bool isPinned(AppCommand command) => current.value.contains(command);

  static Future<void> _keep(
    LibrarySession session,
    List<AppCommand> pinned,
  ) async {
    current.value = List.unmodifiable(pinned);
    await session.setPinnedCommands(encode(pinned));
  }

  /// The stored form: a JSON array of command names, in pinning order.
  static String encode(List<AppCommand> pinned) =>
      jsonEncode([for (final command in pinned) command.name]);

  /// Reads [encode]'s form; unknown names (a command this build dropped)
  /// and anything malformed are left out, not thrown over.
  static List<AppCommand> decode(String? json) {
    if (json == null || json.isEmpty) return const [];
    Object? read;
    try {
      read = jsonDecode(json);
    } on FormatException {
      return const [];
    }
    if (read is! List) return const [];
    final byName = {
      for (final command in AppCommand.values) command.name: command,
    };
    return List.unmodifiable([
      for (final name in read)
        if (name is String) ?byName[name],
    ]);
  }
}
