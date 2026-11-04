import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/search_field_pager.dart';

/// The note hits the Search screen holds and how many of it lists: a
/// page of [pageSize] at a time, Show more listing the next — and, for a
/// `key = value` filter, reading the filter's next page once the hits
/// held run out (#1037).
///
/// A plain holder: the screen changes it inside its own `setState`.
final class SearchPages {
  /// How many hits a page lists.
  static const int pageSize = 50;

  List<SearchHit> _hits = const [];
  int _shown = 0;
  FieldPager? _pager;
  bool _reading = false;

  /// The note hits held.
  List<SearchHit> get hits => _hits;

  /// How many of [hits] are listed.
  int get shown => _shown;

  /// The pages of the `key = value` filter [hits] came from (#1037), or
  /// null for a text search: the notes past the page read are in the index
  /// and not in [hits].
  FieldPager? get pager => _pager;

  /// Whether the list ends in its Show more row: notes held and not shown,
  /// or a filter with pages left to read.
  bool get hasMore => _shown < _hits.length || (_pager?.hasMore ?? false);

  /// Drops the hits; the filter's pages stay as they were.
  void clear() {
    _hits = const [];
    _shown = 0;
  }

  /// Holds [results], read through [pager] for a filter. A [fresh] result
  /// set lists its first page; one that grows lists at least as much.
  void land(
    List<SearchHit> results, {
    required FieldPager? pager,
    required bool fresh,
  }) {
    _pager = pager;
    _hits = results;
    final page = pageSize < results.length ? pageSize : results.length;
    // A scan adding hits keeps the pages the reader has opened.
    final kept = _shown < results.length ? _shown : results.length;
    _shown = fresh || kept < page ? page : kept;
  }

  /// Lists the hits down to the one at [index] at least: a hit under the
  /// page's cut is listed first.
  void showThrough(int index) {
    if (index >= _shown) _shown = index + 1;
  }

  /// Lists the next page of the hits held; true when the filter has to
  /// read its next page for it ([readMore]).
  bool showMore() {
    final next = _shown + pageSize;
    final read = next >= _hits.length && (_pager?.hasMore ?? false);
    _shown = next < _hits.length ? next : _hits.length;
    return read;
  }

  /// Reads the filter's next page and lists it after the notes shown
  /// (#1037); false when none was read, or when it lands for a filter
  /// since replaced, which drops it.
  Future<bool> readMore() async {
    final pager = _pager;
    if (pager == null || _reading) return false;
    _reading = true;
    final more = await pager.next();
    if (!identical(pager, _pager)) return false;
    _reading = false;
    _hits = [..._hits, ...more];
    _shown = _shown + pageSize < _hits.length
        ? _shown + pageSize
        : _hits.length;
    return true;
  }
}
