/// What the wikilink suggester panel offers (#475), and where the app reads
/// it from.
///
/// While a wikilink is typed the panel lists the library's notes after
/// `[[`, its attachments after `![[` (#705), and a note's headings after
/// `#`, and its block ids after `#^` (#844). Everything comes from what the
/// app already keeps: the notes, the attachments and the aliases from
/// `note_stems` ([NoteNames]: one query, never a walk of the tree), a note's
/// headings and block ids from its own file — read and outlined off the UI
/// isolate, once per revision of it (#491) — the headings and ids of the whole
/// library from their word index (`[[##`, `[[^^`; #845; [AnchorSuggestions]),
/// and a book's place forms from the target itself. Nothing here scans the
/// library to fill the panel.
library;

import 'package:niman/src/db/anchor_index.dart';
import 'package:niman/src/db/index_database.dart';
import 'package:niman/src/links/anchor_suggestions.dart';
import 'package:niman/src/links/block_anchors.dart';
import 'package:niman/src/links/note_names.dart';
import 'package:niman/src/links/resolver.dart';
import 'package:niman/src/links/suggestion.dart';
import 'package:niman/src/ui/strings.dart';
import 'package:path/path.dart' as p;

export 'package:niman/src/links/suggestion.dart';

/// The library the panel reads: the notes after `[[`, a note's headings after
/// `#`, and a book's place forms. [IndexWikilinkSuggester] is the production
/// implementation over the drift index; a widget test injects a fake.
abstract interface class WikilinkSuggester {
  /// The notes and aliases matching [query], best match first: prefix
  /// matches before contains, then by path. An empty [query] lists the
  /// library from the top. A note a `[[…]]` target cannot carry (#491) is
  /// left out: the row would write a link the parser reads back as another
  /// note.
  Future<List<NoteSuggestion>> notes(String query);

  /// What an `![[` embed can name, matching [query] (#705): the files of the
  /// attachments folder first — pictures, audio, video, PDFs, whatever is
  /// there — then the attachments kept elsewhere (a picture beside its
  /// note), then the notes, which an embed transcludes. Ranked within each
  /// as [notes] ranks; a target keeps its extension (`photo.png`).
  Future<List<NoteSuggestion>> embeds(String query);

  /// The shortest wiki target that names the file at [path] alone (#704):
  /// its name (`.md` dropped, any other extension kept), with as much of
  /// its folder as another file of that name makes it take.
  Future<String> targetOf(String path);

  /// The headings of the note named by the wiki [target] — `note`,
  /// `folder/note` — or none when it does not resolve or cannot be read.
  /// The list is the note's own headings, as the outline reads them; the
  /// panel filters it for the heading being typed.
  Future<List<HeadingSuggestion>> headings(String target);

  /// The block ids of the note named by the wiki [target] — the blocks that
  /// end with a ` ^id` — or none when it does not resolve or cannot be read.
  /// The panel filters the list for the id being typed after `#^`.
  Future<List<BlockIdSuggestion>> blocks(String target);

  /// The headings of the whole library that match [query] (`[[##query`),
  /// best match first, each with the note it is in. Bounded: at most
  /// [IndexWikilinkSuggester.limit] rows, read from the library's word index
  /// and never a scan of its notes.
  Future<List<HeadingSuggestion>> headingsAcross(String query);

  /// The block ids of the whole library that match [query] (`[[^^query`), as
  /// [headingsAcross].
  Future<List<BlockIdSuggestion>> blocksAcross(String query);

  /// The place forms the book named by [target] offers, or none when the
  /// target is not a PDF or an EPUB.
  Future<List<BookSuggestion>> bookPlaces(String target);
}

/// The panel's suggestions, read off the library's index.
///
/// The notes come from [NoteNames], the headings and block ids from
/// [AnchorSuggestions], a book's forms from the target's extension.
final class IndexWikilinkSuggester implements WikilinkSuggester {
  /// Creates a suggester over [db], reading a named note's headings through
  /// [readHeadings] (the session's own read and scan of a library-relative
  /// path, off the UI isolate; null when it is gone).
  ///
  /// [attachmentsFolder] names the library's attachments folder, whose
  /// files an embed lists first; null lists every attachment as one.
  factory(
    IndexDatabase db, {
    required Future<List<String>?> Function(String path) readHeadings,
    Future<List<BlockAnchor>?> Function(String path)? readBlocks,
    Future<String> Function()? attachmentsFolder,
  }) {
    final resolver = LinkResolver(db);
    final names = NoteNames(db, attachmentsFolder: attachmentsFolder);
    return IndexWikilinkSuggester.of(
      resolver,
      names,
      AnchorSuggestions(
        resolver,
        AnchorIndex(db),
        names,
        readHeadings: readHeadings,
        readBlocks: readBlocks,
      ),
    );
  }

  /// Composes the parts, made apart.
  const new of(this._resolver, this._names, this._anchors);

  final LinkSource _resolver;
  final NoteNames _names;
  final AnchorSuggestions _anchors;

  /// How many rows the panel is handed.
  static const int limit = NoteNames.limit;

  @override
  Future<List<NoteSuggestion>> notes(String query) => _names.notes(query);

  @override
  Future<List<NoteSuggestion>> embeds(String query) => _names.embeds(query);

  @override
  Future<String> targetOf(String path) => _names.targetOf(path);

  @override
  Future<List<HeadingSuggestion>> headings(String target) =>
      _anchors.headings(target);

  @override
  Future<List<BlockIdSuggestion>> blocks(String target) =>
      _anchors.blocks(target);

  @override
  Future<List<HeadingSuggestion>> headingsAcross(String query) =>
      _anchors.headingsAcross(query);

  @override
  Future<List<BlockIdSuggestion>> blocksAcross(String query) =>
      _anchors.blocksAcross(query);

  @override
  Future<List<BookSuggestion>> bookPlaces(String target) async {
    final note = await noteNamed(_resolver, target);
    // The hint beside the form is a label, written when the panel is drawn:
    // it follows the language the app speaks.
    switch (p.extension(note?.path ?? target).toLowerCase()) {
      case '.pdf':
        return <BookSuggestion>[
          BookSuggestion(form: 'page=', hint: AppStrings.suggesterPageHint),
        ];
      case '.epub':
        return <BookSuggestion>[
          BookSuggestion(
            form: 'chapter=',
            hint: AppStrings.suggesterChapterHint,
          ),
        ];
      default:
        return const <BookSuggestion>[];
    }
  }
}
