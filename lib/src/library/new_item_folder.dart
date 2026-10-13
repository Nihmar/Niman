/// The one rule for where a new note or folder is created (issue #850).
///
/// Every flow that makes something new without being told a folder — New
/// note, New folder, a note from a template, the note a dead link
/// creates, a captured web page, a voice note — asks [resolveNewItemFolder]
/// instead of deciding for itself, so the library setting
/// ([NewItemLocation]) moves all of them at once.
///
/// What does not ask: a folder named by the user (the tree's **Create …
/// here**, a Home action's own folder, a folder picked in a capture), a
/// link that names a path (`[[Sub/Foo]]`), a template's own `folder:`
/// directive, the journal's folder and the sidecar a recognition writes
/// beside its file.
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
