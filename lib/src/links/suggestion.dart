/// The rows the wikilink suggester panel can show (#475).
library;

/// One row the panel can show.
sealed class SuggestEntry {
  /// Creates an entry.
  const new();
}

/// A note a `[[` target can name, or a file an `![[` embed can.
final class NoteSuggestion extends SuggestEntry {
  /// Creates a note row: [name] shown, [folder] dimmed, [target] written.
  const new({
    required this.name,
    required this.folder,
    required this.target,
    this.alias,
  });

  /// The name shown — the file's name, its case as on disk (`.md` dropped,
  /// any other extension kept: `photo.png`).
  final String name;

  /// The folder the note sits in, relative to the library; empty at the root.
  final String folder;

  /// What completing the link writes: the stem, `.md` dropped, when that
  /// names this note alone; otherwise the shortest tail of its path that
  /// does (`work/Meeting`), the way the resolver qualifies a shared name. A
  /// bare name shared by two notes resolves to neither of them for sure, so
  /// the row the user picked would not be the note the link opens.
  final String target;

  /// The alias the note was found through, when its own name did not match
  /// the query; null when the name matched, or the query is empty.
  final String? alias;
}

/// A heading a `#` target can name.
final class HeadingSuggestion extends SuggestEntry {
  /// Creates a heading row; a row of the library-wide list (`[[##`) also
  /// says which note it is in.
  const new(this.heading, {this.path, this.target});

  /// The rows for the heading [texts] of one note: those a link can spell.
  static List<HeadingSuggestion> linkable(Iterable<String> texts) => [
    for (final text in texts)
      if (readsBack(text)) HeadingSuggestion(text),
  ];

  /// Whether a link to [heading] reads back as that heading.
  ///
  /// The link ends at its first `]]` and a `|` starts its alias, so a heading
  /// holding one has no wikilink spelling and is left out of the panel. A `#`
  /// is no obstacle: `[[Notes#Issue #12]]` reads as the path `Issue` > `12`
  /// first and, when the note has none, as the heading `Issue #12`.
  static bool readsBack(String heading) => !_unspellable.hasMatch(heading);

  static final RegExp _unspellable = RegExp(r'[|\[\]]');

  /// The heading text, as the outline reads it.
  final String heading;

  /// The library-relative path of the note the heading is in, for a row of a
  /// list across the library; null in a note's own list.
  final String? path;

  /// What completing the link writes before the `#`: the shortest target that
  /// names that note alone (the rule the note rows follow). Null in a note's
  /// own list.
  final String? target;
}

/// A block id a `#^` target can name (#844).
final class BlockIdSuggestion extends SuggestEntry {
  /// Creates a block row; a row of the library-wide list (`[[^^`) also says
  /// which note it is in.
  const new(this.id, {this.excerpt = '', this.path, this.target});

  /// The id, without its `^`.
  final String id;

  /// The block's first words, to tell one id from another.
  final String excerpt;

  /// The library-relative path of the note the block is in, for a row of a
  /// list across the library; null in a note's own list.
  final String? path;

  /// What completing the link writes before the `#^`: as for
  /// [HeadingSuggestion.target]. Null in a note's own list.
  final String? target;
}

/// A place form a book target offers after `#` — `page=` for a PDF,
/// `chapter=` for an EPUB (docs/user/links.md).
final class BookSuggestion extends SuggestEntry {
  /// Creates a place row: the text to insert and what still has to be typed.
  const new({required this.form, required this.hint});

  /// What completing the row writes, e.g. `page=`.
  final String form;

  /// The dimmed note beside it, e.g. `type a number`.
  final String hint;
}
