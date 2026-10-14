/// The dead-link watching of a note view's open note (#847): where its links
/// come from, and the watcher that resolves them.
///
/// The links are the editor's own record of them when it keeps one (a long
/// note, styled block by block), else a read of the note's lines the way the
/// index reads them — on an isolate past [deadLinkInlineLimit], and not at
/// all past [deadLinkTextLimit]. The note's text is never joined into one
/// string: the buffer itself goes to the isolate (#916).
library;

import 'dart:isolate';

import 'package:niman/src/links/dead_link_checker.dart';
import 'package:niman/src/links/parser.dart';
import 'package:niman/src/markdown/note_references.dart';
import 'package:niman/src/markdown/source_buffer.dart';
import 'package:niman/src/ui/dead_link_watcher.dart';

/// The watcher of the open note's dead links: resolved against [source]
/// (null while no library is ready), for the note at library-relative
/// [notePath], waiting [delay] after an edit or an index move.
///
/// [buffer] is the open note's text, null while none is loaded; [kept] is
/// the editor's record of the note's references, null when it keeps none.
DeadLinkWatcher openNoteDeadLinks({
  required DeadLinkSource? Function() source,
  required SourceBuffer? Function() buffer,
  required NoteReferences? Function() kept,
  required String? Function() notePath,
  required Duration Function() delay,
}) => DeadLinkWatcher(
  source: source,
  links: () => openNoteLinks(buffer: buffer(), kept: kept),
  notePath: notePath,
  delay: delay,
);

/// The links of the open note whose text is [buffer], as the index reads
/// them: [kept]'s record when there is one, else a read of its lines — null
/// for no note, or a note too long to read twice.
Future<List<ParsedLink>?> openNoteLinks({
  required SourceBuffer? buffer,
  required NoteReferences? Function() kept,
}) async {
  if (buffer == null) return null;
  final record = kept();
  if (record != null) return record.links;
  if (buffer.length > deadLinkTextLimit) return null;
  return await linksOfBuffer(buffer);
}

/// How long a note's text may be for its links to be read off a copy of it:
/// past this, the links of the note are the editor's own record of them or
/// none (the note is a book, and its links are not worth a second read).
const int deadLinkTextLimit = 32 << 20;

/// A note longer than this (characters) is read for its links on an isolate.
const int deadLinkInlineLimit = 64 << 10;

/// The links of the note [buffer] holds — read the way the index reads them
/// ([noteReferencesOfBuffer]), so what is drawn dead is what the index
/// records. A long note is read on an isolate, off the UI's frames.
///
/// The buffer goes to the isolate as it is, as the background scans send it
/// (`scanInBackground`): the call copies its line index, not its text — a
/// string is shared between the isolates of a group — and what it costs the
/// UI isolate does not grow with a join of the note's lines. The copy is
/// taken by the call, so an edit made while the read runs is not in it; the
/// watcher drops a read an edit overtook.
Future<List<ParsedLink>> linksOfBuffer(SourceBuffer buffer) {
  if (buffer.length <= deadLinkInlineLimit) {
    return Future.value(noteReferencesOfBuffer(buffer).links);
  }
  return Isolate.run(() => noteReferencesOfBuffer(buffer).links);
}
