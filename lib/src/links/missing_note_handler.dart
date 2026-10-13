/// Dead-link note creation (issue #78).
///
/// A dead link is a click that resolves to nothing. The handler proposes
/// where the missing note would be created (per the library's
/// [MissingNoteLocation] setting), asks the user, and creates it through
/// the library's own note-creation path — the same one the tree's New
/// note goes through. Cancelling changes nothing: no file, no error, no
/// second prompt.
library;

import 'package:niman/src/core/files.dart';
import 'package:path/path.dart' as p;

/// Where a note created from a dead link lands (library setting).
enum MissingNoteLocation {
  /// The library root: a bare name is created as `<name>.md` at the top
  /// level.
  libraryRoot,

  /// The folder of the note the link was clicked in: a bare name is
  /// created next to that note.
  currentFolder,
}

/// The context of a dead-link click: the note the link was clicked in,
/// and the open library it belongs to.
final class LinkContext {
  /// Creates a context for the click in [currentNote] (absolute path),
  /// inside the library at [libraryRoot] (absolute path) — or with
  /// [libraryRoot] null for a note opened without a library (editor-only
  /// mode, no creation offered).
  const new({required this.libraryRoot, required this.currentNote});

  /// Absolute path of the open library root, or null.
  final String? libraryRoot;

  /// Absolute path of the note the link was clicked in.
  final String currentNote;

  /// The clicked note's folder, library-relative ('' = the library
  /// root); null when the note is not inside [libraryRoot].
  String? get currentFolder {
    final root = libraryRoot;
    if (root == null) return null;
    if (!p.isWithin(root, currentNote)) return null;
    return parentOf(relPath(currentNote, root));
  }

  /// Whether the click has a library to create in.
  bool get hasLibrary => currentFolder != null;
}

/// The proposed creation path (library-relative, `.md` included) for an
/// unresolved link [target] clicked in [context], or null when the target
/// is not a note.
///
/// A bare name lands per [location]: [MissingNoteLocation.currentFolder]
/// puts it next to the clicked note,
/// [MissingNoteLocation.libraryRoot] at the library root. A
/// folder-qualified target keeps its own folder, which may not exist
/// yet: creating the note creates the folders on the way (#847), as
/// Obsidian does, so `[[Projects/Three laws]]` makes `Projects/` too.
///
/// Not a note (null): an empty target after normalization, or a name
/// with a surviving extension — a `foo.png` target is an attachment, and
/// attachments are never created. The name is sanitized the way notes
/// are named ([sanitizeName]); segments that do not name anything (`.`,
/// `..`, empty) are dropped, so a proposal never leaves the library.
String? proposedMissingNotePath(
  String target,
  MissingNoteLocation location,
  LinkContext context,
) {
  var t = target.trim().replaceAll(r'\', '/');
  final hash = t.indexOf('#');
  if (hash != -1) t = t.substring(0, hash);
  t = t.trim();
  if (t.isEmpty) return null;
  final lower = t.toLowerCase();
  if (lower.endsWith('.md')) t = t.substring(0, t.length - 3);
  final segments = t
      .split('/')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s != '.' && s != '..')
      .toList();
  if (segments.isEmpty) return null;
  final name = segments.last;
  // A surviving dot is an extension, not part of a note name: the target
  // is an attachment, and dead attachments keep their old outcome.
  if (name.contains('.')) return null;
  final folders = <String>[];
  for (final segment in segments.sublist(0, segments.length - 1)) {
    // A segment that starts with a dot names a hidden folder — the app's own
    // (`.niman`, `.trash`) or one the library hides — and a link never makes
    // one. The whole proposal is refused rather than silently created
    // elsewhere: the note would not be where the link says.
    if (segment.startsWith('.')) return null;
    final clean = sanitizeName(segment, fallback: '');
    if (clean.isEmpty) continue;
    folders.add(clean);
  }
  final cleanName = sanitizeName(name, fallback: defaultNoteName);
  final folder = folders.isEmpty
      ? (location == MissingNoteLocation.currentFolder
            ? (context.currentFolder ?? '')
            : '')
      : folders.join('/');
  return folder.isEmpty ? '$cleanName.md' : '$folder/$cleanName.md';
}

/// What happened when a dead link was handled.
sealed class DeadLinkOutcome {
  /// Creates an outcome.
  const new();
}

/// The note was created; open it.
final class DeadLinkCreated extends DeadLinkOutcome {
  /// Creates a created outcome for [path].
  const new(this.path);

  /// Library-relative path of the created note.
  final String path;
}

/// The user declined: nothing was created, and nothing is shown (no
/// error, no second prompt).
final class DeadLinkDeclined extends DeadLinkOutcome {
  /// Creates a declined outcome.
  const new();
}

/// No offer was possible: the note was opened without a library, or the
/// target is not a note (an attachment). The caller keeps its dead-link
/// outcome.
final class DeadLinkNotOffered extends DeadLinkOutcome {
  /// Creates a not-offered outcome.
  const new();
}

/// Handles a dead link: proposes where the missing note would be created,
/// asks the user, and creates it through the library's own note-creation
/// path (issue #78).
///
/// Not a DAO and not stateful: callers create one per use, with their
/// own dialog and creation path. The creation runs off the UI isolate (the
/// caller's job — a `statSync` is a FUSE round trip on Android).
final class MissingNoteHandler {
  /// Creates a handler.
  const new({
    required this.location,
    required this.confirm,
    required this.createNote,
  });

  /// Where the created note lands (the library's setting).
  final MissingNoteLocation location;

  /// Asks the user to create the note at library-relative `[path]`; returns
  /// whether they chose to.
  final Future<bool> Function(String path) confirm;

  /// Creates the empty note at library-relative `[path]` (the library's own
  /// creation path — sanitized, uniquified, indexed), and the folders on the
  /// way to it when the library does not have them yet (#847); returns its
  /// library-relative path.
  final Future<String> Function(String path) createNote;

  /// Handles the unresolved [linkTarget] clicked in [context].
  Future<DeadLinkOutcome> handleDeadLink(
    String linkTarget,
    LinkContext context,
  ) async {
    if (!context.hasLibrary) return const DeadLinkNotOffered();
    final proposed = proposedMissingNotePath(linkTarget, location, context);
    if (proposed == null) return const DeadLinkNotOffered();
    if (!await confirm(proposed)) return const DeadLinkDeclined();
    return DeadLinkCreated(await createNote(proposed));
  }
}
