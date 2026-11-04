import 'package:niman/src/search/query.dart';

/// The `key = value` filter [text] asks for, or null when it is a text
/// search.
///
/// Only in Words mode: Contains ([contains]) is a literal scan of the note
/// bodies, and someone who typed `x = y` there meant to find that string.
({String key, String value})? searchFieldFilter(
  String text, {
  required bool contains,
}) => contains ? null : fieldQuery(text);

/// Whether [text] is a search worth running, in Contains mode when
/// [contains] is set. A one-character FTS prefix (words mode) expands to
/// every term starting with that letter — a multi-second MATCH on a real
/// library, with every query typed after it queueing behind it (T-M3-09
/// device report: `"e"*`/`"p"*` took 9–18 s and the follow-up queries
/// "returned nothing"). Two characters is the floor for both modes; in
/// words mode the last (growing) token must be two characters too,
/// whatever came before it.
bool canSearchQuery(String text, {required bool contains}) {
  if (text.length < 2) return false;
  // A `key = value` filter is an indexed lookup, so the prefix-expansion
  // problem the floor exists for does not apply: `x = 1` runs.
  if (searchFieldFilter(text, contains: contains) != null) return true;
  if (contains) return true;
  final last = text.split(RegExp(r'\s+')).last;
  return last.length >= 2;
}
