import 'package:flutter/foundation.dart';
import 'package:niman/src/core/settings/features.dart';
import 'package:niman/src/library/attachment_store.dart';
import 'package:niman/src/links/library_links.dart';
import 'package:niman/src/links/suggester.dart';
import 'package:niman/src/spellcheck/editor_spell_check.dart';
import 'package:niman/src/ui/note_save_pipeline.dart';
import 'package:niman/src/ui/note_tasks_host.dart';
import 'package:niman/src/ui/unsaved_notes.dart';

/// What the open library lends every note view (#1257): its root, its links
/// and suggestions, its tasks and features, the unsaved registry, the
/// spelling, and the ways a note is read, saved and attached to. One value
/// the shell builds once, in place of sixteen loose arguments repeated
/// wherever a note is shown. Each is null where there is no library (most
/// widget tests), which turns its feature off.
@immutable
final class NoteServices {
  /// The services a library lends; none by default.
  const new({
    this.libraryRoot,
    this.linkSource,
    this.wikilinkSuggester,
    this.tasks,
    this.features,
    this.unsavedTracker,
    this.spellCheck,
    this.saveNote,
    this.saveNoteStream,
    this.createMissingNote,
    this.readNote,
    this.writeNote,
    this.pickImagePath,
    this.importImage,
    this.readClipboardFiles,
    this.onOpenNote,
  });

  /// The library root (T-M2-09): relative image links in the preview
  /// resolve under it, and inserted images are copied into
  /// `<root>/assets/`. Null (tests without a library) disables insert.
  final String? libraryRoot;

  /// The link-resolution source (wiki targets + markdown hrefs against the
  /// open index); null (tests without a session) disables link navigation.
  final LibraryLinks? linkSource;

  /// The library the wikilink suggester panel reads (#475): the notes,
  /// their aliases and their headings. Null (no open library) draws no
  /// panel, and the link is typed as it was before.
  final WikilinkSuggester? wikilinkSuggester;

  /// The tasks that link a note (#1152), for the "Tasks for this note"
  /// section under it. Null — no library — draws none; the section is also
  /// left out while the library's Todo feature is off.
  final NoteTasksHost? tasks;

  /// The library's features (#1109): a note of a kind that is off opens in
  /// the plain editor. Null reads every kind as on.
  final ValueListenable<Features>? features;

  /// The app-level registry of notes with unsaved edits (T-PP-11), which
  /// the window's close guard reads; null when the owner does not track
  /// (most widget tests). The view reports its note's live revision pair,
  /// so the tracker never holds a copy of the text.
  final UnsavedTracker? unsavedTracker;

  /// The editor's spelling state (T-PP-09): underlines misspelled prose.
  /// Null (most widget tests, and a platform without hunspell) draws none.
  final EditorSpellCheck? spellCheck;

  /// Saves a note's content through the library's write path (`NoteOps`),
  /// with the editor session the save belongs to. Takes precedence over
  /// [writeNote]; null (no open library) falls back to a direct write.
  final NoteSaver? saveNote;

  /// Saves a note whose text is too long to join (a [NoteStreamSaver]):
  /// the producer it is handed makes the bytes one slice at a time and the
  /// write takes them as they come. Null — no library, or a note outside
  /// its root — joins the note and saves it through [saveNote] as before.
  final NoteStreamSaver? saveNoteStream;

  /// The note-creation path for dead links (issue #78): creates an empty
  /// note at the library-relative path it is given and returns its
  /// library-relative path; null (no open library) keeps the dead-link
  /// snackbar instead of the offer.
  final Future<String> Function(String path)? createMissingNote;

  /// Reads a note's content. Defaults to an off-isolate file read.
  final Future<String> Function(String path)? readNote;

  /// Persists a note's content. Defaults to an atomic file write.
  ///
  /// A test seam; production passes [saveNote] instead.
  final Future<void> Function(String path, String content)? writeNote;

  /// Picks an image file (T-M2-09); the default is the platform picker
  /// (file_picker). Tests inject a seam.
  final Future<String?> Function()? pickImagePath;

  /// Imports the picked file into the library (default
  /// [importImageToLibrary]); tests inject a seam (it runs an isolate,
  /// which FakeAsync cannot drive).
  final Future<String> Function(String libraryRoot, String sourcePath)?
  importImage;

  /// Reads the paths of the files on the clipboard, which a paste attaches
  /// (#1249); the default is the platform's reader. Tests inject a seam.
  final Future<List<String>> Function()? readClipboardFiles;

  /// Opens a note by library-relative path, then (optionally) jumps to a
  /// heading; the shell implements it (T-M3-07).
  final void Function(String path, String? anchor)? onOpenNote;
}
