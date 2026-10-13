/// The one rule for where a new note or folder is created (issue #850).
///
/// Every flow that makes something new without being told a folder — New
/// note, New folder, New slides, a voice note, the quick note's New, a
/// note from a template, the note a dead link creates, a shared text file
/// imported as a note — asks [resolveNewItemFolder] instead of deciding
/// for itself, so the library setting ([NewItemLocation]) moves all of
/// them at once.
///
/// What does not ask: a folder named by the user (the tree's **Create …
/// here**, a Home action's own folder, a folder picked in a capture), a
/// link that names a path (`[[Sub/Foo]]`), a template's own `folder:`
/// directive, and the kinds with a folder of their own — the journal, list
/// notes, annotations and the web captures folder (`captureFolder`) — plus
/// the sidecar a recognition writes beside its file.
library;

import 'package:niman/src/core/files.dart';

/// Where new notes and folders go (library setting).
enum NewItemLocation {
  /// The top level of the library.
  libraryRoot,

  /// The folder of the note open at the time; the library root while no
  /// note is open.
  openNoteFolder,
}

/// The location a stored [id] names, or null when it names none.
NewItemLocation? newItemLocationFromId(Object? id) => switch (id) {
  'libraryRoot' => NewItemLocation.libraryRoot,
  'openNoteFolder' => NewItemLocation.openNoteFolder,
  _ => null,
};

/// The location an old library config's `missingNoteLocation` stands
/// for (read, never written since #850): `libraryRoot` is the root, and
/// `currentFolder` — like anything else, or nothing — the open note's
/// folder, which is what the old setting defaulted to.
NewItemLocation newItemLocationFromLegacy(Object? legacy) => switch (legacy) {
  'libraryRoot' => NewItemLocation.libraryRoot,
  _ => NewItemLocation.openNoteFolder,
};

/// The library-relative folder ('' = the library root) a new note or
/// folder goes in under [location], with [activeNote] the library-relative
/// path of the note open at the time, or null when none is (or it is not
/// inside the library).
String resolveNewItemFolder(NewItemLocation location, {String? activeNote}) {
  return switch (location) {
    NewItemLocation.libraryRoot => '',
    NewItemLocation.openNoteFolder =>
      activeNote == null || activeNote.isEmpty ? '' : parentOf(activeNote),
  };
}

/// The rule as a flow holds it: the setting and the open note, both read
/// when a creation asks, never when the flow was built (the setting can
/// change, and the open note moves).
final class NewItemRule {
  /// A rule reading [location] and [activeNote] on each [folder].
  const new({required this.location, required this.activeNote});

  /// A rule that never changes: [location], with [activeNote] open.
  new fixed(NewItemLocation location, {String? activeNote})
    : this(location: () => location, activeNote: () => activeNote);

  /// The library setting, read now.
  final NewItemLocation Function() location;

  /// The library-relative path of the note open now, or null.
  final String? Function() activeNote;

  /// The folder a new note or folder goes in now.
  String get folder =>
      resolveNewItemFolder(location(), activeNote: activeNote());
}
