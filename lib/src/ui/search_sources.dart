import 'package:niman/src/core/logging.dart';
import 'package:niman/src/frontmatter/fields.dart';
import 'package:niman/src/library/session.dart';
import 'package:niman/src/search/search_repo.dart';
import 'package:niman/src/ui/search_field_pager.dart';

/// Where the Search screen reads from: the search source and the
/// frontmatter-field source, each the screen's override (widget tests
/// inject a fake) or else the open library session's.
final class SearchSources {
  /// Creates the sources over [session], with the screen's overrides.
  new({
    required this.session,
    required this.searchOverride,
    required this.fieldOverride,
  });

  /// The open library session.
  final LibrarySession Function() session;

  /// The search-source override, or null to resolve it from [session].
  final SearchSource? Function() searchOverride;

  /// The field-source override, or null to resolve it from [session].
  final FieldSource? Function() fieldOverride;

  FieldSource? _fields;

  /// The frontmatter-field source, resolved on first use.
  ///
  /// Unlike the search source it needs no warming: it runs on the UI
  /// connection, and a `key = value` filter is an indexed lookup, not a
  /// MATCH over every body in the library.
  Future<FieldSource?> fields() async {
    final own = fieldOverride();
    if (own != null) return own;
    final cached = _fields;
    if (cached != null) return cached;
    try {
      return _fields = await session().fieldSource;
    } on Object catch (e) {
      const AppLogger(name: 'search.ui').warning('field source failed: $e');
      return null;
    }
  }

  /// The search source: the override, else the [cached] one the screen
  /// holds, else the session's; null when it cannot be had.
  Future<SearchSource?> search({SearchSource? cached}) async {
    final own = searchOverride();
    if (own != null) return own;
    if (cached != null) return cached;
    try {
      return await session().searchSource;
    } on Object catch (e) {
      // The session owns one cached background connection, so a failure
      // here is a real (rare) startup problem; the next query retries.
      const AppLogger(name: 'search.ui')
          .warning('search source unavailable: $e');
      return null;
    }
  }

  /// The pages of the `key = value` filter [f], or null where there is no
  /// field source. Its notes are shaped like search hits, so the results
  /// list stays one list; there is no snippet: the match is the field, not
  /// a place in the text.
  Future<FieldPager?> fieldPager(({String key, String value}) f) async {
    final fields = await this.fields();
    return fields == null ? null : FieldPager(fields, f.key, f.value);
  }
}
