/// The pages of a `key = value` filter in Search (#1037).
///
/// A key most notes carry (`type = note`, `status =`) names a million
/// notes at a million-note library: a list nobody scrolls, and a million
/// rows and hits in memory. So the filter reads a page at a time, in path
/// order, from a cursor on the last path it has shown, and knows the real
/// count from the index — the way the tag list caps what opening a tag
/// reads.
library;

import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/tree.dart' show displayNameOf;

/// One filter's pages: where it stands and how to read the next one.
final class FieldPager {
  /// A filter of [key] and [value] over [_source].
  new(this._source, this.key, this.value);

  final FieldSource _source;

  /// The key asked for.
  final String key;

  /// The value asked for; empty for every note declaring the key.
  final String value;

  /// How many notes a page holds.
  static const int pageSize = 500;

  String? _after;
  int _total = 0;
  int _read = 0;

  /// How many notes the filter lists in all.
  int get total => _total;

  /// Whether notes remain past the pages read.
  bool get hasMore => _read < _total;

  /// The first page. The count is read when the page is full, the only
  /// time it can differ from the page's length.
  Future<List<SearchHit>> first() async {
    final page = await _page();
    _total = page.length < pageSize
        ? page.length
        : await _source.countWithField(key, value);
    return page;
  }

  /// The page after the last one read; none when the list has ended.
  Future<List<SearchHit>> next() async {
    if (!hasMore) return const [];
    final page = await _page();
    // A list that shrank under the reader ends where it ends.
    if (page.length < pageSize) _total = _read;
    return page;
  }

  Future<List<SearchHit>> _page() async {
    final notes = await _source.notesWithField(
      key,
      value,
      limit: pageSize,
      after: _after,
    );
    if (notes.isNotEmpty) _after = notes.last.path;
    _read += notes.length;
    return [
      for (final note in notes)
        SearchHit(
          noteId: note.id,
          path: note.path,
          title: displayNameOf(note),
          snippet: '',
        ),
    ];
  }
}
